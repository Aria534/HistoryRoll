extends SceneTree

const GameplayScene = preload("res://gameplay_placeholder.tscn")
const GameplayScript = preload("res://gameplay_placeholder.gd")
const ProgressScript = preload("res://progress_manager.gd")
const TEST_SAVE := "user://historyroll_completion_card_test.json"

var passed := 0
var failed := 0


class MockProgress:
	extends Node
	var selected_level := 1
	var completion_calls := 0
	var finish_calls := 0
	var recorded_score := -1
	var recorded_statistics: Dictionary = {}
	var delegate: Node

	func record_board_completion(level_id: int, final_score: int, stats: Dictionary) -> bool:
		completion_calls += 1
		recorded_score = final_score
		recorded_statistics = stats.duplicate(true)
		if delegate != null:
			return delegate.record_board_completion(level_id, final_score, stats)
		return true

	func is_certificate_unlocked() -> bool:
		return delegate != null and delegate.is_certificate_unlocked()

	func finish_level_results(level_id: int) -> bool:
		finish_calls += 1
		return delegate.finish_level_results(level_id) if delegate != null else true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	for level_id: int in range(1, 7):
		await _test_level(level_id, Vector2i(1024, 1536))
		await _test_level(level_id, Vector2i(720, 1280))
	await _test_level(1, Vector2i(1080, 2400))
	await _test_bonus_breakdown()
	await _test_zero_and_large_scores()
	await _test_saved_progression()
	await _test_invalid_level()
	_cleanup()
	# Stop procedural test music before engine teardown; no preference is saved.
	var shutdown_audio: Node = get_root().get_node_or_null("AudioManager")
	if shutdown_audio != null:
		shutdown_audio.stop_music(0.0)
	# Accelerated rolls finish before the existing 0.95-second answer callback.
	# Drain those timer continuations before destroying the engine test process.
	await create_timer(1.1).timeout
	await process_frame
	await process_frame
	print("Level completion tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _fixture(level_id: int, viewport_size: Vector2i, delegate: Node = null) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var progress := MockProgress.new()
	progress.selected_level = level_id
	progress.delegate = delegate
	var requested: Array[String] = []
	var game = GameplayScene.instantiate()
	game.progress_manager = progress
	game.shuffle_questions = false
	game.enable_test_dice_controls = true
	game.dice_animation_steps = 1
	game.dice_animation_interval = 0.001
	game.movement_step_duration = 0.001
	game.tile_effect_duration = 0.001
	game.scene_change_handler = func(path: String) -> void: requested.append(path)
	viewport.add_child(game)
	for frame_index in 3:
		await process_frame
	return {"viewport": viewport, "game": game, "progress": progress, "requested": requested}


func _finish_valid(game: Node, correct: bool = true) -> void:
	var answer_index: int = int(game.current_question.correct_index)
	if not correct:
		answer_index = (answer_index + 1) % game.current_question.choices.size()
	game.answer_buttons[answer_index].pressed.emit()
	game.player_position = game.tile_count - 1
	game.board_view.set_player_position_immediate(game.player_position)
	var roll: Array[int] = [1]
	game.set_controlled_dice_results(roll)
	game.roll_button.pressed.emit()
	for frame_index in 600:
		if game.state == GameplayScript.GameplayState.LEVEL_COMPLETE:
			break
		await process_frame
	_check(game.state == GameplayScript.GameplayState.LEVEL_COMPLETE and game.player_position == game.tile_count, "valid exact roll reaches the finish")
	await create_timer(0.4).timeout


func _test_level(level_id: int, viewport_size: Vector2i) -> void:
	var fixture := await _fixture(level_id, viewport_size)
	var game = fixture.game
	var progress: MockProgress = fixture.progress
	var label := "Level %d %dx%d" % [level_id, viewport_size.x, viewport_size.y]
	_check(not game.results_panel.visible, "%s card starts hidden" % label)
	await _finish_valid(game)
	var card = game.results_panel
	_check(card.visible and card.artwork.visible, "%s completion card appears" % label)
	_check(card.great_job_label.text == "Great Job!", "%s displays congratulations" % label)
	_check(card.level_title.text == "Level %d Completed" % level_id, "%s displays the actual level number" % label)
	_check(card.your_score_label.text == "10" and card.bonus_score_label.text == "0" and card.total_score_label.text == "10", "%s uses the actual score, bonus, and total" % label)
	_check(progress.completion_calls == 1 and progress.recorded_score == game.score, "%s final score is saved once" % label)
	_check(progress.recorded_statistics.correct_answers == 1, "%s gameplay statistics are preserved" % label)
	_check(game.roll_button.disabled and game.back_button.disabled and not game.question_popup_layer.visible, "%s board input and question popup are closed" % label)
	_check(card.summary_label.visible and game.results_label.text == "Correct: 1     Incorrect: 0", "%s correct and incorrect totals are visible" % label)
	_check(game.return_button.text == "Continue" and not game.return_button.disabled, "%s Continue is available" % label)
	_check(_inside(card.get_card_rect(), viewport_size), "%s complete artwork fits portrait viewport" % label)
	_check(is_equal_approx(card.artwork.size.aspect(), card.artwork.texture.get_size().aspect()), "%s artwork is not stretched" % label)
	var previous_rect := Rect2()
	for heading: Label in [card.your_score_heading, card.bonus_score_heading, card.total_score_heading]:
		_check(not previous_rect.has_area() or previous_rect.end.y < heading.get_global_rect().position.y, "%s score rows stay separate" % label)
		previous_rect = heading.get_global_rect()
	for text_label: Label in card._completion_labels():
		var font_size := text_label.get_theme_font_size("font_size")
		var font := text_label.get_theme_font("font")
		var text_size := font.get_string_size(text_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		_check(text_size.x <= text_label.size.x and font.get_height(font_size) <= text_label.size.y + 1.0, "%s %s text fits" % [label, text_label.name])
		_check(card.get_card_rect().encloses(text_label.get_global_rect()), "%s %s stays inside the card" % [label, text_label.name])
	_check(_inside(game.return_button.get_global_rect(), viewport_size), "%s Continue stays on-screen" % label)
	var final_score: int = game.score
	game._complete_level()
	_check(progress.completion_calls == 1 and game.score == final_score, "%s repeated completion cannot add rewards" % label)
	await _capture(fixture.viewport, "completion_level_%d_%dx%d.png" % [level_id, viewport_size.x, viewport_size.y])
	if level_id == 1 and viewport_size == Vector2i(1024, 1536):
		fixture.viewport.size = Vector2i(720, 1280)
		for resize_frame in 4:
			await process_frame
		_check(_inside(card.get_card_rect(), Vector2i(720, 1280)), "open card follows a viewport resize")
		_check(game.return_button.size.x <= card.get_card_rect().size.x * 0.5, "resized Continue hit area stays aligned with its green artwork")
		_check(card.get_card_rect().encloses(game.return_button.get_global_rect()), "resized Continue remains inside the completion card")
	_click(fixture.viewport, game.return_button.get_global_rect().get_center())
	_click(fixture.viewport, game.return_button.get_global_rect().get_center())
	game.return_button.pressed.emit()
	_check(fixture.requested == ["res://level_selection.tscn"] and progress.finish_calls == 1, "%s Continue returns to Level Selection once" % label)
	game._complete_level()
	_check(game.return_button.disabled and progress.completion_calls == 1, "%s completion cannot re-enable a consumed Continue button" % label)
	await _dispose(fixture)


func _test_bonus_breakdown() -> void:
	var fixture := await _fixture(1, Vector2i(1024, 1536))
	var game = fixture.game
	game.bonus_points = 25
	game._collect_bonus()
	await _finish_valid(game)
	var card = game.results_panel
	_check(game.score == 35 and game.bonus_score_increase == 25, "existing Bonus Tile reward is unchanged")
	_check(card.your_score_label.text == "10" and card.bonus_score_label.text == "25" and card.total_score_label.text == "35", "bonus is shown separately without being awarded again")
	_check(fixture.progress.recorded_score == 35, "saved score matches the displayed total")
	await _dispose(fixture)


func _test_zero_and_large_scores() -> void:
	var fixture := await _fixture(1, Vector2i(720, 1280))
	await _finish_valid(fixture.game, false)
	_check(fixture.game.results_panel.total_score_label.text == "0" and fixture.game.score == 0, "zero-score completion never invents a reward")
	await _dispose(fixture)
	fixture = await _fixture(1, Vector2i(720, 1280))
	var game = fixture.game
	game.score = 2999990
	game.bonus_score_increase = 1000000
	await _finish_valid(game)
	var card = game.results_panel
	_check(card.your_score_label.text == "2,000,000" and card.bonus_score_label.text == "1,000,000" and card.total_score_label.text == "3,000,000", "large scores use readable thousands separators")
	await _capture(fixture.viewport, "completion_large_score_720x1280.png")
	card.present_completion(1, 5, 25)
	await create_timer(0.4).timeout
	_check(card.your_score_label.text == "-20" and card.bonus_score_label.text == "25" and card.total_score_label.text == "5", "deductions remain represented without changing the nonnegative final score")
	await _dispose(fixture)


func _test_saved_progression() -> void:
	var progress = ProgressScript.new()
	progress.save_path = TEST_SAVE
	for level_id: int in range(1, 7):
		_check(progress.select_level(level_id), "saved progression permits Level %d" % level_id)
		var fixture := await _fixture(level_id, Vector2i(720, 1280), progress)
		await _finish_valid(fixture.game)
		_check(progress.is_level_completed(level_id) and int(progress.best_scores[str(level_id)]) == 10, "Level %d completion preserves saved progress and score" % level_id)
		if level_id < 6:
			_check(progress.is_level_unlocked(level_id + 1), "Level %d still unlocks the next level" % level_id)
		_click(fixture.viewport, fixture.game.return_button.get_global_rect().get_center())
		var expected_scene := "res://certificate.tscn" if level_id == 6 else "res://level_selection.tscn"
		_check(fixture.requested == [expected_scene], "Level %d Continue opens its approved destination" % level_id)
		await _dispose(fixture)
	var reward_count: int = progress.claimed_character_rewards.size()
	var hero_count: int = progress.unlocked_characters.size()
	progress.select_level(1)
	var replay := await _fixture(1, Vector2i(720, 1280), progress)
	await _finish_valid(replay.game)
	_check(replay.game.results_panel.visible and replay.game.results_panel.level_title.text == "Level 1 Completed", "replaying a completed level shows the card again")
	_check(progress.claimed_character_rewards.size() == reward_count and progress.unlocked_characters.size() == hero_count, "replay cannot duplicate one-time hero rewards")
	await _dispose(replay)
	var reloaded = ProgressScript.new()
	reloaded.save_path = TEST_SAVE
	reloaded.load_progress()
	_check(reloaded.completed_levels.size() == 6 and reloaded.game_completed, "all six completions survive save reload")
	_check(reloaded.claimed_character_rewards.size() == 6, "character rewards remain unique across the six completions")
	progress.free()
	reloaded.free()


func _test_invalid_level() -> void:
	var fixture := await _fixture(999, Vector2i(720, 1280))
	var game = fixture.game
	var card = game.results_panel
	_check(game.fatal_error_active and card.visible, "misconfigured gameplay still displays an error")
	_check(not card.artwork.visible and not card.great_job_label.visible and card.summary_label.visible, "fatal errors never display false congratulations")
	_check(fixture.progress.completion_calls == 0, "fatal errors do not record a completed level")
	_click(fixture.viewport, game.return_button.get_global_rect().get_center())
	_check(fixture.requested == ["res://level_selection.tscn"] and fixture.progress.finish_calls == 0, "error Back returns safely without processing results")
	await _dispose(fixture)


func _capture(viewport: SubViewport, filename: String) -> void:
	await RenderingServer.frame_post_draw
	var rendered: Image = viewport.get_texture().get_image()
	_check(rendered != null and not rendered.is_empty() and rendered.save_png("user://%s" % filename) == OK, "%s actual Godot render saved" % filename)


func _dispose(fixture: Dictionary) -> void:
	fixture.game.progress_manager = null
	fixture.viewport.queue_free()
	await process_frame
	fixture.progress.free()


func _click(viewport: SubViewport, point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	viewport.push_input(event, true)
	var release := event.duplicate() as InputEventMouseButton
	release.pressed = false
	viewport.push_input(release, true)


func _inside(rect: Rect2, viewport_size: Vector2i) -> bool:
	return rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= viewport_size.x + 0.1 and rect.end.y <= viewport_size.y + 0.1


func _cleanup() -> void:
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))


func _check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
		print("PASS: ", description)
	else:
		failed += 1
		push_error("FAIL: %s" % description)

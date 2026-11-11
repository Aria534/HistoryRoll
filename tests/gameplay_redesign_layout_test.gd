extends SceneTree

const GameplayScene = preload("res://gameplay_placeholder.tscn")
const GameplayScript = preload("res://gameplay_placeholder.gd")

var passed := 0
var failed := 0

class MockProgress:
	extends Node
	var selected_level := 1
	func record_board_completion(_level: int, _score: int, _stats: Dictionary) -> bool: return true
	func finish_level_results(_level: int) -> bool: return true

func _init() -> void: call_deferred("_run")

func _run() -> void:
	for level_id: int in range(1, 7):
		await _capture_level(level_id, Vector2i(1024, 1536), "gameplay_level_%d_1024x1536.png" % level_id)
	await _capture_level(1, Vector2i(720, 1280), "gameplay_level_1_720x1280.png")
	await _capture_level(6, Vector2i(720, 1280), "gameplay_level_6_720x1280.png")
	await _capture_dice_on_board("gameplay_dice_on_board.png")
	await _capture_reaction(true, "gameplay_happy_reaction.png")
	await _capture_reaction(false, "gameplay_sad_reaction.png")
	print("Gameplay redesign layout tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)

func _capture_level(level_id: int, viewport_size: Vector2i, filename: String) -> void:
	var viewport := SubViewport.new(); viewport.size = viewport_size; viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var progress := MockProgress.new(); progress.selected_level = level_id
	var game = GameplayScene.instantiate(); game.progress_manager = progress; game.shuffle_questions = false
	viewport.add_child(game); await process_frame; await process_frame
	_check(game.question_label.visible, "Level %d question is visible before rolling at %s" % [level_id, viewport_size])
	_check(game.roll_button.disabled, "Level %d dice is initially disabled" % level_id)
	var choice_count: int = game.current_question.get("choices", []).size()
	var expected_columns: int = choice_count if choice_count <= 3 else 2
	_check(game.answers_grid.columns == expected_columns, "Level %d balances its %d answer choices across the quiz row" % [level_id, choice_count])
	_check(not game.get_node("MarginContainer/Content/HistoryRollBrand").visible, "Level %d gameplay header removes the redundant HistoryRoll logo" % level_id)
	var level_banner := game.get_node("MarginContainer/Content/Header/LevelBannerBackground") as TextureRect
	var back_button := game.get_node("%BackButton") as Button
	_check(not level_banner.visible and not game.level_label.visible, "Level %d gameplay header removes the level parchment and title" % level_id)
	_check(back_button.visible and back_button.size.y >= 60.0, "Level %d keeps a large touch-friendly Back to Levels button" % level_id)
	_check(game.board_panel.size.y >= minf(float(viewport_size.y) * 0.45, 700.0), "Level %d board uses the freed header space" % level_id)
	_check(game.board_view.get_board_rect().size.x <= game.board_view.size.x + 0.1, "Level %d board fits horizontally" % level_id)
	_check(game.board_view.player_sprite.texture != null and game.board_view.player_sprite.visible, "Level %d current hero chibi is visible" % level_id)
	_check(game.board_view.player_token_label.visible == false, "Level %d no longer shows start initials over the chibi" % level_id)
	var player_center: Vector2 = game.board_view.player_token.position + game.board_view.player_token.size / 2.0
	_check(player_center.distance_to(game.board_view.get_tile_center(1)) < 1.0, "Level %d current hero starts on Tile 1" % level_id)
	var board_rect: Rect2 = game.board_view.get_board_rect()
	var cell_size := Vector2(board_rect.size.x / game.board_view.columns, board_rect.size.y / game.board_view.rows)
	var previous_token_size := clampf(minf(cell_size.x, cell_size.y) * 0.86, 38.0, 96.0)
	_check(game.board_view.player_token.size.x >= previous_token_size + 4.0, "Level %d current hero chibi is enlarged" % level_id)
	if level_id == 1:
		var player_rotation_before: float = game.board_view.player_sprite.rotation
		var player_position_before: Vector2 = game.board_view.player_sprite.position
		await create_timer(0.24).timeout
		_check(not is_equal_approx(game.board_view.player_sprite.rotation, player_rotation_before), "current hero visibly moves during its idle animation")
		_check(not game.board_view.player_sprite.position.is_equal_approx(player_position_before), "current hero visibly bobs instead of only resizing")
	var finish_center: Vector2 = game.board_view.waiting_hero_token.position + game.board_view.waiting_hero_token.size / 2.0
	_check(finish_center.distance_to(game.board_view.get_tile_center(game.tile_count)) < 1.0, "Level %d finish marker is centered on the final tile" % level_id)
	if level_id < 6:
		_check(game.board_view.waiting_hero_sprite.texture != null and game.board_view.waiting_hero_sprite.visible, "Level %d next unlock hero chibi is visible at the finish" % level_id)
		_check(game.board_view.waiting_hero_sprite.texture.resource_path.ends_with("_wave.png"), "Level %d finish hero uses its waving pose" % level_id)
		_check(game.board_view.waiting_hero_label.visible == false, "Level %d next hero chibi replaces finish initials" % level_id)
		if level_id == 1:
			var wave_rotation_before: float = game.board_view.waiting_hero_sprite.rotation
			await create_timer(0.24).timeout
			_check(not is_equal_approx(game.board_view.waiting_hero_sprite.rotation, wave_rotation_before), "finish hero visibly moves during its wave animation")
	else:
		_check(not game.board_view.waiting_hero_sprite.visible and game.board_view.waiting_hero_label.text == "TROPHY", "Level 6 uses the final trophy instead of inventing a next hero")
	var image: Image = viewport.get_texture().get_image()
	_check(image != null and not image.is_empty() and image.save_png(ProjectSettings.globalize_path("user://%s" % filename)) == OK, "%s rendered capture is saved" % filename)
	game.progress_manager = null; game.queue_free(); viewport.queue_free(); await process_frame; progress.free()

func _capture_dice_on_board(filename: String) -> void:
	var viewport := SubViewport.new(); viewport.size = Vector2i(720, 1280); viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var progress := MockProgress.new()
	var game = GameplayScene.instantiate(); game.progress_manager = progress; game.shuffle_questions = false
	game.enable_test_dice_controls = true; game.dice_animation_steps = 1; game.dice_animation_interval = 0.001; game.movement_step_duration = 0.001
	viewport.add_child(game); await process_frame
	game.answer_buttons[int(game.current_question.correct_index)].pressed.emit()
	var controlled_roll: Array[int] = [4]
	game.set_controlled_dice_results(controlled_roll); game.roll_button.pressed.emit()
	for frame_index: int in range(120):
		if game.state == GameplayScript.GameplayState.QUESTION and game.player_position == 5: break
		await process_frame
	_check(game.board_view.board_die.visible and game.board_view.board_die.face_value == 4, "on-board die visibly shows the movement result")
	_check(game.dice_label.text == "4", "numeric DIE readout matches the on-board die")
	var image: Image = viewport.get_texture().get_image()
	_check(image != null and not image.is_empty() and image.save_png(ProjectSettings.globalize_path("user://%s" % filename)) == OK, "%s is saved" % filename)
	game.progress_manager = null; game.queue_free(); viewport.queue_free(); await process_frame; progress.free()

func _capture_reaction(correct: bool, filename: String) -> void:
	var viewport := SubViewport.new(); viewport.size = Vector2i(1024, 1536); viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var progress := MockProgress.new(); var game = GameplayScene.instantiate(); game.progress_manager = progress; game.shuffle_questions = false
	viewport.add_child(game); await process_frame
	var index := int(game.current_question.correct_index)
	if not correct: index = (index + 1) % 4
	game.answer_buttons[index].pressed.emit(); await process_frame
	_check(game.reaction_label.visible, "%s chibi reaction is visible" % ("happy" if correct else "sad"))
	var image: Image = viewport.get_texture().get_image()
	_check(image != null and not image.is_empty() and image.save_png(ProjectSettings.globalize_path("user://%s" % filename)) == OK, "%s is saved" % filename)
	game.progress_manager = null; game.queue_free(); viewport.queue_free(); await process_frame; progress.free()

func _check(value: bool, description: String) -> void:
	if value: passed += 1; print("PASS: ", description)
	else: failed += 1; push_error("FAIL: %s" % description)

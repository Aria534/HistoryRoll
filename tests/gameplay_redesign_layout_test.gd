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
	await _capture_level(1, Vector2i(1080, 1920), "gameplay_level_1_1080x1920.png")
	await _capture_level(1, Vector2i(1080, 2400), "gameplay_level_1_1080x2400.png")
	await _capture_level(6, Vector2i(720, 1280), "gameplay_level_6_720x1280.png")
	await _capture_long_mactan_question()
	await _capture_dice_on_board("gameplay_dice_on_board.png")
	await _capture_reaction(true, "gameplay_happy_reaction.png")
	await _capture_reaction(false, "gameplay_sad_reaction.png")
	await _test_pointer_controls()
	print("Gameplay redesign layout tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)

func _capture_level(level_id: int, viewport_size: Vector2i, filename: String) -> void:
	var viewport := SubViewport.new(); viewport.size = viewport_size; viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var progress := MockProgress.new(); progress.selected_level = level_id
	var game = GameplayScene.instantiate(); game.progress_manager = progress; game.shuffle_questions = false
	viewport.add_child(game); await process_frame; await process_frame
	_check(game.question_label.visible, "Level %d question is visible before rolling at %s" % [level_id, viewport_size])
	_check(game.question_popup_layer.visible, "Level %d question opens in a modal popup" % level_id)
	_check(game.question_popup_layer.z_index > game.board_panel.z_index, "Level %d question popup appears above the board" % level_id)
	_check(game.roll_button.visible and game.roll_button.disabled, "Level %d bottom Roll Dice is initially visible and disabled" % level_id)
	_check(_rect_inside(game.roll_button.get_global_rect(), viewport_size), "Level %d bottom Roll Dice stays within the portrait safe area" % level_id)
	_check(not game.turn_message_label.visible and not game.feedback_label.visible, "Level %d removes the old instruction descriptions" % level_id)
	if level_id == 1:
		_check(game.background.texture.resource_path.ends_with("terrace_blue/background.png"), "Level 1 uses the reference rice-terrace background")
		var quiz_style := game.quiz_panel.get_theme_stylebox("panel") as StyleBoxTexture
		_check(
			quiz_style != null and quiz_style.texture.resource_path.ends_with("quiz_frame_filipino_v2.png"),
			"Level 1 uses the Filipino bamboo-and-parchment quiz frame"
		)
		_check(game.get_node("%DiceLabel").get_parent().has_node("DiceIcon"), "Die Result card includes its decorative die icon")
		_check(not game.get_node("QuestionPopupLayer/QuizPanel/QuizMargin/QuizContent/TurnControls/ControlDivider").visible, "quiz popup removes the old divider")
	var choice_count: int = game.current_question.get("choices", []).size()
	var expected_columns: int = choice_count if choice_count <= 3 else 2
	_check(game.answers_grid.columns == expected_columns, "Level %d balances its %d answer choices across the quiz row" % [level_id, choice_count])
	_check(game.get_node("MarginContainer/Content/HistoryRollBrand").visible, "Level %d shows the reference aqua-scroll logo" % level_id)
	var level_banner := game.get_node("MarginContainer/Content/Header/LevelBannerBackground") as TextureRect
	var back_button := game.get_node("%BackButton") as Button
	_check(not level_banner.visible and not game.level_label.visible, "Level %d gameplay header removes the level parchment and title" % level_id)
	_check(back_button.visible and back_button.size.y >= 60.0, "Level %d keeps a large touch-friendly Back to Levels button" % level_id)
	_check(game.gameplay_body.size.x >= float(viewport_size.x) * 0.85, "Level %d gameplay body fills the portrait safe width" % level_id)
	var status_row: Control = game.get_node("MarginContainer/Content/BodyCenter/Body/StatusRow")
	_check(game.board_panel.get_global_rect().end.y <= status_row.get_global_rect().position.y, "Level %d board does not overlap its status bar" % level_id)
	_check(status_row.get_global_rect().end.y < game.roll_button.get_global_rect().position.y, "Level %d status bar stays above Roll Dice" % level_id)
	var roll_title: Label = game.get_node("BottomRollArea/RollButton/RollVisual/RollContents/RollTitle")
	var die_icon: TextureRect = game.get_node("BottomRollArea/RollButton/RollVisual/RollContents/DieIcon")
	_check(die_icon.get_global_rect().end.x <= roll_title.get_global_rect().position.x, "Level %d Roll Dice lettering does not overlap the die icon" % level_id)
	_check(game.roll_button.get_global_rect().encloses(roll_title.get_global_rect()), "Level %d Roll Dice lettering fits inside its button" % level_id)
	_check(not game.state_label.visible, "Level %d status bar contains only Position, Score and Shield" % level_id)
	_check(back_button.icon != null and back_button.text.is_empty(), "Level %d Back uses the round reference icon" % level_id)
	_check(game.quiz_panel.size.y >= 390.0, "Level %d compact popup has sufficient vertical space" % level_id)
	_check(_rect_inside(back_button.get_global_rect(), viewport_size), "Level %d Back button respects portrait safe bounds" % level_id)
	_check(_rect_inside(game.board_panel.get_global_rect(), viewport_size), "Level %d board remains fully visible" % level_id)
	_check(_rect_inside(game.quiz_panel.get_global_rect(), viewport_size), "Level %d question controls remain fully visible" % level_id)
	_check(game.board_view.get_board_rect().size.x <= game.board_view.size.x + 0.1, "Level %d board fits horizontally" % level_id)
	_check(game.board_view.player_sprite.texture != null and game.board_view.player_sprite.visible, "Level %d current hero chibi is visible" % level_id)
	_check(game.board_view.player_sprite.texture is AtlasTexture, "Level %d start token uses a cropped face portrait" % level_id)
	_check(game.board_view.player_token_label.visible == false, "Level %d no longer shows start initials over the chibi" % level_id)
	var player_center: Vector2 = game.board_view.player_token.position + game.board_view.player_token.size / 2.0
	_check(player_center.distance_to(game.board_view.get_tile_center(1)) < 1.0, "Level %d current hero starts on Tile 1" % level_id)
	var board_rect: Rect2 = game.board_view.get_board_rect()
	var cell_size := Vector2(board_rect.size.x / game.board_view.columns, board_rect.size.y / game.board_view.rows)
	_check(absf(cell_size.x - cell_size.y) < 0.1, "Level %d tiles stay square at %s" % [level_id, viewport_size])
	var natural_token_size := clampf(minf(cell_size.x, cell_size.y) * 0.88, 44.0, 124.0)
	_check(is_equal_approx(game.board_view.player_token.size.x, natural_token_size), "Level %d current hero portrait keeps natural tile padding" % level_id)
	var token_style := game.board_view.player_token.get_theme_stylebox("panel") as StyleBoxFlat
	_check(token_style != null and is_zero_approx(token_style.bg_color.a), "Level %d hero portrait has no colored backing box" % level_id)
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
		var waiting_portrait := game.board_view.waiting_hero_sprite.texture as AtlasTexture
		_check(waiting_portrait != null and waiting_portrait.atlas.resource_path.ends_with("_chibi.png"), "Level %d finish face portrait excludes the full-body waving pose" % level_id)
		_check(waiting_portrait != null and is_equal_approx(waiting_portrait.region.size.x, waiting_portrait.region.size.y), "Level %d finish token uses a square face crop" % level_id)
		_check(game.board_view.waiting_hero_label.visible == false, "Level %d next hero chibi replaces finish initials" % level_id)
		if level_id == 1:
			var wave_rotation_before: float = game.board_view.waiting_hero_sprite.rotation
			await create_timer(0.24).timeout
			_check(not is_equal_approx(game.board_view.waiting_hero_sprite.rotation, wave_rotation_before), "finish hero visibly moves during its wave animation")
	else:
		_check(not game.board_view.waiting_hero_sprite.visible and game.board_view.waiting_hero_label.text == "TROPHY", "Level 6 uses the final trophy instead of inventing a next hero")
	var image: Image = viewport.get_texture().get_image()
	_check(image != null and not image.is_empty() and image.save_png(ProjectSettings.globalize_path("user://%s" % filename)) == OK, "%s rendered capture is saved" % filename)
	# Capture the playable board after its real answer -> ready transition.
	game.answer_buttons[int(game.current_question.correct_index)].pressed.emit()
	await create_timer(1.3).timeout
	_check(not game.question_popup_layer.visible and not game.roll_button.disabled, "Level %d answer dismisses the popup and enables its themed Roll Dice" % level_id)
	await RenderingServer.frame_post_draw
	image = viewport.get_texture().get_image()
	var ready_filename := filename.trim_suffix(".png") + "_ready.png"
	_check(image != null and image.save_png(ProjectSettings.globalize_path("user://%s" % ready_filename)) == OK, "%s ready-board capture is saved" % ready_filename)
	game.progress_manager = null; game.queue_free(); viewport.queue_free(); await process_frame; progress.free()

func _capture_long_mactan_question() -> void:
	var viewport := SubViewport.new(); viewport.size = Vector2i(720, 1280); viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var progress := MockProgress.new()
	var game = GameplayScene.instantiate(); game.progress_manager = progress; game.shuffle_questions = false
	viewport.add_child(game); await process_frame
	var choices := [
		"Shallow water and coral reefs blocked them",
		"The sea was too deep",
		"Large rocks crashed their ships",
	]
	game.question_label.text = "Why couldn't the Spanish ships get close to the shore of Mactan?"
	game._apply_question_typography(choices)
	game.answers_grid.columns = 3
	for index: int in range(3):
		game.answer_buttons[index].text = choices[index]
		game.answer_buttons[index].visible = true
		game.answer_buttons[index].custom_minimum_size.y = 72.0
	game.answer_buttons[3].hide()
	await process_frame; await process_frame
	_check(game.question_label.get_theme_font_size("font_size") == 24, "long Mactan question uses the fitted parchment font")
	for index: int in range(3):
		_check(_rect_inside(game.answer_buttons[index].get_global_rect(), viewport.size), "long Mactan answer %d stays inside the portrait screen" % (index + 1))
	var image: Image = viewport.get_texture().get_image()
	_check(image != null and not image.is_empty() and image.save_png(ProjectSettings.globalize_path("user://gameplay_long_mactan_question_720x1280.png")) == OK, "long Mactan question render is saved")
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
	_check(game.reaction_popup.visible, "%s chibi score popup is visible" % ("happy" if correct else "sad"))
	_check(game.reaction_face.texture != null, "%s chibi popup uses the current hero face" % ("happy" if correct else "sad"))
	_check(game.reaction_face.texture.resource_path.ends_with("lapulapu_%s.png" % ("happy" if correct else "sad")), "%s popup changes the actual chibi facial expression" % ("happy" if correct else "sad"))
	_check(game.reaction_title.text == ("HOORAY!" if correct else "OH NO!"), "%s reaction title is correct" % ("happy" if correct else "sad"))
	var image: Image = viewport.get_texture().get_image()
	_check(image != null and not image.is_empty() and image.save_png(ProjectSettings.globalize_path("user://%s" % filename)) == OK, "%s is saved" % filename)
	game.progress_manager = null; game.queue_free(); viewport.queue_free(); await process_frame; progress.free()

func _check(value: bool, description: String) -> void:
	if value: passed += 1; print("PASS: ", description)
	else: failed += 1; push_error("FAIL: %s" % description)


func _test_pointer_controls() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var progress := MockProgress.new()
	var game = GameplayScene.instantiate()
	game.progress_manager = progress
	game.shuffle_questions = false
	game.enable_test_dice_controls = true
	game.dice_animation_steps = 2
	game.dice_animation_interval = 0.06
	game.movement_step_duration = 0.02
	viewport.add_child(game)
	await create_timer(0.35).timeout
	_click(viewport, game.answer_buttons[int(game.current_question.correct_index)].get_global_rect().get_center())
	_check(game.score == 10, "pointer click reaches the correct Answer button")
	await create_timer(1.3).timeout
	var controlled_roll: Array[int] = [1]
	game.set_controlled_dice_results(controlled_roll)
	var roll_center: Vector2 = game.roll_button.get_global_rect().get_center()
	_click(viewport, roll_center)
	_click(viewport, roll_center)
	_check(game.state == GameplayScript.GameplayState.DICE_ROLLING, "pointer click through the decorative Roll Dice content starts one turn")
	for frame_index: int in range(180):
		if game.state == GameplayScript.GameplayState.QUESTION: break
		await process_frame
	_check(game.player_position == 2, "rapid pointer clicks move only once by the displayed die result")
	_check(game.dice_label.text == "1" and game.board_view.board_die.face_value == 1, "pointer-started roll displays the same result on the board")
	await create_timer(0.35).timeout
	_click(viewport, game.answer_buttons[int(game.current_question.correct_index)].get_global_rect().get_center())
	await create_timer(1.3).timeout
	_click(viewport, game.back_button.get_global_rect().get_center())
	await process_frame
	await process_frame
	_check(current_scene != null and current_scene.scene_file_path == "res://level_selection.tscn", "pointer click on the round Back icon opens the real Level Selection scene")
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	game.progress_manager = null
	game.queue_free()
	viewport.queue_free()
	await process_frame
	progress.free()


func _click(viewport: SubViewport, position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	viewport.push_input(event, true)
	var release := event.duplicate() as InputEventMouseButton
	release.pressed = false
	viewport.push_input(release, true)

func _rect_inside(rect: Rect2, viewport_size: Vector2i) -> bool:
	return rect.position.x >= -0.1 and rect.position.y >= -0.1 and rect.end.x <= viewport_size.x + 0.1 and rect.end.y <= viewport_size.y + 0.1

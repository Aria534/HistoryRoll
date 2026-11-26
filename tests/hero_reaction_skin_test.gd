extends "res://tests/level_completion_test.gd"

const PopupSkin = preload("res://hero_reaction_skin.gd")


func _run() -> void:
	for level_id: int in range(1, 7):
		await _test_feedback(level_id, Vector2i(720, 1280))
		await _test_feedback(level_id, Vector2i(1024, 1536))
	await _test_feedback(1, Vector2i(1080, 2400))
	await _test_resize()
	await _test_incorrect_special_cases()
	await _test_rapid_feedback()
	await _test_rapid_feedback(false)
	var audio := get_root().get_node_or_null("AudioManager")
	if audio != null:
		audio.stop_music(0.0)
	await create_timer(1.1).timeout
	await process_frame
	print("Hero reaction popup tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _test_feedback(level_id: int, dimensions: Vector2i) -> void:
	var fixture := await _fixture(level_id, dimensions)
	var game = fixture.game
	var board_rect: Rect2 = game.board_view.get_global_rect()
	var roll_rect: Rect2 = game.roll_button.get_global_rect()
	var nodes := _node_paths(game)
	var correct := int(game.current_question.correct_index)
	game.answer_buttons[correct].pressed.emit()
	game.answer_buttons[correct].pressed.emit()
	await create_timer(0.4).timeout
	_check(game.score == 10 and game.correct_answers == 1 and game.quiz_session.get_answer_history().size() == 1, "Level %d keeps one score and accepted answer per submission" % level_id)
	_check(game.reaction_title.text == "HOORAY!" and game.reaction_score.text == "+10 POINTS", "positive feedback uses the actual reward")
	_check(game.reaction_popup.visible and not game.quiz_panel.visible, "the victory popup replaces the question artwork during positive feedback")
	var style := game.reaction_popup.get_theme_stylebox("panel") as StyleBoxTexture
	_check(style != null and style.texture == PopupSkin.FRAME, "positive feedback uses the generated crown-and-green frame")
	var hero_id := str(game.level_data.portrait_path).get_file().trim_suffix("_chibi.png")
	_check(game.reaction_face.texture.resource_path.ends_with("%s_happy.png" % hero_id), "Level %d keeps its existing happy hero face" % level_id)
	_check(_node_paths(game) == nodes, "the skin does not create or reparent any gameplay nodes")
	_check(game.board_view.get_global_rect().is_equal_approx(board_rect) and game.roll_button.get_global_rect().is_equal_approx(roll_rect), "board and Roll Dice positions remain unchanged")
	_check_geometry(game, dimensions)
	await _capture(fixture.viewport, "hooray_level_%d_%dx%d.png" % [level_id, dimensions.x, dimensions.y])
	await create_timer(0.9).timeout
	_check(not game.question_popup_layer.visible and not game.roll_button.disabled, "feedback dismisses automatically and leaves one roll available")
	var roll: Array[int] = [1]
	game.set_controlled_dice_results(roll)
	_click(fixture.viewport, game.roll_button.get_global_rect().get_center())
	for frame in 600:
		if game.state == GameplayScript.GameplayState.QUESTION: break
		await process_frame
	_check(game.state == GameplayScript.GameplayState.QUESTION and game.quiz_panel.visible, "a real Roll Dice click restores the next question")
	var wrong: int = (int(game.current_question.correct_index) + 1) % game.current_question.choices.size()
	game.answer_buttons[wrong].pressed.emit()
	game.answer_buttons[wrong].pressed.emit()
	await create_timer(0.35).timeout
	var wrong_style := game.reaction_popup.get_theme_stylebox("panel") as StyleBoxTexture
	_check(wrong_style != null and wrong_style.texture == PopupSkin.INCORRECT_FRAME, "incorrect feedback uses the matching plum-and-gold frame")
	_check(game.reaction_title.text == "OH NO!" and game.reaction_score.text == "-2 POINTS" and game.score == 8, "incorrect-answer caption and scoring remain unchanged")
	_check(game.reaction_face.texture.resource_path.ends_with("%s_sad.png" % hero_id), "incorrect feedback keeps the matching sad face")
	_check(game.reaction_popup.visible and not game.quiz_panel.visible, "the sad popup replaces the question artwork during incorrect feedback")
	_check(game.incorrect_answers == 1 and game.quiz_session.get_answer_history().size() == 2, "duplicate wrong-answer clicks cannot repeat a penalty or review entry")
	_check(_node_paths(game) == nodes, "sad feedback also reuses the existing scene hierarchy")
	_check_geometry(game, dimensions, PopupSkin.INCORRECT_FRAME)
	await _capture(fixture.viewport, "oh_no_level_%d_%dx%d.png" % [level_id, dimensions.x, dimensions.y])
	await create_timer(0.9).timeout
	_check(not game.question_popup_layer.visible and not game.roll_button.disabled, "sad feedback dismisses and keeps the allowed roll available")
	game.set_controlled_dice_results(roll)
	_click(fixture.viewport, game.roll_button.get_global_rect().get_center())
	for frame in 600:
		if game.state == GameplayScript.GameplayState.QUESTION: break
		await process_frame
	_check(game.quiz_panel.visible and game.state == GameplayScript.GameplayState.QUESTION, "a wrong answer still rolls and restores the next question")
	game.answer_buttons[int(game.current_question.correct_index)].pressed.emit()
	await create_timer(0.35).timeout
	var restored := game.reaction_popup.get_theme_stylebox("panel") as StyleBoxTexture
	_check(restored != null and restored.texture == PopupSkin.FRAME and game.reaction_title.text == "HOORAY!" and game.score == 18, "correct feedback returns to green after sad feedback")
	await _dispose(fixture)


func _test_resize() -> void:
	var fixture := await _fixture(1, Vector2i(720, 1280))
	var game = fixture.game
	game.correct_answer_points = 25
	game.answer_buttons[int(game.current_question.correct_index)].pressed.emit()
	await create_timer(0.3).timeout
	fixture.viewport.size = Vector2i(1024, 1536)
	for frame in 5: await process_frame
	_check_geometry(game, Vector2i(1024, 1536))
	_check(game.reaction_score.text == "+25 POINTS" and game.score == 25, "the design displays configurable rewards rather than a baked-in ten")
	await _dispose(fixture)


func _test_rapid_feedback(second_correct: bool = true) -> void:
	var fixture := await _fixture(1, Vector2i(720, 1280))
	var game = fixture.game
	var started := Time.get_ticks_msec()
	game.answer_buttons[int(game.current_question.correct_index)].pressed.emit()
	var roll: Array[int] = [1]
	game.set_controlled_dice_results(roll)
	game.roll_button.pressed.emit()
	for frame in 600:
		if game.state == GameplayScript.GameplayState.QUESTION: break
		await process_frame
	_check(game.quiz_panel.visible and game.state == GameplayScript.GameplayState.QUESTION, "rolling immediately after feedback still restores the question")
	var next_feedback := Time.get_ticks_msec()
	var next_choice := int(game.current_question.correct_index)
	if not second_correct:
		next_choice = (next_choice + 1) % game.current_question.choices.size()
	game.answer_buttons[next_choice].pressed.emit()
	var delay := maxf(0.0, 1.03 - float(Time.get_ticks_msec() - started) / 1000.0)
	if delay > 0.0: await create_timer(delay).timeout
	_check(Time.get_ticks_msec() - next_feedback < 950 and game.reaction_popup.visible and game.question_popup_layer.visible, "an earlier answer timer cannot close the newer happy or sad popup")
	_check(game.score == (20 if second_correct else 8) and game.correct_answers == (2 if second_correct else 1), "rapid turns preserve the actual rewards and penalties")
	await _dispose(fixture)


func _test_incorrect_special_cases() -> void:
	var fixture := await _fixture(1, Vector2i(720, 1280))
	var game = fixture.game
	var wrong: int = (int(game.current_question.correct_index) + 1) % game.current_question.choices.size()
	game.answer_buttons[wrong].pressed.emit()
	game.answer_buttons[wrong].pressed.emit()
	await create_timer(0.35).timeout
	_check(game.score == 0 and game.incorrect_answers == 1 and game.reaction_title.text == "OH NO!", "a first wrong answer shows a sad face without making score negative")
	_check_geometry(game, Vector2i(720, 1280), PopupSkin.INCORRECT_FRAME)
	await _dispose(fixture)
	fixture = await _fixture(1, Vector2i(720, 1280))
	game = fixture.game
	game.score = 20
	game.incorrect_answer_penalty = 7
	wrong = (int(game.current_question.correct_index) + 1) % game.current_question.choices.size()
	game.answer_buttons[wrong].pressed.emit()
	await create_timer(0.3).timeout
	fixture.viewport.size = Vector2i(1024, 1536)
	for frame in 5: await process_frame
	_check_geometry(game, Vector2i(1024, 1536), PopupSkin.INCORRECT_FRAME)
	_check(game.score == 13 and game.reaction_score.text == "-7 POINTS", "sad feedback uses the configured penalty rather than a baked-in value")
	await _capture(fixture.viewport, "oh_no_custom_penalty_1024x1536.png")
	await _dispose(fixture)


func _check_geometry(game: Node, dimensions: Vector2i, frame_texture: Texture2D = PopupSkin.FRAME) -> void:
	var popup: PanelContainer = game.reaction_popup
	var frame: PanelContainer = game.reaction_face.get_parent()
	_check(_inside(popup.get_global_rect(), dimensions), "complete popup stays inside the portrait screen")
	_check(is_equal_approx(popup.size.aspect(), frame_texture.get_size().aspect()), "popup artwork keeps its natural proportions")
	_check(frame.size.x >= 140.0 and frame.get_global_rect().encloses(game.reaction_face.get_global_rect()), "hero portrait is large and contained by its gold frame")
	_check(game.reaction_face.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED and not game.reaction_face.texture is AtlasTexture, "the full original face is displayed without a new crop")
	var previous: Rect2 = frame.get_global_rect()
	for label: Label in [game.reaction_title, game.reaction_score]:
		var rect := label.get_global_rect()
		var font := label.get_theme_font("font")
		var font_size := label.get_theme_font_size("font_size")
		_check(font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= label.size.x and font.get_height(font_size) <= label.size.y + 1.0, "%s lettering fits" % label.name)
		_check(popup.get_global_rect().encloses(rect) and not previous.intersects(rect), "%s remains separate from portrait and other text" % label.name)
		previous = rect
	_check(not popup.get_global_rect().intersects(game.roll_button.get_global_rect()), "popup leaves the bottom Roll Dice area clear")


func _node_paths(root_node: Node) -> Array[String]:
	var paths: Array[String] = []
	for child: Node in root_node.get_children():
		paths.append(str(child.get_path()))
		paths.append_array(_node_paths(child))
	return paths

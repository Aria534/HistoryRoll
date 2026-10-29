extends SceneTree

const GameplayScene = preload("res://gameplay_placeholder.tscn")

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
	_check(game.board_view.get_board_rect().size.x <= game.board_view.size.x + 0.1, "Level %d board fits horizontally" % level_id)
	_check(game.board_view.waiting_hero_token.visible, "Level %d finish placeholder is visible" % level_id)
	var image: Image = viewport.get_texture().get_image()
	_check(image != null and not image.is_empty() and image.save_png(ProjectSettings.globalize_path("user://%s" % filename)) == OK, "%s rendered capture is saved" % filename)
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

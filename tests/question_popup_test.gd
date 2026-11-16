extends SceneTree

const GameplayScene = preload("res://gameplay_placeholder.tscn")
const GameplayScript = preload("res://gameplay_placeholder.gd")

var passed := 0
var failed := 0


class MockProgress:
	extends Node
	var selected_level := 1

	func record_board_completion(_level: int, _score: int, _stats: Dictionary) -> bool:
		return true

	func finish_level_results(_level: int) -> bool:
		return true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var progress := MockProgress.new()
	var game = GameplayScene.instantiate()
	game.progress_manager = progress
	game.shuffle_questions = false
	game.enable_test_dice_controls = true
	game.dice_animation_steps = 4
	game.dice_animation_interval = 0.15
	game.movement_step_duration = 0.01
	get_root().add_child(game)
	await process_frame
	await process_frame

	_check(game.question_popup_layer.visible, "question popup opens at the start of a turn")
	_check(game.question_popup_layer.get_node("ModalDim").visible, "popup dims the board behind it")
	_check(game.quiz_panel.scale.x >= 0.88 and game.quiz_panel.scale.x <= 1.08, "popup uses the entrance scale animation")
	_check(game.state == GameplayScript.GameplayState.QUESTION, "popup waits for one answer")

	var correct_index := int(game.current_question.get("correct_index", 0))
	game.answer_buttons[correct_index].pressed.emit()
	_check(game.question_popup_layer.visible, "popup briefly remains open to present answer feedback")
	_check(not game.roll_button.disabled, "answer enables the bottom Roll Dice button")
	await create_timer(0.8).timeout
	_check(not game.question_popup_layer.visible, "question popup closes after answer feedback")

	var controlled_roll: Array[int] = [1]
	game.set_controlled_dice_results(controlled_roll)
	game.roll_button.pressed.emit()
	await create_timer(0.24).timeout
	_check(not game.question_popup_layer.visible, "popup closes before the dice animation")
	_check(game.state == GameplayScript.GameplayState.DICE_ROLLING, "board interaction continues after the popup closes")

	for frame_index: int in range(240):
		if game.state == GameplayScript.GameplayState.QUESTION and game.player_position == 2:
			break
		await process_frame
	_check(game.player_position == 2, "hero movement still matches the rolled result")
	_check(game.question_popup_layer.visible, "next turn opens a new question popup")

	if game.question_popup_tween != null and game.question_popup_tween.is_valid():
		game.question_popup_tween.kill()
	game.progress_manager = null
	game.queue_free()
	await process_frame
	progress.free()
	print("Question popup tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _check(value: bool, description: String) -> void:
	if value:
		passed += 1
		print("PASS: ", description)
	else:
		failed += 1
		push_error("FAIL: %s" % description)

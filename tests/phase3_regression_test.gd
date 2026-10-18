extends SceneTree

const BoardRules = preload("res://board_rules.gd")
const DiceRoller = preload("res://dice_roller.gd")
const GameplayScript = preload("res://gameplay_placeholder.gd")
const GameplayScene = preload("res://gameplay_placeholder.tscn")
const LevelCatalog = preload("res://level_catalog.gd")
const ProgressManagerScript = preload("res://progress_manager.gd")
const QuizFixtures = preload("res://quiz_test_fixtures.gd")
const QuizSession = preload("res://quiz_session.gd")

var _passed: int = 0
var _failed: int = 0


class MockProgressManager:
	extends Node

	var selected_level: int = 1
	var completed_levels: Array[int] = []
	var completion_calls: int = 0

	func mark_level_completed(level_id: int) -> bool:
		completion_calls += 1
		if not completed_levels.has(level_id):
			completed_levels.append(level_id)
		return true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_board_rules()
	_test_dice_roller()
	_test_quiz_session()
	_test_progress_persistence()
	await _test_gameplay_flow()
	_test_scene_paths()

	print("Phase 3 regression tests: %d passed, %d failed." % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_board_rules() -> void:
	var level := LevelCatalog.get_level(1)
	var config: Dictionary = level.get("board", {})
	_check(BoardRules.validate_config(config).is_empty(), "board configuration is valid")
	_check(BoardRules.get_tile_count(config) == 100, "board contains exactly 100 tiles")
	_check(int(config.get("columns", 0)) == 10, "board has 10 columns")
	_check(int(config.get("rows", 0)) == 10, "board has 10 rows")

	var cells: Dictionary = {}
	for tile: int in range(1, 101):
		var cell := BoardRules.tile_to_visual_cell(tile, 10, 10)
		cells[cell] = tile
	_check(cells.size() == 100, "all tile coordinates are unique")
	_check(BoardRules.tile_to_visual_cell(1, 10, 10) == Vector2i(0, 9), "tile 1 is bottom-left")
	_check(BoardRules.tile_to_visual_cell(10, 10, 10) == Vector2i(9, 9), "tile 10 is bottom-right")
	_check(BoardRules.tile_to_visual_cell(11, 10, 10) == Vector2i(9, 8), "tile 11 starts the reversed second row")
	_check(BoardRules.tile_to_visual_cell(20, 10, 10) == Vector2i(0, 8), "tile 20 ends the reversed second row")
	_check(BoardRules.tile_to_visual_cell(91, 10, 10) == Vector2i(9, 0), "tile 91 starts the top row")
	_check(BoardRules.tile_to_visual_cell(100, 10, 10) == Vector2i(0, 0), "tile 100 is the top-left finish")
	_check(BoardRules.calculate_normal_destination(1, 6, 100, true) == 7, "movement starts from tile 1")
	_check(BoardRules.calculate_normal_destination(98, 3, 100, true) == 98, "exact-finish rule blocks overshoot")
	_check(BoardRules.calculate_normal_destination(94, 6, 100, true) == 100, "exact roll reaches tile 100")

	for raw_start: Variant in config.get("ladders", {}):
		var destination := int(config["ladders"][raw_start])
		_check(destination > int(raw_start), "ladder %d moves upward" % int(raw_start))
	for raw_start: Variant in config.get("snakes", {}):
		var destination := int(config["snakes"][raw_start])
		_check(destination < int(raw_start), "snake %d moves downward" % int(raw_start))
	_check(BoardRules.get_tile_effect(config, 4).get("to", 0) == 14, "ladder effect maps 4 to 14")
	_check(BoardRules.get_tile_effect(config, 17).get("to", 0) == 7, "snake effect maps 17 to 7")


func _test_dice_roller() -> void:
	var normal_dice = DiceRoller.new()
	var seen: Dictionary = {}
	var all_results_valid := true
	for roll_index: int in range(300):
		var result: int = normal_dice.roll()
		if result < 1 or result > 6:
			all_results_valid = false
		seen[result] = true
	_check(all_results_valid, "300 normal dice results are within 1 through 6")
	_check(seen.size() >= 4, "normal dice produces varied results")

	var controlled_dice = DiceRoller.new(12345, true)
	var controlled_unit_results: Array[int] = [6, 2]
	controlled_dice.set_controlled_results(controlled_unit_results)
	_check(controlled_dice.roll() == 6, "test-only dice accepts first controlled result")
	_check(controlled_dice.roll() == 2, "test-only dice accepts second controlled result")


func _test_quiz_session() -> void:
	var quiz = QuizSession.new()
	_check(quiz.configure(QuizFixtures.get_questions_for_level(1), false), "quiz fixtures configure successfully")
	var question: Dictionary = quiz.next_question()
	_check(question.get("choices", []).size() == 4, "quiz displays four choices")
	var first_result: Dictionary = quiz.submit_answer(int(question.get("correct_index", -1)))
	_check(bool(first_result.get("accepted", false)), "first answer submission is accepted")
	_check(bool(first_result.get("correct", false)), "correct answer is recognized")
	_check(not bool(quiz.submit_answer(0).get("accepted", true)), "duplicate answer submission is rejected")


func _test_progress_persistence() -> void:
	var test_path := "user://historyroll_phase3_regression.json"
	var absolute_path := ProjectSettings.globalize_path(test_path)
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(absolute_path)

	var progress = ProgressManagerScript.new()
	progress.save_path = test_path
	_check(progress.mark_level_completed(1), "supported level completion is recorded")
	_check(progress.completed_levels.has(1), "completed level is stored")
	_check(progress.highest_unlocked_level == 1, "unsupported levels are not unlocked")

	var reloaded = ProgressManagerScript.new()
	reloaded.save_path = test_path
	reloaded.load_progress()
	_check(reloaded.completed_levels.has(1), "completed level persists after reload")
	_check(reloaded.highest_unlocked_level == 1, "unlock state persists after reload")
	progress.free()
	reloaded.free()
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(absolute_path)


func _test_gameplay_flow() -> void:
	var progress := MockProgressManager.new()
	var gameplay = GameplayScene.instantiate()
	gameplay.progress_manager = progress
	gameplay.enable_test_dice_controls = true
	gameplay.shuffle_questions = false
	gameplay.dice_animation_steps = 1
	gameplay.dice_animation_interval = 0.001
	gameplay.movement_step_duration = 0.001
	gameplay.tile_effect_duration = 0.001
	get_root().add_child(gameplay)
	await process_frame

	_check(gameplay.tile_count == 100, "gameplay loads the 100-tile board")
	_check(gameplay.player_position == 1, "new gameplay starts on tile 1")
	_check(gameplay.state == GameplayScript.GameplayState.QUESTION, "gameplay starts in question state")
	_check(gameplay.roll_button.disabled, "roll button starts disabled")

	gameplay.answer_buttons[1].pressed.emit()
	_check(gameplay.state == GameplayScript.GameplayState.ANSWER_FEEDBACK, "incorrect answer enters feedback state")
	_check(gameplay.roll_button.disabled, "incorrect answer keeps roll disabled")
	gameplay.roll_button.pressed.emit()
	await process_frame
	_check(gameplay.player_position == 1, "incorrect answer cannot move the player")
	_check(progress.completion_calls == 0, "opening gameplay does not record completion")

	gameplay.next_turn_button.pressed.emit()
	_check(gameplay.state == GameplayScript.GameplayState.QUESTION, "next question begins after a failed turn")
	gameplay.answer_buttons[1].pressed.emit()
	_check(gameplay.state == GameplayScript.GameplayState.READY_TO_ROLL, "correct answer enables rolling")
	_check(not gameplay.roll_button.disabled, "roll button is enabled after a correct answer")

	var ladder_rolls: Array[int] = [3, 6]
	gameplay.set_controlled_dice_results(ladder_rolls)
	gameplay.roll_button.pressed.emit()
	_check(gameplay.state == GameplayScript.GameplayState.DICE_ROLLING, "roll signal enters dice-rolling state")
	gameplay.roll_button.pressed.emit()
	_check(gameplay.roll_button.disabled, "roll button disables during an active roll")
	_check(await _wait_for_state(gameplay, GameplayScript.GameplayState.ANSWER_FEEDBACK), "movement and ladder effect finish")
	_check(gameplay.dice_label.text == "3", "displayed dice result matches the controlled roll")
	_check(gameplay.player_position == 14, "roll 3 lands on ladder 4 and moves to 14")
	_check(progress.completion_calls == 0, "non-final movement does not record completion")

	gameplay.next_turn_button.pressed.emit()
	gameplay.player_position = 14
	gameplay.board_view.set_player_position_immediate(14)
	gameplay.answer_buttons[1].pressed.emit()
	var snake_roll: Array[int] = [3]
	gameplay.set_controlled_dice_results(snake_roll)
	gameplay.roll_button.pressed.emit()
	_check(await _wait_for_state(gameplay, GameplayScript.GameplayState.ANSWER_FEEDBACK), "snake movement finishes")
	_check(gameplay.player_position == 7, "roll 3 lands on snake 17 and moves to 7")

	gameplay.next_turn_button.pressed.emit()
	gameplay.player_position = 98
	gameplay.board_view.set_player_position_immediate(98)
	gameplay.answer_buttons[0].pressed.emit()
	var overshoot_roll: Array[int] = [3]
	gameplay.set_controlled_dice_results(overshoot_roll)
	gameplay.roll_button.pressed.emit()
	_check(await _wait_for_state(gameplay, GameplayScript.GameplayState.ANSWER_FEEDBACK), "overshoot turn finishes")
	_check(gameplay.player_position == 98, "overshoot leaves the player on the current tile")

	gameplay.next_turn_button.pressed.emit()
	gameplay.player_position = 97
	gameplay.board_view.set_player_position_immediate(97)
	var finish_answer_index := int(gameplay.current_question.get("correct_index", -1))
	gameplay.answer_buttons[finish_answer_index].pressed.emit()
	var finish_roll: Array[int] = [3]
	gameplay.set_controlled_dice_results(finish_roll)
	gameplay.roll_button.pressed.emit()
	_check(await _wait_for_state(gameplay, GameplayScript.GameplayState.LEVEL_COMPLETE), "exact roll to tile 100 completes the level")
	_check(gameplay.player_position == 100, "player finishes on tile 100")
	_check(progress.completion_calls == 1, "completion is recorded exactly once")
	gameplay.roll_button.pressed.emit()
	await process_frame
	_check(progress.completion_calls == 1, "input after completion cannot duplicate the reward")

	gameplay.progress_manager = null
	gameplay.queue_free()
	await process_frame
	progress.free()


func _wait_for_state(gameplay: Node, expected_state: int, maximum_frames: int = 600) -> bool:
	for frame_index: int in range(maximum_frames):
		if gameplay.state == expected_state:
			return true
		await process_frame
	return false


func _test_scene_paths() -> void:
	_check(ResourceLoader.exists("res://main_menu_tscn.tscn"), "Main Menu scene exists")
	_check(ResourceLoader.exists("res://level_selection.tscn"), "Level Selection scene exists")
	_check(ResourceLoader.exists("res://story_mode.tscn"), "Story Mode scene exists")
	_check(ResourceLoader.exists("res://gameplay_placeholder.tscn"), "gameplay scene exists")


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", description)
	else:
		_failed += 1
		push_error("FAIL: %s" % description)

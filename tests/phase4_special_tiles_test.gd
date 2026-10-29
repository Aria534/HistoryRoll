extends SceneTree

const BoardRules = preload("res://board_rules.gd")
const GameplayScript = preload("res://gameplay_placeholder.gd")
const GameplayScene = preload("res://gameplay_placeholder.tscn")
const LevelCatalog = preload("res://level_catalog.gd")

var _passed: int = 0
var _failed: int = 0


class MockProgressManager:
	extends Node

	var selected_level: int = 1
	var completion_calls: int = 0
	var fully_completed: bool = false

	func is_level_completed(_level_id: int) -> bool:
		return fully_completed

	func record_board_completion(_level_id: int, _score: int, _statistics: Dictionary) -> bool:
		completion_calls += 1
		return true

	func begin_post_level_story(_level_id: int) -> bool:
		return true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if int(LevelCatalog.get_level(1).get("correct_answer_points", 0)) == 10:
		_test_redesigned_tiles()
		print("Phase 4 redesigned special-tile tests: %d passed, %d failed." % [_passed, _failed])
		quit(0 if _failed == 0 else 1)
		return
	_test_integrated_tile_configuration()
	await _test_integrated_tile_gameplay()
	print("Phase 4 special-tile tests: %d passed, %d failed." % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_redesigned_tiles() -> void:
	var level := LevelCatalog.get_level(1)
	var board: Dictionary = level.get("board", {})
	_check(BoardRules.get_special_tile_type(board, 5) == "bonus", "Level 1 Bonus Tile is configured")
	_check(BoardRules.get_special_tile_type(board, 15) == "shield", "Level 1 Shield Tile is configured")
	_check(int(level.get("bonus_points", -1)) == 0, "bonus amount remains configurable and pending approval")
	_check(BoardRules.get_primary_tile_effect(board, 17).get("type") == "snake", "snake resolution remains centralized")
	_check(BoardRules.get_primary_tile_effect(board, 3).get("type") == "ladder", "ladder resolution remains centralized")


func _test_integrated_tile_configuration() -> void:
	var level := LevelCatalog.get_level(1)
	var config: Dictionary = level.get("board", {})
	_check(BoardRules.validate_config(config).is_empty(), "integrated tile configuration is valid")
	_check(BoardRules.get_special_tile_type(config, 12) == "bonus", "tile 12 is a Bonus question tile")
	_check(BoardRules.get_special_tile_type(config, 8) == "shield", "tile 8 is a Shield tile")
	_check(BoardRules.get_special_tile_type(config, 27).is_empty(), "obsolete Double Score tile is not configured")
	_check(BoardRules.get_special_tile_type(config, 19).is_empty(), "obsolete Trap tile is not configured")
	_check(int(level.get("correct_answer_points", 0)) == 100, "regular correct-answer score defaults to 100")
	_check(int(level.get("snake_score_penalty", 0)) == 50, "snake penalty defaults to 50")
	_check(not bool(level.get("allow_negative_score", true)), "scores do not become negative by default")
	_check(int(level.get("maximum_shield_charges", -1)) == 0, "zero shield cap config means unlimited stacking")
	_check(bool(level.get("resolve_destination_effects", false)), "destination tile effects are enabled")
	_check(int(level.get("maximum_effect_depth", 0)) > 0, "tile resolver has a maximum depth safeguard")
	_check(BoardRules.get_primary_tile_effect(config, 4).get("type") == "ladder", "movement effects have primary priority")
	_check(BoardRules.get_primary_tile_effect(config, 12).get("type") == "bonus", "Bonus resolves through the central resolver")
	_check(BoardRules.get_primary_tile_effect(config, 6).get("type") == "question", "Question Mark resolves through the central resolver")
	_check(BoardRules.get_primary_tile_effect(config, 2).get("type") == "normal", "normal tiles resolve without an effect")

	var duplicate_config := config.duplicate(true)
	duplicate_config["special_tiles"]["bonus"] = [12, 12]
	_check(not BoardRules.validate_config(duplicate_config).is_empty(), "duplicate special positions are rejected")
	var question_conflict := config.duplicate(true)
	question_conflict["special_tiles"]["bonus"].append(6)
	_check(not BoardRules.validate_config(question_conflict).is_empty(), "special and Question Mark conflicts are rejected")
	var snake_conflict := config.duplicate(true)
	snake_conflict["special_tiles"]["shield"].append(17)
	_check(not BoardRules.validate_config(snake_conflict).is_empty(), "special and snake-start conflicts are rejected")


func _test_integrated_tile_gameplay() -> void:
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

	_check(gameplay.shield_charges == 0, "shield count resets when a level starts")
	_check(gameplay.correct_answers == 0 and gameplay.incorrect_answers == 0, "answer statistics reset when a level starts")
	_check(gameplay.power_status_label.text.contains("Shield: 0"), "shield count remains visible")

	gameplay.score = 300
	gameplay._update_status_labels()
	_check(await _roll_from(gameplay, 11, 1, GameplayScript.GameplayState.QUESTION), "Bonus tile opens a bonus question")
	_check(gameplay.current_question_type == "bonus", "Bonus uses a separate question type")
	var bonus_correct_index := int(gameplay.current_question.get("correct_index", -1))
	gameplay.answer_buttons[bonus_correct_index].pressed.emit()
	_check(gameplay.score == 600, "correct Bonus answer doubles the existing total score")
	_check(gameplay.bonus_correct_answers == 1, "correct Bonus statistic increments")
	_check(gameplay.bonus_score_increase == 300, "Bonus score increase is tracked")
	gameplay.answer_buttons[bonus_correct_index].pressed.emit()
	_check(gameplay.score == 600, "duplicate Bonus submission cannot double the score twice")
	gameplay.next_turn_button.pressed.emit()

	gameplay.score = 300
	gameplay._update_status_labels()
	_check(await _roll_from(gameplay, 34, 1, GameplayScript.GameplayState.QUESTION), "another Bonus tile opens a question")
	var bonus_wrong_index := (int(gameplay.current_question.get("correct_index", 0)) + 1) % 4
	gameplay.answer_buttons[bonus_wrong_index].pressed.emit()
	_check(gameplay.score == 300, "incorrect Bonus answer leaves the current score unchanged")
	_check(gameplay.bonus_incorrect_answers == 1, "incorrect Bonus statistic increments")
	gameplay.next_turn_button.pressed.emit()

	_check(await _roll_from(gameplay, 7, 1, GameplayScript.GameplayState.READY_TO_ROLL), "first Shield tile resolves")
	_check(await _roll_from(gameplay, 25, 1, GameplayScript.GameplayState.READY_TO_ROLL), "second Shield tile resolves")
	_check(gameplay.shield_charges == 2, "multiple shields can be collected")
	_check(gameplay.shields_collected == 2, "shield collections are tracked")

	var score_before_shielded_snake: int = gameplay.score
	_check(await _roll_from(gameplay, 14, 3, GameplayScript.GameplayState.READY_TO_ROLL), "shielded snake resolves")
	_check(gameplay.player_position == 17, "Shield prevents snake movement")
	_check(gameplay.shield_charges == 1, "one Shield is consumed by one snake")
	_check(gameplay.score == score_before_shielded_snake, "shielded snake applies no score penalty")
	_check(gameplay.shields_consumed == 1, "consumed Shield statistic increments")

	_check(await _roll_from(gameplay, 14, 3, GameplayScript.GameplayState.READY_TO_ROLL), "second Shield can protect against another snake")
	_check(gameplay.shield_charges == 0, "second snake consumes the remaining Shield")
	gameplay.score = 40
	gameplay._update_status_labels()
	_check(await _roll_from(gameplay, 14, 3, GameplayScript.GameplayState.READY_TO_ROLL), "unprotected snake resolves")
	_check(gameplay.player_position == 7, "unprotected snake moves the player downward")
	_check(gameplay.score == 0, "snake penalty is clamped so score never becomes negative")
	_check(gameplay.snake_penalties == 40, "actual snake penalty is tracked")

	var score_before_ladder: int = gameplay.score
	_check(await _roll_from(gameplay, 1, 3, GameplayScript.GameplayState.QUESTION), "ladder destination effect resolves")
	_check(gameplay.player_position == 14, "ladder moves the hero upward")
	_check(gameplay.score == score_before_ladder, "ladder does not change the score")
	_check(gameplay.current_question_type == "regular", "Question Mark at ladder destination opens a regular question")
	var ladder_question_wrong := (int(gameplay.current_question.get("correct_index", 0)) + 1) % 4
	gameplay.answer_buttons[ladder_question_wrong].pressed.emit()
	gameplay.next_turn_button.pressed.emit()

	var original_config: Dictionary = gameplay.board_config
	var loop_config: Dictionary = original_config.duplicate(true)
	loop_config["ladders"] = {4: 9}
	loop_config["snakes"] = {9: 4}
	loop_config["question_tiles"] = []
	loop_config["special_tiles"] = {"bonus": [], "shield": []}
	gameplay.board_config = loop_config
	_check(await _roll_from(gameplay, 1, 3, GameplayScript.GameplayState.READY_TO_ROLL), "effect loop is stopped safely")
	_check(gameplay.feedback_label.text.contains("already resolved"), "loop protection reports the repeated tile")
	gameplay.board_config = original_config

	gameplay.progress_manager = null
	gameplay.queue_free()
	await process_frame
	progress.free()


func _roll_from(gameplay: Node, start_tile: int, dice_result: int, expected_state: int) -> bool:
	gameplay.player_position = start_tile
	gameplay.board_view.set_player_position_immediate(start_tile)
	var controlled_roll: Array[int] = [dice_result]
	gameplay.set_controlled_dice_results(controlled_roll)
	gameplay.roll_button.pressed.emit()
	return await _wait_for_state(gameplay, expected_state)


func _wait_for_state(gameplay: Node, expected_state: int, maximum_frames: int = 600) -> bool:
	for frame_index: int in range(maximum_frames):
		if gameplay.state == expected_state:
			return true
		await process_frame
	return false


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", description)
	else:
		_failed += 1
		push_error("FAIL: %s" % description)

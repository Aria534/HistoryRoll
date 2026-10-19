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
	var completion_calls: int = 0
	var recorded_score: int = -1
	var recorded_statistics: Dictionary = {}
	var fully_completed: bool = false

	func is_level_completed(_level_id: int) -> bool:
		return fully_completed

	func record_board_completion(_level_id: int, final_score: int, statistics: Dictionary) -> bool:
		completion_calls += 1
		recorded_score = final_score
		recorded_statistics = statistics.duplicate(true)
		return true

	func begin_post_level_story(_level_id: int) -> bool:
		return true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_board_rules()
	_test_dice_roller()
	_test_quiz_session()
	_test_progress_persistence()
	await _test_gameplay_flow()
	await _test_navigation_wiring()
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
	var question_tiles: Array = config.get("question_tiles", [])
	var unique_question_tiles: Dictionary = {}
	for raw_tile: Variant in question_tiles:
		unique_question_tiles[int(raw_tile)] = true
	_check(not question_tiles.is_empty(), "Level 1 configures Question Mark tiles")
	_check(unique_question_tiles.size() == question_tiles.size(), "Question Mark tiles are unique")
	_check(BoardRules.is_question_tile(config, 6), "tile 6 is configured as a Question Mark tile")
	_check(not BoardRules.is_question_tile(config, 5), "normal tile 5 is not a Question Mark tile")
	_check(int(level.get("correct_answer_points", 0)) == 100, "correct-answer reward is configured as 100 points")

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
	_check(progress.record_board_completion(1, 250, {"correct_answers": 2}), "board completion is recorded")
	_check(progress.board_completed_levels.has(1), "board completion is stored separately")
	_check(not progress.completed_levels.has(1), "board completion does not finish full progression")
	_check(progress.highest_unlocked_level == 1, "Level 2 stays locked after board completion")

	var reloaded = ProgressManagerScript.new()
	reloaded.save_path = test_path
	reloaded.load_progress()
	_check(reloaded.board_completed_levels.has(1), "board completion persists after reload")
	_check(not reloaded.completed_levels.has(1), "incomplete progression remains incomplete after reload")
	_check(reloaded.highest_unlocked_level == 1, "locked Level 2 state persists after reload")
	_check(int(reloaded.best_scores.get("1", 0)) == 250, "best score persists after reload")
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
	_check(gameplay.state == GameplayScript.GameplayState.READY_TO_ROLL, "gameplay starts in Dice First state")
	_check(not gameplay.roll_button.disabled, "Roll Dice is enabled at gameplay start")
	_check(gameplay.score == 0, "new gameplay starts with zero points")
	_check(not gameplay.question_label.visible, "no question appears at gameplay start")
	_check(progress.completion_calls == 0, "opening gameplay does not record completion")
	var visual_board_rect: Rect2 = gameplay.board_view.get_board_rect()
	_check(is_equal_approx(visual_board_rect.size.x, visual_board_rect.size.y), "board renderer uses equal width and height")
	var token_center: Vector2 = gameplay.board_view.player_token.position + gameplay.board_view.player_token.size / 2.0
	_check(token_center.distance_to(gameplay.board_view.get_tile_center(1)) < 1.0, "player token is centered on tile 1")
	var board_panel: Control = gameplay.get_node("MarginContainer/Content/BoardPanel")
	var status_row: Control = gameplay.get_node("MarginContainer/Content/StatusRow")
	_check(not board_panel.get_global_rect().intersects(status_row.get_global_rect()), "board and status labels do not overlap")
	_check(gameplay.roll_button.size.y >= 70.0, "Roll Dice button has a touch-friendly height")

	var first_rolls: Array[int] = [1, 6]
	gameplay.set_controlled_dice_results(first_rolls)
	gameplay.roll_button.pressed.emit()
	_check(gameplay.state == GameplayScript.GameplayState.DICE_ROLLING, "roll signal enters dice-rolling state")
	gameplay.roll_button.pressed.emit()
	_check(gameplay.roll_button.disabled, "roll button disables during an active roll")
	_check(await _wait_for_state(gameplay, GameplayScript.GameplayState.READY_TO_ROLL), "normal movement returns to dice-ready state")
	_check(gameplay.dice_label.text == "1", "displayed dice result matches the movement roll")
	_check(gameplay.player_position == 2, "roll 1 moves the player from tile 1 to tile 2")
	_check(not gameplay.question_label.visible, "normal tile does not trigger a question")

	gameplay.player_position = 5
	gameplay.board_view.set_player_position_immediate(5)
	var passing_roll: Array[int] = [2]
	gameplay.set_controlled_dice_results(passing_roll)
	gameplay.roll_button.pressed.emit()
	_check(await _wait_for_state(gameplay, GameplayScript.GameplayState.READY_TO_ROLL), "passing a Question Mark tile finishes normally")
	_check(gameplay.player_position == 7, "player passes tile 6 and lands on tile 7")
	_check(not gameplay.question_label.visible, "passing over a Question Mark tile does not trigger it")

	gameplay.player_position = 5
	gameplay.board_view.set_player_position_immediate(5)
	var question_roll: Array[int] = [1]
	gameplay.set_controlled_dice_results(question_roll)
	gameplay.roll_button.pressed.emit()
	_check(await _wait_for_state(gameplay, GameplayScript.GameplayState.QUESTION), "landing on tile 6 triggers a question")
	_check(gameplay.player_position == 6, "question triggers only after landing on its tile")
	_check(gameplay.question_label.visible, "question panel content is visible")
	_check(gameplay.answer_buttons.size() == 4, "question presents exactly four answers")
	_check(gameplay.answer_buttons[0].size.y >= 70.0, "answer buttons have a touch-friendly height")
	_check(gameplay.roll_button.disabled, "rolling is blocked while a question is active")
	await process_frame
	_check(not board_panel.get_global_rect().intersects(gameplay.quiz_panel.get_global_rect()), "board and active quiz panel do not overlap")

	var wrong_index := (int(gameplay.current_question.get("correct_index", 0)) + 1) % 4
	gameplay.answer_buttons[wrong_index].pressed.emit()
	_check(gameplay.state == GameplayScript.GameplayState.ANSWER_FEEDBACK, "wrong answer enters feedback state")
	_check(gameplay.score == 0, "wrong answer awards zero points")
	gameplay.answer_buttons[wrong_index].pressed.emit()
	_check(gameplay.score == 0, "repeated wrong submission cannot change the score")
	_check(gameplay.next_turn_button.visible, "Continue is shown after an answer")
	_check(gameplay.roll_button.disabled, "rolling remains blocked until Continue")
	gameplay.next_turn_button.pressed.emit()
	_check(gameplay.state == GameplayScript.GameplayState.READY_TO_ROLL, "wrong answer does not block the next turn")
	_check(not gameplay.roll_button.disabled, "Roll Dice re-enables after wrong-answer feedback")

	gameplay.player_position = 13
	gameplay.board_view.set_player_position_immediate(13)
	var correct_question_roll: Array[int] = [1]
	gameplay.set_controlled_dice_results(correct_question_roll)
	gameplay.roll_button.pressed.emit()
	_check(await _wait_for_state(gameplay, GameplayScript.GameplayState.QUESTION), "another Question Mark tile opens the next question")
	var correct_index := int(gameplay.current_question.get("correct_index", -1))
	gameplay.answer_buttons[correct_index].pressed.emit()
	_check(gameplay.score == 100, "correct answer awards 100 points")
	gameplay.answer_buttons[correct_index].pressed.emit()
	_check(gameplay.score == 100, "repeated correct submission cannot duplicate points")
	_check(gameplay.score_label.text == "Score: 100", "score label updates immediately")
	gameplay.next_turn_button.pressed.emit()

	gameplay.player_position = 1
	gameplay.board_view.set_player_position_immediate(1)
	var ladder_roll: Array[int] = [3]
	gameplay.set_controlled_dice_results(ladder_roll)
	gameplay.roll_button.pressed.emit()
	_check(await _wait_for_state(gameplay, GameplayScript.GameplayState.QUESTION), "question triggers after a ladder destination")
	_check(gameplay.player_position == 14, "roll 3 lands on ladder 4 and climbs to tile 14")
	var ladder_question_wrong := (int(gameplay.current_question.get("correct_index", 0)) + 1) % 4
	gameplay.answer_buttons[ladder_question_wrong].pressed.emit()
	gameplay.next_turn_button.pressed.emit()

	gameplay.player_position = 14
	gameplay.board_view.set_player_position_immediate(14)
	var snake_roll: Array[int] = [3]
	gameplay.set_controlled_dice_results(snake_roll)
	gameplay.roll_button.pressed.emit()
	_check(await _wait_for_state(gameplay, GameplayScript.GameplayState.READY_TO_ROLL), "snake movement returns to dice-ready state")
	_check(gameplay.player_position == 7, "roll 3 lands on snake 17 and moves to 7")
	_check(gameplay.score == 50, "unprotected snake deducts the configured 50-point penalty")

	gameplay.player_position = 98
	gameplay.board_view.set_player_position_immediate(98)
	var overshoot_roll: Array[int] = [3]
	gameplay.set_controlled_dice_results(overshoot_roll)
	gameplay.roll_button.pressed.emit()
	_check(await _wait_for_state(gameplay, GameplayScript.GameplayState.READY_TO_ROLL), "overshoot returns to dice-ready state")
	_check(gameplay.player_position == 98, "overshoot leaves the player on the current tile")

	gameplay.player_position = 97
	gameplay.board_view.set_player_position_immediate(97)
	var finish_roll: Array[int] = [3]
	gameplay.set_controlled_dice_results(finish_roll)
	gameplay.roll_button.pressed.emit()
	_check(await _wait_for_state(gameplay, GameplayScript.GameplayState.LEVEL_COMPLETE), "exact roll to tile 100 completes the level")
	_check(gameplay.player_position == 100, "player finishes on tile 100")
	_check(progress.completion_calls == 1, "completion is recorded exactly once")
	_check(gameplay.results_label.text.contains("Final score: 50"), "completion screen includes the final score")
	_check(progress.recorded_statistics.get("correct_answers", 0) == 1, "completion records gameplay statistics")
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


func _test_navigation_wiring() -> void:
	var main_menu = load("res://main_menu_tscn.tscn").instantiate()
	get_root().add_child(main_menu)
	await process_frame
	_check(main_menu.get_node("StartButton").pressed.get_connections().size() > 0, "Main Menu Start button remains connected")
	_check(main_menu.get_node("HeroCardsButton").pressed.get_connections().size() > 0, "Main Menu Hero Cards button remains connected")
	_check(main_menu.get_node("AchievementButton").pressed.get_connections().size() > 0, "Main Menu Achievements button remains connected")
	_check(main_menu.get_node("QuitButton").pressed.get_connections().size() > 0, "Main Menu Quit button remains connected")
	main_menu.queue_free()
	await process_frame

	var level_selection = load("res://level_selection.tscn").instantiate()
	get_root().add_child(level_selection)
	await process_frame
	_check(level_selection.get_node("MarginContainer/ContentPanel/ContentMargin/Content/NavigationButtons/PlayButton").pressed.get_connections().size() > 0, "Level Selection Play button remains connected")
	_check(level_selection.get_node("MarginContainer/ContentPanel/ContentMargin/Content/NavigationButtons/BackButton").pressed.get_connections().size() > 0, "Level Selection Back button remains connected")
	level_selection.queue_free()
	await process_frame

	var story_mode = load("res://story_mode.tscn").instantiate()
	get_root().add_child(story_mode)
	await process_frame
	_check(story_mode.get_node("MarginContainer/StoryPanel/ContentMargin/Content/DestinationNavigation/ContinueButton").pressed.get_connections().size() > 0, "Story Mode Continue button remains connected")
	_check(story_mode.get_node("MarginContainer/StoryPanel/ContentMargin/Content/DestinationNavigation/BackButton").pressed.get_connections().size() > 0, "Story Mode Back button remains connected")
	story_mode.queue_free()
	await process_frame


func _test_scene_paths() -> void:
	_check(ResourceLoader.exists("res://main_menu_tscn.tscn"), "Main Menu scene exists")
	_check(ResourceLoader.exists("res://level_selection.tscn"), "Level Selection scene exists")
	_check(ResourceLoader.exists("res://story_mode.tscn"), "Story Mode scene exists")
	_check(ResourceLoader.exists("res://gameplay_placeholder.tscn"), "gameplay scene exists")
	_check(ResourceLoader.exists("res://character_unlock.tscn"), "character unlock scene exists")


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", description)
	else:
		_failed += 1
		push_error("FAIL: %s" % description)

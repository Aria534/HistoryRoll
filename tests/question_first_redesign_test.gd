extends SceneTree

const BoardRules = preload("res://board_rules.gd")
const GameplayScene = preload("res://gameplay_placeholder.tscn")
const GameplayScript = preload("res://gameplay_placeholder.gd")
const HeroDatabase = preload("res://hero_database.gd")
const LevelCatalog = preload("res://level_catalog.gd")
const ProgressManagerScript = preload("res://progress_manager.gd")
const QuizQuestionBank = preload("res://quiz_question_bank.gd")

var passed := 0
var failed := 0
var save_path := "user://historyroll_question_first_test.json"

class MockProgress:
	extends Node
	var selected_level := 1
	var completion_calls := 0
	var recorded_score := -1
	func record_board_completion(_level: int, value: int, _stats: Dictionary) -> bool:
		completion_calls += 1
		recorded_score = value
		return true
	func finish_level_results(_level: int) -> bool: return true

func _init() -> void: call_deferred("_run")

func _run() -> void:
	_cleanup()
	_test_catalog_and_boards()
	_test_question_slots_and_heroes()
	_test_direct_progression()
	_test_legacy_save_migration()
	await _test_question_first_gameplay()
	await _test_story_entry()
	_cleanup()
	print("Question-first redesign tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)

func _test_catalog_and_boards() -> void:
	var expected_tiles := [20, 30, 40, 50, 100, 100]
	var expected_snakes := [2, 3, 4, 5, 6, 7]
	var expected_ladders := [3, 4, 4, 5, 6, 6]
	var expected_heroes := ["lapulapu", "andres_bonifacio", "jose_rizal", "antonio_luna", "melchora_aquino", "apolinario_mabini"]
	for level_id: int in range(1, 7):
		var level := LevelCatalog.get_level(level_id)
		var board: Dictionary = level.get("board", {})
		_check(BoardRules.validate_config(board).is_empty(), "Level %d board configuration is valid" % level_id)
		_check(BoardRules.get_tile_count(board) == expected_tiles[level_id - 1], "Level %d has %d tiles" % [level_id, expected_tiles[level_id - 1]])
		_check(board.get("snakes", {}).size() == expected_snakes[level_id - 1], "Level %d has the intended increasing snake count" % level_id)
		_check(board.get("ladders", {}).size() == expected_ladders[level_id - 1], "Level %d has the intended ladder count" % level_id)
		_check(board.get("question_tiles", []).is_empty(), "Level %d has no Question Mark tiles" % level_id)
		_check(str(level.get("hero_id", "")) == expected_heroes[level_id - 1], "Level %d uses the approved hero" % level_id)
		var cells := {}
		for tile: int in range(1, expected_tiles[level_id - 1] + 1):
			cells[BoardRules.tile_to_visual_cell(tile, int(board.columns), int(board.rows))] = true
		_check(cells.size() == expected_tiles[level_id - 1], "Level %d serpentine cells are unique" % level_id)

func _test_question_slots_and_heroes() -> void:
	for level_id: int in range(1, 7):
		_check(QuizQuestionBank.get_questions_for_level(level_id).size() == 50, "Level %d exposes exactly 50 question slots" % level_id)
	_check(HeroDatabase.get_heroes().size() == 6, "hero database contains the final six-hero roster")
	_check(HeroDatabase.get_hero("antonio_luna").get("references", []).size() > 0, "Antonio Luna content has a historical reference")
	_check(HeroDatabase.get_hero("melchora_aquino").get("references", []).size() > 0, "Melchora Aquino content has a historical reference")
	_check(HeroDatabase.get_hero("apolinario_mabini").get("cause_of_death", "").contains("cholera"), "Mabini's documented cause of death is preserved")

func _test_direct_progression() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = save_path
	_check(progress.highest_unlocked_level == 1, "fresh progress starts with Level 1 only")
	_check(progress.record_board_completion(1, 18, {"correct_answers": 2}), "Level 1 completion records directly")
	_check(progress.is_level_completed(1), "board completion immediately marks Level 1 complete")
	_check(progress.is_level_unlocked(2), "Level 1 completion immediately unlocks Level 2")
	_check(not progress.has_pending_progression(), "Story Mode is not a progression gate")
	var reloaded = ProgressManagerScript.new()
	reloaded.save_path = save_path
	reloaded.load_progress()
	_check(reloaded.is_level_unlocked(2), "direct unlock persists after restart")
	_check(reloaded.is_level_completed(1), "completion persists after restart")
	progress.free(); reloaded.free()

func _test_legacy_save_migration() -> void:
	var legacy_path := "user://historyroll_v2_migration_test.json"
	var backup_path := "user://historyroll_v2_migration_test.pre-v2-backup.json"
	for path: String in [legacy_path, backup_path]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var file := FileAccess.open(legacy_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":2,"highest_unlocked_level":2,"completed_levels":[],"board_completed_levels":[1],"completed_story_chapters":[],"unlocked_characters":["historyroll_explorer"],"claimed_character_rewards":[],"selected_hero":"historyroll_explorer","selected_level":1,"pending_progression_level":1,"progression_stage":"post_story"}))
	file = null
	var migrated = ProgressManagerScript.new(); migrated.save_path = legacy_path; migrated.load_progress()
	_check(FileAccess.file_exists(backup_path), "version 2 save is backed up before migration")
	_check(migrated.is_level_completed(1) and migrated.is_level_unlocked(2), "legacy board progress migrates to direct completion")
	_check(not migrated.has_pending_progression(), "legacy pending Story stage cannot trap the player")
	migrated.free()
	for path: String in [legacy_path, backup_path]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _test_question_first_gameplay() -> void:
	var progress := MockProgress.new()
	var game = GameplayScene.instantiate()
	game.progress_manager = progress
	game.enable_test_dice_controls = true
	game.shuffle_questions = false
	game.dice_animation_steps = 1
	game.dice_animation_interval = 0.001
	game.movement_step_duration = 0.001
	game.tile_effect_duration = 0.001
	get_root().add_child(game)
	await process_frame
	_check(game.tile_count == 20, "Level 1 gameplay renders only 20 tiles")
	_check(game.state == GameplayScript.GameplayState.QUESTION, "a question appears before the first roll")
	_check(game.question_label.visible and game.roll_button.disabled, "dice is disabled while the question is unanswered")
	var correct := int(game.current_question.correct_index)
	game.answer_buttons[correct].pressed.emit()
	_check(game.score == 10, "correct answer awards 10 points")
	_check(game.state == GameplayScript.GameplayState.READY_TO_ROLL, "answer enables exactly one dice roll")
	_check(game.reaction_label.text.contains("HAPPY"), "correct answer shows the happy chibi placeholder")
	game.answer_buttons[correct].pressed.emit()
	_check(game.score == 10, "duplicate answer cannot duplicate score")
	var roll_one: Array[int] = [1]
	game.set_controlled_dice_results(roll_one)
	game.roll_button.pressed.emit()
	_check(await _wait_state(game, GameplayScript.GameplayState.QUESTION), "movement finishes before the next question")
	_check(game.player_position == 2, "movement uses the displayed dice result")
	var wrong := (int(game.current_question.correct_index) + 1) % 4
	game.answer_buttons[wrong].pressed.emit()
	_check(game.score == 8, "wrong answer deducts 2 points")
	_check(not game.roll_button.disabled, "wrong answer still allows a dice roll")
	_check(game.reaction_label.text.contains("SAD"), "wrong answer shows the sad chibi placeholder")
	game.player_position = 14; game.board_view.set_player_position_immediate(14)
	game.set_controlled_dice_results(roll_one); game.roll_button.pressed.emit()
	_check(await _wait_state(game, GameplayScript.GameplayState.QUESTION), "Shield Tile resolves before next question")
	_check(game.shield_charges == 1, "Shield Tile awards one shield")
	game.answer_buttons[int(game.current_question.correct_index)].pressed.emit()
	game.player_position = 16; game.board_view.set_player_position_immediate(16)
	game.set_controlled_dice_results(roll_one); game.roll_button.pressed.emit()
	_check(await _wait_state(game, GameplayScript.GameplayState.QUESTION), "shield-protected snake resolves")
	_check(game.player_position == 17 and game.shield_charges == 0, "one shield blocks one snake")
	_check(game.board_view.waiting_animation_active, "waiting hero placeholder has an idle animation")
	game.answer_buttons[int(game.current_question.correct_index)].pressed.emit()
	game.player_position = 19; game.board_view.set_player_position_immediate(19)
	game.set_controlled_dice_results(roll_one); game.roll_button.pressed.emit()
	_check(await _wait_state(game, GameplayScript.GameplayState.LEVEL_COMPLETE), "exact roll completes Level 1 at tile 20")
	_check(progress.completion_calls == 1, "completion is recorded once")
	_check(game.return_button.text == "RETURN TO LEVEL SELECTION", "Results no longer routes to Story Mode")
	game.progress_manager = null; game.queue_free(); await process_frame; progress.free()

func _test_story_entry() -> void:
	var progress = ProgressManagerScript.new(); progress.save_path = save_path
	var cards = load("res://hero_cards.tscn").instantiate(); cards.progress_manager = progress
	var requested: Array[String] = []; cards.scene_change_handler = func(path: String): requested.append(path)
	get_root().add_child(cards); await process_frame
	var hero_button := cards.hero_list.get_child(3) as Button
	hero_button.pressed.emit()
	_check(requested == ["res://story_mode.tscn"], "Hero Cards opens standalone Story Mode")
	_check(progress.selected_story_level == 4, "Hero Cards passes the selected hero story")
	cards.queue_free(); await process_frame
	var story = load("res://story_mode.tscn").instantiate(); story.progress_manager = progress
	requested.clear(); story.scene_change_handler = func(path: String): requested.append(path)
	get_root().add_child(story); await process_frame
	_check(story.hero_name_label.text.contains("Antonio Luna"), "Story Mode displays the selected hero")
	story.continue_button.pressed.emit()
	_check(requested == ["res://hero_cards.tscn"], "Story Mode returns to Hero Cards")
	story.queue_free(); await process_frame; progress.free()

func _wait_state(game: Node, expected: int, frames: int = 600) -> bool:
	for _frame: int in range(frames):
		if game.state == expected: return true
		await process_frame
	return false

func _cleanup() -> void:
	if FileAccess.file_exists(save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

func _check(value: bool, description: String) -> void:
	if value: passed += 1; print("PASS: ", description)
	else: failed += 1; push_error("FAIL: %s" % description)

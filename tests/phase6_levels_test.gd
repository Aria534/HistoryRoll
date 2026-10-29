extends SceneTree

const BoardRules = preload("res://board_rules.gd")
const CharacterUnlockScene = preload("res://character_unlock.tscn")
const GameplayScene = preload("res://gameplay_placeholder.tscn")
const GameplayScript = preload("res://gameplay_placeholder.gd")
const LevelCatalog = preload("res://level_catalog.gd")
const LevelSelectionScene = preload("res://level_selection.tscn")
const ProgressManagerScript = preload("res://progress_manager.gd")
const QuizQuestionBank = preload("res://quiz_question_bank.gd")
const QuestionBank = preload("res://quiz_question_bank.gd")
const StoryModeScene = preload("res://story_mode.tscn")

const EXPECTED_QUESTION_COUNTS: Array[int] = [10, 12, 14, 16, 18, 20]
const EXPECTED_SNAKE_COUNTS: Array[int] = [8, 8, 9, 9, 10, 10]
const EXPECTED_LADDER_COUNTS: Array[int] = [8, 8, 7, 7, 6, 6]
const EXPECTED_HERO_IDS: Array[String] = [
	"lapulapu", "andres_bonifacio", "jose_rizal", "gabriela_silang", "emilio_aguinaldo",
]
const LEVEL_1_QUESTION_TILES: Array[int] = [6, 14, 23, 34, 46, 58, 67, 76, 84, 97]
const LEVEL_1_SNAKES: Dictionary = {17: 7, 54: 34, 62: 19, 64: 60, 87: 24, 93: 73, 95: 75, 99: 78}
const LEVEL_1_LADDERS: Dictionary = {4: 14, 9: 31, 20: 38, 28: 84, 40: 59, 51: 67, 63: 81, 71: 91}

var _passed: int = 0
var _failed: int = 0
var _save_path: String = "user://historyroll_phase6_levels.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if BoardRules.get_tile_count(LevelCatalog.get_level(1).get("board", {})) == 20:
		_test_redesigned_levels()
		print("Phase 6 redesigned-level tests: %d passed, %d failed." % [_passed, _failed])
		quit(0 if _failed == 0 else 1)
		return
	_cleanup()
	_test_all_level_configurations()
	await _test_complete_six_level_progression()
	_cleanup()
	print("Phase 6 level tests: %d passed, %d failed." % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_redesigned_levels() -> void:
	var expected := [20, 30, 40, 50, 100, 100]
	for level_id: int in range(1, 7):
		var board: Dictionary = LevelCatalog.get_level(level_id).get("board", {})
		_check(BoardRules.validate_config(board).is_empty(), "Level %d redesigned board is valid" % level_id)
		_check(BoardRules.get_tile_count(board) == expected[level_id - 1], "Level %d uses its approved tile count" % level_id)
		_check(QuizQuestionBank.get_questions_for_level(level_id).size() == 50, "Level %d supports 50 question slots" % level_id)


func _test_all_level_configurations() -> void:
	for level_id: int in range(1, 7):
		var level := LevelCatalog.get_level(level_id)
		var board: Dictionary = level.get("board", {})
		_check(LevelCatalog.is_level_playable(level_id), "Level %d is playable" % level_id)
		_check(str(level.get("gameplay_scene", "")) == "res://gameplay_placeholder.tscn", "Level %d uses the reusable gameplay scene" % level_id)
		_check(BoardRules.validate_config(board).is_empty(), "Level %d board configuration is valid" % level_id)
		_check(BoardRules.get_tile_count(board) == 100, "Level %d contains exactly 100 tiles" % level_id)
		_check(bool(board.get("exact_finish", false)), "Level %d uses exact-roll completion" % level_id)
		_check(_board_can_reach_finish(board), "Level %d can reach Tile 100 through legal dice movement" % level_id)
		_check((board.get("question_tiles", []) as Array).size() == EXPECTED_QUESTION_COUNTS[level_id - 1], "Level %d has the target Question Mark count" % level_id)
		_check((board.get("snakes", {}) as Dictionary).size() == EXPECTED_SNAKE_COUNTS[level_id - 1], "Level %d has the target snake count" % level_id)
		_check((board.get("ladders", {}) as Dictionary).size() == EXPECTED_LADDER_COUNTS[level_id - 1], "Level %d has the target ladder count" % level_id)
		for raw_start: Variant in (board.get("snakes", {}) as Dictionary):
			_check(int(board["snakes"][raw_start]) < int(raw_start), "Level %d snake %d moves downward" % [level_id, int(raw_start)])
		for raw_start: Variant in (board.get("ladders", {}) as Dictionary):
			_check(int(board["ladders"][raw_start]) > int(raw_start), "Level %d ladder %d moves upward" % [level_id, int(raw_start)])

		var regular := QuestionBank.get_questions_for_level(level_id, "regular")
		var bonus := QuestionBank.get_questions_for_level(level_id, "bonus")
		_check(regular.size() == 15 and bonus.size() == 5, "Level %d loads its complete 20-question bank" % level_id)
		for question: Dictionary in regular + bonus:
			_check(int(question.get("level", 0)) == level_id, "%s does not leak across levels" % str(question.get("question_id", "question")))
			if level_id < 6:
				_check(str(question.get("hero_id", "")) == EXPECTED_HERO_IDS[level_id - 1], "%s uses Level %d's assigned hero" % [str(question.get("question_id", "question")), level_id])
			else:
				_check(EXPECTED_HERO_IDS.has(str(question.get("hero_id", ""))), "%s is part of the intentional mixed review" % str(question.get("question_id", "question")))

	var level_one_board: Dictionary = LevelCatalog.get_level(1).get("board", {})
	_check(level_one_board.get("question_tiles", []) == LEVEL_1_QUESTION_TILES, "Level 1 Question Mark placements remain unchanged")
	_check(level_one_board.get("snakes", {}) == LEVEL_1_SNAKES, "Level 1 snake placements remain unchanged")
	_check(level_one_board.get("ladders", {}) == LEVEL_1_LADDERS, "Level 1 ladder placements remain unchanged")
	_check(LevelCatalog.get_next_level_id(6) == 0, "Level 6 does not create Level 7")
	_check(LevelCatalog.get_character_reward(6).is_empty(), "Level 6 does not create a sixth hero reward")


func _test_complete_six_level_progression() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = _save_path
	_check(progress.is_level_unlocked(1), "Level 1 begins unlocked")
	for locked_level: int in range(2, 7):
		_check(not progress.is_level_unlocked(locked_level), "Level %d begins locked" % locked_level)
		_check(not progress.select_level(locked_level), "locked Level %d cannot be selected" % locked_level)

	for level_id: int in range(1, 7):
		_check(progress.is_level_unlocked(level_id), "Level %d is unlocked only when its turn is reached" % level_id)
		var requested_scenes: Array[String] = []
		var level_selection = LevelSelectionScene.instantiate()
		level_selection.progress_manager = progress
		level_selection.scene_change_handler = func(path: String): requested_scenes.append(path)
		get_root().add_child(level_selection)
		await process_frame
		level_selection._select_level(level_id)
		level_selection.play_button.pressed.emit()
		_check(requested_scenes == ["res://gameplay_placeholder.tscn"], "Level Selection opens gameplay for unlocked Level %d" % level_id)
		level_selection.queue_free()
		await process_frame

		requested_scenes.clear()
		var gameplay = GameplayScene.instantiate()
		gameplay.progress_manager = progress
		gameplay.enable_test_dice_controls = true
		gameplay.dice_animation_steps = 1
		gameplay.dice_animation_interval = 0.0
		gameplay.movement_step_duration = 0.0
		gameplay.tile_effect_duration = 0.0
		gameplay.scene_change_handler = func(path: String): requested_scenes.append(path)
		get_root().add_child(gameplay)
		await process_frame
		_check(gameplay.level_id == level_id, "gameplay loads selected Level %d" % level_id)
		_check(gameplay.player_position == 1, "Level %d starts the token on Tile 1" % level_id)
		_check(gameplay.state == GameplayScript.GameplayState.READY_TO_ROLL, "Level %d starts ready to roll" % level_id)
		_check(gameplay.quiz_session.get_current_question().is_empty(), "Level %d does not start with a quiz" % level_id)

		gameplay.player_position = 99
		gameplay.board_view.set_player_position_immediate(99)
		var final_roll: Array[int] = [1]
		gameplay.set_controlled_dice_results(final_roll)
		gameplay.roll_button.pressed.emit()
		_check(await _wait_for_state(gameplay, GameplayScript.GameplayState.LEVEL_COMPLETE), "Level %d completes on an exact roll to Tile 100" % level_id)
		_check(gameplay.results_label.text.contains("LEVEL %d COMPLETE!" % level_id), "Level %d Results displays the correct level number" % level_id)
		_check(gameplay.return_button.text == "CONTINUE TO STORY MODE", "Level %d Results continues to Story Mode" % level_id)
		gameplay.return_button.pressed.emit()
		_check(requested_scenes == ["res://story_mode.tscn"], "Level %d Results requests Story Mode" % level_id)
		_check(progress.progression_stage == progress.STAGE_POST_STORY, "Level %d records the post-story stage" % level_id)
		gameplay.queue_free()
		await process_frame

		requested_scenes.clear()
		var story = StoryModeScene.instantiate()
		story.progress_manager = progress
		story.scene_change_handler = func(path: String): requested_scenes.append(path)
		get_root().add_child(story)
		await process_frame
		_check(story.level_id == level_id and story.story_available, "Level %d opens its one-screen post-game story" % level_id)
		var expected_name := "Mixed Review" if level_id == 6 else str(LevelCatalog.get_level(level_id).get("hero_name", ""))
		_check(story.hero_name_label.text == expected_name, "Level %d story displays the correct featured content" % level_id)
		_check(not progress.is_story_completed(level_id), "opening Level %d story does not complete it" % level_id)
		story.continue_button.pressed.emit()
		_check(progress.is_story_completed(level_id), "Level %d Story Continue records completion" % level_id)
		_check(requested_scenes == ["res://character_unlock.tscn"], "Level %d Story Continue requests the progression confirmation" % level_id)
		story.queue_free()
		await process_frame

		requested_scenes.clear()
		var character_screen = CharacterUnlockScene.instantiate()
		character_screen.progress_manager = progress
		character_screen.scene_change_handler = func(path: String): requested_scenes.append(path)
		get_root().add_child(character_screen)
		await process_frame
		if level_id < 6:
			var reward_id := str(LevelCatalog.get_character_reward(level_id).get("id", ""))
			_check(progress.is_character_unlocked(reward_id), "Level %d grants its assigned hero once" % level_id)
			_check(not progress.is_level_unlocked(level_id + 1), "Level %d does not unlock early when Character Unlock merely opens" % (level_id + 1))
			character_screen.continue_button.pressed.emit()
			_check(progress.is_level_unlocked(level_id + 1), "Character Continue unlocks Level %d" % (level_id + 1))
			_check(character_screen.title_label.text == "LEVEL %d UNLOCKED!" % (level_id + 1), "Level %d unlock confirmation is displayed" % (level_id + 1))
			character_screen.continue_button.pressed.emit()
		else:
			_check(character_screen.title_label.text == "CONGRATULATIONS!", "Level 6 displays the final congratulations screen")
			_check(character_screen.hero_name_label.text == "YOU COMPLETED HISTORYROLL!", "Level 6 displays the final game-completion message")
			_check(progress.claimed_character_rewards.size() == 5, "Level 6 does not add a sixth character reward")
			character_screen.continue_button.pressed.emit()
		_check(requested_scenes == ["res://level_selection.tscn"], "Level %d confirmation returns to Level Selection" % level_id)
		_check(not progress.has_pending_progression(), "Level %d clears its pending progression after confirmation" % level_id)
		character_screen.queue_free()
		await process_frame

	_check(progress.game_completed, "finishing Level 6 stores final game completion")
	_check(progress.highest_unlocked_level == 6, "progression stops at Level 6")
	_check(progress.completed_levels.size() == 6, "all six levels are recorded complete")
	_check(progress.unlocked_characters.size() == 6, "collection contains the explorer and five hero rewards")

	var reloaded = ProgressManagerScript.new()
	reloaded.save_path = _save_path
	reloaded.load_progress()
	_check(reloaded.game_completed, "final game completion survives restart")
	_check(reloaded.highest_unlocked_level == 6, "all unlocked levels survive restart")
	_check(reloaded.completed_levels.size() == 6, "all completed levels survive restart")
	_check(reloaded.unlocked_characters.size() == 6, "all character rewards survive restart")
	_check(not reloaded.has_pending_progression(), "completed final progression reloads without a pending stage")
	progress.free()
	reloaded.free()


func _wait_for_state(gameplay: Node, expected_state: int, maximum_frames: int = 120) -> bool:
	for frame_index: int in range(maximum_frames):
		if gameplay.state == expected_state:
			return true
		await process_frame
	return false


func _board_can_reach_finish(board: Dictionary) -> bool:
	var tile_count := BoardRules.get_tile_count(board)
	var frontier: Array[int] = [1]
	var visited: Dictionary = {1: true}
	while not frontier.is_empty():
		var position: int = frontier.pop_front()
		for dice_result: int in range(1, 7):
			var destination := BoardRules.calculate_normal_destination(position, dice_result, tile_count, true)
			var resolved_positions: Dictionary = {}
			while not resolved_positions.has(destination):
				resolved_positions[destination] = true
				var effect := BoardRules.get_tile_effect(board, destination)
				if effect.is_empty():
					break
				destination = int(effect.get("to", destination))
			if destination == tile_count:
				return true
			if not visited.has(destination):
				visited[destination] = true
				frontier.append(destination)
	return false


func _cleanup() -> void:
	if FileAccess.file_exists(_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_path))


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", description)
	else:
		_failed += 1
		push_error("FAIL: %s" % description)

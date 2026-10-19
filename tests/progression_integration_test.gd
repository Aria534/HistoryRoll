extends SceneTree

const CharacterUnlockScene = preload("res://character_unlock.tscn")
const LevelCatalog = preload("res://level_catalog.gd")
const ProgressManagerScript = preload("res://progress_manager.gd")
const StoryModeScene = preload("res://story_mode.tscn")

var _passed: int = 0
var _failed: int = 0
var _test_path: String = "user://historyroll_progression_integration.json"
var _legacy_path: String = "user://historyroll_legacy_migration.json"
var _corrupt_path: String = "user://historyroll_corrupt_regression.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup(_test_path)
	_cleanup(_legacy_path)
	_cleanup(_corrupt_path)
	await _test_required_progression_sequence()
	_test_legacy_save_migration()
	_test_corrupted_save_recovery()
	_test_catalog_and_scene_coverage()
	_cleanup(_test_path)
	_cleanup(_legacy_path)
	_cleanup(_corrupt_path)
	print("Progression integration tests: %d passed, %d failed." % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_required_progression_sequence() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = _test_path
	_check(progress.is_level_unlocked(1), "Level 1 starts unlocked")
	_check(not progress.is_level_unlocked(2), "Level 2 starts locked")
	_check(progress.start_level_introduction(1), "Level 1 introduction can be started")
	_check(progress.story_context == "introduction", "pre-game story is identified as an introduction")
	_check(not progress.is_story_completed(1), "viewing the introduction does not complete the post-level story")

	var final_statistics := {
		"correct_answers": 3,
		"incorrect_answers": 1,
		"bonus_correct_answers": 1,
		"bonus_incorrect_answers": 0,
		"bonus_score_increase": 200,
		"snake_penalties": 50,
		"shields_collected": 2,
		"shields_consumed": 1,
		"position": 100,
	}
	_check(progress.record_board_completion(1, 450, final_statistics), "board completion and final statistics are saved")
	_check(progress.is_board_completed(1), "board completion is stored separately")
	_check(not progress.is_level_completed(1), "board completion alone does not complete full progression")
	_check(not progress.is_level_unlocked(2), "board completion does not unlock Level 2")
	_check(progress.progression_stage == progress.STAGE_RESULTS, "results stage follows board completion")
	_check(int(progress.best_scores.get("1", 0)) == 450, "best score is stored")

	_check(progress.begin_post_level_story(1), "Continue from results starts the mandatory post-level story")
	_check(progress.progression_stage == progress.STAGE_POST_STORY, "post-level story stage is recorded")
	_check(not progress.is_story_completed(1), "opening mandatory Story Mode does not complete it")
	_check(not progress.is_level_unlocked(2), "Level 2 remains locked while Story Mode is open")

	var story = StoryModeScene.instantiate()
	story.progress_manager = progress
	get_root().add_child(story)
	await process_frame
	_check(story.is_post_completion_story, "Story Mode loads the post-completion chapter in progression context")
	_check(story.back_button.disabled, "mandatory Story Mode cannot be skipped with Back")
	_check(story.continue_button.disabled, "Story completion is blocked before the final panel")
	_check(not progress.is_story_completed(1), "instantiating Story Mode does not mark story completion")
	story.queue_free()
	await process_frame

	_check(progress.mark_story_completed(1), "finishing all story sections records story completion")
	_check(progress.is_story_completed(1), "story completion is stored separately")
	_check(progress.progression_stage == progress.STAGE_CHARACTER_UNLOCK, "story completion advances to Character Unlock")
	_check(not progress.is_level_unlocked(2), "Level 2 remains locked before Character Unlock Continue")

	var reward_id := str(LevelCatalog.get_character_reward(1).get("id", ""))
	var reward_screen = CharacterUnlockScene.instantiate()
	reward_screen.progress_manager = progress
	get_root().add_child(reward_screen)
	await process_frame
	_check(progress.is_character_unlocked(reward_id), "Character Unlock adds the reward hero to the collection")
	_check(progress.claimed_character_rewards.has(1), "one-time character reward claim is stored")
	_check(not progress.is_level_unlocked(2), "showing Character Unlock does not prematurely unlock Level 2")
	var character_count: int = progress.unlocked_characters.size()
	_check(progress.claim_character_reward(1), "repeated reward processing is accepted idempotently")
	_check(progress.unlocked_characters.size() == character_count, "repeated reward processing does not duplicate the hero")

	reward_screen.continue_button.pressed.emit()
	await process_frame
	_check(progress.progression_stage == progress.STAGE_LEVEL_UNLOCK, "Character Unlock Continue advances to unlock confirmation")
	_check(progress.is_level_completed(1), "full Level 1 progression is marked complete")
	_check(progress.is_level_unlocked(2), "Level 2 unlocks only after Character Unlock Continue")
	_check(reward_screen.title_label.text.contains("LEVEL 2 UNLOCKED"), "Level 2 unlock confirmation is displayed")
	reward_screen.queue_free()
	await process_frame

	_check(progress.finish_progression(1), "unlock confirmation can finish the progression sequence")
	_check(not progress.has_pending_progression(), "finished progression has no pending reward stage")
	_check(progress.select_hero(reward_id), "unlocked reward hero can be selected")
	_check(not progress.select_hero("locked_test_hero"), "locked heroes cannot be selected")

	var reloaded = ProgressManagerScript.new()
	reloaded.save_path = _test_path
	reloaded.load_progress()
	_check(reloaded.is_board_completed(1), "board completion survives restart")
	_check(reloaded.is_story_completed(1), "story completion survives restart")
	_check(reloaded.is_character_unlocked(reward_id), "character unlock survives restart")
	_check(reloaded.is_level_unlocked(2), "Level 2 unlock survives restart")
	_check(reloaded.selected_hero == reward_id, "selected hero survives restart")
	_check(int(reloaded.best_scores.get("1", 0)) == 450, "best score survives restart")
	progress.free()
	reloaded.free()


func _test_legacy_save_migration() -> void:
	var file := FileAccess.open(_legacy_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"version": 1,
		"highest_unlocked_level": 2,
		"completed_levels": [1],
	}))
	file = null
	var migrated = ProgressManagerScript.new()
	migrated.save_path = _legacy_path
	migrated.load_progress()
	var reward_id := str(LevelCatalog.get_character_reward(1).get("id", ""))
	_check(migrated.is_level_completed(1), "legacy completed level remains completed after migration")
	_check(migrated.is_board_completed(1), "legacy completion migrates board status")
	_check(migrated.is_story_completed(1), "legacy completion migrates story status")
	_check(migrated.is_character_unlocked(reward_id), "legacy completion preserves its one-time character reward")
	_check(migrated.is_level_unlocked(2), "legacy Level 2 unlock is preserved")
	_check(not migrated.has_pending_progression(), "migration does not grant duplicate pending rewards")
	migrated.free()


func _test_catalog_and_scene_coverage() -> void:
	_check(LevelCatalog.get_levels().size() == 6, "Level Selection catalog exposes Levels 1 through 6")
	_check(LevelCatalog.is_level_playable(1), "Level 1 gameplay is marked implemented")
	_check(not LevelCatalog.is_level_playable(2), "Level 2 gameplay is honestly marked pending")
	_check(ResourceLoader.exists("res://character_unlock.tscn"), "Character Unlock scene exists")
	_check(ResourceLoader.exists("res://hero_cards.tscn"), "Hero Collection scene exists")
	_check(LevelCatalog.get_all_characters().size() >= 2, "Hero Collection includes default and reward characters")


func _test_corrupted_save_recovery() -> void:
	var file := FileAccess.open(_corrupt_path, FileAccess.WRITE)
	file.store_string("{ this is not valid JSON")
	file = null
	var recovered = ProgressManagerScript.new()
	recovered.save_path = _corrupt_path
	recovered.load_progress()
	_check(recovered.is_level_unlocked(1), "corrupted save recovery restores Level 1")
	_check(not recovered.is_level_unlocked(2), "corrupted save recovery does not grant Level 2")
	_check(recovered.unlocked_characters == [recovered.DEFAULT_HERO_ID], "corrupted save recovery restores only the default hero")
	recovered.free()


func _cleanup(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", description)
	else:
		_failed += 1
		push_error("FAIL: %s" % description)

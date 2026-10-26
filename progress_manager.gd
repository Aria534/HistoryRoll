extends Node

signal progress_changed

const LevelCatalog = preload("res://level_catalog.gd")
const DEFAULT_SAVE_PATH: String = "user://historyroll_progress.json"
const SAVE_VERSION: int = 2
const DEFAULT_HERO_ID: String = "historyroll_explorer"
const STAGE_RESULTS: String = "results"
const STAGE_POST_STORY: String = "post_story"
const STAGE_CHARACTER_UNLOCK: String = "character_unlock"
const STAGE_LEVEL_UNLOCK: String = "level_unlock_confirmation"

var save_path: String = DEFAULT_SAVE_PATH
var highest_unlocked_level: int = 1
var completed_levels: Array[int] = []
var board_completed_levels: Array[int] = []
var completed_story_chapters: Array[int] = []
var unlocked_characters: Array[String] = [DEFAULT_HERO_ID]
var claimed_character_rewards: Array[int] = []
var selected_hero: String = DEFAULT_HERO_ID
var best_scores: Dictionary = {}
var last_level_stats: Dictionary = {}
var selected_level: int = 1
var pending_progression_level: int = 0
var progression_stage: String = ""
var game_completed: bool = false


func _ready() -> void:
	load_progress()


func is_level_unlocked(level_id: int) -> bool:
	return level_id >= 1 and LevelCatalog.has_level(level_id) and level_id <= highest_unlocked_level


func is_level_completed(level_id: int) -> bool:
	return completed_levels.has(level_id)


func is_board_completed(level_id: int) -> bool:
	return board_completed_levels.has(level_id)


func is_story_completed(level_id: int) -> bool:
	return completed_story_chapters.has(level_id)


func is_character_unlocked(character_id: String) -> bool:
	return unlocked_characters.has(character_id)


func select_level(level_id: int) -> bool:
	if not is_level_unlocked(level_id):
		return false
	var selection_changed := selected_level != level_id
	selected_level = level_id
	if selection_changed:
		save_progress()
	return true


func record_board_completion(level_id: int, final_score: int, statistics: Dictionary) -> bool:
	if not is_level_unlocked(level_id) or not LevelCatalog.is_level_playable(level_id):
		return false
	_add_unique_int(board_completed_levels, level_id)
	var score_key := str(level_id)
	best_scores[score_key] = maxi(int(best_scores.get(score_key, 0)), maxi(0, final_score))
	last_level_stats = statistics.duplicate(true)
	last_level_stats["level_id"] = level_id
	last_level_stats["final_score"] = maxi(0, final_score)
	pending_progression_level = level_id
	progression_stage = STAGE_RESULTS
	save_progress()
	progress_changed.emit()
	return true


# Compatibility entry point. Under version 2, board completion intentionally
# does not unlock the next level.
func mark_level_completed(level_id: int) -> bool:
	return record_board_completion(level_id, 0, {})


func begin_post_level_story(level_id: int) -> bool:
	if (
		not is_board_completed(level_id)
		or progression_stage != STAGE_RESULTS
		or pending_progression_level != level_id
	):
		return false
	pending_progression_level = level_id
	progression_stage = STAGE_POST_STORY
	selected_level = level_id
	save_progress()
	progress_changed.emit()
	return true


func mark_story_completed(level_id: int) -> bool:
	if (
		not is_board_completed(level_id)
		or progression_stage != STAGE_POST_STORY
		or pending_progression_level != level_id
	):
		return false
	_add_unique_int(completed_story_chapters, level_id)
	pending_progression_level = level_id
	if LevelCatalog.get_character_reward(level_id).is_empty():
		_add_unique_int(completed_levels, level_id)
		var next_level_id := LevelCatalog.get_next_level_id(level_id)
		if next_level_id > 0:
			highest_unlocked_level = maxi(highest_unlocked_level, next_level_id)
		progression_stage = STAGE_LEVEL_UNLOCK
	else:
		progression_stage = STAGE_CHARACTER_UNLOCK
	save_progress()
	progress_changed.emit()
	return true


func claim_character_reward(level_id: int) -> bool:
	if (
		not is_story_completed(level_id)
		or progression_stage != STAGE_CHARACTER_UNLOCK
		or pending_progression_level != level_id
	):
		return false
	var reward := LevelCatalog.get_character_reward(level_id)
	var character_id := str(reward.get("id", ""))
	if character_id.is_empty():
		return false
	if not unlocked_characters.has(character_id):
		unlocked_characters.append(character_id)
	_add_unique_int(claimed_character_rewards, level_id)
	pending_progression_level = level_id
	progression_stage = STAGE_CHARACTER_UNLOCK
	save_progress()
	progress_changed.emit()
	return true


func confirm_character_unlock(level_id: int) -> bool:
	if (
		not claimed_character_rewards.has(level_id)
		or not is_story_completed(level_id)
		or progression_stage != STAGE_CHARACTER_UNLOCK
		or pending_progression_level != level_id
	):
		return false
	_add_unique_int(completed_levels, level_id)
	var next_level_id := LevelCatalog.get_next_level_id(level_id)
	if next_level_id > 0:
		highest_unlocked_level = maxi(highest_unlocked_level, next_level_id)
	pending_progression_level = level_id
	progression_stage = STAGE_LEVEL_UNLOCK
	save_progress()
	progress_changed.emit()
	return true


func finish_progression(level_id: int) -> bool:
	if progression_stage != STAGE_LEVEL_UNLOCK or pending_progression_level != level_id:
		return false
	if LevelCatalog.get_next_level_id(level_id) == 0 and is_level_completed(level_id):
		game_completed = true
	pending_progression_level = 0
	progression_stage = ""
	save_progress()
	progress_changed.emit()
	return true


func has_pending_progression(level_id: int = 0) -> bool:
	return not progression_stage.is_empty() and (level_id == 0 or pending_progression_level == level_id)


func select_hero(character_id: String) -> bool:
	if not is_character_unlocked(character_id):
		return false
	selected_hero = character_id
	save_progress()
	progress_changed.emit()
	return true


func save_progress() -> bool:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to save HistoryRoll progress: %s" % FileAccess.get_open_error())
		return false
	var data := {
		"version": SAVE_VERSION,
		"highest_unlocked_level": highest_unlocked_level,
		"completed_levels": completed_levels,
		"board_completed_levels": board_completed_levels,
		"completed_story_chapters": completed_story_chapters,
		"unlocked_characters": unlocked_characters,
		"claimed_character_rewards": claimed_character_rewards,
		"selected_hero": selected_hero,
		"best_scores": best_scores,
		"last_level_stats": last_level_stats,
		"selected_level": selected_level,
		"pending_progression_level": pending_progression_level,
		"progression_stage": progression_stage,
		"game_completed": game_completed,
	}
	file.store_string(JSON.stringify(data))
	return true


func load_progress() -> void:
	_reset_to_defaults()
	if not FileAccess.file_exists(save_path):
		progress_changed.emit()
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		push_warning("Unable to read HistoryRoll progress: %s" % FileAccess.get_open_error())
		progress_changed.emit()
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or typeof(json.data) != TYPE_DICTIONARY:
		push_warning("HistoryRoll progress is invalid. Default progress was loaded.")
		progress_changed.emit()
		return
	var data: Dictionary = json.data
	if int(data.get("version", 1)) < SAVE_VERSION:
		_migrate_version_one(data)
		save_progress()
	else:
		_load_version_two(data)
	progress_changed.emit()


func _load_version_two(data: Dictionary) -> void:
	highest_unlocked_level = clampi(int(data.get("highest_unlocked_level", 1)), 1, LevelCatalog.get_highest_level_id())
	_load_level_array(data.get("completed_levels", []), completed_levels)
	_load_level_array(data.get("board_completed_levels", []), board_completed_levels)
	_load_level_array(data.get("completed_story_chapters", []), completed_story_chapters)
	_load_level_array(data.get("claimed_character_rewards", []), claimed_character_rewards)
	var saved_characters: Variant = data.get("unlocked_characters", [])
	if saved_characters is Array:
		for raw_id: Variant in saved_characters:
			var character_id := str(raw_id)
			if not character_id.is_empty() and not unlocked_characters.has(character_id):
				unlocked_characters.append(character_id)
	selected_hero = str(data.get("selected_hero", DEFAULT_HERO_ID))
	if not unlocked_characters.has(selected_hero):
		selected_hero = DEFAULT_HERO_ID
	if data.get("best_scores", {}) is Dictionary:
		best_scores = (data.get("best_scores", {}) as Dictionary).duplicate(true)
	if data.get("last_level_stats", {}) is Dictionary:
		last_level_stats = (data.get("last_level_stats", {}) as Dictionary).duplicate(true)
	selected_level = clampi(int(data.get("selected_level", 1)), 1, highest_unlocked_level)
	if not LevelCatalog.has_level(selected_level):
		selected_level = 1
	pending_progression_level = int(data.get("pending_progression_level", 0))
	progression_stage = str(data.get("progression_stage", ""))
	game_completed = bool(data.get("game_completed", completed_levels.has(LevelCatalog.get_highest_level_id())))
	var valid_stages: PackedStringArray = [STAGE_RESULTS, STAGE_POST_STORY, STAGE_CHARACTER_UNLOCK, STAGE_LEVEL_UNLOCK]
	if not LevelCatalog.has_level(pending_progression_level) or not valid_stages.has(progression_stage):
		pending_progression_level = 0
		progression_stage = ""
	for completed_level: int in completed_levels:
		var next_level_id := LevelCatalog.get_next_level_id(completed_level)
		if next_level_id > 0:
			highest_unlocked_level = maxi(highest_unlocked_level, next_level_id)


func _migrate_version_one(data: Dictionary) -> void:
	highest_unlocked_level = clampi(int(data.get("highest_unlocked_level", 1)), 1, LevelCatalog.get_highest_level_id())
	var legacy_completed: Array[int] = []
	_load_level_array(data.get("completed_levels", []), legacy_completed)
	for level_id: int in legacy_completed:
		_add_unique_int(board_completed_levels, level_id)
		_add_unique_int(completed_story_chapters, level_id)
		_add_unique_int(claimed_character_rewards, level_id)
		_add_unique_int(completed_levels, level_id)
		var reward := LevelCatalog.get_character_reward(level_id)
		var character_id := str(reward.get("id", ""))
		if not character_id.is_empty() and not unlocked_characters.has(character_id):
			unlocked_characters.append(character_id)
		var next_level_id := LevelCatalog.get_next_level_id(level_id)
		if next_level_id > 0:
			highest_unlocked_level = maxi(highest_unlocked_level, next_level_id)
	game_completed = completed_levels.has(LevelCatalog.get_highest_level_id())


func _load_level_array(source: Variant, destination: Array[int]) -> void:
	if not source is Array:
		return
	for raw_level: Variant in source:
		if raw_level is int or raw_level is float:
			var level_id := int(raw_level)
			if LevelCatalog.has_level(level_id):
				_add_unique_int(destination, level_id)
	destination.sort()


func _add_unique_int(values: Array[int], value: int) -> void:
	if not values.has(value):
		values.append(value)
		values.sort()


func _reset_to_defaults() -> void:
	highest_unlocked_level = 1
	completed_levels.clear()
	board_completed_levels.clear()
	completed_story_chapters.clear()
	unlocked_characters = [DEFAULT_HERO_ID]
	claimed_character_rewards.clear()
	selected_hero = DEFAULT_HERO_ID
	best_scores.clear()
	last_level_stats.clear()
	selected_level = 1
	pending_progression_level = 0
	progression_stage = ""
	game_completed = false

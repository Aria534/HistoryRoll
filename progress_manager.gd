extends Node

signal progress_changed

const DEFAULT_SAVE_PATH: String = "user://historyroll_progress.json"
const SAVE_VERSION: int = 1

var save_path: String = DEFAULT_SAVE_PATH
var highest_unlocked_level: int = 1
var completed_levels: Array[int] = []
var selected_level: int = 1


func _ready() -> void:
	load_progress()


func is_level_unlocked(level_id: int) -> bool:
	return level_id >= 1 and level_id <= highest_unlocked_level


func is_level_completed(level_id: int) -> bool:
	return completed_levels.has(level_id)


func select_level(level_id: int) -> bool:
	if not is_level_unlocked(level_id):
		return false
	selected_level = level_id
	return true


func mark_level_completed(level_id: int) -> bool:
	if not is_level_unlocked(level_id):
		return false

	if not completed_levels.has(level_id):
		completed_levels.append(level_id)
		completed_levels.sort()

	highest_unlocked_level = max(highest_unlocked_level, level_id + 1)
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
	var saved_highest: Variant = data.get("highest_unlocked_level", 1)
	if saved_highest is int or saved_highest is float:
		highest_unlocked_level = max(1, int(saved_highest))

	var saved_completed: Variant = data.get("completed_levels", [])
	if saved_completed is Array:
		for value: Variant in saved_completed:
			if value is int or value is float:
				var level_id := int(value)
				if level_id >= 1 and not completed_levels.has(level_id):
					completed_levels.append(level_id)
					highest_unlocked_level = max(highest_unlocked_level, level_id + 1)
		completed_levels.sort()

	selected_level = 1
	progress_changed.emit()


func _reset_to_defaults() -> void:
	highest_unlocked_level = 1
	completed_levels.clear()
	selected_level = 1

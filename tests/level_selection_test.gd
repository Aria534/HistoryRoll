extends SceneTree

const LevelSelectionScene = preload("res://level_selection.tscn")
const ProgressManagerScript = preload("res://progress_manager.gd")

var _passed := 0
var _failed := 0
var _save_path := "user://historyroll_level_selection_test.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	await _test_fresh_level_selection()
	await _test_saved_selection_and_pending_progression()
	_cleanup()
	print("Level Selection tests: %d passed, %d failed." % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_fresh_level_selection() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = _save_path
	var requested_scenes: Array[String] = []
	var screen = LevelSelectionScene.instantiate()
	screen.progress_manager = progress
	screen.scene_change_handler = func(path: String): requested_scenes.append(path)
	get_root().add_child(screen)
	await process_frame

	var selection_label := screen.get_node_or_null("%SelectionLabel")
	_check(selection_label is Label, "SelectionLabel exists and resolves as a unique Label")
	_check(screen._validate_required_nodes(), "required-node validation succeeds")
	_check(screen.level_buttons.size() == 6, "all six temporary level buttons are generated")
	_check(not screen.level_buttons[1].disabled, "Level 1 is unlocked by default")
	for level_id: int in range(2, 7):
		_check(screen.level_buttons[level_id].disabled, "Level %d is disabled while locked" % level_id)
	_check(screen.selected_level_id == 1, "saved default Level 1 selection is restored")
	_check(selection_label.text == "Selected: Level 1", "selected-level message updates without a null error")
	_check(not screen.play_button.disabled, "Play is enabled for the selected playable level")

	screen._on_level_pressed(2)
	_check(selection_label.text == "That level is still locked.", "locked-level selection displays its status message")
	screen.selected_level_id = 0
	screen._on_play_pressed()
	_check(selection_label.text == "Select an unlocked level first.", "Play rejects an unavailable selection clearly")
	_check(screen.play_button.disabled, "Play disables itself when the current selection is unavailable")

	screen._select_level(1)
	screen.play_button.pressed.emit()
	_check(requested_scenes == ["res://gameplay_placeholder.tscn"], "Play loads Level 1 gameplay through its button signal")
	requested_scenes.clear()
	screen.back_button.pressed.emit()
	_check(requested_scenes == ["res://main_menu_tscn.tscn"], "Back opens the Main Menu through its button signal")
	_check(screen.back_button.mouse_entered.get_connections().size() > 0, "Back hover animation remains connected")
	_check(screen.play_button.button_down.get_connections().size() > 0, "Play press animation remains connected")
	_check(screen.size.x < screen.size.y, "Level Selection uses the portrait project viewport")

	screen.queue_free()
	await process_frame
	progress.free()


func _test_saved_selection_and_pending_progression() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = _save_path
	progress.highest_unlocked_level = 2
	_check(progress.select_level(2), "an unlocked Level 2 selection can be saved")
	progress.save_progress()
	var reloaded = ProgressManagerScript.new()
	reloaded.save_path = _save_path
	reloaded.load_progress()
	_check(reloaded.selected_level == 2, "selected level survives save reload")
	_check(reloaded.select_level(1), "Level 1 can be reselected for progression testing")
	_check(reloaded.record_board_completion(1, 100, {}), "test board completion creates pending progression")

	var requested_scenes: Array[String] = []
	var screen = LevelSelectionScene.instantiate()
	screen.progress_manager = reloaded
	screen.scene_change_handler = func(path: String): requested_scenes.append(path)
	get_root().add_child(screen)
	await process_frame
	_check(screen.play_button.text == "Continue", "pending progression changes Play to Continue")
	screen.play_button.pressed.emit()
	_check(requested_scenes == ["res://story_mode.tscn"], "pending results progression resumes Story Mode")
	_check(reloaded.progression_stage == reloaded.STAGE_POST_STORY, "pending progression advances without resetting save data")

	screen.queue_free()
	await process_frame
	progress.free()
	reloaded.free()


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

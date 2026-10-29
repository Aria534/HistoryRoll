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
	await _test_editor_customization_round_trip()
	await _test_saved_selection_and_pending_progression()
	_cleanup()
	await _test_unlock_visual_refresh()
	_cleanup()
	print("Level Selection tests: %d passed, %d failed." % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_fresh_level_selection() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = _save_path
	_check(progress.highest_unlocked_level == 1, "fresh progress starts with only Level 1 unlocked")
	_check(progress.completed_levels.is_empty(), "fresh progress has no completed levels")
	_check(progress.board_completed_levels.is_empty(), "fresh progress has no completed boards")
	_check(progress.completed_story_chapters.is_empty(), "fresh progress has no completed stories")
	_check(progress.claimed_character_rewards.is_empty(), "fresh progress has no claimed rewards")
	_check(progress.selected_level == 1, "fresh progress selects Level 1")
	var requested_scenes: Array[String] = []
	var screen = LevelSelectionScene.instantiate()
	screen.progress_manager = progress
	screen.scene_change_handler = func(path: String): requested_scenes.append(path)
	var editor_geometry: Dictionary = {}
	for level_id: int in range(1, 7):
		var packed_button := screen.get_node("LevelButtonsArea/Level%dButton" % level_id) as TextureButton
		editor_geometry[level_id] = {"position": packed_button.position, "size": packed_button.size}
	get_root().add_child(screen)
	await process_frame

	var selection_label := screen.get_node_or_null("%SelectionLabel")
	_check(selection_label is Label, "SelectionLabel exists and resolves as a unique Label")
	_check(screen._validate_required_nodes(), "required-node validation succeeds")
	_check(screen.level_buttons.size() == 6, "all six permanent custom level buttons are cached")
	_check(screen.level_buttons_area.get_child_count() == 6, "runtime does not create duplicate level buttons")
	_check(screen.title_banner is TextureRect and screen.title_banner.visible, "permanent title banner is visible")
	_check(screen.title_banner.texture.resource_path.ends_with("Choose Your Level Glossy Game Banner.png"), "title banner uses the supplied PNG")
	_check(screen.get_node("TitleLabel").visible == false, "legacy plain title remains hidden")
	_check(screen.get_node("InstructionLabel").visible == false, "instruction text remains hidden")
	for level_id: int in range(1, 7):
		var level_button = screen.level_buttons[level_id]
		var expected_texture := "Level1.png" if level_id == 1 else "Level%d_locked.png" % level_id
		_check(level_button is TextureButton, "Level %d uses a TextureButton" % level_id)
		_check(level_button.owner == screen, "Level %d button is stored in the packed scene" % level_id)
		_check(level_button.texture_normal != null, "Level %d custom texture is loaded" % level_id)
		_check(level_button.texture_normal.resource_path.ends_with(expected_texture), "Level %d uses the correct fresh-player PNG" % level_id)
		_check(level_button.size.is_equal_approx(Vector2(405.0, 135.0)), "Level %d keeps the approved 405 by 135 dimensions" % level_id)
		_check(is_equal_approx(level_button.size.x / level_button.size.y, 3.0), "Level %d keeps the source artwork's 3-to-1 aspect ratio" % level_id)
		_check(level_button.position.is_equal_approx(editor_geometry[level_id].position), "Level %d editor position is preserved at runtime" % level_id)
		_check(level_button.size.is_equal_approx(editor_geometry[level_id].size), "Level %d editor size is preserved at runtime" % level_id)
	_check(screen.back_button is TextureButton, "Back uses a TextureButton")
	_check(screen.play_button is TextureButton, "Play uses a TextureButton")
	_check(not screen.level_buttons[1].disabled, "Level 1 is unlocked by default")
	_check(screen.level_buttons[1].texture_disabled == null, "unlocked Level 1 has no disabled-state texture")
	var locked_texture_count := 0
	for level_id: int in range(2, 7):
		var level_button: TextureButton = screen.level_buttons[level_id]
		_check(level_button.disabled, "Level %d is disabled while locked" % level_id)
		_check(level_button.self_modulate.is_equal_approx(Color.WHITE), "Level %d locked artwork keeps the original full-color palette" % level_id)
		_check(level_button.get_child_count() == 0, "Level %d has no runtime lock overlay" % level_id)
		_check(level_button.texture_normal.resource_path.ends_with("Level%d_locked.png" % level_id), "Level %d displays its self-contained locked PNG" % level_id)
		_check(level_button.texture_disabled == level_button.texture_normal, "Level %d disabled state preserves its locked artwork" % level_id)
		if level_button.texture_normal.resource_path.ends_with("_locked.png"):
			locked_texture_count += 1
		_check(not level_button.tooltip_text.contains(["", "LAPU-LAPU", "BONIFACIO", "RIZAL", "LUNA", "AQUINO", "MABINI"][level_id]), "Level %d locked tooltip does not reveal its hero name" % level_id)
	_check(locked_texture_count == 5, "fresh-player Level Selection displays exactly five locked PNGs")
	_check(screen.selected_level_id == 1, "saved default Level 1 selection is restored")
	_check(selection_label.text == "Selected: Level 1", "selected-level message updates without a null error")
	_check(not selection_label.get_parent().visible, "selected-level status panel is hidden without removing its label")
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
	screen.play_button.pressed.emit()
	_check(requested_scenes.size() == 1, "repeated Play presses cannot request duplicate scene transitions")
	screen.scene_transition_pending = false
	screen.back_button.disabled = false
	requested_scenes.clear()
	screen.back_button.pressed.emit()
	_check(requested_scenes == ["res://main_menu_tscn.tscn"], "Back opens the Main Menu through its button signal")
	_check(screen.back_button.mouse_entered.get_connections().size() > 0, "Back hover animation remains connected")
	_check(screen.play_button.button_down.get_connections().size() > 0, "Play press animation remains connected")
	_check(screen.size.x < screen.size.y, "Level Selection uses the portrait project viewport")

	screen.queue_free()
	await process_frame
	progress.free()


func _test_editor_customization_round_trip() -> void:
	var temp_scene_path := "user://level_selection_editor_customization_test.tscn"
	var screen = LevelSelectionScene.instantiate()
	var button := screen.get_node("LevelButtonsArea/Level4Button") as TextureButton
	var expected_position := button.position + Vector2(7.0, 5.0)
	var expected_size := button.size + Vector2(12.0, 8.0)
	button.position = expected_position
	button.size = expected_size
	var packed := PackedScene.new()
	_check(packed.pack(screen) == OK, "temporary editor-customization scene packs successfully")
	_check(ResourceSaver.save(packed, temp_scene_path) == OK, "temporary editor-customization scene saves successfully")
	screen.free()
	var reloaded_scene := load(temp_scene_path) as PackedScene
	var reloaded = reloaded_scene.instantiate()
	var progress = ProgressManagerScript.new()
	progress.save_path = _save_path
	reloaded.progress_manager = progress
	get_root().add_child(reloaded)
	await process_frame
	var reloaded_button := reloaded.get_node("LevelButtonsArea/Level4Button") as TextureButton
	_check(reloaded_button.position.is_equal_approx(expected_position), "manual button position survives a scene save and reload")
	_check(reloaded_button.size.is_equal_approx(expected_size), "manual button size survives a scene save and reload")
	_check(reloaded_button.texture_normal.resource_path.ends_with("Level4_locked.png"), "resized locked button keeps its self-contained texture")
	_check(reloaded_button.get_child_count() == 0, "resized button remains independently editable without overlay children")
	reloaded.queue_free()
	await process_frame
	progress.free()
	if FileAccess.file_exists(temp_scene_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_scene_path))


func _test_saved_selection_and_pending_progression() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = _save_path
	progress.highest_unlocked_level = 3
	progress.completed_levels.assign([1, 2])
	progress.board_completed_levels.assign([1, 2])
	progress.completed_story_chapters.assign([1, 2])
	progress.claimed_character_rewards.assign([1, 2])
	_check(progress.select_level(2), "an unlocked Level 2 selection can be saved")
	progress.save_progress()
	var reloaded = ProgressManagerScript.new()
	reloaded.save_path = _save_path
	reloaded.load_progress()
	_check(reloaded.selected_level == 2, "selected level survives save reload")
	_check(reloaded.select_level(1), "Level 1 can be reselected for progression testing")
	_check(reloaded.record_board_completion(1, 100, {}), "test board completion records direct progression")

	var requested_scenes: Array[String] = []
	var screen = LevelSelectionScene.instantiate()
	screen.progress_manager = reloaded
	screen.scene_change_handler = func(path: String): requested_scenes.append(path)
	get_root().add_child(screen)
	await process_frame
	var returning_lock_count := 0
	for level_id: int in range(1, 4):
		_check(not screen.level_buttons[level_id].disabled, "returning-player Level %d remains unlocked" % level_id)
		_check(screen.level_buttons[level_id].texture_normal.resource_path.ends_with("Level%d.png" % level_id), "returning-player Level %d uses its original unlocked PNG" % level_id)
		_check(screen.level_buttons[level_id].texture_disabled == null, "returning-player Level %d has no locked disabled texture" % level_id)
		_check(screen.level_buttons[level_id].self_modulate.is_equal_approx(Color.WHITE), "returning-player Level %d uses its original colors" % level_id)
	for level_id: int in range(4, 7):
		_check(screen.level_buttons[level_id].disabled, "returning-player Level %d remains locked" % level_id)
		_check(screen.level_buttons[level_id].texture_normal.resource_path.ends_with("Level%d_locked.png" % level_id), "returning-player Level %d keeps its locked PNG" % level_id)
		if screen.level_buttons[level_id].texture_normal.resource_path.ends_with("_locked.png"):
			returning_lock_count += 1
	_check(returning_lock_count == 3, "returning-player Level Selection displays exactly three locked PNGs")
	_check(screen.play_button.tooltip_text == "Play Level 1", "completed levels remain directly replayable")
	screen.play_button.pressed.emit()
	_check(requested_scenes == ["res://gameplay_placeholder.tscn"], "completed level replay opens gameplay, not Story Mode")
	_check(not reloaded.has_pending_progression(), "direct progression has no mandatory Story stage")

	screen.queue_free()
	await process_frame
	progress.free()
	reloaded.free()


func _test_unlock_visual_refresh() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = _save_path
	var screen = LevelSelectionScene.instantiate()
	screen.progress_manager = progress
	get_root().add_child(screen)
	await process_frame
	_check(screen.level_buttons[2].disabled, "Level 2 starts locked before progression confirmation")
	_check(screen.level_buttons[2].texture_normal.resource_path.ends_with("Level2_locked.png"), "Level 2 starts with its locked PNG")

	_check(progress.record_board_completion(1, 100, {}), "Level 1 board completion is recorded for unlock testing")
	_check(progress.is_level_completed(1), "Level 1 completion is finalized immediately")
	_check(progress.is_level_unlocked(2), "Level 1 completion legitimately unlocks Level 2")
	await process_frame
	await process_frame

	var level_two: TextureButton = screen.level_buttons[2]
	_check(progress.is_level_unlocked(2), "ProgressManager reports Level 2 unlocked")
	_check(not level_two.disabled, "Level 2 becomes enabled without reopening the screen")
	_check(level_two.texture_normal.resource_path.ends_with("Level2.png"), "Level 2 switches to its original full-name PNG after unlocking")
	_check(level_two.texture_disabled == null, "Level 2 clears its locked disabled texture after unlocking")
	_check(level_two.self_modulate.is_equal_approx(Color.WHITE), "Level 2 returns to its original full-color appearance")
	_check(not screen.level_buttons[1].disabled, "completed Level 1 remains replayable")
	screen._select_level(2)
	_check(screen.selected_level_id == 2, "newly unlocked Level 2 can be selected")
	_check(not screen.play_button.disabled, "PLAY enables for newly unlocked Level 2")

	screen.queue_free()
	await process_frame
	progress.free()

	var reloaded = ProgressManagerScript.new()
	reloaded.save_path = _save_path
	reloaded.load_progress()
	var reopened = LevelSelectionScene.instantiate()
	reopened.progress_manager = reloaded
	get_root().add_child(reopened)
	await process_frame
	_check(reloaded.is_level_unlocked(2), "Level 2 unlock persists after save reload")
	_check(not reopened.level_buttons[2].disabled, "reopened Level 2 remains enabled")
	_check(reopened.level_buttons[2].texture_normal.resource_path.ends_with("Level2.png"), "reopened Level 2 keeps its unlocked PNG")
	_check(reloaded.record_board_completion(2, 200, {}), "Level 2 board completion is recorded for sequential unlock testing")
	_check(reloaded.is_level_completed(2), "Level 2 completion is finalized immediately")
	_check(reloaded.is_level_unlocked(3), "Level 2 completion legitimately unlocks Level 3")
	await process_frame
	await process_frame
	var level_three: TextureButton = reopened.level_buttons[3]
	_check(reloaded.is_level_unlocked(3), "ProgressManager reports Level 3 unlocked")
	_check(not level_three.disabled, "Level 3 becomes enabled without reopening the screen")
	_check(level_three.texture_normal.resource_path.ends_with("Level3.png"), "Level 3 switches to its original full-name PNG after unlocking")
	_check(level_three.texture_disabled == null, "Level 3 clears its locked disabled texture after unlocking")
	_check(level_three.self_modulate.is_equal_approx(Color.WHITE), "Level 3 returns to its original full-color appearance")
	reopened._select_level(3)
	_check(reopened.selected_level_id == 3, "newly unlocked Level 3 can be selected")
	_check(not reopened.play_button.disabled, "PLAY enables for newly unlocked Level 3")

	reopened.queue_free()
	await process_frame
	reloaded.free()

	var final_reload = ProgressManagerScript.new()
	final_reload.save_path = _save_path
	final_reload.load_progress()
	_check(final_reload.is_level_unlocked(3), "Level 3 unlock persists after save reload")
	_check(final_reload.completed_levels.has(2), "Level 2 completion persists after save reload")
	final_reload.free()


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

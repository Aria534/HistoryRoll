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
	await _test_unlock_visual_refresh()
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
	_check(screen.level_buttons.size() == 6, "all six custom level buttons are generated")
	for level_id: int in range(1, 7):
		var level_button = screen.level_buttons[level_id]
		_check(level_button is TextureButton, "Level %d uses a TextureButton" % level_id)
		_check(level_button.texture_normal != null, "Level %d custom texture is loaded" % level_id)
		_check(level_button.texture_normal.resource_path.ends_with("Level%d.png" % level_id), "Level %d uses its matching custom PNG" % level_id)
	_check(screen.back_button is TextureButton, "Back uses a TextureButton")
	_check(screen.play_button is TextureButton, "Play uses a TextureButton")
	_check(not screen.level_buttons[1].disabled, "Level 1 is unlocked by default")
	_check(not screen.level_buttons[1].get_node("LockIndicator").visible, "unlocked Level 1 has no visible padlock")
	var expected_glyph_size := Vector2(54.0, 54.0)
	_check(screen.LOCK_GOLD.is_equal_approx(Color("#FFD43B")), "padlock fill uses the required bright gold color")
	_check(screen.LOCK_OUTLINE.is_equal_approx(Color("#5C3900")), "padlock uses the required dark-brown outline")
	for level_id: int in range(2, 7):
		var level_button: TextureButton = screen.level_buttons[level_id]
		var lock_nodes := level_button.find_children("LockIndicator", "CenterContainer", false, false)
		_check(level_button.disabled, "Level %d is disabled while locked" % level_id)
		_check(lock_nodes.size() == 1, "Level %d has exactly one lock indicator" % level_id)
		if lock_nodes.size() != 1:
			continue
		var lock_indicator: CenterContainer = lock_nodes[0]
		var padlock_glyph := lock_indicator.get_node("PadlockGlyph") as Control
		_check(lock_indicator.visible, "Level %d displays its lock indicator" % level_id)
		_check(lock_indicator.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Level %d lock does not intercept input" % level_id)
		_check(padlock_glyph != null, "Level %d lock contains its gold padlock glyph" % level_id)
		if padlock_glyph == null:
			continue
		_check(padlock_glyph.size.is_equal_approx(expected_glyph_size), "Level %d lock uses consistent dimensions" % level_id)
		_check(is_equal_approx(padlock_glyph.size.y / level_button.size.y, 0.4), "Level %d lock occupies 40 percent of the button height" % level_id)
		_check((padlock_glyph.position + padlock_glyph.size * 0.5).distance_to(level_button.size * 0.5) <= 0.75, "Level %d lock is centered inside its button" % level_id)
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


func _test_saved_selection_and_pending_progression() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = _save_path
	progress.highest_unlocked_level = 3
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
	for level_id: int in range(1, 4):
		_check(not screen.level_buttons[level_id].disabled, "returning-player Level %d remains unlocked" % level_id)
		_check(not screen.level_buttons[level_id].get_node("LockIndicator").visible, "returning-player Level %d hides its padlock" % level_id)
		_check(screen.level_buttons[level_id].self_modulate.is_equal_approx(Color.WHITE), "returning-player Level %d uses its original colors" % level_id)
	for level_id: int in range(4, 7):
		_check(screen.level_buttons[level_id].disabled, "returning-player Level %d remains locked" % level_id)
		_check(screen.level_buttons[level_id].get_node("LockIndicator").visible, "returning-player Level %d keeps its padlock" % level_id)
	_check(screen.play_button.tooltip_text == "Continue Level 1 progression", "pending progression gives Play a Continue description")
	screen.play_button.pressed.emit()
	_check(requested_scenes == ["res://story_mode.tscn"], "pending results progression resumes Story Mode")
	_check(reloaded.progression_stage == reloaded.STAGE_POST_STORY, "pending progression advances without resetting save data")

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
	_check(screen.level_buttons[2].get_node("LockIndicator").visible, "Level 2 starts with a visible padlock")

	_check(progress.record_board_completion(1, 100, {}), "Level 1 board completion is recorded for unlock testing")
	_check(progress.begin_post_level_story(1), "Level 1 post-game progression begins")
	_check(progress.mark_story_completed(1), "Level 1 story completion is recorded")
	_check(progress.claim_character_reward(1), "Level 1 character reward is claimed")
	_check(progress.confirm_character_unlock(1), "Level 1 confirmation legitimately unlocks Level 2")
	await process_frame
	await process_frame

	var level_two: TextureButton = screen.level_buttons[2]
	_check(progress.is_level_unlocked(2), "ProgressManager reports Level 2 unlocked")
	_check(not level_two.disabled, "Level 2 becomes enabled without reopening the screen")
	_check(not level_two.get_node("LockIndicator").visible, "Level 2 padlock disappears after unlocking")
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
	_check(not reopened.level_buttons[2].get_node("LockIndicator").visible, "reopened Level 2 has no leftover padlock")

	reopened.queue_free()
	await process_frame
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

extends SceneTree

const Progress = preload("res://progress_manager.gd")
const EntryScene = preload("res://player_name_entry.tscn")
const CertificateScene = preload("res://certificate.tscn")
const TEST_SAVE := "user://historyroll_identity_test.json"
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if OS.get_cmdline_user_args().has("--verify-name-reload"):
		var restored = _new_progress()
		restored.load_progress()
		var valid: bool = restored.player_name == "Anne-Marie O\'Connor" and restored.completed_levels == [1,2] and restored.best_scores.get("1") == 123
		restored.free()
		print("Fresh-process name/progress restore: ", valid)
		quit(0 if valid else 1)
		return
	_cleanup()
	var audio := get_root().get_node_or_null("AudioManager")
	var music_enabled: bool = audio.is_music_enabled() if audio != null else true
	if Engine.is_editor_hint():
		await _test_editor()
	else:
		_test_name_rules()
		_test_save_compatibility()
		await _test_entry()
		await _test_certificate_gate()
		for dimensions: Vector2i in [Vector2i(1024,1536), Vector2i(720,1280), Vector2i(1080,2400)]:
			await _test_layout(dimensions)
		await _test_actual_navigation()
	if audio != null:
		audio.stop_music(0.0)
		audio.set_music_enabled(music_enabled, false)
	_cleanup()
	await process_frame
	await process_frame
	print("Player identity tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)

func _new_progress():
	var progress = Progress.new()
	progress.save_path = TEST_SAVE
	return progress

func _test_name_rules() -> void:
	for value: String in ["", "   ", "123", "Ana2", "Ana_B", "Ana\nB", "Ana\tB", "Ana🙂", "-- '", "<Name>", "W".repeat(31)]:
		_check(not Progress.get_player_name_error(value).is_empty(), "invalid name rejected: " + value)
	for value: String in ["A", "Ana Maria", "José Niño", "Anne-Marie", "O'Connor", "D’Arcy", "张伟", "W".repeat(30)]:
		_check(Progress.get_player_name_error(value).is_empty(), "valid name accepted: " + value)
	_check(Progress.normalize_player_name("  Ana   Maria  ") == "Ana Maria", "outer and repeated ordinary spaces are normalized")

func _test_save_compatibility() -> void:
	var legacy := {"version":3, "highest_unlocked_level":3, "completed_levels":[1,2], "board_completed_levels":[1,2],
		"best_scores":{"1":123,"2":87}, "unlocked_characters":["historyroll_explorer","lapulapu"],
		"claimed_character_rewards":[1,2], "selected_hero":"lapulapu", "selected_level":2,
		"watched_story_chapters":[1], "game_completed":false}
	_write_json(legacy)
	var progress = _new_progress()
	progress.load_progress()
	_check(progress.player_name.is_empty(), "old version-3 save defaults to an empty player name")
	_check(progress.highest_unlocked_level == 3 and progress.best_scores["1"] == 123, "old unlocks and best score are preserved")
	var completed: Array = progress.completed_levels.duplicate()
	var heroes: Array = progress.unlocked_characters.duplicate()
	var scores: Dictionary = progress.best_scores.duplicate()
	_check(progress.set_player_name("  Ana   María  "), "name is saved through the existing ProgressManager")
	_check(progress.player_name == "Ana María", "saved name is normalized")
	_check(progress.completed_levels == completed and progress.unlocked_characters == heroes and progress.best_scores == scores, "adding a name preserves completions, heroes and scores")
	var reloaded = _new_progress()
	reloaded.load_progress()
	_check(reloaded.player_name == "Ana María" and reloaded.selected_hero == "lapulapu" and reloaded.selected_level == 2, "disk reload restores name and existing selections")
	_check(reloaded.set_player_name("Anne-Marie O'Connor"), "returning player can edit the saved name")
	_check(not reloaded.set_player_name("123") and reloaded.player_name == "Anne-Marie O'Connor", "invalid edit cannot overwrite a saved name")
	_check(reloaded.best_scores == scores and reloaded.completed_levels == completed and reloaded.highest_unlocked_level == 3, "editing never resets progress")
	var restart_output: Array = []
	var restart_code := OS.execute(OS.get_executable_path(), PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"), "--script", "res://tests/player_identity_test.gd", "--audio-driver", "Dummy", "--", "--verify-name-reload"]), restart_output, true)
	_check(restart_code == 0 and str(restart_output).contains("Fresh-process name/progress restore: true"), "a separate Godot process restores the saved player name and existing progress")
	reloaded.save_path = "user://missing_identity_test_directory/progress.json"
	_check(not reloaded.set_player_name("New Name") and reloaded.player_name == "Anne-Marie O'Connor", "failed save rolls back the name in memory")
	for malformed: Variant in [[], 123, "W".repeat(31), "Name123", null]:
		var invalid := legacy.duplicate(true)
		invalid["player_name"] = malformed
		_write_json(invalid)
		progress.load_progress()
		_check(progress.player_name.is_empty() and progress.completed_levels == completed, "malformed saved name cannot damage existing progress")
	var corrupt := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.close()
	progress.load_progress()
	_check(progress.player_name.is_empty() and progress.highest_unlocked_level == 1, "corrupt-save recovery remains safe")
	progress.free()
	reloaded.free()
	_cleanup()

func _test_entry() -> void:
	var progress = _new_progress()
	var viewport := _viewport(Vector2i(720,1280))
	var screen = EntryScene.instantiate()
	screen.progress_manager = progress
	var requested: Array[String] = []
	screen.scene_change_handler = func(path: String): requested.append(path)
	viewport.add_child(screen)
	await _frames()
	_check(screen.name_input.text.is_empty() and screen.continue_button.disabled, "fresh entry has no name and Continue disabled")
	_check(not screen.certificate_button.visible, "fresh player cannot view an unearned certificate")
	await _capture(viewport, "identity_entry_fresh_720x1280.png")
	_check(screen.name_input.max_length == 30 and screen.name_input.virtual_keyboard_enabled, "input enables native Android keyboard and a 30-character limit")
	_check(not screen.get_node("%WelcomeHeading").visible and screen.get_node("%Subtitle").text == "Enter your name to begin your journey.", "name entry displays only the journey prompt instead of Welcome")
	_check(screen.get_node("Presentation/Artwork").texture.resource_path.ends_with("name_entry_background_no_leaves.png"), "name entry uses the background without logo laurel leaves")
	_check(screen.name_input.size.x < screen.form.size.x * 0.9 and screen.name_input.get_global_rect().size.y >= 44.0, "name field is narrower while retaining a touch-friendly height")
	viewport.gui_release_focus()
	_click(viewport, screen.name_input.get_global_rect().get_center())
	await _frames()
	_check(screen.name_input.has_focus() and screen.name_input.is_editing(), "one mouse click immediately enters name editing")
	await _capture(viewport, "identity_entry_caret_empty_720x1280.png")
	_type_text(viewport, "Ana")
	await _frames()
	_check(screen.name_input.text == "Ana" and screen.character_count.text == "3 / 30" and not screen.continue_button.disabled, "real keyboard typing after one click updates the name and Continue")
	await _capture(viewport, "identity_entry_focused_720x1280.png")
	viewport.gui_release_focus()
	_input(screen, "")
	_tap(viewport, screen.name_input.get_global_rect().get_center())
	await _frames()
	_check(screen.name_input.has_focus() and screen.name_input.is_editing(), "one touchscreen tap also enters name editing")
	_type_text(viewport, "Maria")
	await _frames()
	_check(screen.name_input.text == "Maria" and not screen.continue_button.disabled, "typing after a tap uses the same native name field")
	screen.back_button.grab_focus()
	await _frames()
	_check(not screen.name_input.is_editing() and not screen.name_input.caret_force_displayed and screen.name_input.placeholder_text == "Enter your name...", "leaving the name field removes its typing caret and restores the placeholder")
	for value: String in ["   ", "Ana2", "-"]:
		_input(screen, value)
		_check(screen.continue_button.disabled and not screen.validation_label.text.is_empty(), "invalid input disables Continue and explains validation")
	screen.name_input.text = "W".repeat(31)
	_check(screen.name_input.text.length() == 30, "native LineEdit prevents more than 30 characters")
	_input(screen, "  Ana   María  ")
	_check(not screen.continue_button.disabled, "valid name enables Continue")
	_click(viewport, screen.continue_button.get_global_rect().get_center())
	screen.continue_button.pressed.emit()
	_check(requested == ["res://level_selection.tscn"], "real pointer Continue navigates once to existing Level Selection")
	_check(progress.player_name == "Ana María", "Continue saves the normalized name")
	viewport.queue_free()
	await _frames()
	var reloaded = _new_progress()
	reloaded.load_progress()
	viewport = _viewport(Vector2i(720,1280))
	screen = EntryScene.instantiate()
	screen.progress_manager = reloaded
	requested.clear()
	screen.scene_change_handler = func(path: String): requested.append(path)
	viewport.add_child(screen)
	await _frames()
	_check(screen.name_input.text == "Ana María" and not screen.continue_button.disabled, "returning entry prefills the saved name")
	_input(screen, "O'Connor")
	screen.name_input.text_submitted.emit(screen.name_input.text)
	_check(requested == ["res://level_selection.tscn"] and reloaded.player_name == "O'Connor", "keyboard submit saves an edited name and continues")
	viewport.queue_free()
	await _frames()
	viewport = _viewport(Vector2i(720,1280))
	screen = EntryScene.instantiate()
	screen.progress_manager = reloaded
	requested.clear()
	screen.scene_change_handler = func(path: String): requested.append(path)
	viewport.add_child(screen)
	await _frames()
	_input(screen, "Unsaved Edit")
	screen.back_button.pressed.emit()
	_check(requested == ["res://main_menu_tscn.tscn"] and reloaded.player_name == "O'Connor", "Back returns to Main Menu without saving an unconfirmed edit")
	viewport.queue_free()
	await _frames()
	progress.free()
	reloaded.free()

func _test_certificate_gate() -> void:
	var progress = _new_progress()
	progress.player_name = "History Explorer"
	progress.highest_unlocked_level = 6
	progress.game_completed = true
	progress.completed_levels.assign([6])
	_check(not progress.is_certificate_unlocked(), "level 6 and a completion flag cannot bypass the other five levels")
	for omitted: int in range(1,7):
		progress.completed_levels.clear()
		for level_id: int in range(1,7):
			if level_id != omitted:
				progress.completed_levels.append(level_id)
		_check(not progress.is_certificate_unlocked(), "certificate stays locked with Level %d missing" % omitted)
	progress.completed_levels.assign([1,2,3,4,5,6])
	progress.save_progress()
	var reloaded = _new_progress()
	reloaded.load_progress()
	_check(reloaded.is_certificate_unlocked() and reloaded.player_name == "History Explorer", "certificate eligibility and name survive disk reload")
	var viewport := _viewport(Vector2i(720,1280))
	var screen = CertificateScene.instantiate()
	screen.progress_manager = reloaded
	var requested: Array[String] = []
	screen.scene_change_handler = func(path: String): requested.append(path)
	viewport.add_child(screen)
	await _frames()
	_check(screen.certificate_canvas.visible and screen.player_name_label.text == reloaded.player_name, "earned certificate shows the saved name")
	await _capture(viewport, "identity_certificate_earned_720x1280.png")
	screen.back_button.pressed.emit()
	screen.back_button.pressed.emit()
	_check(requested == ["res://level_selection.tscn"], "certificate Back returns once to Level Selection")
	reloaded.completed_levels.erase(3)
	reloaded.progress_changed.emit()
	_check(not screen.certificate_canvas.visible and screen.player_name_label.text.is_empty(), "direct-open certificate hides unearned artwork and name")
	reloaded.completed_levels.append(3)
	reloaded.player_name = ""
	reloaded.progress_changed.emit()
	_check(not screen.certificate_canvas.visible and screen.name_button.visible, "legacy completer without a name is prompted to add one")
	viewport.queue_free()
	await _frames()
	viewport = _viewport(Vector2i(720,1280))
	var entry = EntryScene.instantiate()
	reloaded.player_name = "Maria"
	entry.progress_manager = reloaded
	entry.scene_change_handler = func(path: String): requested.append(path)
	requested.clear()
	viewport.add_child(entry)
	await _frames()
	_check(entry.certificate_button.visible and not entry.certificate_button.disabled, "earned certificate can be viewed again from name entry")
	entry.certificate_button.pressed.emit()
	_check(requested == ["res://certificate.tscn"], "View Certificate requests the earned certificate scene")
	viewport.queue_free()
	await _frames()
	progress.free()
	reloaded.free()

func _test_layout(dimensions: Vector2i) -> void:
	var progress = _new_progress()
	progress.player_name = "W".repeat(30)
	progress.completed_levels.assign([1,2,3,4,5,6])
	var viewport := _viewport(dimensions)
	var entry = EntryScene.instantiate()
	entry.progress_manager = progress
	viewport.add_child(entry)
	await _frames()
	for control: Control in [entry.form, entry.name_input, entry.back_button, entry.continue_button, entry.certificate_button, entry.validation_label]:
		_check(_inside(control.get_global_rect(), dimensions), "%s entry %s is in bounds" % [dimensions, control.name])
	_check(entry.name_input.get_global_rect().size.y >= 44.0 and entry.continue_button.get_global_rect().size.y >= 44.0, "%s entry has touch-friendly controls" % dimensions)
	_check(not entry.back_button.get_global_rect().intersects(entry.continue_button.get_global_rect()), "%s Back and Continue do not overlap" % dimensions)
	await _capture(viewport, "identity_entry_%dx%d.png" % [dimensions.x,dimensions.y])
	entry._keyboard_height = roundi(entry.get_window().size.y * 0.42)
	entry._apply_layout()
	await _frames()
	_check(entry.name_input.get_global_rect().end.y < dimensions.y * 0.58 and entry.continue_button.get_global_rect().end.y < dimensions.y * 0.58, "%s keyboard geometry leaves input and Continue visible" % dimensions)
	entry._keyboard_height = 0
	entry._apply_layout()
	await _frames()
	_check(not entry.get_node("%WelcomeHeading").visible and entry.get_node("%Subtitle").visible and _inside(entry.form.get_global_rect(), dimensions), "closing the keyboard restores the journey prompt without bringing Welcome back")
	entry.queue_free()
	await _frames()
	var certificate = CertificateScene.instantiate()
	certificate.progress_manager = progress
	viewport.add_child(certificate)
	await _frames()
	_check(_inside(certificate.certificate_canvas.get_global_rect(), dimensions), "%s certificate artwork stays in bounds" % dimensions)
	_check(_inside(certificate.back_button.get_global_rect(), dimensions), "%s certificate Back is in bounds" % dimensions)
	for node: Node in certificate.certificate_canvas.get_children():
		if node is Label:
			var label := node as Label
			var measured := label.get_theme_font("font").get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size"))
			_check(measured.x <= label.size.x + 1.0 and measured.y <= label.size.y + 1.0, "%s certificate %s text fits" % [dimensions,label.name])
	_check(certificate.player_name_label.get_theme_font_size("font_size") < 64, "long player name automatically fits the certificate name line")
	await _capture(viewport, "identity_certificate_%dx%d.png" % [dimensions.x,dimensions.y])
	viewport.size = Vector2i(1024,1055)
	await _frames()
	_check(_inside(certificate.back_button.get_global_rect(), viewport.size), "certificate follows live viewport resizing")
	viewport.queue_free()
	await _frames()
	progress.free()

func _test_actual_navigation() -> void:
	var menu = load("res://main_menu_tscn.tscn").instantiate()
	get_root().add_child(menu)
	current_scene = menu
	await _frames()
	menu.start_button.pressed.emit()
	await _frames()
	_check(current_scene != null and current_scene.scene_file_path == "res://player_name_entry.tscn", "actual Main Menu Start Game opens Player Name Entry")
	var progress = _new_progress()
	if current_scene != null and current_scene.scene_file_path == "res://player_name_entry.tscn":
		current_scene.progress_manager = progress
		_input(current_scene, "History Explorer")
		current_scene.continue_button.pressed.emit()
		await _frames()
		_check(current_scene != null and current_scene.scene_file_path == "res://level_selection.tscn", "actual Continue opens existing Level Selection")
		if current_scene != null and current_scene.scene_file_path == "res://level_selection.tscn":
			current_scene.back_button.pressed.emit()
			await _frames()
			_check(current_scene != null and current_scene.scene_file_path == "res://main_menu_tscn.tscn", "actual Level Selection Back still opens Main Menu")
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	await _frames()
	progress.free()

func _test_editor() -> void:
	var viewport := _viewport(Vector2i(1024,1536))
	for scene: PackedScene in [EntryScene, CertificateScene]:
		var screen := scene.instantiate()
		viewport.add_child(screen)
		await _frames()
		_check(screen.size == Vector2(1024,1536), "editable scene fills the Editor preview")
		if screen.has_node("%WelcomeHeading"):
			_check(not screen.get_node("%WelcomeHeading").visible and screen.get_node("%Subtitle").visible and screen.get_node("%Subtitle").text == "Enter your name to begin your journey." and screen.name_input.placeholder_text == "Enter your name...", "Editor preview has only the journey prompt and an editable input")
		else:
			_check(screen.player_name_label.text == "Player Name", "Editor certificate keeps a labeled preview name")
		await _capture(viewport, "identity_editor_%s.png" % screen.name)
		screen.queue_free()
		await _frames()
	viewport.queue_free()
	await _frames()

func _viewport(dimensions: Vector2i) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	return viewport

func _input(screen: Node, value: String) -> void:
	screen.name_input.text = value
	screen.name_input.text_changed.emit(screen.name_input.text)

func _click(viewport: SubViewport, point: Vector2) -> void:
	for down: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		viewport.push_input(event, true)

func _type_text(viewport: SubViewport, value: String) -> void:
	for index in value.length():
		var key := InputEventKey.new()
		key.pressed = true
		key.unicode = value.unicode_at(index)
		viewport.push_input(key, true)
		var release := key.duplicate() as InputEventKey
		release.pressed = false
		viewport.push_input(release, true)

func _tap(viewport: SubViewport, point: Vector2) -> void:
	for down: bool in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.pressed = down
		viewport.push_input(event, true)

func _frames() -> void:
	for index in 4:
		await process_frame

func _capture(viewport: SubViewport, filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	RenderingServer.force_draw(false)
	var capture := viewport.get_texture().get_image()
	_check(capture != null and not capture.is_empty() and capture.save_png("user://" + filename) == OK, "actual Godot render saved: " + filename)

func _inside(rect: Rect2, dimensions: Vector2i) -> bool:
	if not Rect2(Vector2.ZERO, Vector2(dimensions)).grow(1.0).encloses(rect): print("OUT OF BOUNDS: ", rect, " in ", dimensions)
	return Rect2(Vector2.ZERO, Vector2(dimensions)).grow(1.0).encloses(rect)

func _write_json(data: Dictionary) -> void:
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func _cleanup() -> void:
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))

func _check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + message)

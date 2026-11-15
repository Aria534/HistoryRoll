extends SceneTree

const SettingsScene = preload("res://settings.tscn")
const TEST_SETTINGS_PATH := "user://historyroll_settings_design_test.cfg"

var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	await _capture(Vector2i(1024, 1536), "settings_1024x1536.png")
	await _capture(Vector2i(720, 1280), "settings_720x1280.png")
	_cleanup()
	print("Settings design tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _capture(viewport_size: Vector2i, filename: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)

	var settings = SettingsScene.instantiate()
	settings.settings_path = TEST_SETTINGS_PATH
	settings.scene_change_handler = func(_path: String) -> void: pass
	viewport.add_child(settings)
	await process_frame
	await process_frame

	var frame := settings.get_node("%SettingsFrame") as TextureRect
	_check(frame.texture != null and frame.texture.resource_path.ends_with("settings_frame_filipino_no_foliage.png"), "%s uses the foliage-free Filipino parchment Settings frame" % viewport_size)
	_check(settings.music_state_label.text == "MUSIC: ON", "%s displays Music ON" % viewport_size)
	_check(settings.sfx_state_label.text == "SOUND EFFECTS: ON", "%s displays Sound Effects ON" % viewport_size)
	_check(not settings.help_button.text.contains("?"), "%s How to Play has no question-mark prefix" % viewport_size)
	_check(settings.back_button.text.is_empty() and settings.back_button.icon != null, "%s Back control is icon-only" % viewport_size)
	_check(settings.music_switch_knob.anchor_left > 0.5 and settings.sfx_switch_knob.anchor_left > 0.5, "%s ON switches place their knobs on the right" % viewport_size)
	_check(_inside(settings.music_toggle.get_global_rect(), viewport_size), "%s Music control stays on-screen" % viewport_size)
	_check(_inside(settings.sfx_toggle.get_global_rect(), viewport_size), "%s Sound Effects control stays on-screen" % viewport_size)
	_check(_inside(settings.help_button.get_global_rect(), viewport_size), "%s How to Play control stays on-screen" % viewport_size)
	_check(_inside(settings.back_button.get_global_rect(), viewport_size), "%s Back control stays on-screen" % viewport_size)
	_check(not settings.music_toggle.get_global_rect().intersects(settings.sfx_toggle.get_global_rect()), "%s toggle rows do not overlap" % viewport_size)

	var image: Image = viewport.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path("user://%s" % filename)) if image != null and not image.is_empty() else ERR_CANT_CREATE
	_check(error == OK, "%s capture is saved" % filename)

	settings._on_music_toggled(false)
	_check(settings.music_state_label.text == "MUSIC: OFF" and settings.music_switch_knob.anchor_left < 0.1, "%s Music OFF updates its label and switch" % viewport_size)
	settings.help_button.pressed.emit()
	_check(settings.how_to_play_overlay.visible, "%s How to Play overlay opens" % viewport_size)
	_check(settings.help_rows.get_child_count() == 12, "%s How to Play displays twelve instruction rows" % viewport_size)
	var help_frame := settings.get_node("%HelpFrame") as TextureRect
	_check(help_frame.texture != null and help_frame.texture.resource_path.ends_with("how_to_play_frame_filipino.png"), "%s uses the Filipino How to Play frame" % viewport_size)
	await process_frame
	await process_frame
	var help_image: Image = viewport.get_texture().get_image()
	var help_filename := filename.replace("settings_", "how_to_play_")
	var help_error := help_image.save_png(ProjectSettings.globalize_path("user://%s" % help_filename)) if help_image != null and not help_image.is_empty() else ERR_CANT_CREATE
	_check(help_error == OK, "%s capture is saved" % help_filename)
	settings.close_help_button.pressed.emit()
	_check(not settings.how_to_play_overlay.visible, "%s How to Play overlay closes" % viewport_size)

	settings.queue_free()
	viewport.queue_free()
	await process_frame
	_cleanup()


func _inside(rect: Rect2, viewport_size: Vector2i) -> bool:
	return rect.position.x >= -0.1 and rect.position.y >= -0.1 and rect.end.x <= viewport_size.x + 0.1 and rect.end.y <= viewport_size.y + 0.1


func _check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS: %s" % message)
	else:
		failed += 1
		push_error("FAIL: %s" % message)


func _cleanup() -> void:
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS_PATH))

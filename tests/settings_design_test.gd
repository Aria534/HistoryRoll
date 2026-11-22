extends SceneTree

const SettingsScene = preload("res://settings.tscn")
const TEST_SETTINGS_PATH := "user://historyroll_settings_design_test.cfg"
const VIEWPORTS := [
	Vector2i(1024, 1536), Vector2i(720, 1280), Vector2i(1086, 1448),
	Vector2i(1080, 1920), Vector2i(1080, 2340), Vector2i(1080, 2400),
]

var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	var audio: Node = get_root().get_node("AudioManager")
	var saved_music: bool = audio.is_music_enabled()
	var saved_sfx: bool = audio.is_sfx_enabled()
	for viewport_size: Vector2i in VIEWPORTS:
		await _capture(viewport_size)
	audio.set_music_enabled(saved_music, false)
	audio.set_sfx_enabled(saved_sfx, false)
	_cleanup()
	print("Settings design tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _capture(viewport_size: Vector2i) -> void:
	_cleanup()
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var requested: Array[String] = []
	var settings = SettingsScene.instantiate()
	settings.settings_path = TEST_SETTINGS_PATH
	settings.scene_change_handler = func(path: String) -> void: requested.append(path)
	viewport.add_child(settings)
	await _settle()

	var label := "%dx%d" % [viewport_size.x, viewport_size.y]
	var frame := settings.get_node("%SettingsFrame") as TextureRect
	var frame_rect := frame.get_global_rect()
	var background := settings.get_node("Background") as TextureRect
	_check(frame.texture.resource_path == "res://assets/settings_ui/waterfall/frame.png", "%s uses the waterfall and wood Settings frame" % label)
	_check(background.texture.resource_path == "res://assets/settings_ui/waterfall/background_terraces.png", "%s uses the sunrise rice-terraces scenery" % label)
	_check(frame.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "%s panel artwork keeps its proportions" % label)
	_check(_inside(frame_rect, viewport_size), "%s whole frame stays inside the viewport" % label)
	_check(not settings.get_node("Shade").visible, "%s scenery has no dark overlay" % label)
	_check(settings.music_state_label.text == "MUSIC: ON", "%s displays Music ON" % label)
	_check(settings.sfx_state_label.text == "SFX SOUND EFFECTS: ON", "%s displays Sound Effects ON" % label)
	_check(settings.help_button.get_node("Content/Row/Caption").text == "HOW TO PLAY" and settings.help_button.get_node("Content/Row/Icon").texture != null, "%s How to Play has a book icon" % label)
	_check(settings.back_button.get_node("Content/Row/Caption").text == "BACK" and settings.back_button.get_node("Content/Row/Icon").texture.resource_path.ends_with("/back.svg"), "%s red Back control has a cream arrow" % label)
	_check(settings.music_switch_knob.anchor_left > 0.5 and settings.sfx_switch_knob.anchor_left > 0.5, "%s ON knobs appear on the right" % label)
	for button: Button in [settings.help_button, settings.back_button]:
		var row := button.get_node("Content/Row") as HBoxContainer
		var icon := row.get_node("Icon") as TextureRect
		var caption := row.get_node("Caption") as Label
		_check(button.get_global_rect().encloses(row.get_global_rect()), "%s %s icon/text group fits the button" % [label, button.name])
		_check(absf(row.get_global_rect().get_center().x - button.get_global_rect().get_center().x) < 1.0, "%s %s icon/text group is centered" % [label, button.name])
		_check(icon.get_global_rect().end.x < caption.get_global_rect().position.x, "%s %s icon and caption do not overlap" % [label, button.name])
	var previous_rect := Rect2()
	for button: Button in [settings.music_toggle, settings.sfx_toggle, settings.help_button, settings.back_button]:
		var rect := button.get_global_rect()
		_check(_inside(rect, viewport_size), "%s %s stays on-screen" % [label, button.name])
		_check(frame_rect.encloses(rect), "%s %s stays inside the panel" % [label, button.name])
		if previous_rect.has_area():
			_check(previous_rect.end.y + 8.0 < rect.position.y, "%s %s has clear spacing" % [label, button.name])
		previous_rect = rect
	_check(settings.help_button.get_global_rect().end.y < frame_rect.position.y + frame_rect.size.y * 0.63, "%s controls leave the waterfall visible" % label)
	for state_label: Label in [settings.music_state_label, settings.sfx_state_label]:
		var text_size := state_label.get_theme_font("font").get_string_size(state_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, state_label.get_theme_font_size("font_size"))
		_check(text_size.x <= state_label.size.x and text_size.y <= state_label.size.y, "%s %s lettering fits" % [label, state_label.name])
	for track: Panel in [settings.music_switch_track, settings.sfx_switch_track]:
		var row := track.get_parent()
		var icon := row.get_node("Icon") as TextureRect
		var state_label := row.get_child(1) as Label
		_check(icon.get_global_rect().end.x < state_label.get_global_rect().position.x and state_label.get_global_rect().end.x < track.get_global_rect().position.x, "%s %s icon, text, and switch do not overlap" % [label, track.name])
	_check(settings.get_node("Title").get_global_rect().end.y < settings.music_toggle.get_global_rect().position.y, "%s title and Music row do not overlap" % label)
	await _save_capture(viewport, "settings_%s.png" % label)

	# Push actual pointer events through the production scene: child artwork must
	# not swallow clicks, including clicks directly on the switch graphics.
	_click(viewport, settings.music_switch_knob.get_global_rect().get_center())
	await _settle()
	var audio: Node = get_root().get_node("AudioManager")
	_check(not settings.music_enabled and not settings.music_toggle.button_pressed, "%s clicking the Music switch disables music" % label)
	_check(not audio.is_music_enabled() and AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "%s global Music is muted" % label)
	_check(settings.music_state_label.text == "MUSIC: OFF" and settings.music_switch_knob.anchor_left < 0.1, "%s Music OFF label and knob update" % label)
	_click(viewport, settings.sfx_switch_knob.get_global_rect().get_center())
	await _settle()
	_check(not settings.sfx_enabled and not settings.sfx_toggle.button_pressed, "%s clicking the SFX switch disables sound effects" % label)
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "%s Sound Effects bus is muted separately" % label)
	_check(settings.sfx_state_label.text == "SFX SOUND EFFECTS: OFF" and settings.sfx_switch_knob.anchor_left < 0.1, "%s SFX OFF label and knob update" % label)
	if viewport_size == Vector2i(720, 1280):
		await _save_capture(viewport, "settings_off_%s.png" % label)
	var config := ConfigFile.new()
	var error := config.load(TEST_SETTINGS_PATH)
	_check(error == OK and not bool(config.get_value("audio", "music_enabled", true)) and not bool(config.get_value("audio", "sfx_enabled", true)), "%s both preferences save in the existing config format" % label)
	if viewport_size == Vector2i(720, 1280):
		await _save_capture(viewport, "settings_off_%s.png" % label)

	_click(viewport, settings.help_button.get_global_rect().get_center())
	await _settle()
	_check(settings.how_to_play_overlay.visible, "%s pointer opens How to Play" % label)
	_check(settings.help_rows.get_child_count() == 11, "%s eleven reference-layout instruction rows explain the existing rules" % label)
	var help_frame := settings.get_node("%HelpFrame") as TextureRect
	_check(help_frame.texture.resource_path.ends_with("how_to_play_ui/library/frame.png"), "%s new library help artwork is applied" % label)
	if viewport_size == Vector2i(720, 1280):
		await _save_capture(viewport, "how_to_play_%s.png" % label)
	_click(viewport, settings.close_help_button.get_global_rect().get_center())
	await _settle()
	_check(not settings.how_to_play_overlay.visible, "%s pointer closes How to Play" % label)
	_click(viewport, settings.back_button.get_global_rect().get_center())
	await _settle()
	_check(requested == ["res://main_menu_tscn.tscn"], "%s pointer Back requests Main Menu once" % label)

	settings.queue_free()
	await process_frame
	var reloaded = SettingsScene.instantiate()
	reloaded.settings_path = TEST_SETTINGS_PATH
	reloaded.scene_change_handler = func(_path: String) -> void: pass
	viewport.add_child(reloaded)
	await _settle()
	_check(not reloaded.music_enabled and not reloaded.sfx_enabled, "%s both OFF preferences survive scene recreation" % label)
	_check(not audio.is_music_enabled() and AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "%s reload preserves audio mute" % label)
	_click(viewport, reloaded.music_state_label.get_global_rect().get_center())
	_click(viewport, reloaded.sfx_state_label.get_global_rect().get_center())
	await _settle()
	_check(reloaded.music_enabled and reloaded.sfx_enabled, "%s row labels also accept clicks to turn audio back ON" % label)
	_check(not AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")) and not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")), "%s both audio buses restore correctly" % label)
	viewport.queue_free()
	await process_frame
	_cleanup()


func _settle() -> void:
	for frame_index in 4:
		await process_frame


func _save_capture(viewport: SubViewport, filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path("user://%s" % filename)) if image != null and not image.is_empty() else ERR_CANT_CREATE
	_check(error == OK, "%s actual Godot render saved" % filename)


func _click(viewport: SubViewport, point: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	viewport.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	viewport.push_input(release, true)


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

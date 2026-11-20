extends SceneTree

const MainMenuScene = preload("res://main_menu_tscn.tscn")
const SettingsScene = preload("res://settings.tscn")
const TEST_SETTINGS_PATH := "user://historyroll_main_menu_settings_test.cfg"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_settings()
	var audio_manager: Node = get_root().get_node_or_null("AudioManager")
	var saved_music: bool = audio_manager.is_music_enabled()
	var saved_sfx: bool = audio_manager.is_sfx_enabled()
	audio_manager.set_music_enabled(true, false)
	await _test_main_menu_viewport(Vector2i(720, 1280))
	await _test_main_menu_viewport(Vector2i(1080, 1920))
	await _test_main_menu_viewport(Vector2i(1080, 2340))
	await _test_main_menu_viewport(Vector2i(1080, 2400))
	await _test_main_menu_viewport(Vector2i(1024, 1536))
	await _test_main_menu_viewport(Vector2i(1086, 1448))
	await _test_touch_entry()
	await _test_settings()
	audio_manager.set_music_enabled(saved_music, false)
	audio_manager.set_sfx_enabled(saved_sfx, false)
	_cleanup_settings()
	print("Main Menu redesign tests: %d passed, %d failed." % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_main_menu_viewport(viewport_size: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var menu = MainMenuScene.instantiate()
	var requested: Array[String] = []
	var exit_state := {"requested": false}
	menu.scene_change_handler = func(path: String) -> void: requested.append(path)
	menu.quit_handler = func() -> void: exit_state["requested"] = true
	viewport.add_child(menu)
	await process_frame
	await process_frame
	var audio_manager: Node = get_root().get_node_or_null("AudioManager")
	var label := "%dx%d" % [viewport_size.x, viewport_size.y]
	_check(audio_manager.get_current_track_path() == "res://assets/audio/music/main_menu.ogg", "%s Main Menu requests its music" % label)
	_check(audio_manager.is_music_playing(), "%s enabled music is playing" % label)
	var music_stream: AudioStream = audio_manager._player.stream
	menu._request_music("res://assets/audio/music/main_menu.ogg")
	_check(audio_manager._player.stream == music_stream, "%s the same music stream is retained" % label)
	_check(menu.size.round() == Vector2(viewport_size), "%s menu fills the portrait viewport" % label)
	_check(_rect_inside(menu.menu_logo.get_global_rect(), viewport_size), "%s independent logo stays on-screen" % label)
	_check(is_equal_approx(menu.menu_logo.size.aspect(), menu.menu_logo.texture.get_size().aspect()), "%s logo keeps its source aspect ratio" % label)
	_check(not menu.get_node("AnimatedPlants").visible and not menu.get_node("BoardDecoration").visible, "%s retired decorations do not cover the approved scenery" % label)
	var background: AnimatedSprite2D = menu.get_node("LiveBackground")
	var texture := background.sprite_frames.get_frame_texture("default", 0)
	_check(texture.resource_path.ends_with("forest_daylight/background.png"), "%s uses the separated forest scenery" % label)
	_check(is_equal_approx(background.scale.x, background.scale.y), "%s scenery is not stretched" % label)
	var background_size := texture.get_size() * background.scale
	_check(background_size.x >= viewport_size.x and background_size.y >= viewport_size.y, "%s scenery covers the viewport without black bars" % label)
	_check(background.position.is_equal_approx(Vector2(viewport_size) * 0.5), "%s scenery remains centered" % label)
	_check(not menu.get_node("SkyFill").visible, "%s retired blue sky strip is hidden" % label)
	_check(menu.menu_explorers.visible and _rect_inside(menu.menu_explorers.get_global_rect(), viewport_size), "%s both full-body explorers stay inside the screen" % label)
	_check(menu.menu_explorers.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s explorer art cannot consume menu input" % label)
	_check(menu.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "%s menu uses nearest filtering" % label)
	var buttons: Array[TextureButton] = [menu.start_button, menu.hero_cards_button, menu.settings_button, menu.quit_button]
	var previous_rect := Rect2()
	var gap := -1.0
	for index: int in buttons.size():
		var button := buttons[index]
		var rect := button.get_global_rect()
		var caption := button.get_node("Caption") as Label
		var text_size := caption.get_theme_font("font").get_string_size(caption.text, HORIZONTAL_ALIGNMENT_LEFT, -1, caption.get_theme_font_size("font_size"))
		_check(_rect_inside(rect, viewport_size) and rect.size.y >= 64.0, "%s button %d stays visible and touch-friendly" % [label, index + 1])
		_check(rect.size.is_equal_approx(buttons[0].size), "%s button %d has the same dimensions" % [label, index + 1])
		_check(caption.text == menu.BUTTON_LABELS[index], "%s button %d has the approved wording" % [label, index + 1])
		_check(text_size.x <= caption.size.x and text_size.y < rect.size.y, "%s button %d lettering fits its wooden sign" % [label, index + 1])
		var icon := button.get_node("ActionIcon") as TextureRect
		_check(icon.texture != null and icon.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s button %d icon preserves pointer input" % [label, index + 1])
		_check(icon.get_global_rect().end.x < caption.get_global_rect().position.x, "%s button %d icon and lettering do not overlap" % [label, index + 1])
		if index > 0:
			var current_gap := rect.position.y - previous_rect.end.y
			if gap < 0.0:
				gap = current_gap
			_check(not rect.intersects(previous_rect) and current_gap >= 12.0, "%s button rows do not overlap" % label)
			_check(is_equal_approx(gap, current_gap), "%s button rows have equal spacing" % label)
		previous_rect = rect
	_check(menu.menu_logo.get_global_rect().end.y < buttons[0].position.y, "%s logo and controls are separated" % label)
	_check(buttons[3].get_global_rect().end.y < menu.menu_explorers.get_global_rect().position.y, "%s Quit remains above the explorer artwork" % label)
	menu._on_button_mouse_entered(buttons[2])
	await create_timer(menu.anim_time + 0.03).timeout
	_check(menu._selected_button == buttons[2] and buttons[2].scale.x > 1.0 and not menu.selection_arrow.visible, "%s the hovered sign enlarges without an extra external arrow" % label)
	var rest: Vector2 = menu._button_rest_positions[buttons[2]]
	menu._on_button_down(buttons[2])
	await create_timer(menu.anim_time + 0.03).timeout
	_check(buttons[2].position.y > rest.y and buttons[2].self_modulate.r < 1.0, "%s pressing shifts and dims the button" % label)
	menu._on_button_up(buttons[2])
	menu._on_button_mouse_exited(buttons[2])
	await create_timer(menu.anim_time + 0.03).timeout
	_check(buttons[2].position.is_equal_approx(rest) and buttons[2].self_modulate == Color.WHITE, "%s release restores the button" % label)
	# Exercise actual GUI hit-testing, including the nonblocking text and scenery.
	var center := buttons[0].get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = center
	viewport.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.position = center
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	viewport.push_input(press, true)
	var release := InputEventMouseButton.new()
	release.position = center
	release.button_index = MOUSE_BUTTON_LEFT
	viewport.push_input(release, true)
	_check(requested == ["res://level_selection.tscn"], "%s mouse/touch-emulation hit-test opens Level Selection" % label)
	var routes := ["res://level_selection.tscn", "res://hero_cards.tscn", "res://settings.tscn"]
	for index: int in range(3):
		menu._scene_transition_pending = false
		menu._set_buttons_disabled(false)
		requested.clear()
		buttons[index].pressed.emit()
		buttons[index].pressed.emit()
		_check(requested == [routes[index]], "%s %s navigates once" % [label, menu.BUTTON_LABELS[index]])
		menu._scene_transition_pending = false
		menu._set_buttons_disabled(false)
		requested.clear()
		_click(viewport, buttons[index].get_node("ActionIcon").get_global_rect().get_center())
		_check(requested == [routes[index]], "%s clicking the %s icon opens the correct screen" % [label, menu.BUTTON_LABELS[index]])
	menu._scene_transition_pending = false
	menu._set_buttons_disabled(false)
	_click(viewport, menu.quit_button.get_node("ActionIcon").get_global_rect().get_center())
	_check(bool(exit_state["requested"]), "%s Quit icon requests quit" % label)
	menu._scene_transition_pending = false
	menu._set_buttons_disabled(false)
	menu._on_button_mouse_exited(buttons[0])
	menu._select_button(buttons[0])
	await create_timer(menu.anim_time + 0.03).timeout
	await RenderingServer.frame_post_draw
	var capture := viewport.get_texture().get_image()
	var capture_path := ProjectSettings.globalize_path("user://main_menu_%dx%d.png" % [viewport_size.x, viewport_size.y])
	_check(capture != null and not capture.is_empty() and capture.save_png(capture_path) == OK, "%s actual rendered capture is saved" % label)
	# Verify live resize, rather than only correctly sized initial instances.
	viewport.size = Vector2i(720, 1280) if viewport_size.x != 720 else Vector2i(1080, 2400)
	await process_frame
	await process_frame
	_check(_rect_inside(menu.quit_button.get_global_rect(), viewport.size), "%s live resize keeps Quit in bounds" % label)
	menu.queue_free()
	viewport.queue_free()
	await process_frame


func _test_touch_entry() -> void:
	var menu = MainMenuScene.instantiate()
	var requested: Array[String] = []
	menu.scene_change_handler = func(path: String) -> void: requested.append(path)
	get_root().add_child(menu)
	await process_frame
	var was_emulating := Input.emulate_mouse_from_touch
	Input.emulate_mouse_from_touch = true
	var point: Vector2 = get_root().get_final_transform() * menu.start_button.get_global_rect().get_center()
	var touch := InputEventScreenTouch.new()
	touch.position = point
	touch.index = 0
	touch.pressed = true
	Input.parse_input_event(touch)
	await process_frame
	var release := InputEventScreenTouch.new()
	release.position = point
	release.index = 0
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	_check(requested == ["res://level_selection.tscn"], "a simulated touch tap opens Level Selection through input emulation")
	Input.emulate_mouse_from_touch = was_emulating
	menu.queue_free()
	await process_frame


func _test_settings() -> void:
	var requested_scenes: Array[String] = []
	var settings = SettingsScene.instantiate()
	settings.settings_path = TEST_SETTINGS_PATH
	settings.scene_change_handler = func(path: String): requested_scenes.append(path)
	get_root().add_child(settings)
	await process_frame
	_check(settings.name == "Settings", "Settings scene no longer uses Achievements root")
	_check(settings.music_enabled and settings.sfx_enabled, "audio preferences default to enabled")
	_check(not settings.how_to_play_overlay.visible, "How to Play starts closed")
	settings.help_button.pressed.emit()
	_check(settings.how_to_play_overlay.visible, "question-mark option opens How to Play")
	_check(settings.get_node("%Instructions").text.contains("exact dice roll"), "How to Play contains exact-roll rule")
	settings.close_help_button.pressed.emit()
	_check(not settings.how_to_play_overlay.visible, "How to Play closes")
	settings._on_music_toggled(false)
	settings._on_sfx_toggled(false)
	_check(FileAccess.file_exists(TEST_SETTINGS_PATH), "settings preferences save locally")
	settings.back_button.pressed.emit()
	_check(requested_scenes == ["res://main_menu_tscn.tscn"], "Settings Back returns to Main Menu")
	settings.queue_free()
	await process_frame
	var reloaded = SettingsScene.instantiate()
	reloaded.settings_path = TEST_SETTINGS_PATH
	get_root().add_child(reloaded)
	await process_frame
	_check(not reloaded.music_enabled and not reloaded.sfx_enabled, "audio preferences survive scene reload")
	reloaded.queue_free()
	await process_frame


func _rect_inside(rect: Rect2, viewport_size: Vector2i) -> bool:
	return rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= viewport_size.x and rect.end.y <= viewport_size.y


func _click(viewport: SubViewport, point: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	viewport.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	viewport.push_input(release, true)


func _cleanup_settings() -> void:
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS_PATH))


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", description)
	else:
		_failed += 1
		push_error("FAIL: %s" % description)

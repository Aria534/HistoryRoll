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
	await _test_main_menu_viewport(Vector2i(1024, 1536), "main_menu_1024x1536.png")
	await _test_main_menu_viewport(Vector2i(720, 1280), "main_menu_720x1280.png")
	await _test_settings()
	_cleanup_settings()
	print("Main Menu redesign tests: %d passed, %d failed." % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_main_menu_viewport(viewport_size: Vector2i, capture_name: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var menu = MainMenuScene.instantiate()
	menu.scene_change_handler = func(_path: String): pass
	menu.quit_handler = func(): pass
	viewport.add_child(menu)
	await process_frame
	await process_frame
	var label := "%dx%d" % [viewport_size.x, viewport_size.y]
	_check(menu.size.round() == Vector2(viewport_size), "%s Main Menu fills viewport" % label)
	_check(not menu.has_node("HistoryRollLogo"), "%s has no duplicate logo node" % label)
	var background := menu.get_node("LiveBackground") as AnimatedSprite2D
	var background_texture := background.sprite_frames.get_frame_texture("default", 0)
	_check(background_texture.resource_path.ends_with("main_menu_complete_reference_v7_natural_board.png"), "%s uses the natural integrated 25-tile board artwork" % label)
	_check(menu.get_node("AnimatedPlants").self_modulate.a <= 0.15, "%s keeps foliage motion subtle over the complete artwork" % label)
	var buttons: Array[TextureButton] = [menu.start_button, menu.hero_cards_button, menu.settings_button, menu.quit_button]
	var previous_rect := Rect2()
	for index: int in buttons.size():
		var button := buttons[index]
		var rect := button.get_global_rect()
		_check(_rect_inside(rect, viewport_size), "%s button %d stays on-screen" % [label, index + 1])
		_check(rect.size.y >= 90.0, "%s button %d remains touch-friendly" % [label, index + 1])
		if index > 0:
			_check(not previous_rect.intersects(rect), "%s buttons %d and %d do not overlap" % [label, index, index + 1])
			_check(rect.position.y - previous_rect.end.y >= viewport_size.y * 0.015, "%s buttons %d and %d have a clear vertical gap" % [label, index, index + 1])
		previous_rect = rect
	menu._on_button_mouse_entered(buttons[0])
	await create_timer(menu.anim_time + 0.05).timeout
	_check(is_equal_approx(buttons[0].scale.x, 1.03), "%s mouse hover matches Level Selection's 1.03 scale" % label)
	_check(is_equal_approx(buttons[0].self_modulate.a, 1.0), "%s mouse hover fully displays the animated button artwork" % label)
	if viewport_size == Vector2i(720, 1280):
		var hover_image := viewport.get_texture().get_image()
		var hover_capture_path := ProjectSettings.globalize_path("user://main_menu_hover_720x1280.png")
		_check(hover_image != null and not hover_image.is_empty() and hover_image.save_png(hover_capture_path) == OK, "720x1280 hover-state capture is saved")
	menu._on_button_mouse_exited(buttons[0])
	await create_timer(menu.anim_time + 0.05).timeout
	menu._on_button_down(buttons[0])
	await create_timer(menu.anim_time + 0.05).timeout
	_check(is_equal_approx(buttons[0].scale.x, menu.press_scale), "%s touch press visibly shrinks the active button" % label)
	_check(is_equal_approx(buttons[0].self_modulate.a, menu.press_overlay_alpha), "%s touch press displays the button feedback overlay" % label)
	menu._on_button_up(buttons[0])
	await create_timer(menu.anim_time + 0.05).timeout
	_check(is_equal_approx(buttons[0].scale.x, 1.0), "%s released button returns to normal scale" % label)
	_check(is_equal_approx(buttons[0].self_modulate.a, 0.0), "%s released touch feedback clears" % label)
	var board: Control = menu.get_node("BoardDecoration")
	_check(not board.visible, "%s avoids drawing a duplicate procedural board" % label)
	var board_rect := board.get_global_rect()
	_check(board_rect.position.x < 0.0 and board_rect.end.x > viewport_size.x, "%s board extends beyond both side edges like the reference" % label)
	_check(board_rect.position.y > 0.0 and board_rect.position.y < viewport_size.y, "%s board begins visibly behind Quit" % label)
	_check(board_rect.end.y > viewport_size.y, "%s board continues below the viewport like the reference" % label)
	_check(board_rect.position.y <= previous_rect.end.y - viewport_size.y * 0.04, "%s board visibly overlaps behind the Quit artwork" % label)
	_check(board.get_visual_numbers() == [[21, 22, 23, 24, 25], [20, 19, 18, 17, 16], [11, 12, 13, 14, 15], [10, 9, 8, 7, 6], [1, 2, 3, 4, 5]], "%s board numbering is exact and serpentine" % label)
	_check(board.get_start_label() == "START", "%s board marks the starting tile" % label)
	_check(board.get_path_sequence() == range(1, 26), "%s board path is sequential from 1 through 25" % label)
	_check(board.has_snakes_and_ladders(), "%s board contains snakes and ladders" % label)
	_check(board_rect.position.y < previous_rect.end.y, "%s board begins behind Quit like the reference" % label)
	_check(board.z_index < menu.quit_button.z_index, "%s board stays visually behind Quit" % label)
	var image := viewport.get_texture().get_image()
	var capture_path := ProjectSettings.globalize_path("user://%s" % capture_name)
	_check(image != null and not image.is_empty() and image.save_png(capture_path) == OK, "%s capture is saved" % label)
	menu.queue_free()
	viewport.queue_free()
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

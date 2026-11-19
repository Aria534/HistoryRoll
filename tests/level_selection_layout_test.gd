extends SceneTree

const LevelSelectionScene = preload("res://level_selection.tscn")
const ProgressManagerScript = preload("res://progress_manager.gd")
const SAVE_PATH := "user://historyroll_level_selection_layout_test.json"

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_save()
	await _test_viewport(Vector2i(1024, 1536), "level_selection_1024x1536.png")
	await _test_viewport(Vector2i(720, 1280), "level_selection_720x1280.png")
	await _test_viewport(Vector2i(1086, 1448), "level_selection_reference_1086x1448.png")
	await _test_viewport(Vector2i(1080, 1920), "level_selection_1080x1920.png")
	await _test_viewport(Vector2i(1080, 2340), "level_selection_1080x2340.png")
	await _test_viewport(Vector2i(1080, 2400), "level_selection_1080x2400.png")
	_cleanup_save()
	await _test_returning_player_capture()
	_cleanup_save()
	await _test_main_menu_entry()
	print("Level Selection layout tests: %d passed, %d failed." % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_viewport(viewport_size: Vector2i, capture_name: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)

	var progress = ProgressManagerScript.new()
	progress.save_path = SAVE_PATH
	var screen = LevelSelectionScene.instantiate()
	screen.progress_manager = progress
	var requested_scenes: Array[String] = []
	screen.scene_change_handler = func(path: String) -> void: requested_scenes.append(path)
	viewport.add_child(screen)
	await process_frame
	await process_frame

	var size_label := "%dx%d" % [viewport_size.x, viewport_size.y]
	_check(screen.size.round() == Vector2(viewport_size), "%s root fills the viewport" % size_label)
	_check(screen.level_buttons.size() == 6, "%s shows all six level controls" % size_label)
	_check(screen.level_buttons_area.get_child_count() == 6, "%s does not create duplicate runtime buttons" % size_label)
	_check(not screen.level_buttons_area is Container, "%s keeps level cards independently positionable in the 2D Editor" % size_label)
	_check(screen.selection_label == null, "%s preserves the intentionally removed selected-level label" % size_label)
	_check(_rect_is_inside(screen.title_banner.get_global_rect(), viewport_size), "%s title banner stays on-screen" % size_label)
	_check(screen.back_button.visible and screen.help_button.visible, "%s top controls remain visible beside the transparent banner" % size_label)
	_check(_rect_is_inside(screen.back_button.get_global_rect(), viewport_size), "%s Back Arrow stays on-screen" % size_label)
	_check(_rect_is_inside(screen.help_button.get_global_rect(), viewport_size), "%s Help icon stays on-screen" % size_label)
	_check(screen.help_button.texture_normal.resource_path.ends_with("parchment_forest/icon_base.svg"), "%s Help uses the matching wooden icon" % size_label)
	_check(_rect_is_inside(screen.play_button.get_global_rect(), viewport_size), "%s PLAY stays on-screen" % size_label)
	var instructions: Label = screen.get_node("UIRoot/HelpOverlay/Panel/Margin/Content/Instructions")
	_check(instructions.text.contains("Earn 10 points"), "%s Help explains correct-answer scoring" % size_label)
	_check(instructions.text.contains("Lose 2 points"), "%s Help explains wrong-answer scoring" % size_label)
	_check(instructions.text.contains("exact dice roll"), "%s Help explains exact-roll completion" % size_label)

	var previous_rect := Rect2()
	var visible_lock_count := 0
	for level_id: int in range(1, 7):
		var button: LevelSelectionRow = screen.level_buttons[level_id]
		var button_rect := button.get_global_rect()
		_check(_rect_is_inside(button_rect, viewport_size), "%s Level %d stays on-screen" % [size_label, level_id])
		_check(button.name_label.visible and button.portrait_rect.visible, "%s Level %d displays its separate portrait and complete name" % [size_label, level_id])
		_check(button.frame_rect.texture == button.row_texture, "%s Level %d keeps its shared parchment frame when unlocked" % [size_label, level_id])
		var font := button.name_label.get_theme_font("font")
		var lettering := font.get_string_size(button.level_title, HORIZONTAL_ALIGNMENT_LEFT, -1, button.name_label.get_theme_font_size("font_size"))
		_check(lettering.x <= button.name_label.size.x, "%s Level %d name fits without truncation" % [size_label, level_id])
		_check(button.name_label.get_global_rect().end.x < button.lock_icon.get_global_rect().position.x, "%s Level %d name does not overlap its padlock" % [size_label, level_id])
		_check(button.portrait_rect.get_global_rect().end.x < button.name_label.get_global_rect().position.x, "%s Level %d portrait has space before its name" % [size_label, level_id])
		_check(is_equal_approx(button.lock_icon.position.x + button.lock_icon.size.x, button.size.x - 16.0), "%s Level %d padlock keeps its right margin" % [size_label, level_id])
		_check(is_equal_approx(button.lock_icon.position.y + button.lock_icon.size.y * 0.5, button.size.y * 0.5), "%s Level %d padlock stays vertically centered" % [size_label, level_id])
		if level_id == 1:
			_check(not button.is_lock_visible(), "%s unlocked Level 1 has no padlock" % size_label)
		else:
			_check(button.disabled, "%s Level %d is disabled" % [size_label, level_id])
			_check(button.is_lock_visible(), "%s Level %d shows its padlock" % [size_label, level_id])
			var lock_uses_reference := button.lock_icon is TextureRect and (button.lock_icon as TextureRect).texture.resource_path.ends_with("parchment_forest/padlock.svg")
			_check(lock_uses_reference, "%s Level %d uses the cream-and-gold reference lock" % [size_label, level_id])
			if button.is_lock_visible():
				visible_lock_count += 1
		if level_id > 1:
			_check(not previous_rect.intersects(button_rect), "%s Levels %d and %d do not overlap" % [size_label, level_id - 1, level_id])
		previous_rect = button_rect
	_check(visible_lock_count == 5, "%s fresh-player capture has exactly five padlocks" % size_label)
	_check(previous_rect.end.y <= screen.play_button.get_global_rect().position.y, "%s PLAY is below the level list" % size_label)

	var image: Image = viewport.get_texture().get_image()
	if image != null and not image.is_empty():
		var capture_path := ProjectSettings.globalize_path("user://%s" % capture_name)
		_check(image.save_png(capture_path) == OK, "%s rendered capture is saved" % size_label)
	else:
		_check(false, "%s rendered capture is available" % size_label)

	screen.help_button.pressed.emit()
	await process_frame
	var help_panel: Control = screen.get_node("UIRoot/HelpOverlay/Panel")
	_check(screen.help_overlay.visible, "%s Help panel opens" % size_label)
	_check(_rect_is_inside(help_panel.get_global_rect(), viewport_size), "%s Help panel stays on-screen" % size_label)
	_check(_rect_contains(help_panel.get_global_rect(), instructions.get_global_rect()), "%s Help instructions stay inside the panel" % size_label)
	var help_image: Image = viewport.get_texture().get_image()
	if help_image != null and not help_image.is_empty():
		var help_capture_name := capture_name.trim_suffix(".png") + "_help.png"
		var help_capture_path := ProjectSettings.globalize_path("user://%s" % help_capture_name)
		_check(help_image.save_png(help_capture_path) == OK, "%s Help-panel capture is saved" % size_label)
	else:
		_check(false, "%s Help-panel capture is available" % size_label)
	screen.close_help_button.pressed.emit()
	_check(not screen.help_overlay.visible, "%s Help panel closes" % size_label)
	# Exercise the rendered button through GUI hit-testing, rather than calling
	# only its navigation callback. All artwork children must ignore input.
	var point: Vector2 = screen.play_button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	viewport.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = point
	press.pressed = true
	viewport.push_input(press, true)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = point
	viewport.push_input(release, true)
	_check(requested_scenes == ["res://gameplay_placeholder.tscn"], "%s PLAY hit-test requests the existing gameplay scene" % size_label)
	screen.play_button.pressed.emit()
	_check(requested_scenes.size() == 1, "%s repeated PLAY cannot request a second transition" % size_label)

	screen.queue_free()
	viewport.queue_free()
	await process_frame
	progress.free()


func _test_returning_player_capture() -> void:
	var saved_progress = ProgressManagerScript.new()
	saved_progress.save_path = SAVE_PATH
	saved_progress.highest_unlocked_level = 3
	saved_progress.completed_levels.assign([1, 2])
	saved_progress.board_completed_levels.assign([1, 2])
	saved_progress.completed_story_chapters.assign([1, 2])
	saved_progress.claimed_character_rewards.assign([1, 2])
	saved_progress.selected_level = 3
	_check(saved_progress.save_progress(), "returning-player visual fixture is saved separately")
	saved_progress.free()

	var progress = ProgressManagerScript.new()
	progress.save_path = SAVE_PATH
	progress.load_progress()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1024, 1536)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var screen = LevelSelectionScene.instantiate()
	screen.progress_manager = progress
	viewport.add_child(screen)
	await process_frame
	await process_frame

	for level_id: int in range(1, 4):
		_check(not screen.level_buttons[level_id].disabled, "returning-player capture keeps Level %d enabled" % level_id)
		_check(not screen.level_buttons[level_id].is_lock_visible(), "returning-player capture hides Level %d padlock" % level_id)
		_check(screen.level_buttons[level_id].self_modulate.is_equal_approx(Color.WHITE), "returning-player capture restores Level %d colors" % level_id)
	var returning_lock_count := 0
	for level_id: int in range(4, 7):
		_check(screen.level_buttons[level_id].disabled, "returning-player capture keeps Level %d disabled" % level_id)
		_check(screen.level_buttons[level_id].is_lock_visible(), "returning-player capture keeps Level %d padlock" % level_id)
		if screen.level_buttons[level_id].is_lock_visible():
			returning_lock_count += 1
	_check(returning_lock_count == 3, "returning-player capture has exactly three padlocks")

	var image: Image = viewport.get_texture().get_image()
	var capture_path := ProjectSettings.globalize_path("user://level_selection_returning_1024x1536.png")
	_check(image != null and not image.is_empty() and image.save_png(capture_path) == OK, "returning-player rendered capture is saved")

	screen.queue_free()
	viewport.queue_free()
	await process_frame
	progress.free()


func _rect_is_inside(rect: Rect2, viewport_size: Vector2i) -> bool:
	return (
		rect.position.x >= 0.0
		and rect.position.y >= 0.0
		and rect.end.x <= float(viewport_size.x)
		and rect.end.y <= float(viewport_size.y)
	)


func _test_main_menu_entry() -> void:
	# Use the actual Autoload and navigation without resetting or awarding progress.
	var menu = load("res://main_menu_tscn.tscn").instantiate()
	get_root().add_child(menu)
	current_scene = menu
	await process_frame
	menu.start_button.pressed.emit()
	await process_frame
	await process_frame
	var screen = current_scene
	_check(screen != null and screen.scene_file_path == "res://level_selection.tscn", "actual Main Menu Start Game opens the redesigned Level Selection")
	if screen != null and screen.scene_file_path == "res://level_selection.tscn":
		var progress: Node = get_root().get_node("ProgressManager")
		for level_id: int in range(1, 7):
			_check(screen.level_buttons[level_id].disabled == (not progress.is_level_unlocked(level_id)), "actual Level %d lock follows the real saved progress" % level_id)
		await RenderingServer.frame_post_draw
		var image: Image = get_root().get_texture().get_image()
		_check(image != null and image.save_png(ProjectSettings.globalize_path("user://level_selection_actual_project.png")) == OK, "actual project Level Selection capture is saved")
		await create_timer(0.2).timeout
		screen.back_button.pressed.emit()
		await process_frame
		await process_frame
		_check(current_scene != null and current_scene.scene_file_path == "res://main_menu_tscn.tscn", "actual Back navigation restores the existing Main Menu")
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	await process_frame


func _rect_contains(outer: Rect2, inner: Rect2) -> bool:
	return (
		inner.position.x >= outer.position.x
		and inner.position.y >= outer.position.y
		and inner.end.x <= outer.end.x
		and inner.end.y <= outer.end.y
	)


func _cleanup_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", description)
	else:
		_failed += 1
		push_error("FAIL: %s" % description)

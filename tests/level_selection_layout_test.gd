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
	_cleanup_save()
	await _test_returning_player_capture()
	_cleanup_save()
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
	viewport.add_child(screen)
	await process_frame
	await process_frame

	var size_label := "%dx%d" % [viewport_size.x, viewport_size.y]
	_check(screen.size.round() == Vector2(viewport_size), "%s root fills the viewport" % size_label)
	_check(screen.level_buttons.size() == 6, "%s shows all six level controls" % size_label)
	_check(screen.level_buttons_area.get_child_count() == 6, "%s does not create duplicate runtime buttons" % size_label)
	_check(not screen.selection_label.get_parent().visible, "%s keeps the status panel hidden" % size_label)
	_check(_rect_is_inside(screen.title_banner.get_global_rect(), viewport_size), "%s title banner stays on-screen" % size_label)
	_check(not screen.title_banner.get_global_rect().intersects(screen.back_button.get_global_rect()), "%s title does not overlap Back Arrow" % size_label)
	_check(_rect_is_inside(screen.back_button.get_global_rect(), viewport_size), "%s Back Arrow stays on-screen" % size_label)
	_check(_rect_is_inside(screen.play_button.get_global_rect(), viewport_size), "%s PLAY stays on-screen" % size_label)

	var previous_rect := Rect2()
	var locked_texture_count := 0
	for level_id: int in range(1, 7):
		var button: TextureButton = screen.level_buttons[level_id]
		var button_rect := button.get_global_rect()
		_check(_rect_is_inside(button_rect, viewport_size), "%s Level %d stays on-screen" % [size_label, level_id])
		if level_id == 1:
			_check(button.texture_normal.resource_path.ends_with("Level1.png"), "%s unlocked Level 1 uses its original PNG" % size_label)
		else:
			_check(button.texture_normal.resource_path.ends_with("Level%d_locked.png" % level_id), "%s Level %d uses its complete locked PNG" % [size_label, level_id])
			_check(button.texture_disabled == button.texture_normal, "%s Level %d disabled state preserves the locked PNG" % [size_label, level_id])
			if button.texture_normal.resource_path.ends_with("_locked.png"):
				locked_texture_count += 1
		if level_id > 1:
			_check(not previous_rect.intersects(button_rect), "%s Levels %d and %d do not overlap" % [size_label, level_id - 1, level_id])
		previous_rect = button_rect
	_check(locked_texture_count == 5, "%s fresh-player capture has exactly five locked PNGs" % size_label)
	_check(previous_rect.end.y <= screen.play_button.get_global_rect().position.y, "%s PLAY is below the level list" % size_label)

	var image: Image = viewport.get_texture().get_image()
	if image != null and not image.is_empty():
		var capture_path := ProjectSettings.globalize_path("user://%s" % capture_name)
		_check(image.save_png(capture_path) == OK, "%s rendered capture is saved" % size_label)
	else:
		_check(false, "%s rendered capture is available" % size_label)

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
		_check(screen.level_buttons[level_id].texture_normal.resource_path.ends_with("Level%d.png" % level_id), "returning-player capture uses Level %d unlocked PNG" % level_id)
		_check(screen.level_buttons[level_id].self_modulate.is_equal_approx(Color.WHITE), "returning-player capture restores Level %d colors" % level_id)
	var returning_lock_count := 0
	for level_id: int in range(4, 7):
		_check(screen.level_buttons[level_id].disabled, "returning-player capture keeps Level %d disabled" % level_id)
		_check(screen.level_buttons[level_id].texture_normal.resource_path.ends_with("Level%d_locked.png" % level_id), "returning-player capture keeps Level %d locked PNG" % level_id)
		if screen.level_buttons[level_id].texture_normal.resource_path.ends_with("_locked.png"):
			returning_lock_count += 1
	_check(returning_lock_count == 3, "returning-player capture has exactly three locked PNGs")

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

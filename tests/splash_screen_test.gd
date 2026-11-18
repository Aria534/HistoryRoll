extends SceneTree

const SplashScene = preload("res://splash_screen.tscn")

var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(str(ProjectSettings.get_setting("application/run/main_scene")) == "res://splash_screen.tscn", "Splash Screen is the project startup scene")
	await _test_layout(Vector2i(1024, 1536))
	await _test_layout(Vector2i(720, 1280))
	await _test_transition()
	print("Splash Screen tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _test_layout(viewport_size: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var splash = SplashScene.instantiate()
	splash.fade_in_duration = 0.0
	splash.hold_duration = 10.0
	viewport.add_child(splash)
	await process_frame
	await process_frame
	var logo := splash.get_node("Presentation/Logo") as Control
	var tagline := splash.get_node("Presentation/Tagline") as Control
	_check(_visible_inside(logo, viewport_size), "%s keeps the HistoryRoll logo visible" % viewport_size)
	_check(_visible_inside(tagline, viewport_size), "%s keeps the tagline visible" % viewport_size)
	_check(logo.texture == load("res://assets/gameplay_ui/historyroll_sign.png"), "Splash reuses the existing transparent HistoryRoll sign")
	var capture := viewport.get_texture().get_image()
	var filename := "splash_%dx%d.png" % [viewport_size.x, viewport_size.y]
	var save_error := capture.save_png(ProjectSettings.globalize_path("user://%s" % filename)) if capture != null and not capture.is_empty() else ERR_CANT_CREATE
	_check(save_error == OK, "%s rendered splash capture is saved" % viewport_size)
	splash.queue_free()
	viewport.queue_free()
	await process_frame


func _test_transition() -> void:
	var requested: Array[String] = []
	var splash = SplashScene.instantiate()
	splash.fade_in_duration = 0.0
	splash.hold_duration = 10.0
	splash.fade_out_duration = 0.0
	splash.scene_change_handler = func(path: String) -> void: requested.append(path)
	get_root().add_child(splash)
	await process_frame
	splash.skip_splash()
	await process_frame
	await process_frame
	_check(requested == ["res://main_menu_tscn.tscn"], "Splash opens the existing Main Menu exactly once")
	splash.skip_splash()
	await process_frame
	_check(requested.size() == 1, "Repeated input cannot trigger duplicate scene changes")
	splash.queue_free()
	await process_frame


func _visible_inside(control: Control, viewport_size: Vector2i) -> bool:
	var rect := control.get_global_rect()
	return control.is_visible_in_tree() and rect.size.x >= 44.0 and rect.size.y >= 44.0 and rect.position.x >= -0.1 and rect.position.y >= -0.1 and rect.end.x <= viewport_size.x + 0.1 and rect.end.y <= viewport_size.y + 0.1


func _check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS: ", message)
	else:
		failed += 1
		push_error("FAIL: %s" % message)

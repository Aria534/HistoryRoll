extends SceneTree

const SplashScene = preload("res://splash_screen.tscn")
const MAIN_MENU := "res://main_menu_tscn.tscn"
const VIEWPORTS := [
	Vector2i(1024, 1536), Vector2i(720, 1280), Vector2i(1086, 1448), Vector2i(1065, 1477),
	Vector2i(1080, 1920), Vector2i(1080, 2340), Vector2i(1080, 2400),
]

var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(str(ProjectSettings.get_setting("application/run/main_scene")) == "res://splash_screen.tscn", "the existing splash remains the project startup scene")
	for viewport_size: Vector2i in VIEWPORTS:
		await _test_layout(viewport_size)
	await _test_transition()
	await _test_skip_input()
	await _test_automatic_transition()
	await _test_actual_main_menu()
	await _test_nine_second_timing()
	var audio: Node = get_root().get_node_or_null("AudioManager")
	if audio != null:
		audio.stop_music(0.0)
	await process_frame
	await process_frame
	print("Splash Screen tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _fixture(viewport_size: Vector2i) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var requested: Array[String] = []
	var splash = SplashScene.instantiate()
	splash.minimum_intro_duration = 0.0
	splash.fade_in_duration = 0.0
	splash.fade_out_duration = 0.0
	splash.hold_duration = 60.0
	splash.scene_change_handler = func(path: String) -> void: requested.append(path)
	viewport.add_child(splash)
	return {"viewport": viewport, "splash": splash, "requested": requested}


func _wait_ready(splash: Node) -> bool:
	var previous := 0.0
	var monotonic := true
	for frame_index in 900:
		monotonic = monotonic and splash.loading_bar.value >= previous and splash.loading_bar.value <= 100.0
		previous = splash.loading_bar.value
		if splash._menu_scene != null:
			for settle_frame in 3:
				await process_frame
			_check(monotonic, "the resource loading progress stays within bounds and does not move backward")
			return true
		await process_frame
	_check(false, "Main Menu finishes threaded loading")
	return false


func _test_layout(viewport_size: Vector2i) -> void:
	var fixture := await _fixture(viewport_size)
	var splash = fixture.splash
	_check(await _wait_ready(splash), "%s Main Menu resource is ready" % viewport_size)
	var label := "%dx%d" % [viewport_size.x, viewport_size.y]
	_check(_texture_path(splash.logo.texture).ends_with("/splash_ui/hero_board/hero_header.png"), "%s uses the six-hero HistoryRoll header" % label)
	_check(_texture_path(splash.explorers.texture).ends_with("/splash_ui/hero_board/winding_board_perspective.png"), "%s uses the separate winding board artwork" % label)
	_check(splash.get_node("Background").texture.resource_path.ends_with("/splash_ui/hero_board/background.png"), "%s uses the Philippine gate scenery" % label)
	_check(not splash.get_node("GlowBottom").visible, "%s retired gradient decoration is hidden" % label)
	_check(splash.loading_bar.value == 100.0 and not splash.loading_bar.show_percentage, "%s actual menu load fills the yellow bar without a percentage overlay" % label)
	_check(splash.tagline.text == "LEARN • PLAY • DISCOVER", "%s tagline matches the reference" % label)
	_check(splash.subject.text == "Discover Heroes. Learn Our History.", "%s subject caption matches the reference" % label)
	_check(not splash.loading_label.visible and not splash.get_node("Presentation/LoadingBanner").visible, "%s normal loading omits the red caption banner" % label)
	for control: Control in [splash.logo, splash.tagline, splash.subject, splash.explorers, splash.loading_bar]:
		_check(_visible_inside(control, viewport_size), "%s %s remains visible and inside the portrait viewport" % [label, control.name])
		_check(control.mouse_filter == Control.MOUSE_FILTER_IGNORE, "%s %s cannot swallow skip input" % [label, control.name])
	for caption: Label in [splash.tagline, splash.subject]:
		var font_size := caption.get_theme_font_size("font_size")
		var font := caption.get_theme_font("font")
		var text_size := font.get_string_size(caption.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		_check(text_size.x <= caption.size.x and font.get_height(font_size) <= caption.size.y, "%s %s text fits" % [label, caption.name])
	_check(is_equal_approx(splash.logo.size.aspect(), splash.logo.texture.get_size().aspect()), "%s logo is not stretched" % label)
	_check(is_equal_approx(splash.explorers.size.aspect(), splash.explorers.texture.get_size().aspect()), "%s winding board is not stretched or cropped" % label)
	_check(splash.logo.get_global_rect().end.y < splash.tagline.position.y, "%s logo and tagline have clear spacing" % label)
	_check(splash.tagline.get_global_rect().end.y < splash.subject.position.y, "%s tagline does not overlap the subject banner" % label)
	_check(splash.subject.get_global_rect().end.y < splash.explorers.position.y, "%s winding board stays below the captions" % label)
	_check(splash.explorers.get_global_rect().end.y < splash.loading_bar.position.y, "%s winding board remains above the progress bar" % label)
	_check(splash.loading_bar.is_visible_in_tree(), "%s progress bar remains visible without the caption banner" % label)
	var frame := splash.get_node("Presentation/LoadingBarFrame") as TextureRect
	_check(frame.get_global_rect().encloses(splash.loading_bar.get_global_rect()), "%s progress fill stays inside its white/brown frame" % label)
	await RenderingServer.frame_post_draw
	var capture: Image = fixture.viewport.get_texture().get_image()
	_check(capture != null and not capture.is_empty() and capture.save_png("user://splash_hero_board_%s.png" % label) == OK, "%s actual Godot screenshot saved" % label)
	await _dispose(fixture)


func _test_transition() -> void:
	var fixture := await _fixture(Vector2i(720, 1280))
	var splash = fixture.splash
	# Ask to skip before the first load-status poll has supplied the PackedScene.
	splash.skip_splash()
	_check(fixture.requested.is_empty() and splash._skip_requested, "an early skip waits for the required Main Menu resource")
	for frame_index in 900:
		if not fixture.requested.is_empty():
			break
		await process_frame
	_check(fixture.requested == [MAIN_MENU], "early skip eventually opens the existing Main Menu exactly once")
	splash.skip_splash()
	splash.skip_splash()
	await process_frame
	_check(fixture.requested.size() == 1, "repeated skip requests cannot duplicate scene changes")
	await _dispose(fixture)


func _test_skip_input() -> void:
	for kind: String in ["touch", "mouse", "keyboard"]:
		var fixture := await _fixture(Vector2i(720, 1280))
		var splash = fixture.splash
		await _wait_ready(splash)
		var event: InputEvent
		if kind == "touch":
			var touch := InputEventScreenTouch.new()
			touch.pressed = true
			event = touch
		elif kind == "mouse":
			var mouse := InputEventMouseButton.new()
			mouse.pressed = true
			mouse.button_index = MOUSE_BUTTON_LEFT
			event = mouse
		else:
			var key := InputEventKey.new()
			key.pressed = true
			key.keycode = KEY_SPACE
			event = key
		splash._elapsed = splash.minimum_skip_delay - 0.01
		splash._unhandled_input(event)
		_check(fixture.requested.is_empty() and not splash._transitioning, "%s input respects the minimum skip delay" % kind)
		splash._elapsed = splash.minimum_skip_delay + 0.01
		splash._unhandled_input(event)
		for frame_index in 6:
			await process_frame
		_check(fixture.requested == [MAIN_MENU], "%s input skips the intro after the guard delay" % kind)
		splash._unhandled_input(event)
		_check(fixture.requested.size() == 1, "%s repeated input remains guarded" % kind)
		await _dispose(fixture)


func _test_automatic_transition() -> void:
	var fixture := await _fixture(Vector2i(720, 1280))
	var splash = fixture.splash
	# Rebuild only the existing timed sequence with short fixture durations.
	if splash._sequence_tween != null:
		splash._sequence_tween.kill()
	splash.hold_duration = 0.02
	splash.fade_out_duration = 0.02
	for frame_index in 900:
		if not fixture.requested.is_empty():
			break
		await process_frame
	_check(fixture.requested == [MAIN_MENU], "intro advances automatically without a tap")
	_check(splash.loading_bar.value == 100.0 and splash._menu_scene != null, "automatic transition waits for real loading completion")
	await _dispose(fixture)


func _test_actual_main_menu() -> void:
	var audio: Node = get_root().get_node("AudioManager")
	var music_enabled: bool = audio.is_music_enabled()
	var splash = SplashScene.instantiate()
	splash.minimum_intro_duration = 0.0
	splash.fade_in_duration = 0.01
	splash.hold_duration = 0.02
	splash.fade_out_duration = 0.01
	get_root().add_child(splash)
	current_scene = splash
	for frame_index in 900:
		if current_scene != null and current_scene.scene_file_path == MAIN_MENU:
			break
		await process_frame
	_check(current_scene != null and current_scene.scene_file_path == MAIN_MENU, "real startup routing instantiates the existing Main Menu")
	if current_scene != null and current_scene.scene_file_path == MAIN_MENU:
		_check(current_scene.start_button != null and not current_scene.start_button.disabled, "real Main Menu Start Game remains available")
		_check(current_scene.hero_cards_button != null and current_scene.settings_button != null and current_scene.quit_button != null, "real Main Menu retains its other three controls")
	_check(audio.is_music_enabled() == music_enabled, "intro preserves the saved global Music preference")
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	await process_frame


func _test_nine_second_timing() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(720, 1280)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var requested: Array[String] = []
	var elapsed_at_open := {"seconds": -1.0}
	var splash = SplashScene.instantiate()
	var started := Time.get_ticks_msec()
	splash.scene_change_handler = func(path: String) -> void:
		requested.append(path)
		elapsed_at_open.seconds = float(Time.get_ticks_msec() - started) / 1000.0
	viewport.add_child(splash)
	await _wait_ready(splash)
	while splash._elapsed < 1.0:
		await process_frame
	var first_progress: float = splash.loading_bar.value
	_check(first_progress > 0.0 and first_progress < 100.0, "nine-second startup bar fills gradually after resources are ready")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	var mouse := InputEventMouseButton.new()
	mouse.pressed = true
	mouse.button_index = MOUSE_BUTTON_LEFT
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_SPACE
	for event: InputEvent in [touch, mouse, key]:
		splash._unhandled_input(event)
	_check(requested.is_empty() and not splash._transitioning, "touch, mouse, and keyboard cannot shorten the nine-second intro")
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	_check(image != null and image.save_png("user://splash_hero_board_1second_720x1280.png") == OK, "partially filled nine-second loading bar capture is saved")
	while splash._elapsed < 8.0:
		await process_frame
	_check(requested.is_empty(), "Main Menu is not opened before the nine-second interval")
	_check(splash.loading_bar.value > first_progress and splash.loading_bar.value < 100.0, "startup progress continues across the requested duration")
	for frame_index in 900:
		if not requested.is_empty():
			break
		await process_frame
	_check(requested == [MAIN_MENU], "nine-second intro opens Main Menu once")
	_check(elapsed_at_open.seconds >= 8.95 and elapsed_at_open.seconds < 10.5, "normal transition occurs after nine seconds including both fades")
	_check(splash.loading_bar.value == 100.0, "startup bar finishes before Main Menu opens")
	print("Nine-second intro measured duration: %.3f seconds." % elapsed_at_open.seconds)
	splash.skip_splash()
	_check(requested.size() == 1, "input after the nine-second transition cannot duplicate navigation")
	viewport.queue_free()
	await process_frame


func _texture_path(texture: Texture2D) -> String:
	return texture.atlas.resource_path if texture is AtlasTexture else texture.resource_path


func _dispose(fixture: Dictionary) -> void:
	fixture.viewport.queue_free()
	await process_frame


func _visible_inside(control: Control, viewport_size: Vector2i) -> bool:
	var rect := control.get_global_rect()
	return control.is_visible_in_tree() and rect.size.x > 0.0 and rect.size.y > 0.0 and rect.position.x >= -0.1 and rect.position.y >= -0.1 and rect.end.x <= viewport_size.x + 0.1 and rect.end.y <= viewport_size.y + 0.1


func _check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS: ", message)
	else:
		failed += 1
		push_error("FAIL: %s" % message)

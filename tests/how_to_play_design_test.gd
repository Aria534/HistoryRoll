extends SceneTree

const SettingsScene = preload("res://settings.tscn")
const LevelScene = preload("res://level_selection.tscn")
const ProgressScript = preload("res://progress_manager.gd")
const Catalog = preload("res://level_catalog.gd")
const HELP_SETTINGS := "user://historyroll_help_design_settings.cfg"
const HELP_PROGRESS := "user://historyroll_help_design_progress.json"
const VIEWPORTS := [
	Vector2i(1024, 1536), Vector2i(720, 1280), Vector2i(1086, 1448),
	Vector2i(1080, 1920), Vector2i(1080, 2340), Vector2i(1080, 2400), Vector2i(1024, 1055),
]
var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if Engine.is_editor_hint():
		await _test_editor_preview()
		print("Library editor-preview tests: %d passed, %d failed." % [passed, failed])
		quit(0 if failed == 0 else 1)
		return
	_cleanup()
	var audio := get_root().get_node("AudioManager")
	var saved_music: bool = audio.is_music_enabled()
	var saved_sfx: bool = audio.is_sfx_enabled()
	for viewport_size: Vector2i in (VIEWPORTS.slice(0, 1) if OS.get_cmdline_user_args().has("--quick") else VIEWPORTS):
		await _capture(viewport_size, true)
		await _capture(viewport_size, false)
	await _test_main_game_help()
	audio.set_music_enabled(saved_music, false)
	audio.set_sfx_enabled(saved_sfx, false)
	audio.stop_music(0.0)
	_cleanup()
	await process_frame
	await process_frame
	print("Library How to Play tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _capture(viewport_size: Vector2i, from_settings: bool) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var progress = ProgressScript.new()
	progress.save_path = HELP_PROGRESS
	var screen = SettingsScene.instantiate() if from_settings else LevelScene.instantiate()
	if from_settings:
		screen.settings_path = HELP_SETTINGS
	else:
		screen.progress_manager = progress
	var requested: Array[String] = []
	screen.scene_change_handler = func(path: String) -> void: requested.append(path)

	var stored_panel = screen.get_node("HowToPlayOverlay/HelpAspect/Canvas" if from_settings else "UIRoot/HelpOverlay/Panel")
	var stored_rows: VBoxContainer = stored_panel.get_node(stored_panel.rows_path)
	_check(stored_rows.get_child_count() == 11, "the PackedScene contains eleven rules before any ready callback")
	for stored_row: HBoxContainer in stored_rows.get_children():
		_check(not (stored_row.get_node("Description") as Label).text.is_empty(), "saved scene already contains " + stored_row.name + " text")
	if from_settings:
		_check(screen.get_node("HowToPlayOverlay/HelpAspect").stretch_mode == AspectRatioContainer.STRETCH_FIT, "Settings help artwork fits both available width and height")
	viewport.add_child(screen)
	await _settle()
	# Users can leave the screen idle before opening Help. Hidden Containers
	# must not retain an oversized first layout when the overlay is shown later.
	for hidden_frame in 12:
		await process_frame
	var overlay: Control = screen.how_to_play_overlay if from_settings else screen.help_overlay
	var panel = screen.get_node("HowToPlayOverlay/HelpAspect/Canvas" if from_settings else "UIRoot/HelpOverlay/Panel")
	var label := "%s_%dx%d" % ["settings" if from_settings else "levels", viewport_size.x, viewport_size.y]
	_click(viewport, screen.help_button.get_global_rect().get_center())
	await _settle()
	_check(overlay.visible, label + " actual pointer opens help")
	_check(panel.frame.texture.resource_path.ends_with("how_to_play_ui/library/frame.png"), label + " uses the library artwork")
	_check(panel.rows.get_child_count() == 11, label + " shows all eleven numbered rules")
	_check(panel.heading.text == "HOW TO PLAY", label + " title is live text")
	_check(panel.get_node_or_null("PlayButton") == null, label + " has no extra PLAY control")
	_check(not panel.instructions.visible, label + " original text is retained without duplicate lettering")
	var paper_rect: Rect2 = panel.frame.get_global_rect()
	var previous_rect := Rect2()
	for row: HBoxContainer in panel.rows.get_children():
		var number := row.get_child(0) as Label
		var description := row.get_child(1) as Label
		var rect := row.get_global_rect()
		_check(paper_rect.encloses(rect), label + " " + row.name + " remains inside the illustrated frame")
		_check(panel.rows.get_global_rect().grow(0.5).encloses(rect), label + " " + row.name + " fits the parchment text area")
		_check(number.get_global_rect().end.x < description.get_global_rect().position.x, label + " " + row.name + " number has a text gap")
		_check(description.get_minimum_size().y <= description.size.y + 0.5, label + " " + row.name + " wrapped text is not clipped")
		if previous_rect.has_area():
			_check(previous_rect.end.y <= rect.position.y + 0.5, label + " " + row.name + " does not overlap the previous rule")
		previous_rect = rect
	_check(previous_rect.end.y < panel.close_button.get_global_rect().position.y, label + " instructions do not overlap GOT IT")
	for control: Control in [panel.frame, panel.heading, panel.close_button, panel.help_back_button, panel.help_hint_button]:
		_check(_inside(control.get_global_rect(), viewport_size), label + " " + control.name + " stays on-screen")
	for navigation: Control in [panel.help_back_button, panel.help_hint_button]:
		_check(_artwork_covers_control(panel.frame, navigation), label + " " + navigation.name + " fits fully on the visible library background")
	_check(panel.help_hint_button.size.is_equal_approx(panel.help_back_button.size), label + " Back and question icons keep matching button bounds")
	var title_font: Font = panel.heading.get_theme_font("font")
	var title_size: int = panel.heading.get_theme_font_size("font_size")
	_check(title_font.get_string_size(panel.heading.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x <= panel.heading.size.x, label + " title lettering fits its red plaque")
	var rule_text: String = panel.instructions.text
	for level: Dictionary in Catalog.get_levels():
		_check(rule_text.contains("Earn %d points" % int(level.correct_answer_points)) and rule_text.contains("Lose %d points" % int(level.incorrect_answer_penalty)), label + " instructions match Level %d scoring" % level.id)
	_check(rule_text.contains("Ladders") and rule_text.contains("Snakes") and rule_text.contains("exact dice roll"), label + " preserves real board terminology and the exact-roll rule")
	if not from_settings:
		_click(viewport, screen.play_button.get_global_rect().get_center())
		await _settle()
		_check(requested.is_empty(), label + " help blocks the underlying PLAY button")
	await RenderingServer.frame_post_draw
	var image: Image = viewport.get_texture().get_image()
	_check(image != null and image.save_png("user://how_to_play_library_" + label + ".png") == OK, label + " actual Godot capture saved")

	_click(viewport, panel.help_hint_button.get_global_rect().get_center())
	await _settle()
	_check(panel.rows.has_focus() and overlay.visible, label + " question icon focuses the instructions")
	_click(viewport, panel.help_back_button.get_global_rect().get_center())
	await _settle()
	_check(not overlay.visible and requested.is_empty(), label + " top Back closes help without changing scenes")
	_check(screen.help_button.has_focus(), label + " closing help returns focus to its opener")
	_click(viewport, screen.help_button.get_global_rect().get_center())
	await _settle()
	_click(viewport, panel.close_button.get_global_rect().get_center())
	await _settle()
	_check(not overlay.visible and requested.is_empty(), label + " GOT IT still closes the existing overlay")
	viewport.queue_free()
	await process_frame
	progress.free()
	_cleanup()


func _settle() -> void:
	for index in 5:
		await process_frame


func _click(viewport: Viewport, point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	viewport.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	viewport.push_input(press, true)
	var release := InputEventMouseButton.new()
	release.position = point
	release.button_index = MOUSE_BUTTON_LEFT
	viewport.push_input(release, true)


func _inside(rect: Rect2, viewport_size: Vector2i) -> bool:
	return Rect2(Vector2.ZERO, Vector2(viewport_size)).grow(0.5).encloses(rect)


func _artwork_covers_control(frame: TextureRect, control: Control) -> bool:
	var art_rect := frame.get_global_rect()
	var control_rect := control.get_global_rect()
	if not art_rect.encloses(control_rect):
		return false
	var source := frame.texture.get_image()
	if source == null or source.is_empty():
		return false
	# Check the image alpha, not just its rectangular bounds: rounded corners
	# can leave a button over transparent pixels even when it is on-screen.
	for sample_y: int in range(5):
		for sample_x: int in range(5):
			var fraction := Vector2(float(sample_x), float(sample_y)) / 4.0
			var point := control_rect.position + control_rect.size * fraction
			var pixel := Vector2i((point - art_rect.position) / art_rect.size * Vector2(source.get_size()))
			if source.get_pixelv(pixel).a < 0.95:
				return false
	return true


func _cleanup() -> void:
	for path: String in [HELP_SETTINGS, HELP_PROGRESS]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + message)

func _test_main_game_help() -> void:
	var menu_scene := load("res://main_menu_tscn.tscn") as PackedScene
	var menu := menu_scene.instantiate()
	get_root().add_child(menu)
	current_scene = menu
	await _settle()
	for from_settings: bool in [true, false]:
		var entry_button: BaseButton = current_scene.settings_button if from_settings else current_scene.start_button
		_click(get_root(), entry_button.get_global_rect().get_center())
		var destination := "res://settings.tscn" if from_settings else "res://level_selection.tscn"
		if not await _wait_for_scene(destination):
			break
		var screen = current_scene
		_click(get_root(), screen.help_button.get_global_rect().get_center())
		for frame_index in 8:
			await process_frame
		var overlay: Control = screen.how_to_play_overlay if from_settings else screen.help_overlay
		var panel = screen.get_node("HowToPlayOverlay/HelpAspect/Canvas" if from_settings else "UIRoot/HelpOverlay/Panel")
		_check(overlay.is_visible_in_tree(), "main game opens populated help from " + destination)
		_check(panel.rows.get_child_count() == 11, "main game contains all eleven visible instruction rows")
		for control: Control in [panel.frame, panel.heading, panel.close_button, panel.help_back_button, panel.help_hint_button]:
			_check(_inside(control.get_global_rect(), Vector2i(get_root().get_visible_rect().size)), "main game keeps " + control.name + " visible in the current window")
		for row: HBoxContainer in panel.rows.get_children():
			var description := row.get_node("Description") as Label
			_check(description.is_visible_in_tree() and not description.text.is_empty(), "main game displays " + row.name)
		await RenderingServer.frame_post_draw
		var image: Image = get_root().get_texture().get_image()
		var filename := "user://how_to_play_main_game_%s.png" % ("settings" if from_settings else "levels")
		_check(image != null and image.save_png(filename) == OK, "main-game help screenshot is saved")
		_click(get_root(), panel.close_button.get_global_rect().get_center())
		await _settle()
		_check(not overlay.visible, "main-game GOT IT closes help")
		_click(get_root(), screen.back_button.get_global_rect().get_center())
		if not await _wait_for_scene("res://main_menu_tscn.tscn"):
			break
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	await process_frame


func _wait_for_scene(path: String) -> bool:
	for frame_index in 120:
		if current_scene != null and current_scene.scene_file_path == path:
			await _settle()
			_check(true, "main-game navigation reaches " + path)
			return true
		await process_frame
	_check(false, "main-game navigation reaches " + path)
	return false


func _test_editor_preview() -> void:
	_check(Engine.is_editor_hint(), "preview test runs with editor tool scripts enabled")
	for from_settings: bool in [true, false]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(1086, 1448)
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		get_root().add_child(viewport)
		var scene = SettingsScene.instantiate() if from_settings else LevelScene.instantiate()
		viewport.add_child(scene)
		var overlay: Control = scene.get_node("HowToPlayOverlay" if from_settings else "UIRoot/HelpOverlay")
		for hidden_frame in 12:
			await process_frame
		overlay.show()
		for frame_index in 10:
			await process_frame
		var panel = scene.get_node("HowToPlayOverlay/HelpAspect/Canvas" if from_settings else "UIRoot/HelpOverlay/Panel")
		_check(panel.rows.get_child_count() == 11, "editor preview shows all eleven saved rules")
		_check(panel.heading.is_visible_in_tree() and panel.heading.text == "HOW TO PLAY", "editor preview displays the title")
		_check(panel.close_button.is_visible_in_tree() and panel.close_button.text == "GOT IT", "editor preview displays GOT IT")
		_check(panel.help_hint_button.size.is_equal_approx(panel.help_back_button.size), "editor preview keeps matching top navigation button bounds: Back=%s Help=%s" % [panel.help_back_button.size, panel.help_hint_button.size])
		for navigation: Control in [panel.help_back_button, panel.help_hint_button]:
			_check(_artwork_covers_control(panel.frame, navigation), "editor preview keeps " + navigation.name + " inside the visible artwork")
		for row: HBoxContainer in panel.rows.get_children():
			var description := row.get_node("Description") as Label
			_check(description.is_visible_in_tree() and not description.text.is_empty(), "editor preview displays " + row.name)
			_check(panel.frame.get_global_rect().encloses(row.get_global_rect()), "editor preview keeps " + row.name + " inside the frame")
		# Editor low-processor mode may stop automatic drawing once layout is idle.
		# Render now instead of waiting indefinitely for a future redraw signal.
		RenderingServer.force_draw(false)
		var image: Image = viewport.get_texture().get_image()
		var filename := "user://how_to_play_editor_%s_1086x1448.png" % ("settings" if from_settings else "levels")
		_check(image != null and image.save_png(filename) == OK, "editor-preview screenshot is saved")
		viewport.queue_free()
		await process_frame

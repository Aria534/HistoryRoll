extends SceneTree

# Retains the existing regression entry point for the retired foliage menu.
# The approved 2026-11-19 reference uses a static landscape instead.
const MainMenuScene = preload("res://main_menu_tscn.tscn")
var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var menu := MainMenuScene.instantiate()
	get_root().add_child(menu)
	await process_frame
	_check(not menu.get_node("AnimatedPlants").visible, "retired foliage branch stays hidden")
	_check(not menu.get_node("BoardDecoration").visible, "retired board stays hidden")
	_check(not menu.has_node("HistoryRollLogo"), "the deleted legacy logo node is not recreated")
	_check(menu.menu_logo.texture != null, "the new independent parchment logo has its own artwork")
	var background: AnimatedSprite2D = menu.get_node("LiveBackground")
	var start_position := background.position
	var start_scale := background.scale
	await create_timer(0.2).timeout
	_check(background.position == start_position and background.scale == start_scale, "scenery stays stationary between layout changes")
	for button: TextureButton in [menu.start_button, menu.hero_cards_button, menu.settings_button, menu.quit_button]:
		_check(not button.disabled and button.pressed.get_connections().size() == 1, "%s keeps one navigation connection" % button.name)
	var audio_manager: Node = get_root().get_node_or_null("AudioManager")
	var saved_music: bool = audio_manager.is_music_enabled()
	var saved_sfx: bool = audio_manager.is_sfx_enabled()
	audio_manager.set_music_enabled(false, false)
	menu._request_music("res://assets/audio/music/main_menu.ogg")
	_check(not audio_manager.is_music_playing(), "opening the menu respects Music OFF")
	audio_manager.set_sfx_enabled(false, false)
	audio_manager.last_sfx_role = ""
	menu._on_button_down(menu.start_button)
	_check(audio_manager.get_last_sfx_role().is_empty(), "button press respects Sound Effects OFF")
	audio_manager.set_sfx_enabled(true, false)
	menu._on_button_down(menu.start_button)
	_check(audio_manager.get_last_sfx_role() == "menu_press", "enabled button sound uses the shared SFX manager")
	audio_manager.set_music_enabled(saved_music, false)
	audio_manager.set_sfx_enabled(saved_sfx, false)
	menu.queue_free()
	await process_frame
	print("Main Menu scenery/audio tests: %d passed, %d failed." % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)

extends SceneTree

const ProgressScript = preload("res://progress_manager.gd")
const AudioScript = preload("res://audio_manager.gd")
const TEST_SETTINGS := "user://historyroll_scene_music_test.cfg"
const TEST_PROGRESS := "user://historyroll_scene_music_test.json"

var passed := 0
var failed := 0
var audio: Node
var saved_music := true
var saved_sfx := true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	audio = get_root().get_node("AudioManager")
	saved_music = audio.is_music_enabled()
	saved_sfx = audio.is_sfx_enabled()
	for enabled: bool in [true, false]:
		_write_settings(enabled)
		await _test_loading_handoff(enabled)
		await _test_scene("res://settings.tscn", AudioScript.MAIN_MENU_TRACK, enabled)
		await _test_scene("res://character_unlock.tscn", AudioScript.VICTORY_TRACK, enabled)
		await _test_scene("res://level_selection.tscn", AudioScript.LEVEL_SELECT_TRACK, enabled)
		await _test_scene("res://hero_cards.tscn", AudioScript.MAIN_MENU_TRACK, enabled)
		await _test_scene("res://gameplay_placeholder.tscn", AudioScript.GAMEPLAY_TRACK, enabled)
		await _test_story_ending(enabled)
	audio.stop_music(0.0)
	audio.set_music_enabled(saved_music, false)
	audio.set_sfx_enabled(saved_sfx, false)
	_cleanup()
	await process_frame
	await process_frame
	print("Scene music tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _prepare_audio(enabled: bool) -> void:
	audio.stop_music(0.0)
	audio.set_music_enabled(enabled, false)


func _new_progress():
	var progress = ProgressScript.new()
	progress.save_path = TEST_PROGRESS
	progress.selected_level = 1
	progress.selected_story_level = 1
	return progress


func _test_loading_handoff(enabled: bool) -> void:
	_prepare_audio(enabled)
	var splash = load("res://splash_screen.tscn").instantiate()
	splash.hold_duration = 60.0
	get_root().add_child(splash)
	await create_timer(0.7).timeout
	_check_music(AudioScript.MAIN_MENU_TRACK, enabled, "loading")
	_check(is_equal_approx(splash.minimum_intro_duration, 9.0), "music keeps the nine-second loading requirement")
	if enabled:
		await _check_music_signal()
	var player := audio.get_node("MusicPlayer") as AudioStreamPlayer
	var original_stream := player.stream
	var original_position := player.get_playback_position()
	var menu = load("res://main_menu_tscn.tscn").instantiate()
	get_root().add_child(menu)
	await create_timer(0.12).timeout
	_check_music(AudioScript.MAIN_MENU_TRACK, enabled, "Main Menu after loading")
	_check(player.stream == original_stream, "loading and Main Menu share the same loaded track")
	if enabled:
		_check(player.get_playback_position() >= original_position, "Main Menu does not restart the loading soundtrack")
	menu.queue_free()
	splash.queue_free()
	await process_frame
	await process_frame


func _test_scene(scene_path: String, track_path: String, enabled: bool) -> void:
	_prepare_audio(enabled)
	var progress = _new_progress()
	if scene_path == "res://character_unlock.tscn":
		# A valid reward fixture, isolated from the real player save.
		progress.board_completed_levels.assign([1])
		progress.completed_story_chapters.assign([1])
		progress.pending_progression_level = 1
		progress.progression_stage = progress.STAGE_CHARACTER_UNLOCK
	var screen = load(scene_path).instantiate()
	if scene_path == "res://settings.tscn":
		screen.settings_path = TEST_SETTINGS
	else:
		screen.progress_manager = progress
	get_root().add_child(screen)
	await create_timer(0.7).timeout
	_check_music(track_path, enabled, scene_path.get_file())
	if scene_path == "res://settings.tscn":
		screen.help_button.pressed.emit()
		await process_frame
		_check(screen.how_to_play_overlay.visible and audio.get_current_track_path() == track_path,
			"Settings How to Play keeps the same soundtrack")
		screen.close_help_button.pressed.emit()
	elif scene_path == "res://level_selection.tscn":
		screen.help_button.pressed.emit()
		await process_frame
		_check(screen.help_overlay.visible and audio.get_current_track_path() == track_path,
			"Level Selection How to Play keeps the same soundtrack")
		screen.close_help_button.pressed.emit()
	elif scene_path == "res://character_unlock.tscn":
		_check(not screen.has_error and progress.highest_unlocked_level == 1,
			"unlock music preserves the valid reward flow and does not unlock the next level early")
		screen.continue_button.pressed.emit()
		_check(progress.progression_stage == progress.STAGE_LEVEL_UNLOCK,
			"the existing character Continue still opens level-unlock confirmation")
		_check_music(track_path, enabled, "level-unlock confirmation")
	screen.queue_free()
	await process_frame
	await process_frame
	progress.free()


func _test_story_ending(enabled: bool) -> void:
	_prepare_audio(enabled)
	var progress = _new_progress()
	var story = load("res://hero_story_video_player.tscn").instantiate()
	story.progress_manager = progress
	var requested: Array[String] = []
	story.scene_change_handler = func(path: String) -> void: requested.append(path)
	get_root().add_child(story)
	await process_frame
	story._show_ending(false)
	await create_timer(0.7).timeout
	_check_music(AudioScript.MAIN_MENU_TRACK, enabled, "Story ending / coming-soon screen")
	_check(not progress.is_story_watched(1), "ending music does not mark an unwatched story complete")
	# Exercise playback controls without inventing or installing a story movie.
	story.video_available = true
	story._on_replay_pressed()
	_check(not audio.is_music_playing() and audio.get_current_track_path().is_empty(),
		"Replay stops global music before the video owns its audio")
	story._show_ending(false)
	await create_timer(0.7).timeout
	_check_music(AudioScript.MAIN_MENU_TRACK, enabled, "Story ending after Replay")
	story._on_back_pressed()
	_check(requested == ["res://hero_cards.tscn"], "Story Back keeps the existing Hero Cards destination")
	story.queue_free()
	await process_frame
	await process_frame
	progress.free()


func _check_music(expected_path: String, enabled: bool, context: String) -> void:
	var player := audio.get_node("MusicPlayer") as AudioStreamPlayer
	_check(audio.get_current_track_path() == expected_path, context + " selects the correct background track")
	_check(audio.is_music_enabled() == enabled and audio.is_music_playing() == enabled,
		context + " respects Music " + ("ON" if enabled else "OFF"))
	_check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")) == not enabled,
		context + " preserves the Music bus mute state")
	_check(player.bus == "Music" and audio.get_child_count() == 1 + AudioScript.SFX_POOL_SIZE,
		context + " keeps one global music player separate from SFX")
	_check(audio.is_sfx_enabled() == saved_sfx, context + " does not change Sound Effects")
	if enabled:
		_check(player.volume_db > -12.0, context + " completes its audible fade-in")


func _check_music_signal() -> void:
	var music_bus := AudioServer.get_bus_index("Music")
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 0.3
	var effect_index := AudioServer.get_bus_effect_count(music_bus)
	AudioServer.add_bus_effect(music_bus, capture)
	await create_timer(0.2).timeout
	var samples := capture.get_buffer(capture.get_frames_available())
	var peak := 0.0
	for sample: Vector2 in samples:
		peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
	AudioServer.remove_bus_effect(music_bus, effect_index)
	_check(not samples.is_empty() and peak > 0.001 and peak < 1.0,
		"loading produces non-silent, unclipped audio through the actual Music bus")
	print("Captured loading Music bus: %d frames, peak %.4f." % [samples.size(), peak])


func _write_settings(enabled: bool) -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_enabled", enabled)
	config.set_value("audio", "sfx_enabled", saved_sfx)
	_check(config.save(TEST_SETTINGS) == OK, "scene music preferences use an isolated test settings file")


func _check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + message)


func _cleanup() -> void:
	for path: String in [TEST_SETTINGS, TEST_PROGRESS]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

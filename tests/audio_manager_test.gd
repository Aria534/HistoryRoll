extends SceneTree

const AudioManagerScript = preload("res://audio_manager.gd")
const TEST_SETTINGS_PATH := "user://historyroll_audio_manager_test.cfg"
const TEST_TRACK_A := "user://historyroll_test_track_a.tres"
const TEST_TRACK_B := "user://historyroll_test_track_b.tres"

var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	_create_silent_track(TEST_TRACK_A)
	_create_silent_track(TEST_TRACK_B)

	var manager = AudioManagerScript.new()
	manager.settings_path = TEST_SETTINGS_PATH
	get_root().add_child(manager)
	await process_frame

	_check(AudioServer.get_bus_index("Music") >= 0, "Music bus is available")
	_check(manager.get_child_count() == 1 and manager.get_child(0) is AudioStreamPlayer, "one global music player is created")
	_check(manager.is_music_enabled(), "music defaults to enabled when no setting exists")
	var fallback_started: bool = manager.play_music(AudioManagerScript.MAIN_MENU_TRACK, 0.0)
	_check(fallback_started and manager.is_using_fallback_music(), "missing OGG files use audible built-in fallback music")
	_check(manager.is_music_playing(), "fallback music starts when Music is ON")
	var fallback_peak := 0.0
	for sample_index: int in range(400):
		fallback_peak = maxf(fallback_peak, absf(manager._sample_fallback_music(float(sample_index) / 200.0, "main_menu")))
	_check(fallback_peak >= 0.10 and fallback_peak <= 0.28, "fallback music has a clear but clipping-safe output level")

	var first_started: bool = manager.play_music(TEST_TRACK_A, 0.0)
	_check(first_started and manager.get_current_track_path() == TEST_TRACK_A, "a requested track starts")
	_check(manager.is_music_playing(), "the enabled track is playing")
	var original_stream: AudioStream = manager.get_child(0).stream
	var same_track_result: bool = manager.play_music(TEST_TRACK_A, 0.0)
	_check(same_track_result and manager.get_child(0).stream == original_stream, "requesting the same track does not reload or restart it")

	var second_started: bool = manager.play_music(TEST_TRACK_B, 0.0)
	_check(second_started and manager.get_current_track_path() == TEST_TRACK_B, "changing roles replaces the previous track")
	_check(manager.get_child_count() == 1, "track changes cannot create overlapping players")
	_check(int(manager.get_child(0).stream.loop_mode) == AudioStreamWAV.LOOP_FORWARD, "background tracks are configured to loop")

	var sfx_bus := AudioServer.get_bus_index("SFX")
	var previous_sfx_mute := AudioServer.is_bus_mute(sfx_bus) if sfx_bus >= 0 else false
	manager.set_music_enabled(false, true)
	_check(not manager.is_music_enabled() and not manager.is_music_playing(), "Music OFF stops global playback")
	_check(sfx_bus < 0 or AudioServer.is_bus_mute(sfx_bus) == previous_sfx_mute, "Music OFF does not change SFX")
	var config := ConfigFile.new()
	_check(config.load(TEST_SETTINGS_PATH) == OK and not bool(config.get_value("audio", "music_enabled", true)), "Music OFF persists in the existing config format")

	var selected_while_muted: bool = manager.play_music(TEST_TRACK_A, 0.0)
	_check(selected_while_muted and manager.get_current_track_path() == TEST_TRACK_A and not manager.is_music_playing(), "scene changes select tracks without audible playback while Music is OFF")
	manager.set_music_enabled(true, false)
	_check(manager.is_music_playing(), "Music ON resumes the track requested by the current scene")

	manager.stop_music(0.0)
	_check(manager.get_current_track_path().is_empty() and not manager.is_music_playing(), "stop_music clears the active track")
	original_stream = null
	manager.free()
	manager = null
	await process_frame
	_cleanup()
	call_deferred("_finish")


func _finish() -> void:
	print("AudioManager tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _create_silent_track(path: String) -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 8000
	stream.stereo = false
	var data := PackedByteArray()
	data.resize(8000)
	data.fill(128)
	stream.data = data
	ResourceSaver.save(stream, path)


func _check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS: %s" % message)
	else:
		failed += 1
		push_error("FAIL: %s" % message)


func _cleanup() -> void:
	for path: String in [TEST_SETTINGS_PATH, TEST_TRACK_A, TEST_TRACK_B]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

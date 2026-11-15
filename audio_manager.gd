extends Node

## Global, single-player background-music controller.
##
## Scene scripts request a track by path. Only this Autoload owns the music
## player, so changing scenes cannot create overlapping background tracks.

const DEFAULT_SETTINGS_PATH := "user://historyroll_settings.cfg"
const MAIN_MENU_TRACK := "res://assets/audio/music/main_menu.ogg"
const LEVEL_SELECT_TRACK := "res://assets/audio/music/level_select.ogg"
const GAMEPLAY_TRACK := "res://assets/audio/music/gameplay.ogg"
const VICTORY_TRACK := "res://assets/audio/music/victory.ogg"
const SILENCE_DB := -60.0

@export_range(-40.0, 6.0, 0.5) var music_volume_db := -8.0

var settings_path := DEFAULT_SETTINGS_PATH
var music_enabled := true
var current_track_path := ""

var _player: AudioStreamPlayer
var _fade_tween: Tween
var _transition_serial := 0
var _reported_missing_tracks: Dictionary = {}


func _ready() -> void:
	_ensure_music_bus()
	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.bus = "Music"
	_player.volume_db = SILENCE_DB
	add_child(_player)
	_load_music_setting()
	_apply_bus_mute()


func play_music(track_path: String, fade_duration := 0.6) -> bool:
	var normalized_path := track_path.strip_edges()
	if normalized_path.is_empty():
		stop_music(fade_duration)
		return true
	if not ResourceLoader.exists(normalized_path, "AudioStream"):
		if not _reported_missing_tracks.has(normalized_path):
			_reported_missing_tracks[normalized_path] = true
			push_warning("Background music is not installed yet: %s" % normalized_path)
		return false

	# Related scenes can request the same role without restarting its music.
	if normalized_path == current_track_path and _player.stream != null:
		if music_enabled and not _player.playing:
			_start_loaded_track(fade_duration)
		return true

	var next_stream := load(normalized_path) as AudioStream
	if next_stream == null:
		push_warning("Background music could not be loaded: %s" % normalized_path)
		return false
	_configure_loop(next_stream)

	_transition_serial += 1
	var serial := _transition_serial
	_kill_fade()
	if _player.playing and music_enabled and fade_duration > 0.0:
		_fade_tween = create_tween()
		_fade_tween.tween_property(_player, "volume_db", SILENCE_DB, fade_duration)
		_fade_tween.tween_callback(_finish_track_change.bind(serial, next_stream, normalized_path, fade_duration))
	else:
		_finish_track_change(serial, next_stream, normalized_path, fade_duration)
	return true


func stop_music(fade_duration := 0.6) -> void:
	_transition_serial += 1
	var serial := _transition_serial
	_kill_fade()
	if _player.playing and music_enabled and fade_duration > 0.0:
		_fade_tween = create_tween()
		_fade_tween.tween_property(_player, "volume_db", SILENCE_DB, fade_duration)
		_fade_tween.tween_callback(_finish_stop.bind(serial))
	else:
		_finish_stop(serial)


func _finish_track_change(serial: int, stream: AudioStream, track_path: String, fade_duration: float) -> void:
	if serial != _transition_serial:
		return
	_player.stop()
	_player.stream = stream
	current_track_path = track_path
	if music_enabled:
		_start_loaded_track(fade_duration)


func _finish_stop(serial: int) -> void:
	if serial != _transition_serial:
		return
	_player.stop()
	_player.stream = null
	current_track_path = ""


func set_music_enabled(enabled: bool, save_setting := true) -> void:
	music_enabled = enabled
	_apply_bus_mute()
	_transition_serial += 1
	_kill_fade()
	if music_enabled:
		if _player.stream != null and not _player.playing:
			_start_loaded_track(0.35)
	else:
		# Keep the requested stream/path, but stop its playback so a disabled
		# soundtrack never consumes resources or leaks across scene changes.
		_player.stop()
		_player.volume_db = SILENCE_DB
	if save_setting:
		_save_music_setting()


func is_music_enabled() -> bool:
	return music_enabled


func is_music_playing() -> bool:
	return _player != null and _player.playing and music_enabled


func get_current_track_path() -> String:
	return current_track_path


func _start_loaded_track(fade_duration: float) -> void:
	if _player.stream == null or not music_enabled:
		return
	_kill_fade()
	_player.volume_db = SILENCE_DB if fade_duration > 0.0 else music_volume_db
	_player.play()
	if fade_duration > 0.0:
		_fade_tween = create_tween()
		_fade_tween.tween_property(_player, "volume_db", music_volume_db, fade_duration)


func _kill_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null


func _configure_loop(stream: AudioStream) -> void:
	if _has_property(stream, &"loop"):
		stream.set("loop", true)
	elif _has_property(stream, &"loop_mode"):
		stream.set("loop_mode", AudioStreamWAV.LOOP_FORWARD)


func _has_property(object: Object, property_name: StringName) -> bool:
	for property: Dictionary in object.get_property_list():
		if property.get("name", &"") == property_name:
			return true
	return false


func _ensure_music_bus() -> void:
	if AudioServer.get_bus_index("Music") >= 0:
		return
	AudioServer.add_bus()
	var bus_index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_index, "Music")


func _apply_bus_mute() -> void:
	var bus_index := AudioServer.get_bus_index("Music")
	if bus_index >= 0:
		AudioServer.set_bus_mute(bus_index, not music_enabled)


func _load_music_setting() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		music_enabled = true
		return
	music_enabled = bool(config.get_value("audio", "music_enabled", true))


func _save_music_setting() -> bool:
	var config := ConfigFile.new()
	config.load(settings_path)
	config.set_value("audio", "music_enabled", music_enabled)
	var error := config.save(settings_path)
	if error != OK:
		push_warning("Unable to save HistoryRoll music setting: %s" % error_string(error))
		return false
	return true

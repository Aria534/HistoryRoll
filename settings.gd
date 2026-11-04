extends Control

const MAIN_MENU_SCENE := "res://main_menu_tscn.tscn"
const DEFAULT_SETTINGS_PATH := "user://historyroll_settings.cfg"

@onready var music_toggle: Button = %MusicToggle
@onready var sfx_toggle: Button = %SfxToggle
@onready var help_button: Button = %HelpButton
@onready var back_button: Button = %BackButton
@onready var how_to_play_overlay: Control = %HowToPlayOverlay
@onready var close_help_button: Button = %CloseHelpButton

var settings_path := DEFAULT_SETTINGS_PATH
var music_enabled := true
var sfx_enabled := true
var scene_change_handler: Callable


func _ready() -> void:
	_load_settings()
	_connect_once(music_toggle.toggled, _on_music_toggled)
	_connect_once(sfx_toggle.toggled, _on_sfx_toggled)
	_connect_once(help_button.pressed, _on_help_pressed)
	_connect_once(close_help_button.pressed, _on_close_help_pressed)
	_connect_once(back_button.pressed, _on_back_pressed)
	_refresh_controls()
	_apply_audio_settings()


func _connect_once(signal_value: Signal, callback: Callable) -> void:
	if not signal_value.is_connected(callback):
		signal_value.connect(callback)


func _on_music_toggled(enabled: bool) -> void:
	music_enabled = enabled
	_apply_bus_setting("Music", music_enabled)
	_save_settings()
	_refresh_controls()


func _on_sfx_toggled(enabled: bool) -> void:
	sfx_enabled = enabled
	_apply_bus_setting("SFX", sfx_enabled)
	_save_settings()
	_refresh_controls()


func _on_help_pressed() -> void:
	how_to_play_overlay.visible = true
	close_help_button.grab_focus()


func _on_close_help_pressed() -> void:
	how_to_play_overlay.visible = false
	help_button.grab_focus()


func _on_back_pressed() -> void:
	if scene_change_handler.is_valid():
		scene_change_handler.call(MAIN_MENU_SCENE)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _refresh_controls() -> void:
	music_toggle.set_pressed_no_signal(music_enabled)
	sfx_toggle.set_pressed_no_signal(sfx_enabled)
	music_toggle.text = "MUSIC: ON" if music_enabled else "MUSIC: OFF"
	sfx_toggle.text = "SOUND EFFECTS: ON" if sfx_enabled else "SOUND EFFECTS: OFF"


func _apply_audio_settings() -> void:
	_apply_bus_setting("Music", music_enabled)
	_apply_bus_setting("SFX", sfx_enabled)


func _apply_bus_setting(bus_name: String, enabled: bool) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_mute(bus_index, not enabled)


func _save_settings() -> bool:
	var config := ConfigFile.new()
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("audio", "sfx_enabled", sfx_enabled)
	var error := config.save(settings_path)
	if error != OK:
		push_warning("Unable to save HistoryRoll settings: %s" % error_string(error))
		return false
	return true


func _load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(settings_path)
	if error != OK:
		music_enabled = true
		sfx_enabled = true
		return
	music_enabled = bool(config.get_value("audio", "music_enabled", true))
	sfx_enabled = bool(config.get_value("audio", "sfx_enabled", true))

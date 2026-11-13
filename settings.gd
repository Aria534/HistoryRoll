extends Control

const MAIN_MENU_SCENE := "res://main_menu_tscn.tscn"
const DEFAULT_SETTINGS_PATH := "user://historyroll_settings.cfg"
const TITLE_FONT: FontFile = preload("res://assets/fonts/TitanOne-Regular.ttf")
const BODY_FONT: FontFile = preload("res://assets/fonts/Roboto-Variable.ttf")
const HELP_ROWS := [
	["1", "?", "A question appears first."],
	["2", "ABC", "Answer the question before rolling the dice."],
	["3", "+10", "A correct answer gives +10 points."],
	["4", "-2", "A wrong answer deducts 2 points, but never below zero."],
	["5", "DIE", "Roll the dice after answering."],
	["6", "H", "Move your Filipino hero by the dice result."],
	["7", "UP", "Ladders move you forward."],
	["8", "SNK", "Snakes move you backward unless you have a shield."],
	["9", "SH", "One shield protects you from one snake."],
	["10", "STAR", "Bonus Tiles award additional points."],
	["11", "FLAG", "Reach the final tile with an exact dice roll."],
	["12", "OPEN", "Complete a level to unlock the next level."],
]

@onready var music_toggle: Button = %MusicToggle
@onready var sfx_toggle: Button = %SfxToggle
@onready var music_state_label: Label = %MusicStateLabel
@onready var sfx_state_label: Label = %SfxStateLabel
@onready var music_switch_track: Panel = %MusicSwitchTrack
@onready var sfx_switch_track: Panel = %SfxSwitchTrack
@onready var music_switch_knob: PanelContainer = %MusicSwitchKnob
@onready var sfx_switch_knob: PanelContainer = %SfxSwitchKnob
@onready var help_button: Button = %HelpButton
@onready var back_button: Button = %BackButton
@onready var how_to_play_overlay: Control = %HowToPlayOverlay
@onready var help_rows: VBoxContainer = %HelpRows
@onready var close_help_button: Button = %CloseHelpButton

var settings_path := DEFAULT_SETTINGS_PATH
var music_enabled := true
var sfx_enabled := true
var scene_change_handler: Callable


func _ready() -> void:
	_load_settings()
	_build_help_rows()
	_connect_once(music_toggle.toggled, _on_music_toggled)
	_connect_once(sfx_toggle.toggled, _on_sfx_toggled)
	_connect_once(help_button.pressed, _on_help_pressed)
	_connect_once(close_help_button.pressed, _on_close_help_pressed)
	_connect_once(back_button.pressed, _on_back_pressed)
	_refresh_controls()
	_apply_audio_settings()


func _build_help_rows() -> void:
	if help_rows.get_child_count() > 0:
		return
	for row_data: Array in HELP_ROWS:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0.0, 46.0)
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		help_rows.add_child(row)

		var number_label := _make_help_label(str(row_data[0]), TITLE_FONT, 22, Color(1.0, 0.92, 0.68, 1.0))
		number_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		number_label.size_flags_stretch_ratio = 0.12
		number_label.add_theme_color_override("font_outline_color", Color(0.22, 0.03, 0.01, 1.0))
		number_label.add_theme_constant_override("outline_size", 4)
		number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(number_label)

		var icon_label := _make_help_label(str(row_data[1]), TITLE_FONT, 15, Color(0.42, 0.10, 0.03, 1.0))
		icon_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon_label.size_flags_stretch_ratio = 0.08
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(icon_label)

		var icon_spacer := Control.new()
		icon_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		icon_spacer.size_flags_stretch_ratio = 0.02
		icon_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon_spacer)

		var description := _make_help_label(str(row_data[2]), BODY_FONT, 18, Color(0.18, 0.075, 0.025, 1.0))
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		description.size_flags_stretch_ratio = 0.78
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(description)


func _make_help_label(label_text: String, font: Font, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = label_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


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
	music_state_label.text = "MUSIC: ON" if music_enabled else "MUSIC: OFF"
	sfx_state_label.text = "SOUND EFFECTS: ON" if sfx_enabled else "SOUND EFFECTS: OFF"
	music_toggle.tooltip_text = music_state_label.text
	sfx_toggle.tooltip_text = sfx_state_label.text
	_update_switch_visual(music_switch_track, music_switch_knob, music_enabled)
	_update_switch_visual(sfx_switch_track, sfx_switch_knob, sfx_enabled)


func _update_switch_visual(track: Panel, knob: PanelContainer, enabled: bool) -> void:
	track.modulate = Color.WHITE if enabled else Color(0.62, 0.62, 0.58, 1.0)
	knob.anchor_left = 0.54 if enabled else 0.04
	knob.anchor_right = 0.96 if enabled else 0.46
	knob.offset_left = 0.0
	knob.offset_right = 0.0


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

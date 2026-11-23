extends Control

const MAIN_MENU_SCENE := "res://main_menu_tscn.tscn"
const DEFAULT_SETTINGS_PATH := "user://historyroll_settings.cfg"
const TITLE_FONT: FontFile = preload("res://assets/fonts/TitanOne-Regular.ttf")
const BODY_FONT: FontFile = preload("res://assets/fonts/Roboto-Variable.ttf")
# All live controls share the artwork coordinate space; the panel never stretches.
const SETTINGS_DESIGN_SIZE := Vector2(1086, 1448)
const HowToPlayPanel = preload("res://how_to_play_panel.gd")
const HELP_ROWS := HowToPlayPanel.RULES

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
var _settings_ui_scale := 1.0


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
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_music"):
		audio_manager.play_music("res://assets/audio/music/main_menu.ogg", 0.45)
	resized.connect(_apply_responsive_layout)
	_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var safe_rect := Rect2(Vector2.ZERO, size).grow(-minf(16.0, size.x * 0.02))
	if OS.has_feature("android"):
		var screen_size := Vector2(DisplayServer.screen_get_size())
		var device_safe := Rect2(DisplayServer.get_display_safe_area())
		if screen_size.x > 0.0 and screen_size.y > 0.0 and device_safe.has_area():
			safe_rect = Rect2(device_safe.position / screen_size * size, device_safe.size / screen_size * size)
	_settings_ui_scale = minf(safe_rect.size.x / SETTINGS_DESIGN_SIZE.x, safe_rect.size.y / SETTINGS_DESIGN_SIZE.y)
	var frame_size := SETTINGS_DESIGN_SIZE * _settings_ui_scale
	var frame_rect := Rect2(safe_rect.get_center() - frame_size * 0.5, frame_size)
	var frame: TextureRect = %SettingsFrame
	frame.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	frame.position = frame_rect.position
	frame.size = frame_rect.size
	_place_in_frame($Title, frame_rect, Rect2(0.20, 0.15, 0.60, 0.09))
	_place_in_frame($Controls, frame_rect, Rect2(0.145, 0.32, 0.71, 0.29))
	_place_in_frame(back_button, frame_rect, Rect2(0.315, 0.81, 0.37, 0.075))
	$Title.add_theme_font_size_override("font_size", maxi(24, roundi(92.0 * _settings_ui_scale)))
	$Title.add_theme_constant_override("outline_size", maxi(2, roundi(6.0 * _settings_ui_scale)))
	$Controls.add_theme_constant_override("separation", roundi(29.0 * _settings_ui_scale))
	for button: Button in [music_toggle, sfx_toggle]:
		button.custom_minimum_size.y = frame_size.y * 0.078
		var content := button.get_child(0) as MarginContainer
		content.add_theme_constant_override("margin_left", roundi(30.0 * _settings_ui_scale))
		content.add_theme_constant_override("margin_right", roundi(24.0 * _settings_ui_scale))
		content.add_theme_constant_override("margin_top", roundi(14.0 * _settings_ui_scale))
		content.add_theme_constant_override("margin_bottom", roundi(14.0 * _settings_ui_scale))
		var row := content.get_child(0) as HBoxContainer
		row.add_theme_constant_override("separation", roundi(18.0 * _settings_ui_scale))
		(row.get_node("Icon") as TextureRect).custom_minimum_size.x = 72.0 * _settings_ui_scale
	for track: Panel in [music_switch_track, sfx_switch_track]:
		track.custom_minimum_size = Vector2(142.0, 72.0) * _settings_ui_scale
		track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	help_button.custom_minimum_size.y = frame_size.y * 0.084
	for button: Button in [help_button, back_button]:
		var row := button.get_node("Content/Row") as HBoxContainer
		var caption := row.get_node("Caption") as Label
		var icon := row.get_node("Icon") as TextureRect
		var is_back := button == back_button
		caption.add_theme_font_size_override("font_size", maxi(14, roundi((48.0 if is_back else 46.0) * _settings_ui_scale)))
		icon.custom_minimum_size = Vector2(60.0 if is_back else 86.0, 60.0) * _settings_ui_scale
		row.add_theme_constant_override("separation", roundi(18.0 * _settings_ui_scale))
	_fit_audio_labels.call_deferred()


func _place_in_frame(control: Control, frame: Rect2, ratios: Rect2) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	control.position = frame.position + ratios.position * frame.size
	control.size = ratios.size * frame.size


func _fit_audio_labels() -> void:
	for label: Label in [music_state_label, sfx_state_label]:
		var base_size := 44.0 if label == music_state_label else 32.0
		var font_size := maxi(12, roundi(base_size * _settings_ui_scale))
		var font := label.get_theme_font("font")
		while font_size > 10 and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x:
			font_size -= 1
		label.add_theme_font_size_override("font_size", font_size)


func _build_help_rows() -> void:
	$HowToPlayOverlay/HelpAspect/Canvas.build_rows(HELP_ROWS)


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
	_sync_audio_manager_music_setting()
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
	sfx_state_label.text = "SFX SOUND EFFECTS: ON" if sfx_enabled else "SFX SOUND EFFECTS: OFF"
	music_toggle.tooltip_text = music_state_label.text
	sfx_toggle.tooltip_text = sfx_state_label.text
	_update_switch_visual(music_switch_track, music_switch_knob, music_enabled)
	_update_switch_visual(sfx_switch_track, sfx_switch_knob, sfx_enabled)
	_fit_audio_labels.call_deferred()


func _update_switch_visual(track: Panel, knob: PanelContainer, enabled: bool) -> void:
	track.modulate = Color.WHITE if enabled else Color(0.62, 0.62, 0.58, 1.0)
	knob.anchor_left = 0.54 if enabled else 0.04
	knob.anchor_right = 0.96 if enabled else 0.46
	knob.offset_left = 0.0
	knob.offset_right = 0.0


func _apply_audio_settings() -> void:
	_sync_audio_manager_music_setting()
	_apply_bus_setting("Music", music_enabled)
	_apply_bus_setting("SFX", sfx_enabled)


func _sync_audio_manager_music_setting() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("set_music_enabled"):
		# Settings owns the combined Music/SFX config write. The manager only
		# applies the live global music state here, avoiding duplicate saves.
		audio_manager.call("set_music_enabled", music_enabled, false)
	if audio_manager != null and audio_manager.has_method("set_sfx_enabled"):
		audio_manager.call("set_sfx_enabled", sfx_enabled, false)


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

extends Control

const DESIGN_SIZE := Vector2(1086, 1448)
const BUTTON_LABELS := ["Start Game", "Hero Cards", "Settings", "Quit"]

@export_file("*.tscn") var start_game_scene: String = "res://player_name_entry.tscn"
@export_file("*.tscn") var hero_cards_scene: String = "res://hero_cards.tscn"
@export_file("*.tscn") var settings_scene: String = "res://settings.tscn"

@export var hover_scale: float = 1.03
@export var press_scale: float = 0.97
@export var anim_time: float = 0.12
# Retained for compatibility with previously saved scene overrides. Main Menu
# buttons now match Level Selection and remain fully opaque while scaling.
@export_range(0.0, 1.0, 0.01) var hover_overlay_alpha: float = 1.0
@export_range(0.0, 1.0, 0.01) var press_overlay_alpha: float = 1.0

@onready var start_button := get_node_or_null("StartButton") as TextureButton
@onready var hero_cards_button := get_node_or_null("HeroCardsButton") as TextureButton
@onready var settings_button := get_node_or_null("SettingsButton") as TextureButton
@onready var quit_button := get_node_or_null("QuitButton") as TextureButton
@onready var menu_logo: TextureRect = %MenuLogo
@onready var selection_arrow: TextureRect = %SelectionArrow
@onready var live_background: AnimatedSprite2D = $LiveBackground
@onready var menu_explorers: TextureRect = %MenuExplorers

var _button_tweens: Dictionary = {}
var _hovered_buttons: Dictionary = {}
var _button_rest_positions: Dictionary = {}
var _selected_button: TextureButton
var _scene_transition_pending := false
var scene_change_handler: Callable
var quit_handler: Callable


func _ready() -> void:
	_request_music("res://assets/audio/music/main_menu.ogg")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not _validate_required_buttons():
		return
	_setup_button(start_button, _on_start_pressed)
	_setup_button(hero_cards_button, _on_hero_cards_pressed)
	_setup_button(settings_button, _on_settings_pressed)
	_setup_button(quit_button, _on_quit_pressed)
	resized.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	_select_button(start_button)


func _apply_responsive_layout() -> void:
	if size.x <= 0.0 or size.y <= 0.0 or not _validate_required_buttons():
		return
	var safe_rect := _get_safe_rect()
	var ui_scale := minf(safe_rect.size.x / DESIGN_SIZE.x, safe_rect.size.y / DESIGN_SIZE.y)
	var extra_height := maxf(0.0, safe_rect.size.y - DESIGN_SIZE.y * ui_scale)
	var top := safe_rect.position.y + extra_height * 0.25
	var logo_width := minf(safe_rect.size.x * 0.80, 760.0 * ui_scale)
	var logo_aspect := menu_logo.texture.get_size().aspect()
	menu_logo.size = Vector2(logo_width, logo_width / logo_aspect)
	menu_logo.position = Vector2(safe_rect.get_center().x - logo_width * 0.5, top + 12.0 * ui_scale)
	var button_size := Vector2(520.0, 104.0) * ui_scale
	var button_top := menu_logo.position.y + menu_logo.size.y + 28.0 * ui_scale + extra_height * 0.08
	var button_pitch := 124.0 * ui_scale + extra_height * 0.035
	var buttons: Array[TextureButton] = [start_button, hero_cards_button, settings_button, quit_button]
	for index: int in buttons.size():
		var button := buttons[index]
		var tween: Tween = _button_tweens.get(button)
		if tween != null and tween.is_valid():
			tween.kill()
		button.scale = Vector2.ONE
		button.self_modulate = Color.WHITE
		button.get_node("PlankArt").self_modulate = Color.WHITE
		button.position = Vector2(safe_rect.get_center().x - button_size.x * 0.5, button_top + index * button_pitch)
		button.size = button_size
		_button_rest_positions[button] = button.position
		button.pivot_offset = button_size * 0.5
		var label := button.get_node("Caption") as Label
		var font := label.get_theme_font("font")
		var font_size := maxi(18, roundi(66.0 * ui_scale))
		while font_size > 18 and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > button_size.x * 0.61:
			font_size -= 1
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_constant_override("outline_size", maxi(1, roundi(2.0 * ui_scale)))
		label.add_theme_constant_override("shadow_offset_y", maxi(1, roundi(3.0 * ui_scale)))
	selection_arrow.size = Vector2(27.0, 36.0) * ui_scale
	_position_selection_arrow()
	# The background carries the path and lantern; the two complete explorers
	# remain separate, keep their aspect ratio and leave the path visible below.
	var texture := live_background.sprite_frames.get_frame_texture("default", 0)
	var fit_scale := maxf(size.x / texture.get_width(), size.y / texture.get_height())
	live_background.scale = Vector2.ONE * fit_scale
	live_background.position = size * 0.5
	var foreground_width := minf(safe_rect.size.x * 0.80, 700.0 * ui_scale + minf(extra_height * 0.20, 100.0 * ui_scale))
	var foreground_height := foreground_width / menu_explorers.texture.get_size().aspect()
	menu_explorers.size = Vector2(foreground_width, foreground_height)
	var foreground_bottom := safe_rect.end.y - 140.0 * ui_scale
	var foreground_top := maxf(quit_button.position.y + button_size.y + 36.0 * ui_scale, foreground_bottom - foreground_height)
	menu_explorers.position = Vector2(safe_rect.get_center().x + 36.0 * ui_scale - foreground_width * 0.5, foreground_top)


func _get_safe_rect() -> Rect2:
	var result := Rect2(Vector2.ZERO, size)
	if OS.has_feature("android"):
		var screen_size := Vector2(DisplayServer.screen_get_size())
		var safe_area := Rect2(DisplayServer.get_display_safe_area())
		if screen_size.x > 0.0 and screen_size.y > 0.0 and safe_area.has_area():
			result = Rect2(safe_area.position / screen_size * size, safe_area.size / screen_size * size)
	return result.grow(-minf(16.0, size.x * 0.02))


func _select_button(button: TextureButton) -> void:
	_selected_button = button
	_position_selection_arrow()


func _position_selection_arrow() -> void:
	if _selected_button == null:
		return
	var rest: Vector2 = _button_rest_positions.get(_selected_button, _selected_button.position)
	selection_arrow.position = Vector2(rest.x - selection_arrow.size.x * 1.65, rest.y + (_selected_button.size.y - selection_arrow.size.y) * 0.5)


func _request_music(track_path: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_music"):
		audio_manager.call("play_music", track_path, 0.6)


func _validate_required_buttons() -> bool:
	var missing_buttons: Array[String] = []
	if start_button == null:
		missing_buttons.append("StartButton")
	if hero_cards_button == null:
		missing_buttons.append("HeroCardsButton")
	if settings_button == null:
		missing_buttons.append("SettingsButton")
	if quit_button == null:
		missing_buttons.append("QuitButton")
	if not missing_buttons.is_empty():
		push_error("Main Menu is missing required TextureButton nodes: %s" % ", ".join(missing_buttons))
		return false
	return true


func _setup_button(button: TextureButton, callback: Callable) -> void:
	button.disabled = false
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.button_mask = MOUSE_BUTTON_MASK_LEFT
	button.self_modulate.a = 1.0
	button.scale = Vector2.ONE
	button.pivot_offset = button.size / 2.0

	var resize_callback := _update_button_pivot.bind(button)
	var mouse_entered_callback := _on_button_mouse_entered.bind(button)
	var mouse_exited_callback := _on_button_mouse_exited.bind(button)
	var button_down_callback := _on_button_down.bind(button)
	var button_up_callback := _on_button_up.bind(button)
	var focus_callback := _select_button.bind(button)
	if not button.resized.is_connected(resize_callback):
		button.resized.connect(resize_callback)
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)
	if not button.mouse_entered.is_connected(mouse_entered_callback):
		button.mouse_entered.connect(mouse_entered_callback)
	if not button.mouse_exited.is_connected(mouse_exited_callback):
		button.mouse_exited.connect(mouse_exited_callback)
	if not button.button_down.is_connected(button_down_callback):
		button.button_down.connect(button_down_callback)
	if not button.button_up.is_connected(button_up_callback):
		button.button_up.connect(button_up_callback)
	if not button.focus_entered.is_connected(focus_callback):
		button.focus_entered.connect(focus_callback)


func _update_button_pivot(button: TextureButton) -> void:
	button.pivot_offset = button.size / 2.0


func _on_button_mouse_entered(button: TextureButton) -> void:
	_hovered_buttons[button] = true
	_select_button(button)
	if not button.button_pressed:
		_animate_button(button, hover_scale)


func _on_button_mouse_exited(button: TextureButton) -> void:
	_hovered_buttons[button] = false
	if not button.button_pressed:
		_animate_button(button, 1.0)


func _on_button_down(button: TextureButton) -> void:
	_select_button(button)
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_sfx"):
		audio_manager.call("play_sfx", "res://assets/audio/sfx/menu_press.ogg", "menu_press")
	_animate_button(button, press_scale)


func _on_button_up(button: TextureButton) -> void:
	# Touch devices return to normal size even when touch-to-mouse emulation leaves
	# a synthetic hover active. Desktop mouse input keeps its hover scale.
	var target_scale := 1.0
	if not DisplayServer.is_touchscreen_available() and _hovered_buttons.get(button, false):
		target_scale = hover_scale
	_animate_button(button, target_scale)


func _animate_button(button: TextureButton, target_scale: float) -> void:
	# Stop this button's previous animation so rapid input cannot stack tweens.
	var current_tween: Tween = _button_tweens.get(button)
	if current_tween != null and current_tween.is_valid():
		current_tween.kill()

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE * target_scale, anim_time)
	tween.parallel().tween_property(button, "self_modulate", Color(0.82, 0.88, 0.96) if target_scale == press_scale else Color.WHITE, anim_time)
	tween.parallel().tween_property(button.get_node("PlankArt"), "self_modulate", Color(0.82, 0.88, 0.96) if target_scale == press_scale else Color.WHITE, anim_time)
	var rest: Vector2 = _button_rest_positions.get(button, button.position)
	var press_offset := Vector2(0, maxf(2.0, button.size.y * 0.04)) if target_scale == press_scale else Vector2.ZERO
	tween.parallel().tween_property(button, "position", rest + press_offset, anim_time)
	_button_tweens[button] = tween


func _open_scene(path: String) -> void:
	if _scene_transition_pending:
		return
	if path.is_empty():
		push_error("Main Menu cannot open an empty scene path.")
		return
	if not ResourceLoader.exists(path):
		push_error("Main Menu scene was not found: %s" % path)
		return
	_scene_transition_pending = true
	_set_buttons_disabled(true)
	if scene_change_handler.is_valid():
		scene_change_handler.call(path)
		return
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		_scene_transition_pending = false
		_set_buttons_disabled(false)
		push_error("Main Menu could not open scene: %s" % path)


func _set_buttons_disabled(disabled: bool) -> void:
	for button: TextureButton in [start_button, hero_cards_button, settings_button, quit_button]:
		if button != null:
			button.disabled = disabled


func _on_start_pressed() -> void:
	_open_scene(start_game_scene)


func _on_hero_cards_pressed() -> void:
	_open_scene(hero_cards_scene)


func _on_settings_pressed() -> void:
	_open_scene(settings_scene)


func _on_quit_pressed() -> void:
	if _scene_transition_pending:
		return
	_scene_transition_pending = true
	_set_buttons_disabled(true)
	if quit_handler.is_valid():
		quit_handler.call()
	else:
		get_tree().quit()

extends Control

@export_file("*.tscn") var start_game_scene: String = "res://level_selection.tscn"
@export_file("*.tscn") var hero_cards_scene: String = "res://hero_cards.tscn"
@export_file("*.tscn") var settings_scene: String = "res://settings.tscn"

@export var hover_scale: float = 1.05
@export var press_scale: float = 0.95
@export var anim_time: float = 0.15

@onready var start_button := get_node_or_null("StartButton") as TextureButton
@onready var hero_cards_button := get_node_or_null("HeroCardsButton") as TextureButton
@onready var settings_button := get_node_or_null("SettingsButton") as TextureButton
@onready var quit_button := get_node_or_null("QuitButton") as TextureButton

var _button_tweens: Dictionary = {}
var _hovered_buttons: Dictionary = {}
var _scene_transition_pending := false
var scene_change_handler: Callable
var quit_handler: Callable


func _ready() -> void:
	# Siguroha nga ang root mo-cover sa tibuok screen ug dili mo-block sa click
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if not _validate_required_buttons():
		return
	_setup_button(start_button, _on_start_pressed)
	_setup_button(hero_cards_button, _on_hero_cards_pressed)
	_setup_button(settings_button, _on_settings_pressed)
	_setup_button(quit_button, _on_quit_pressed)


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
	button.pivot_offset = button.size / 2.0

	var resize_callback := _update_button_pivot.bind(button)
	var mouse_entered_callback := _on_button_mouse_entered.bind(button)
	var mouse_exited_callback := _on_button_mouse_exited.bind(button)
	var button_down_callback := _on_button_down.bind(button)
	var button_up_callback := _on_button_up.bind(button)
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


func _update_button_pivot(button: TextureButton) -> void:
	button.pivot_offset = button.size / 2.0


func _on_button_mouse_entered(button: TextureButton) -> void:
	_hovered_buttons[button] = true
	if not button.button_pressed:
		_animate_button(button, hover_scale)


func _on_button_mouse_exited(button: TextureButton) -> void:
	_hovered_buttons[button] = false
	if not button.button_pressed:
		_animate_button(button, 1.0)


func _on_button_down(button: TextureButton) -> void:
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

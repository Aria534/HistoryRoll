extends Control

const MAIN_MENU_SCENE: String = "res://main_menu_tscn.tscn"
const STORY_MODE_SCENE: String = "res://story_mode.tscn"
const LevelCatalog = preload("res://level_catalog.gd")

@export var hover_scale: float = 1.03
@export var press_scale: float = 0.97
@export var animation_time: float = 0.12

@onready var level_list: VBoxContainer = %LevelList
@onready var selection_label: Label = %SelectionLabel
@onready var back_button: Button = %BackButton
@onready var play_button: Button = %PlayButton

var selected_level_id: int = 0
var level_buttons: Dictionary = {}
var button_tweens: Dictionary = {}
var hovered_buttons: Dictionary = {}


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	play_button.pressed.connect(_on_play_pressed)
	_setup_animated_button(back_button)
	_setup_animated_button(play_button)
	ProgressManager.progress_changed.connect(_refresh_levels)
	_refresh_levels()


func _refresh_levels() -> void:
	for child: Node in level_list.get_children():
		child.queue_free()
	level_buttons.clear()

	for level: Dictionary in LevelCatalog.get_levels():
		var level_id := int(level.get("id", 0))
		var button := Button.new()
		button.name = "Level%dButton" % level_id
		button.custom_minimum_size = Vector2(0, 126)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 30)
		button.disabled = not ProgressManager.is_level_unlocked(level_id)
		button.text = _get_level_button_text(level, button.disabled)
		button.pressed.connect(_on_level_pressed.bind(level_id))
		level_list.add_child(button)
		level_buttons[level_id] = button
		_setup_animated_button(button)

	var preferred_level: int = ProgressManager.selected_level
	if level_buttons.has(preferred_level) and ProgressManager.is_level_unlocked(preferred_level):
		_select_level(preferred_level)
	else:
		selected_level_id = 0
		selection_label.text = "Select an unlocked level"
		play_button.disabled = true


func _get_level_button_text(level: Dictionary, locked: bool) -> String:
	var title := str(level.get("title", "Level"))
	if locked:
		return "🔒  %s\nLOCKED" % title.to_upper()
	if ProgressManager.is_level_completed(int(level.get("id", 0))):
		return "%s\nCOMPLETED" % title.to_upper()
	return "%s\nAVAILABLE" % title.to_upper()


func _on_level_pressed(level_id: int) -> void:
	if not ProgressManager.is_level_unlocked(level_id):
		selection_label.text = "That level is still locked."
		return
	_select_level(level_id)


func _select_level(level_id: int) -> void:
	if not ProgressManager.select_level(level_id):
		return

	selected_level_id = level_id
	play_button.disabled = false
	selection_label.text = "Selected: Level %d" % level_id
	for key: Variant in level_buttons:
		var button: Button = level_buttons[key]
		button.modulate = Color(1.0, 0.88, 0.42) if int(key) == level_id else Color.WHITE


func _on_play_pressed() -> void:
	if selected_level_id < 1 or not ProgressManager.is_level_unlocked(selected_level_id):
		selection_label.text = "Select an unlocked level first."
		return
	if not ResourceLoader.exists(STORY_MODE_SCENE):
		push_error("Story Mode scene is missing: %s" % STORY_MODE_SCENE)
		return
	get_tree().change_scene_to_file(STORY_MODE_SCENE)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _setup_animated_button(button: Button) -> void:
	button.pivot_offset = button.size / 2.0
	button.resized.connect(func(): button.pivot_offset = button.size / 2.0)
	button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
	button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
	button.button_down.connect(_animate_button.bind(button, press_scale))
	button.button_up.connect(_on_button_up.bind(button))


func _on_button_mouse_entered(button: Button) -> void:
	hovered_buttons[button] = true
	if not button.button_pressed:
		_animate_button(button, hover_scale)


func _on_button_mouse_exited(button: Button) -> void:
	hovered_buttons[button] = false
	if not button.button_pressed:
		_animate_button(button, 1.0)


func _on_button_up(button: Button) -> void:
	var target_scale := 1.0
	if not DisplayServer.is_touchscreen_available() and hovered_buttons.get(button, false):
		target_scale = hover_scale
	_animate_button(button, target_scale)


func _animate_button(button: Button, target_scale: float) -> void:
	var current_tween: Tween = button_tweens.get(button)
	if current_tween != null and current_tween.is_valid():
		current_tween.kill()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE * target_scale, animation_time)
	button_tweens[button] = tween

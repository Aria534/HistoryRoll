extends Control

@export_file("*.tscn") var start_game_scene: String = "res://level_selection.tscn"
@export_file("*.tscn") var hero_cards_scene: String = ""
@export_file("*.tscn") var achievement_scene: String = ""

@export var hover_scale: float = 1.05
@export var press_scale: float = 0.95
@export var anim_time: float = 0.15

@onready var start_button: TextureButton = $StartButton
@onready var hero_cards_button: TextureButton = $HeroCardsButton
@onready var achievement_button: TextureButton = $AchievementButton
@onready var quit_button: TextureButton = $QuitButton

var _button_tweens: Dictionary = {}
var _hovered_buttons: Dictionary = {}


func _ready() -> void:
	# Siguroha nga ang root mo-cover sa tibuok screen ug dili mo-block sa click
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_setup_button(start_button, _on_start_pressed)
	_setup_button(hero_cards_button, _on_hero_cards_pressed)
	_setup_button(achievement_button, _on_achievement_pressed)
	_setup_button(quit_button, _on_quit_pressed)


func _setup_button(button: TextureButton, callback: Callable) -> void:
	button.disabled = false
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.button_mask = MOUSE_BUTTON_MASK_LEFT
	button.pivot_offset = button.size / 2.0
	button.resized.connect(func(): button.pivot_offset = button.size / 2.0)

	button.pressed.connect(callback)
	button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
	button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
	button.button_down.connect(_on_button_down.bind(button))
	button.button_up.connect(_on_button_up.bind(button))


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
	if path.is_empty():
		print("Walay scene nga na-assign.")
		return
	if not ResourceLoader.exists(path):
		print("Scene wala makita: ", path)
		return
	get_tree().change_scene_to_file(path)


func _on_start_pressed() -> void:
	print("START PRESSED")
	_open_scene(start_game_scene)


func _on_hero_cards_pressed() -> void:
	_open_scene(hero_cards_scene)


func _on_achievement_pressed() -> void:
	_open_scene(achievement_scene)


func _on_quit_pressed() -> void:
	get_tree().quit()

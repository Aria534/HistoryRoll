extends Control

const MAIN_MENU_SCENE := "res://main_menu_tscn.tscn"

@export_range(0.0, 5.0, 0.05) var fade_in_duration := 0.45
@export_range(0.0, 5.0, 0.05) var hold_duration := 1.35
@export_range(0.0, 5.0, 0.05) var fade_out_duration := 0.45
@export_range(0.0, 5.0, 0.05) var minimum_skip_delay := 0.45

@onready var presentation: Control = %Presentation
@onready var logo: TextureRect = %Logo
@onready var fade_overlay: ColorRect = %FadeOverlay

var scene_change_handler: Callable
var _elapsed := 0.0
var _transitioning := false
var _sequence_tween: Tween


func _ready() -> void:
	fade_overlay.show()
	fade_overlay.modulate.a = 1.0
	presentation.modulate.a = 0.0
	logo.scale = Vector2(0.9, 0.9)
	call_deferred("_start_sequence")


func _process(delta: float) -> void:
	_elapsed += delta


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning or _elapsed < minimum_skip_delay:
		return
	var requested_skip := false
	if event is InputEventScreenTouch:
		requested_skip = event.pressed
	elif event is InputEventMouseButton:
		requested_skip = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventKey:
		requested_skip = event.pressed and not event.echo
	if requested_skip:
		get_viewport().set_input_as_handled()
		skip_splash()


func _start_sequence() -> void:
	_set_logo_pivot()
	_sequence_tween = create_tween().set_parallel(true)
	_sequence_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_sequence_tween.tween_property(fade_overlay, "modulate:a", 0.0, fade_in_duration)
	_sequence_tween.tween_property(presentation, "modulate:a", 1.0, fade_in_duration)
	_sequence_tween.tween_property(logo, "scale", Vector2.ONE, fade_in_duration)
	_sequence_tween.chain().tween_interval(hold_duration)
	_sequence_tween.chain().tween_callback(skip_splash)


func skip_splash() -> void:
	if _transitioning:
		return
	_transitioning = true
	if _sequence_tween != null and _sequence_tween.is_valid():
		_sequence_tween.kill()
	fade_overlay.show()
	var fade := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fade.tween_property(fade_overlay, "modulate:a", 1.0, fade_out_duration)
	fade.tween_callback(_open_main_menu)


func _open_main_menu() -> void:
	if scene_change_handler.is_valid():
		scene_change_handler.call(MAIN_MENU_SCENE)
		return
	var error := get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	if error != OK:
		_transitioning = false
		push_error("Unable to open the HistoryRoll Main Menu: %s" % error)


func _set_logo_pivot() -> void:
	logo.pivot_offset = logo.size * 0.5

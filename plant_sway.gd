extends Node2D

@export_node_path("AnimatedSprite2D") var background_path: NodePath = NodePath("../LiveBackground")
@export_range(0.0, 2.0, 0.05) var sway_strength: float = 1.0
@export_range(0.1, 2.5, 0.05) var sway_speed: float = 1.15
@export_range(0.0, 16.0, 0.5) var horizontal_displacement: float = 6.5
@export var motion_enabled: bool = true:
	set(value):
		motion_enabled = value
		set_process(value)
		if not value:
			_restore_neutral_pose()

const PLANT_SETTINGS := {
	"PlantTopLeft": {"degrees": 3.0, "speed": 0.92, "phase": 0.15, "horizontal": 0.82},
	"PlantTopRight": {"degrees": 3.5, "speed": 0.84, "phase": 1.55, "horizontal": 0.78},
	"PlantLeft": {"degrees": 0.65, "speed": 0.78, "phase": 2.45, "horizontal": 1.0},
	"PlantRight": {"degrees": 0.75, "speed": 0.74, "phase": 3.75, "horizontal": 1.05},
	"PlantBottomLeft": {"degrees": 0.45, "speed": 0.96, "phase": 4.55, "horizontal": 0.9},
	"PlantBottomRight": {"degrees": 0.55, "speed": 0.88, "phase": 5.6, "horizontal": 0.96},
}

var _background: AnimatedSprite2D
var _base_positions: Dictionary = {}
var _base_rotations: Dictionary = {}
var _elapsed := 0.0


func _ready() -> void:
	_background = get_node_or_null(background_path) as AnimatedSprite2D
	if _background == null:
		push_warning("AnimatedPlants could not find LiveBackground; foliage animation is disabled.")
		set_process(false)
		return

	for child in get_children():
		if child is Sprite2D:
			child.set_meta("main_menu_foliage", true)
			_base_positions[child] = child.position
			_base_rotations[child] = child.rotation

	_sync_to_background()
	get_viewport().size_changed.connect(_sync_to_background)
	set_process(motion_enabled)
	if not motion_enabled:
		_restore_neutral_pose()


func _process(delta: float) -> void:
	_elapsed += delta
	for child in get_children():
		var plant_name := String(child.name)
		if not child is Sprite2D or not PLANT_SETTINGS.has(plant_name):
			continue

		var settings: Dictionary = PLANT_SETTINGS[plant_name]
		var speed_multiplier: float = settings["speed"]
		var phase: float = settings["phase"]
		var wave := sin((_elapsed * sway_speed * speed_multiplier) + phase)
		var secondary_wave := sin((_elapsed * sway_speed * speed_multiplier * 0.73) + phase * 1.37)
		var degrees: float = settings["degrees"] * sway_strength
		var horizontal: float = horizontal_displacement * float(settings["horizontal"]) * sway_strength

		child.rotation = _base_rotations[child] + deg_to_rad(degrees * wave)
		child.position = _base_positions[child] + Vector2(
			horizontal * secondary_wave,
			0.0
		)


func _sync_to_background() -> void:
	if _background == null or _background.sprite_frames == null:
		return
	if not _background.sprite_frames.has_animation("default"):
		return
	if _background.sprite_frames.get_frame_count("default") == 0:
		return

	var texture := _background.sprite_frames.get_frame_texture("default", 0)
	if texture == null:
		return

	# The overlays use source-image pixel coordinates. Matching the background's
	# top-left and uniform cover scale keeps every cutout aligned in portrait mode.
	position = _background.position - texture.get_size() * _background.scale * 0.5
	scale = _background.scale


func reset_motion_for_test() -> void:
	_elapsed = 0.0
	_restore_neutral_pose()


func _restore_neutral_pose() -> void:
	for child in get_children():
		if child is Sprite2D and _base_positions.has(child):
			child.position = _base_positions[child]
			child.rotation = _base_rotations[child]

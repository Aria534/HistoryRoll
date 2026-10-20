
extends AnimatedSprite2D

@export var zoom_amount: float = 0.02
@export var zoom_speed: float = 0.5
@export var float_amount: float = 5.0
@export var float_speed: float = 0.6

var starting_position: Vector2
var starting_scale: Vector2
var elapsed: float = 0.0


func _ready() -> void:
	# Keep the background centered
	centered = true

	# Automatically fit the background
	fit_background()

	# Store the fitted position and scale
	starting_position = position
	starting_scale = scale

	# Play existing animation
	if sprite_frames != null:
		if sprite_frames.has_animation("default"):
			play("default")


func fit_background() -> void:
	if sprite_frames == null:
		return

	if not sprite_frames.has_animation("default"):
		return

	if sprite_frames.get_frame_count("default") == 0:
		return

	var texture := sprite_frames.get_frame_texture("default", 0)

	if texture == null:
		return

	var screen_size := get_viewport_rect().size
	var image_size := texture.get_size()

	if image_size.x <= 0 or image_size.y <= 0:
		return

	# Cover the entire screen while preserving aspect ratio
	var fit_scale: float = max(
		screen_size.x / image_size.x,
		screen_size.y / image_size.y
	)

	# Small extra margin for zoom and float animation
	var safe_scale: float = fit_scale * (
		1.0 + abs(zoom_amount)
	)

	safe_scale *= 1.02

	position = screen_size / 2.0
	scale = Vector2.ONE * safe_scale


func _process(delta: float) -> void:
	elapsed += delta

	# Gentle vertical floating animation
	position.y = starting_position.y + \
		sin(elapsed * float_speed) * float_amount

	# Gentle cinematic zoom animation
	var zoom_factor: float = 1.0 + \
		sin(elapsed * zoom_speed) * zoom_amount

	scale = starting_scale * zoom_factor

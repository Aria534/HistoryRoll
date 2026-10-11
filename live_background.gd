
extends AnimatedSprite2D

@export var zoom_amount: float = 0.02
@export var zoom_speed: float = 0.5
@export var float_amount: float = 5.0
@export var float_speed: float = 0.6

var starting_position: Vector2
var starting_scale: Vector2
var elapsed: float = 0.0

func _ready() -> void:
	starting_position = position
	starting_scale = scale

	if sprite_frames != null:
		if sprite_frames.has_animation("default"):
			play("default")

func _process(delta: float) -> void:
	elapsed += delta

	# Gentle vertical movement
	position.y = starting_position.y + \
		sin(elapsed * float_speed) * float_amount

	# Gentle cinematic zoom
	var zoom_factor = 1.0 + \
		sin(elapsed * zoom_speed) * zoom_amount

	scale = starting_scale * zoom_factor


extends AnimatedSprite2D

func _ready() -> void:
	# Center the background
	centered = true

	# Fit the image to the screen
	fit_background()

	# Keep the background static. Plant motion is isolated in AnimatedPlants.
	if sprite_frames != null:
		if sprite_frames.has_animation("default"):
			stop()
			frame = 0


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

	var screen_size: Vector2 = get_viewport_rect().size
	var image_size: Vector2 = texture.get_size()

	if image_size.x <= 0 or image_size.y <= 0:
		return

	# Cover the screen without stretching the image
	var fit_scale: float = max(
		screen_size.x / image_size.x,
		screen_size.y / image_size.y
	)

	position = screen_size / 2.0
	scale = Vector2.ONE * fit_scale

extends Control

@export var body_color := Color("#FFD43B")
@export var highlight_color := Color("#FFF2A6")
@export var outline_color := Color("#3B2A12")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var unit := maxf(2.0, floorf(minf(size.x, size.y) / 16.0))
	var center := size * 0.5
	var body_size := Vector2(unit * 10.0, unit * 8.0)
	var body_rect := Rect2(center.x - body_size.x * 0.5, center.y - unit, body_size.x, body_size.y)

	# Pixel-stepped shackle. Separate bars leave the middle genuinely open.
	var shackle_color := Color("#A9BAC6")
	draw_rect(Rect2(center.x - unit * 4.0, center.y - unit * 6.0, unit * 8.0, unit * 2.0), outline_color)
	draw_rect(Rect2(center.x - unit * 4.0, center.y - unit * 5.0, unit * 2.0, unit * 6.0), outline_color)
	draw_rect(Rect2(center.x + unit * 2.0, center.y - unit * 5.0, unit * 2.0, unit * 6.0), outline_color)
	draw_rect(Rect2(center.x - unit * 3.0, center.y - unit * 5.0, unit * 6.0, unit), shackle_color)
	draw_rect(Rect2(center.x - unit * 3.0, center.y - unit * 4.0, unit, unit * 5.0), shackle_color)
	draw_rect(Rect2(center.x + unit * 2.0, center.y - unit * 4.0, unit, unit * 5.0), shackle_color)

	draw_rect(body_rect.grow(unit), outline_color)
	draw_rect(body_rect, body_color)
	draw_rect(Rect2(body_rect.position + Vector2(unit, unit), Vector2(body_rect.size.x - unit * 2.0, unit)), highlight_color)

	var keyhole_center := Vector2(center.x, body_rect.position.y + body_rect.size.y * 0.48)
	draw_circle(keyhole_center, unit * 1.15, outline_color)
	draw_rect(Rect2(keyhole_center.x - unit * 0.65, keyhole_center.y, unit * 1.3, unit * 2.2), outline_color)

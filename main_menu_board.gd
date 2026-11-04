@tool
extends Control

const BOARD_NUMBERS: Array[Array] = [
	[11, 12, 13, 14, 15],
	[10, 9, 8, 7, 6],
	[1, 2, 3, 4, 5],
]
const TILE_COLORS: Array[Color] = [
	Color("#F7E3C1"), Color("#ED6A62"), Color("#48B9A8"),
	Color("#62A7F2"), Color("#F4C34F"),
]
const BOARD_FONT: Font = preload("res://assets/fonts/Roboto-Variable.ttf")
const BOARD_DECORATIONS: Texture2D = preload("res://assets/main_menu_pixel/board_decorations.png")

@export_range(12.0, 48.0, 1.0) var number_font_size: float = 30.0:
	set(value):
		number_font_size = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func get_visual_numbers() -> Array[Array]:
	return BOARD_NUMBERS.duplicate(true)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var padding := 8.0
	var board_rect := Rect2(Vector2(padding, padding), size - Vector2.ONE * padding * 2.0)
	var top_inset := board_rect.size.x * 0.035
	var outer := PackedVector2Array([
		board_rect.position + Vector2(top_inset, 0.0),
		board_rect.position + Vector2(board_rect.size.x - top_inset, 0.0),
		board_rect.end,
		board_rect.position + Vector2(0.0, board_rect.size.y),
	])
	draw_colored_polygon(outer, Color("#12233F"))
	draw_polyline(PackedVector2Array([outer[0], outer[1], outer[2], outer[3], outer[0]]), Color("#EAA33A"), 7.0, true)
	for row: int in range(3):
		var top_ratio := float(row) / 3.0
		var bottom_ratio := float(row + 1) / 3.0
		var top_left: float = board_rect.position.x + lerpf(top_inset, 0.0, top_ratio)
		var top_right: float = board_rect.end.x - lerpf(top_inset, 0.0, top_ratio)
		var bottom_left: float = board_rect.position.x + lerpf(top_inset, 0.0, bottom_ratio)
		var bottom_right: float = board_rect.end.x - lerpf(top_inset, 0.0, bottom_ratio)
		var top_y := board_rect.position.y + board_rect.size.y * top_ratio
		var bottom_y := board_rect.position.y + board_rect.size.y * bottom_ratio
		for column: int in range(5):
			var left_ratio := float(column) / 5.0
			var right_ratio := float(column + 1) / 5.0
			var tile_points := PackedVector2Array([
				Vector2(lerp(top_left, top_right, left_ratio), top_y),
				Vector2(lerp(top_left, top_right, right_ratio), top_y),
				Vector2(lerp(bottom_left, bottom_right, right_ratio), bottom_y),
				Vector2(lerp(bottom_left, bottom_right, left_ratio), bottom_y),
			])
			var color_index := (row * 2 + column) % TILE_COLORS.size()
			draw_colored_polygon(tile_points, TILE_COLORS[color_index])
			draw_polyline(PackedVector2Array([tile_points[0], tile_points[1], tile_points[2], tile_points[3], tile_points[0]]), Color("#7A563D"), 2.0, true)
	draw_texture_rect(BOARD_DECORATIONS, board_rect, false, Color(1.0, 1.0, 1.0, 0.78))
	for row: int in range(3):
		var top_ratio := float(row) / 3.0
		var bottom_ratio := float(row + 1) / 3.0
		var center_ratio := (top_ratio + bottom_ratio) * 0.5
		var center_left: float = board_rect.position.x + lerpf(top_inset, 0.0, center_ratio)
		var center_right: float = board_rect.end.x - lerpf(top_inset, 0.0, center_ratio)
		var center_y := board_rect.position.y + board_rect.size.y * center_ratio
		for column: int in range(5):
			var number := str(BOARD_NUMBERS[row][column])
			var cell_width: float = (center_right - center_left) / 5.0
			var tile_center := Vector2(center_left + cell_width * (float(column) + 0.5), center_y)
			var text_width := BOARD_FONT.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(number_font_size)).x
			var baseline := tile_center + Vector2(-text_width * 0.5, number_font_size * 0.32)
			draw_string(BOARD_FONT, baseline + Vector2(2.0, 2.0), number, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(number_font_size), Color(1.0, 0.97, 0.88, 0.95))
			draw_string(BOARD_FONT, baseline, number, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(number_font_size), Color("#263247"))

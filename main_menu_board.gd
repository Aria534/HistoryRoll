@tool
extends Control

const BOARD_NUMBERS: Array[Array] = [
	[21, 22, 23, 24, 25],
	[20, 19, 18, 17, 16],
	[11, 12, 13, 14, 15],
	[10, 9, 8, 7, 6],
	[1, 2, 3, 4, 5],
]
const START_LABEL := "START"
const START_BADGE_TEXT := "START 1"
const START_TILE := 1
const SNAKE_COUNT := 2
const LADDER_COUNT := 3
const TILE_COLORS: Array[Color] = [
	Color("#F7E3C1"), Color("#ED6A62"), Color("#48B9A8"),
	Color("#62A7F2"), Color("#F4C34F"),
]
const BOARD_FONT: Font = preload("res://assets/fonts/Roboto-Variable.ttf")
const BOARD_DECORATIONS: Texture2D = preload("res://assets/main_menu_pixel/board_decorations_reference_v2.png")
const ROW_DEPTHS: Array[float] = [0.0, 0.14, 0.30, 0.49, 0.72, 1.0]

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


func get_path_sequence() -> Array[int]:
	var sequence: Array[int] = []
	for visual_row: int in range(BOARD_NUMBERS.size() - 1, -1, -1):
		var row_from_bottom := BOARD_NUMBERS.size() - 1 - visual_row
		if row_from_bottom % 2 == 0:
			for column: int in range(5):
				sequence.append(BOARD_NUMBERS[visual_row][column])
		else:
			for column: int in range(4, -1, -1):
				sequence.append(BOARD_NUMBERS[visual_row][column])
	return sequence


func get_start_label() -> String:
	return START_LABEL


func has_snakes_and_ladders() -> bool:
	return BOARD_DECORATIONS != null and SNAKE_COUNT > 0 and LADDER_COUNT > 0


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var board_rect := Rect2(Vector2(5.0, 5.0), size - Vector2(10.0, 12.0))
	var outer := PackedVector2Array([
		_grid_point(board_rect, 0.0, 0.0),
		_grid_point(board_rect, 0.0, 1.0),
		_grid_point(board_rect, 1.0, 1.0),
		_grid_point(board_rect, 1.0, 0.0),
	])
	var shadow := PackedVector2Array()
	for point: Vector2 in outer:
		shadow.append(point + Vector2(0.0, 7.0))
	draw_colored_polygon(shadow, Color(0.02, 0.07, 0.12, 0.72))
	for row: int in range(BOARD_NUMBERS.size()):
		var top_ratio: float = ROW_DEPTHS[row]
		var bottom_ratio: float = ROW_DEPTHS[row + 1]
		for column: int in range(5):
			var left_ratio := float(column) / 5.0
			var right_ratio := float(column + 1) / 5.0
			var tile_points := PackedVector2Array([
				_grid_point(board_rect, top_ratio, left_ratio),
				_grid_point(board_rect, top_ratio, right_ratio),
				_grid_point(board_rect, bottom_ratio, right_ratio),
				_grid_point(board_rect, bottom_ratio, left_ratio),
			])
			var color_index := (row * 2 + column) % TILE_COLORS.size()
			draw_colored_polygon(tile_points, TILE_COLORS[color_index])
			draw_polyline(PackedVector2Array([tile_points[0], tile_points[1], tile_points[2], tile_points[3], tile_points[0]]), Color("#7A563D"), 2.5, true)
	draw_polyline(PackedVector2Array([outer[0], outer[1], outer[2], outer[3], outer[0]]), Color("#13243E"), 11.0, true)
	draw_polyline(PackedVector2Array([outer[0], outer[1], outer[2], outer[3], outer[0]]), Color("#E8A43B"), 4.0, true)
	draw_texture_rect(BOARD_DECORATIONS, board_rect.grow(-5.0), false, Color(1.0, 1.0, 1.0, 0.92))
	for row: int in range(BOARD_NUMBERS.size()):
		var top_ratio: float = ROW_DEPTHS[row]
		var bottom_ratio: float = ROW_DEPTHS[row + 1]
		var center_ratio := (top_ratio + bottom_ratio) * 0.5
		for column: int in range(5):
			var tile_number: int = BOARD_NUMBERS[row][column]
			var number := str(tile_number)
			var tile_center := _grid_point(board_rect, center_ratio, (float(column) + 0.5) / 5.0)
			if tile_number == START_TILE:
				_draw_start_badge(tile_center + Vector2(32.0, -number_font_size * 0.5))
				continue
			var text_width := BOARD_FONT.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(number_font_size)).x
			var baseline := tile_center + Vector2(-text_width * 0.5, number_font_size * 0.32)
			draw_string(BOARD_FONT, baseline + Vector2(2.0, 2.0), number, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(number_font_size), Color(1.0, 0.97, 0.88, 0.95))
			draw_string(BOARD_FONT, baseline, number, HORIZONTAL_ALIGNMENT_LEFT, -1.0, int(number_font_size), Color("#263247"))


func _draw_start_badge(center: Vector2) -> void:
	var font_size := maxi(15, int(number_font_size * 0.52))
	var text_size := BOARD_FONT.get_string_size(START_BADGE_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var badge_rect := Rect2(center - Vector2(text_size.x * 0.5 + 7.0, font_size * 0.55), Vector2(text_size.x + 14.0, font_size + 8.0))
	draw_rect(badge_rect, Color("#183052"), true)
	draw_rect(badge_rect, Color("#F4C34F"), false, 2.0)
	var baseline := center + Vector2(-text_size.x * 0.5, font_size * 0.32)
	draw_string(BOARD_FONT, baseline, START_BADGE_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color("#FFF4D6"))


func _grid_point(board_rect: Rect2, depth: float, horizontal: float) -> Vector2:
	var top_inset := board_rect.size.x * 0.105
	var inset := lerpf(top_inset, 0.0, depth)
	var left := board_rect.position.x + inset
	var right := board_rect.end.x - inset
	var edge_distance := absf(horizontal - 0.5) * 2.0
	var curve_height := lerpf(17.0, 4.0, depth)
	var curved_y := edge_distance * edge_distance * curve_height
	return Vector2(
		lerpf(left, right, horizontal),
		board_rect.position.y + board_rect.size.y * depth + curved_y
	)

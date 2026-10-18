extends Control

const BoardRules = preload("res://board_rules.gd")

@onready var player_token: Control = %PlayerToken

var board_config: Dictionary = {}
var columns: int = 5
var rows: int = 6
var displayed_position: int = 0


func _ready() -> void:
	resized.connect(_on_resized)
	queue_redraw()
	call_deferred("set_player_position_immediate", displayed_position)


func configure(config: Dictionary) -> PackedStringArray:
	var errors := BoardRules.validate_config(config)
	if not errors.is_empty():
		return errors
	board_config = config.duplicate(true)
	columns = int(board_config.get("columns", 5))
	rows = int(board_config.get("rows", 6))
	queue_redraw()
	call_deferred("set_player_position_immediate", displayed_position)
	return errors


func set_player_position_immediate(tile: int) -> void:
	displayed_position = tile
	if not is_node_ready() or size.x <= 0.0 or size.y <= 0.0:
		return
	player_token.position = _get_token_top_left(tile)


func animate_player_to(tile: int, duration: float) -> void:
	displayed_position = tile
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(player_token, "position", _get_token_top_left(tile), duration)
	await tween.finished


func get_tile_center(tile: int) -> Vector2:
	var cell := BoardRules.tile_to_visual_cell(tile, columns, rows)
	if cell.x < 0:
		cell = BoardRules.tile_to_visual_cell(1, columns, rows)
	var cell_size := Vector2(size.x / columns, size.y / rows)
	return Vector2((cell.x + 0.5) * cell_size.x, (cell.y + 0.5) * cell_size.y)


func _get_token_top_left(tile: int) -> Vector2:
	var center := get_tile_center(max(tile, 1))
	if tile <= 0:
		center.y += size.y / rows * 0.28
	return center - player_token.size / 2.0


func _on_resized() -> void:
	queue_redraw()
	set_player_position_immediate(displayed_position)


func _draw() -> void:
	if columns < 1 or rows < 1:
		return
	var cell_size := Vector2(size.x / columns, size.y / rows)
	var tile_count := columns * rows
	for tile: int in range(1, tile_count + 1):
		var cell := BoardRules.tile_to_visual_cell(tile, columns, rows)
		var tile_rect := Rect2(Vector2(cell.x, cell.y) * cell_size, cell_size)
		var color := Color("#dbe9d1") if (cell.x + cell.y) % 2 == 0 else Color("#f2dfb4")
		draw_rect(tile_rect, color, true)
		draw_rect(tile_rect, Color("#4d5d53"), false, 2.0)
		var baseline := tile_rect.position + Vector2(0.0, cell_size.y * 0.62)
		draw_string(
			ThemeDB.fallback_font,
			baseline,
			str(tile),
			HORIZONTAL_ALIGNMENT_CENTER,
			cell_size.x,
			clampi(int(min(cell_size.x, cell_size.y) * 0.28), 18, 30),
			Color("#24352c")
		)

	for raw_start: Variant in board_config.get("ladders", {}):
		var start := int(raw_start)
		var destination := int(board_config["ladders"][raw_start])
		_draw_ladder(get_tile_center(start), get_tile_center(destination))
	for raw_start: Variant in board_config.get("snakes", {}):
		var start := int(raw_start)
		var destination := int(board_config["snakes"][raw_start])
		_draw_snake(get_tile_center(start), get_tile_center(destination))


func _draw_ladder(start: Vector2, destination: Vector2) -> void:
	var direction := destination - start
	if direction.length() <= 0.0:
		return
	var perpendicular := direction.normalized().orthogonal() * 8.0
	draw_line(start - perpendicular, destination - perpendicular, Color("#8b5a2b"), 6.0, true)
	draw_line(start + perpendicular, destination + perpendicular, Color("#8b5a2b"), 6.0, true)
	for step: int in range(1, 7):
		var point := start.lerp(destination, step / 7.0)
		draw_line(point - perpendicular, point + perpendicular, Color("#d8ad63"), 4.0, true)


func _draw_snake(start: Vector2, destination: Vector2) -> void:
	var direction := destination - start
	if direction.length() <= 0.0:
		return
	var perpendicular := direction.normalized().orthogonal() * 13.0
	var points := PackedVector2Array()
	for step: int in range(9):
		var point := start.lerp(destination, step / 8.0)
		if step > 0 and step < 8:
			point += perpendicular * (1.0 if step % 2 == 0 else -1.0)
		points.append(point)
	draw_polyline(points, Color("#9b3d46"), 9.0, true)
	draw_circle(start, 14.0, Color("#c95b62"))
	draw_circle(start + Vector2(-5, -3), 2.5, Color.WHITE)
	draw_circle(start + Vector2(5, -3), 2.5, Color.WHITE)

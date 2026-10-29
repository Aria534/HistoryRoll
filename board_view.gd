extends Control

const BoardRules = preload("res://board_rules.gd")

@onready var player_token: Control = %PlayerToken
@onready var player_token_label: Label = %PlayerTokenLabel
@onready var waiting_hero_token: Control = %WaitingHeroToken
@onready var waiting_hero_label: Label = %WaitingHeroLabel

var board_config: Dictionary = {}
var columns: int = 10
var rows: int = 10
var displayed_position: int = 1
var waiting_animation_active: bool = false


func _ready() -> void:
	resized.connect(_on_resized)
	queue_redraw()
	call_deferred("set_player_position_immediate", displayed_position)
	call_deferred("_start_waiting_animation")


func configure(config: Dictionary) -> PackedStringArray:
	var errors := BoardRules.validate_config(config)
	if not errors.is_empty():
		return errors
	board_config = config.duplicate(true)
	columns = int(board_config.get("columns", 10))
	rows = int(board_config.get("rows", 10))
	queue_redraw()
	call_deferred("set_player_position_immediate", displayed_position)
	return errors


func set_player_position_immediate(tile: int) -> void:
	displayed_position = tile
	if not is_node_ready() or size.x <= 0.0 or size.y <= 0.0:
		return
	player_token.position = _get_token_top_left(tile)
	_position_waiting_hero()


func set_hero_placeholders(player_name: String, waiting_name: String, final_marker: bool) -> void:
	player_token.tooltip_text = "%s chibi artwork slot" % player_name
	player_token_label.text = _initials(player_name)
	waiting_hero_token.tooltip_text = "%s artwork slot" % waiting_name
	waiting_hero_label.text = "TROPHY" if final_marker else _initials(waiting_name)
	_position_waiting_hero()


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
	var board_rect := get_board_rect()
	var cell_size := Vector2(board_rect.size.x / columns, board_rect.size.y / rows)
	return board_rect.position + Vector2((cell.x + 0.5) * cell_size.x, (cell.y + 0.5) * cell_size.y)


func get_board_rect() -> Rect2:
	var aspect := float(columns) / float(rows)
	var board_size := Vector2(size.x, size.x / aspect)
	if board_size.y > size.y:
		board_size = Vector2(size.y * aspect, size.y)
	return Rect2((size - board_size) / 2.0, board_size)


func _get_token_top_left(tile: int) -> Vector2:
	var center := get_tile_center(max(tile, 1))
	return center - player_token.size / 2.0


func _on_resized() -> void:
	queue_redraw()
	set_player_position_immediate(displayed_position)
	_position_waiting_hero()


func _draw() -> void:
	if columns < 1 or rows < 1:
		return
	var board_rect := get_board_rect()
	var cell_size := Vector2(board_rect.size.x / columns, board_rect.size.y / rows)
	var tile_count := columns * rows
	for tile: int in range(1, tile_count + 1):
		var cell := BoardRules.tile_to_visual_cell(tile, columns, rows)
		var tile_rect := Rect2(board_rect.position + Vector2(cell.x, cell.y) * cell_size, cell_size)
		draw_rect(tile_rect.grow(-1.0), _get_tile_color(tile, cell), true)
		draw_rect(tile_rect, Color("#806348"), false, 2.0)

	for raw_start: Variant in board_config.get("ladders", {}):
		var start := int(raw_start)
		var destination := int(board_config["ladders"][raw_start])
		_draw_ladder(get_tile_center(start), get_tile_center(destination))
	for raw_start: Variant in board_config.get("snakes", {}):
		var start := int(raw_start)
		var destination := int(board_config["snakes"][raw_start])
		_draw_snake(get_tile_center(start), get_tile_center(destination))

	for tile: int in range(1, tile_count + 1):
		var cell := BoardRules.tile_to_visual_cell(tile, columns, rows)
		var tile_rect := Rect2(board_rect.position + Vector2(cell.x, cell.y) * cell_size, cell_size)
		_draw_tile_content(tile, tile_rect)


func _get_tile_color(tile: int, cell: Vector2i) -> Color:
	if BoardRules.is_question_tile(board_config, tile):
		return Color("#c9dce3")
	var special_type := BoardRules.get_special_tile_type(board_config, tile)
	match special_type:
		"bonus":
			return Color("#f0dfaa")
		"shield":
			return Color("#c9d9e7")
	if _mapping_has(board_config.get("snakes", {}), tile):
		return Color("#e2c4bd")
	if _mapping_has(board_config.get("ladders", {}), tile):
		return Color("#ead7a4")
	var palette := [Color("#8CCDE8"), Color("#F5D989"), Color("#A9CFA5"), Color("#EBA49A"), Color("#F8EED7")]
	return palette[(cell.x + cell.y * columns) % palette.size()]


func _draw_tile_content(tile: int, tile_rect: Rect2) -> void:
	var minimum_side: float = minf(tile_rect.size.x, tile_rect.size.y)
	var number_size := clampi(int(minimum_side * 0.24), 14, 24)
	var number_position := tile_rect.position + Vector2(5.0, number_size + 3.0)
	draw_string(ThemeDB.fallback_font, number_position, str(tile), HORIZONTAL_ALIGNMENT_LEFT, tile_rect.size.x - 8.0, number_size, Color("#26362f"))

	if BoardRules.is_question_tile(board_config, tile):
		var icon_size := clampi(int(minimum_side * 0.42), 22, 34)
		var icon_position := tile_rect.position + Vector2(0.0, tile_rect.size.y * 0.72)
		draw_string(ThemeDB.fallback_font, icon_position, "?", HORIZONTAL_ALIGNMENT_CENTER, tile_rect.size.x, icon_size, Color("#315a70"))
	else:
		var special_type := BoardRules.get_special_tile_type(board_config, tile)
		if not special_type.is_empty():
			_draw_special_icon(special_type, tile_rect, minimum_side)

	var marker := "START" if tile == 1 else ("FINISH" if tile == columns * rows else "")
	if not marker.is_empty():
		var marker_size := clampi(int(minimum_side * 0.14), 9, 13)
		var marker_position := tile_rect.position + Vector2(2.0, tile_rect.size.y - 5.0)
		draw_string(ThemeDB.fallback_font, marker_position, marker, HORIZONTAL_ALIGNMENT_CENTER, tile_rect.size.x - 4.0, marker_size, Color("#6a4025"))


func _draw_special_icon(tile_type: String, tile_rect: Rect2, minimum_side: float) -> void:
	var center := tile_rect.get_center() + Vector2(0.0, minimum_side * 0.08)
	var radius := minimum_side * 0.22
	match tile_type:
		"bonus":
			draw_colored_polygon(_make_star(center, radius, radius * 0.45), Color("#c58b24"))
		"shield":
			var shield_points := PackedVector2Array([
				center + Vector2(-radius * 0.75, -radius * 0.7),
				center + Vector2(radius * 0.75, -radius * 0.7),
				center + Vector2(radius * 0.62, radius * 0.35),
				center + Vector2(0.0, radius),
				center + Vector2(-radius * 0.62, radius * 0.35),
			])
			draw_colored_polygon(shield_points, Color("#4c78a3"))
			draw_polyline(shield_points + PackedVector2Array([shield_points[0]]), Color("#315574"), 2.0, true)


func _make_star(center: Vector2, outer_radius: float, inner_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index: int in range(10):
		var radius := outer_radius if point_index % 2 == 0 else inner_radius
		var angle := -PI / 2.0 + point_index * TAU / 10.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _mapping_has(mapping: Dictionary, tile: int) -> bool:
	return mapping.has(tile) or mapping.has(str(tile))


func _draw_ladder(start: Vector2, destination: Vector2) -> void:
	var direction := destination - start
	if direction.length() <= 0.0:
		return
	var perpendicular := direction.normalized().orthogonal() * 7.0
	draw_line(start - perpendicular, destination - perpendicular, Color("#7a532f"), 5.0, true)
	draw_line(start + perpendicular, destination + perpendicular, Color("#7a532f"), 5.0, true)
	for step: int in range(1, 7):
		var point := start.lerp(destination, step / 7.0)
		draw_line(point - perpendicular, point + perpendicular, Color("#c99e5c"), 3.0, true)


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
	draw_polyline(points, Color("#8f4650"), 7.0, true)
	draw_circle(start, 12.0, Color("#b95760"))
	draw_circle(start + Vector2(-5, -3), 2.5, Color.WHITE)
	draw_circle(start + Vector2(5, -3), 2.5, Color.WHITE)


func _position_waiting_hero() -> void:
	if not is_node_ready() or waiting_hero_token == null or size.x <= 0.0:
		return
	var board_rect := get_board_rect()
	var cell_size := Vector2(board_rect.size.x / columns, board_rect.size.y / rows)
	var diameter := clampf(minf(cell_size.x, cell_size.y) * 0.58, 30.0, 58.0)
	waiting_hero_token.size = Vector2(diameter, diameter)
	var finish_center := get_tile_center(columns * rows)
	var target := finish_center + Vector2(cell_size.x * 0.2, cell_size.y * 0.12) - waiting_hero_token.size / 2.0
	target.x = clampf(target.x, board_rect.position.x, board_rect.end.x - diameter)
	target.y = clampf(target.y, board_rect.position.y, board_rect.end.y - diameter)
	waiting_hero_token.position = target


func _start_waiting_animation() -> void:
	if waiting_hero_token == null or waiting_animation_active:
		return
	waiting_animation_active = true
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(waiting_hero_token, "position:y", waiting_hero_token.position.y - 8.0, 0.8)
	tween.tween_property(waiting_hero_token, "position:y", waiting_hero_token.position.y, 0.8)


func _initials(hero_name: String) -> String:
	var result := ""
	for part: String in hero_name.split(" ", false):
		result += part.left(1).to_upper()
		if result.length() >= 3:
			break
	return result if not result.is_empty() else "H"

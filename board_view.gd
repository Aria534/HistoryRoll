extends Control

const BoardRules = preload("res://board_rules.gd")
const BOARD_FONT: FontFile = preload("res://assets/fonts/TitanOne-Regular.ttf")

class BoardDie:
	extends Control

	var face_value: int = 1:
		set(value):
			face_value = clampi(value, 1, 6)
			queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		queue_redraw()

	func _draw() -> void:
		var die_box := StyleBoxFlat.new()
		die_box.bg_color = Color("#FFF5DF")
		die_box.border_color = Color("#4A2D25")
		die_box.set_border_width_all(maxi(2, int(size.x * 0.065)))
		die_box.set_corner_radius_all(maxi(7, int(size.x * 0.18)))
		die_box.shadow_color = Color(0.12, 0.08, 0.06, 0.38)
		die_box.shadow_size = maxi(3, int(size.x * 0.08))
		draw_style_box(die_box, Rect2(Vector2.ZERO, size))

		var pip_positions: Array[Vector2] = []
		var top_left := Vector2(0.29, 0.29)
		var top_right := Vector2(0.71, 0.29)
		var middle_left := Vector2(0.29, 0.5)
		var center := Vector2(0.5, 0.5)
		var middle_right := Vector2(0.71, 0.5)
		var bottom_left := Vector2(0.29, 0.71)
		var bottom_right := Vector2(0.71, 0.71)
		match face_value:
			1: pip_positions = [center]
			2: pip_positions = [top_left, bottom_right]
			3: pip_positions = [top_left, center, bottom_right]
			4: pip_positions = [top_left, top_right, bottom_left, bottom_right]
			5: pip_positions = [top_left, top_right, center, bottom_left, bottom_right]
			6: pip_positions = [top_left, top_right, middle_left, middle_right, bottom_left, bottom_right]
		var pip_radius := clampf(size.x * 0.078, 3.0, 7.0)
		for normalized_position: Vector2 in pip_positions:
			draw_circle(normalized_position * size, pip_radius, Color("#352A2A"))

const FRAME_WIDTH: float = 16.0
const TILE_PALETTE: Array[Color] = [
	Color("#F7D77C"), Color("#F6E7C5"), Color("#A9D3C2"),
	Color("#EFA99F"), Color("#A9D5EA"),
]
const SNAKE_PALETTES: Array[Array] = [
	[Color("#702A2C"), Color("#EF624B"), Color("#FFD06A")],
	[Color("#3D285E"), Color("#9065C6"), Color("#D9BAFF")],
	[Color("#315A34"), Color("#71AE4D"), Color("#CDEB76")],
]

@onready var player_token: Control = %PlayerToken
@onready var player_token_label: Label = %PlayerTokenLabel
@onready var waiting_hero_token: Control = %WaitingHeroToken
@onready var waiting_hero_label: Label = %WaitingHeroLabel

var board_config: Dictionary = {}
var columns: int = 10
var rows: int = 10
var displayed_position: int = 1
var player_sprite: TextureRect
var waiting_hero_sprite: TextureRect
var player_idle_tween: Tween
var waiting_idle_tween: Tween
var waiting_animation_active: bool = false
var board_die: BoardDie
var dice_animation_active: bool = false


func _ready() -> void:
	player_sprite = _ensure_token_sprite(player_token, "HeroSprite")
	waiting_hero_sprite = _ensure_token_sprite(waiting_hero_token, "WaitingHeroSprite")
	board_die = _ensure_board_die()
	player_token.z_index = 5
	waiting_hero_token.z_index = 4
	resized.connect(_on_resized)
	queue_redraw()
	call_deferred("set_player_position_immediate", displayed_position)
	reset_dice_display()


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
	_position_tokens()


func set_hero_tokens(
	player_name: String,
	player_portrait_path: String,
	waiting_name: String,
	waiting_portrait_path: String,
	final_marker: bool
) -> void:
	if player_sprite == null:
		player_sprite = _ensure_token_sprite(player_token, "HeroSprite")
	if waiting_hero_sprite == null:
		waiting_hero_sprite = _ensure_token_sprite(waiting_hero_token, "WaitingHeroSprite")

	player_token.tooltip_text = "%s face portrait" % player_name
	player_sprite.texture = _load_face_texture(player_portrait_path)
	player_sprite.visible = player_sprite.texture != null
	player_token_label.text = _initials(player_name)
	player_token_label.visible = not player_sprite.visible

	waiting_hero_token.tooltip_text = "%s next hero face portrait" % waiting_name
	waiting_hero_sprite.texture = _load_face_texture(waiting_portrait_path)
	waiting_hero_sprite.visible = waiting_hero_sprite.texture != null and not final_marker
	waiting_hero_label.text = "TROPHY" if final_marker else _initials(waiting_name)
	waiting_hero_label.visible = not waiting_hero_sprite.visible
	_position_tokens()
	call_deferred("_restart_idle_animations")


# Compatibility for older tests or scenes that do not provide portrait paths.
func set_hero_placeholders(player_name: String, waiting_name: String, final_marker: bool) -> void:
	set_hero_tokens(player_name, "", waiting_name, "", final_marker)


func animate_player_to(tile: int, duration: float) -> void:
	displayed_position = tile
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(player_token, "position", _get_token_top_left(tile, player_token), duration)
	await tween.finished


func reset_dice_display() -> void:
	if board_die == null:
		board_die = _ensure_board_die()
	dice_animation_active = false
	board_die.hide()
	board_die.face_value = 1
	board_die.rotation = 0.0
	board_die.scale = Vector2.ONE


func animate_dice_result(result: int, animation_steps: int, interval: float) -> void:
	if board_die == null:
		board_die = _ensure_board_die()
	var board_rect := get_board_rect()
	var cell_size := Vector2(board_rect.size.x / columns, board_rect.size.y / rows)
	var die_size := clampf(minf(cell_size.x, cell_size.y) * 0.82, 48.0, 88.0)
	board_die.size = Vector2(die_size, die_size)
	board_die.pivot_offset = board_die.size / 2.0
	var target_position := board_rect.get_center() - board_die.size / 2.0
	board_die.position = Vector2(board_rect.end.x - die_size * 0.25, board_rect.end.y + die_size * 0.18)
	board_die.rotation = -0.55
	board_die.scale = Vector2(0.58, 0.58)
	board_die.show()
	dice_animation_active = true

	var total_steps := maxi(1, animation_steps)
	var step_interval := maxf(0.001, interval)
	var travel_duration := maxf(0.22, total_steps * step_interval)
	var travel_tween := create_tween().set_parallel(true)
	travel_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	travel_tween.tween_property(board_die, "position", target_position, travel_duration)
	travel_tween.tween_property(board_die, "rotation", 0.0, travel_duration)
	travel_tween.tween_property(board_die, "scale", Vector2.ONE, travel_duration)
	for step: int in range(total_steps):
		# These preview faces are deterministic animation frames. Only `result` is
		# generated by the RandomNumberGenerator and used for movement.
		board_die.face_value = (result + step) % 6 + 1
		await get_tree().create_timer(step_interval).timeout
	board_die.face_value = result
	if travel_tween.is_running():
		await travel_tween.finished
	var settle_tween := create_tween()
	settle_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	settle_tween.tween_property(board_die, "scale", Vector2(1.15, 1.15), 0.09)
	settle_tween.tween_property(board_die, "scale", Vector2.ONE, 0.12)
	await settle_tween.finished
	dice_animation_active = false


func get_tile_center(tile: int) -> Vector2:
	var cell := BoardRules.tile_to_visual_cell(tile, columns, rows)
	if cell.x < 0:
		cell = BoardRules.tile_to_visual_cell(1, columns, rows)
	var board_rect := get_board_rect()
	var cell_size := Vector2(board_rect.size.x / columns, board_rect.size.y / rows)
	return board_rect.position + Vector2((cell.x + 0.5) * cell_size.x, (cell.y + 0.5) * cell_size.y)


func get_board_rect() -> Rect2:
	var usable_size := Vector2(maxf(1.0, size.x - FRAME_WIDTH * 2.0), maxf(1.0, size.y - FRAME_WIDTH * 2.0))
	var aspect := float(columns) / float(rows)
	var board_size := Vector2(usable_size.x, usable_size.x / aspect)
	if board_size.y > usable_size.y:
		board_size = Vector2(usable_size.y * aspect, usable_size.y)
	return Rect2((size - board_size) / 2.0, board_size)


func _get_token_top_left(tile: int, token: Control) -> Vector2:
	return get_tile_center(maxi(tile, 1)) - token.size / 2.0


func _on_resized() -> void:
	queue_redraw()
	_position_tokens()
	_position_board_die()
	call_deferred("_sync_sprite_pivots")


func _draw() -> void:
	if columns < 1 or rows < 1:
		return
	var board_rect := get_board_rect()
	_draw_wooden_frame(board_rect)
	var cell_size := Vector2(board_rect.size.x / columns, board_rect.size.y / rows)
	var tile_count := columns * rows

	for tile: int in range(1, tile_count + 1):
		var cell := BoardRules.tile_to_visual_cell(tile, columns, rows)
		var tile_rect := Rect2(board_rect.position + Vector2(cell.x, cell.y) * cell_size, cell_size)
		_draw_tile_surface(tile, tile_rect, cell)

	for raw_start: Variant in board_config.get("ladders", {}):
		var start := int(raw_start)
		var destination := int(board_config["ladders"][raw_start])
		_draw_ladder(get_tile_center(start), get_tile_center(destination), cell_size)

	var snake_index := 0
	for raw_start: Variant in board_config.get("snakes", {}):
		var start := int(raw_start)
		var destination := int(board_config["snakes"][raw_start])
		_draw_snake(get_tile_center(start), get_tile_center(destination), cell_size, snake_index)
		snake_index += 1

	for tile: int in range(1, tile_count + 1):
		var cell := BoardRules.tile_to_visual_cell(tile, columns, rows)
		var tile_rect := Rect2(board_rect.position + Vector2(cell.x, cell.y) * cell_size, cell_size)
		_draw_tile_content(tile, tile_rect)


func _draw_wooden_frame(board_rect: Rect2) -> void:
	var outer := board_rect.grow(FRAME_WIDTH)
	draw_rect(outer.grow(3.0), Color(0.08, 0.035, 0.015, 0.42), true)
	draw_rect(outer, Color("#3A1C11"), true)
	draw_rect(outer.grow(-3.0), Color("#8B431E"), true)
	draw_rect(outer.grow(-6.0), Color("#D88832"), true)
	draw_rect(outer.grow(-9.0), Color("#F2B84E"), true)
	draw_rect(board_rect.grow(3.0), Color("#552B19"), true)
	draw_rect(board_rect.grow(1.0), Color("#FFE08A"), false, 2.0, true)
	draw_line(outer.position + Vector2(10, 8), Vector2(outer.end.x - 10, outer.position.y + 8), Color("#FFE18A"), 2.5, true)
	draw_line(Vector2(outer.position.x + 9, outer.end.y - 7), outer.end - Vector2(9, 7), Color("#642C18"), 3.0, true)
	var corner_size := FRAME_WIDTH * 1.4
	for corner: Vector2 in [outer.position, Vector2(outer.end.x, outer.position.y), outer.end, Vector2(outer.position.x, outer.end.y)]:
		draw_circle(corner, corner_size * 0.58, Color("#4A2416"))
		draw_circle(corner, corner_size * 0.42, Color("#D08030"))
		draw_circle(corner, corner_size * 0.23, Color("#FFD469"))
		draw_circle(corner - Vector2(1.5, 1.5), corner_size * 0.09, Color("#FFF0A8"))


func _draw_tile_surface(tile: int, tile_rect: Rect2, cell: Vector2i) -> void:
	var minimum_side := minf(tile_rect.size.x, tile_rect.size.y)
	var inset := maxf(0.9, minimum_side * 0.012)
	var inner := tile_rect.grow(-inset)
	draw_rect(inner, _get_tile_color(tile, cell), true)
	# Soft inset shading adds depth while keeping the tile numbers readable.
	draw_rect(inner.grow(-minimum_side * 0.035), Color(1.0, 0.96, 0.82, 0.065), true)
	var highlight := Color(1.0, 0.94, 0.72, 0.72)
	var shadow := Color(0.25, 0.12, 0.07, 0.42)
	var bevel_width := clampf(minimum_side * 0.022, 1.2, 3.0)
	draw_line(inner.position, Vector2(inner.end.x, inner.position.y), highlight, bevel_width, true)
	draw_line(inner.position, Vector2(inner.position.x, inner.end.y), highlight, bevel_width, true)
	draw_line(Vector2(inner.position.x, inner.end.y), inner.end, shadow, bevel_width, true)
	draw_line(Vector2(inner.end.x, inner.position.y), inner.end, shadow, bevel_width, true)
	draw_rect(tile_rect, Color("#68412B"), false, maxf(1.4, minimum_side * 0.018), true)
	if tile == 1 or tile == columns * rows:
		draw_rect(inner.grow(-minimum_side * 0.055), Color("#B8661F"), false, maxf(2.0, minimum_side * 0.028), true)


func _get_tile_color(tile: int, cell: Vector2i) -> Color:
	if BoardRules.is_question_tile(board_config, tile):
		return Color("#C9DCE3")
	var special_type := BoardRules.get_special_tile_type(board_config, tile)
	match special_type:
		"bonus":
			return Color("#F7D66F")
		"shield":
			return Color("#BDD7E8")
	if _mapping_has(board_config.get("snakes", {}), tile):
		return Color("#E9B1A5")
	if _mapping_has(board_config.get("ladders", {}), tile):
		return Color("#F0D8A3")
	return TILE_PALETTE[(cell.x + cell.y * columns) % TILE_PALETTE.size()]


func _draw_tile_content(tile: int, tile_rect: Rect2) -> void:
	var minimum_side: float = minf(tile_rect.size.x, tile_rect.size.y)
	var number_size := clampi(int(minimum_side * 0.22), 13, 28)
	var number_position := tile_rect.position + Vector2(maxf(5.0, minimum_side * 0.075), number_size + maxf(3.0, minimum_side * 0.045))
	draw_string(BOARD_FONT, number_position + Vector2(1.6, 2.0), str(tile), HORIZONTAL_ALIGNMENT_LEFT, tile_rect.size.x - 8.0, number_size, Color(1.0, 0.91, 0.70, 0.88))
	draw_string(BOARD_FONT, number_position, str(tile), HORIZONTAL_ALIGNMENT_LEFT, tile_rect.size.x - 8.0, number_size, Color("#3D271C"))

	if BoardRules.is_question_tile(board_config, tile):
		var icon_size := clampi(int(minimum_side * 0.42), 20, 36)
		var icon_position := tile_rect.position + Vector2(0.0, tile_rect.size.y * 0.72)
		draw_string(ThemeDB.fallback_font, icon_position, "?", HORIZONTAL_ALIGNMENT_CENTER, tile_rect.size.x, icon_size, Color("#315A70"))
	else:
		var special_type := BoardRules.get_special_tile_type(board_config, tile)
		if not special_type.is_empty():
			_draw_special_icon(special_type, tile_rect, minimum_side)


func _draw_special_icon(tile_type: String, tile_rect: Rect2, minimum_side: float) -> void:
	var center := tile_rect.get_center() + Vector2(0.0, minimum_side * 0.08)
	var radius := minimum_side * 0.22
	match tile_type:
		"bonus":
			draw_circle(center + Vector2(2.0, 3.0), radius * 1.18, Color(0.30, 0.13, 0.03, 0.22))
			draw_circle(center, radius * 1.12, Color("#FFF1A0"))
			var star := _make_star(center, radius, radius * 0.45)
			draw_colored_polygon(star, Color("#F6B92C"))
			draw_polyline(star + PackedVector2Array([star[0]]), Color("#874913"), 2.5, true)
			draw_line(center - Vector2(radius * 0.18, radius * 0.48), center - Vector2(radius * 0.42, radius * 0.08), Color("#FFF1A0"), 2.0, true)
		"shield":
			var shield_points := PackedVector2Array([
				center + Vector2(-radius * 0.75, -radius * 0.7),
				center + Vector2(radius * 0.75, -radius * 0.7),
				center + Vector2(radius * 0.62, radius * 0.35),
				center + Vector2(0.0, radius),
				center + Vector2(-radius * 0.62, radius * 0.35),
			])
			var shield_shadow := PackedVector2Array()
			for point: Vector2 in shield_points:
				shield_shadow.append(point + Vector2(2.0, 3.0))
			draw_colored_polygon(shield_shadow, Color(0.12, 0.20, 0.28, 0.32))
			draw_colored_polygon(shield_points, Color("#397CB6"))
			draw_polyline(shield_points + PackedVector2Array([shield_points[0]]), Color("#244965"), 2.5, true)
			draw_line(center + Vector2(0.0, -radius * 0.6), center + Vector2(0.0, radius * 0.58), Color("#8BC8EE"), 2.0, true)


func _make_star(center: Vector2, outer_radius: float, inner_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index: int in range(10):
		var radius := outer_radius if point_index % 2 == 0 else inner_radius
		var angle := -PI / 2.0 + point_index * TAU / 10.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _mapping_has(mapping: Dictionary, tile: int) -> bool:
	return mapping.has(tile) or mapping.has(str(tile))


func _draw_ladder(start: Vector2, destination: Vector2, cell_size: Vector2) -> void:
	var direction := destination - start
	if direction.length() <= 0.0:
		return
	var scale_factor := clampf(minf(cell_size.x, cell_size.y) / 70.0, 0.55, 1.25)
	var perpendicular := direction.normalized().orthogonal() * 8.0 * scale_factor
	var shadow_offset := Vector2(3.0, 5.0) * scale_factor
	for side: float in [-1.0, 1.0]:
		draw_line(start + perpendicular * side + shadow_offset, destination + perpendicular * side + shadow_offset, Color(0.20, 0.09, 0.03, 0.30), 10.0 * scale_factor, true)
	for side: float in [-1.0, 1.0]:
		draw_line(start + perpendicular * side, destination + perpendicular * side, Color("#4A2818"), 9.0 * scale_factor, true)
		draw_line(start + perpendicular * side, destination + perpendicular * side, Color("#D88732"), 5.4 * scale_factor, true)
		draw_line(start + perpendicular * side - perpendicular.normalized() * 1.0, destination + perpendicular * side - perpendicular.normalized() * 1.0, Color("#F5BD5D"), 1.4 * scale_factor, true)
	for step: int in range(1, 8):
		var point := start.lerp(destination, step / 8.0)
		draw_line(point - perpendicular, point + perpendicular, Color("#4A2818"), 6.5 * scale_factor, true)
		draw_line(point - perpendicular, point + perpendicular, Color("#E7A348"), 3.6 * scale_factor, true)


func _draw_snake(start: Vector2, destination: Vector2, cell_size: Vector2, snake_index: int) -> void:
	var direction := destination - start
	if direction.length() <= 0.0:
		return
	var minimum_cell_side := minf(cell_size.x, cell_size.y)
	var scale_factor := clampf(minimum_cell_side / 70.0, 0.55, 1.2)
	var body_width := clampf(minimum_cell_side * 0.12, 7.0, 14.0)
	var wave_amplitude := clampf(minimum_cell_side * 0.18, 10.0, 23.0)
	var travel_direction := direction.normalized()
	var perpendicular_direction := travel_direction.orthogonal()
	var wave_count := 2.0 + float(snake_index % 3) * 0.22
	var phase := float(snake_index % 2) * PI
	var points := PackedVector2Array()
	for step: int in range(49):
		var progress := step / 48.0
		var end_taper := sin(progress * PI)
		var wave_offset := sin(progress * TAU * wave_count + phase) * wave_amplitude * end_taper
		var point := start.lerp(destination, progress) + perpendicular_direction * wave_offset
		points.append(point)
	var colors: Array = SNAKE_PALETTES[snake_index % SNAKE_PALETTES.size()]
	var shadow_points := PackedVector2Array()
	for point: Vector2 in points:
		shadow_points.append(point + Vector2(3.0, 5.0) * scale_factor)
	draw_polyline(shadow_points, Color(0.18, 0.06, 0.04, 0.30), body_width + 7.0 * scale_factor, true)
	draw_polyline(points, colors[0], body_width + 5.0 * scale_factor, true)
	draw_polyline(points, colors[1], body_width, true)
	draw_polyline(points, colors[2], maxf(1.4, body_width * 0.18), true)

	# Rounded spots make the body read like the friendly snakes in the reference.
	for spot_index: int in range(1, 8):
		var progress := spot_index / 8.0
		var end_taper := sin(progress * PI)
		var wave_offset := sin(progress * TAU * wave_count + phase) * wave_amplitude * end_taper
		var spot_center := start.lerp(destination, progress) + perpendicular_direction * wave_offset
		draw_circle(spot_center, maxf(1.2, body_width * 0.19), colors[2])

	_draw_snake_head(start, -travel_direction, colors, body_width, scale_factor)
	# The two tail circles form a clean rounded taper instead of an abrupt line end.
	draw_circle(destination, maxf(2.8, body_width * 0.38), colors[0])
	draw_circle(destination, maxf(1.6, body_width * 0.24), colors[2])


func _draw_snake_head(
	center: Vector2,
	forward: Vector2,
	colors: Array,
	body_width: float,
	scale_factor: float
) -> void:
	var side := forward.orthogonal()
	var head_length := maxf(13.0, body_width * 1.45)
	var head_half_width := maxf(9.0, body_width * 0.9)
	var outer_head := PackedVector2Array([
		center + forward * head_length,
		center + forward * head_length * 0.42 + side * head_half_width,
		center - forward * head_length * 0.35 + side * head_half_width * 0.72,
		center - forward * head_length * 0.58,
		center - forward * head_length * 0.35 - side * head_half_width * 0.72,
		center + forward * head_length * 0.42 - side * head_half_width,
	])
	draw_colored_polygon(outer_head, colors[0])
	var inner_head := PackedVector2Array([
		center + forward * head_length * 0.82,
		center + forward * head_length * 0.34 + side * head_half_width * 0.72,
		center - forward * head_length * 0.28 + side * head_half_width * 0.52,
		center - forward * head_length * 0.44,
		center - forward * head_length * 0.28 - side * head_half_width * 0.52,
		center + forward * head_length * 0.34 - side * head_half_width * 0.72,
	])
	draw_colored_polygon(inner_head, colors[1])

	for eye_side: float in [-1.0, 1.0]:
		var eye_center := center + forward * head_length * 0.34 + side * head_half_width * 0.43 * eye_side
		draw_circle(eye_center, 3.0 * scale_factor, Color.WHITE)
		draw_circle(eye_center + forward * scale_factor, 1.35 * scale_factor, Color("#211922"))

	var mouth_start := center + forward * head_length * 0.55 - side * head_half_width * 0.48
	var mouth_end := center + forward * head_length * 0.64 + side * head_half_width * 0.48
	draw_line(mouth_start, mouth_end, colors[0], maxf(1.2, 1.5 * scale_factor), true)
	var tongue_start := center + forward * head_length * 0.92
	var tongue_end := tongue_start + forward * 8.0 * scale_factor
	draw_line(tongue_start, tongue_end, Color("#B52D48"), maxf(1.2, 1.8 * scale_factor), true)
	draw_line(tongue_end, tongue_end + (forward + side * 0.65).normalized() * 4.0 * scale_factor, Color("#B52D48"), maxf(1.0, 1.4 * scale_factor), true)
	draw_line(tongue_end, tongue_end + (forward - side * 0.65).normalized() * 4.0 * scale_factor, Color("#B52D48"), maxf(1.0, 1.4 * scale_factor), true)


func _ensure_token_sprite(token: Control, sprite_name: String) -> TextureRect:
	var existing := token.get_node_or_null(sprite_name) as TextureRect
	if existing != null:
		return existing
	var sprite := TextureRect.new()
	sprite.name = sprite_name
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	token.add_child(sprite)
	sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	token.move_child(sprite, 0)
	sprite.z_index = 1
	return sprite


func _ensure_board_die() -> BoardDie:
	var existing := get_node_or_null("BoardDie") as BoardDie
	if existing != null:
		return existing
	var die := BoardDie.new()
	die.name = "BoardDie"
	die.z_index = 8
	die.hide()
	add_child(die)
	return die


func _load_token_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


func _load_face_texture(path: String) -> Texture2D:
	var source := _load_token_texture(path)
	if source == null:
		return null
	var source_size := source.get_size()
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return source
	# Every gameplay portrait is a tall chibi sheet. Present only the upper head
	# and shoulder area on board tiles so the token reads as a face portrait.
	var crop_size := floorf(minf(source_size.x * 0.68, source_size.y * 0.40))
	var crop_x := floorf((source_size.x - crop_size) * 0.5)
	var crop_y := floorf(source_size.y * 0.018)
	var portrait := AtlasTexture.new()
	portrait.atlas = source
	portrait.region = Rect2(crop_x, crop_y, crop_size, crop_size)
	portrait.filter_clip = true
	return portrait


func _get_wave_variant_path(path: String) -> String:
	if path.ends_with("_chibi.png"):
		var wave_path := path.trim_suffix("_chibi.png") + "_wave.png"
		if ResourceLoader.exists(wave_path):
			return wave_path
	return path


func _position_tokens() -> void:
	if not is_node_ready() or player_token == null or waiting_hero_token == null or size.x <= 0.0 or columns <= 0 or rows <= 0:
		return
	var board_rect := get_board_rect()
	var cell_size := Vector2(board_rect.size.x / columns, board_rect.size.y / rows)
	var token_size := clampf(minf(cell_size.x, cell_size.y) * 0.98, 44.0, 136.0)
	player_token.size = Vector2(token_size, token_size)
	waiting_hero_token.size = Vector2(token_size, token_size)
	player_token.position = _get_token_top_left(displayed_position, player_token)
	waiting_hero_token.position = _get_token_top_left(columns * rows, waiting_hero_token)
	_sync_sprite_pivots()


func _position_board_die() -> void:
	if board_die == null or not board_die.visible or dice_animation_active:
		return
	var board_rect := get_board_rect()
	var cell_size := Vector2(board_rect.size.x / columns, board_rect.size.y / rows)
	var die_size := clampf(minf(cell_size.x, cell_size.y) * 0.82, 48.0, 88.0)
	board_die.size = Vector2(die_size, die_size)
	board_die.pivot_offset = board_die.size / 2.0
	board_die.position = board_rect.get_center() - board_die.size / 2.0


func _sync_sprite_pivots() -> void:
	if player_sprite != null:
		player_sprite.pivot_offset = player_sprite.size / 2.0
	if waiting_hero_sprite != null:
		waiting_hero_sprite.pivot_offset = Vector2(waiting_hero_sprite.size.x * 0.5, waiting_hero_sprite.size.y * 0.82)


func _restart_idle_animations() -> void:
	_sync_sprite_pivots()
	waiting_animation_active = false
	if player_idle_tween != null:
		player_idle_tween.kill()
	if waiting_idle_tween != null:
		waiting_idle_tween.kill()
	if player_sprite != null and player_sprite.visible:
		player_sprite.rotation = -0.025
		player_sprite.position = Vector2.ZERO
		player_sprite.scale = Vector2(1.12, 1.12)
		player_idle_tween = create_tween().set_loops()
		player_idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		player_idle_tween.tween_property(player_sprite, "rotation", 0.025, 0.68)
		player_idle_tween.parallel().tween_property(player_sprite, "scale", Vector2(1.17, 1.08), 0.68)
		player_idle_tween.parallel().tween_property(player_sprite, "position", Vector2(0.0, -5.0), 0.68)
		player_idle_tween.tween_property(player_sprite, "rotation", -0.025, 0.68)
		player_idle_tween.parallel().tween_property(player_sprite, "scale", Vector2(1.12, 1.12), 0.68)
		player_idle_tween.parallel().tween_property(player_sprite, "position", Vector2.ZERO, 0.68)
	if waiting_hero_sprite != null and waiting_hero_sprite.visible:
		waiting_animation_active = true
		waiting_hero_sprite.rotation = -0.085
		waiting_hero_sprite.position = Vector2.ZERO
		waiting_hero_sprite.scale = Vector2(1.1, 1.1)
		waiting_idle_tween = create_tween().set_loops()
		waiting_idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		waiting_idle_tween.tween_property(waiting_hero_sprite, "rotation", 0.085, 0.42)
		waiting_idle_tween.parallel().tween_property(waiting_hero_sprite, "scale", Vector2(1.15, 1.08), 0.42)
		waiting_idle_tween.parallel().tween_property(waiting_hero_sprite, "position", Vector2(0.0, -4.0), 0.42)
		waiting_idle_tween.tween_property(waiting_hero_sprite, "rotation", -0.085, 0.42)
		waiting_idle_tween.parallel().tween_property(waiting_hero_sprite, "scale", Vector2(1.1, 1.1), 0.42)
		waiting_idle_tween.parallel().tween_property(waiting_hero_sprite, "position", Vector2.ZERO, 0.42)


func _initials(hero_name: String) -> String:
	var result := ""
	for part: String in hero_name.split(" ", false):
		result += part.left(1).to_upper()
		if result.length() >= 3:
			break
	return result if not result.is_empty() else "H"

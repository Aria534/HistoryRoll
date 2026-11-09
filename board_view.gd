extends Control

const BoardRules = preload("res://board_rules.gd")

const FRAME_WIDTH: float = 12.0
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


func _ready() -> void:
	player_sprite = _ensure_token_sprite(player_token, "HeroSprite")
	waiting_hero_sprite = _ensure_token_sprite(waiting_hero_token, "WaitingHeroSprite")
	player_token.z_index = 5
	waiting_hero_token.z_index = 4
	resized.connect(_on_resized)
	queue_redraw()
	call_deferred("set_player_position_immediate", displayed_position)


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

	player_token.tooltip_text = "%s board chibi" % player_name
	player_sprite.texture = _load_token_texture(player_portrait_path)
	player_sprite.visible = player_sprite.texture != null
	player_token_label.text = _initials(player_name)
	player_token_label.visible = not player_sprite.visible

	waiting_hero_token.tooltip_text = "%s next hero" % waiting_name
	var waiting_display_path := _get_wave_variant_path(waiting_portrait_path)
	waiting_hero_sprite.texture = _load_token_texture(waiting_display_path)
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
		draw_rect(tile_rect.grow(-0.8), _get_tile_color(tile, cell), true)
		draw_rect(tile_rect, Color("#76513A"), false, maxf(1.2, minf(cell_size.x, cell_size.y) * 0.018), true)

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
	draw_rect(outer, Color("#4B2B1D"), true)
	draw_rect(outer.grow(-3.0), Color("#B86F32"), true)
	draw_rect(outer.grow(-6.0), Color("#E3A54D"), true)
	draw_rect(board_rect.grow(2.0), Color("#5B3525"), false, 4.0, true)
	draw_line(outer.position + Vector2(8, 7), Vector2(outer.end.x - 8, outer.position.y + 7), Color("#F5C86A"), 2.0, true)
	draw_line(Vector2(outer.position.x + 7, outer.end.y - 6), outer.end - Vector2(7, 6), Color("#7E421F"), 2.0, true)
	var corner_size := FRAME_WIDTH * 1.4
	for corner: Vector2 in [outer.position, Vector2(outer.end.x, outer.position.y), outer.end, Vector2(outer.position.x, outer.end.y)]:
		draw_circle(corner, corner_size * 0.55, Color("#6E3D22"))
		draw_circle(corner, corner_size * 0.34, Color("#D9933F"))


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
	var number_size := clampi(int(minimum_side * 0.25), 12, 29)
	var number_position := tile_rect.position + Vector2(maxf(3.0, minimum_side * 0.06), number_size + maxf(2.0, minimum_side * 0.03))
	draw_string(ThemeDB.fallback_font, number_position + Vector2(1.3, 1.3), str(tile), HORIZONTAL_ALIGNMENT_LEFT, tile_rect.size.x - 6.0, number_size, Color("#F4DDAF"))
	draw_string(ThemeDB.fallback_font, number_position, str(tile), HORIZONTAL_ALIGNMENT_LEFT, tile_rect.size.x - 6.0, number_size, Color("#30251F"))

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
			var star := _make_star(center, radius, radius * 0.45)
			draw_colored_polygon(star, Color("#C58B24"))
			draw_polyline(star + PackedVector2Array([star[0]]), Color("#7B4A19"), 2.0, true)
		"shield":
			var shield_points := PackedVector2Array([
				center + Vector2(-radius * 0.75, -radius * 0.7),
				center + Vector2(radius * 0.75, -radius * 0.7),
				center + Vector2(radius * 0.62, radius * 0.35),
				center + Vector2(0.0, radius),
				center + Vector2(-radius * 0.62, radius * 0.35),
			])
			draw_colored_polygon(shield_points, Color("#4C78A3"))
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


func _draw_ladder(start: Vector2, destination: Vector2, cell_size: Vector2) -> void:
	var direction := destination - start
	if direction.length() <= 0.0:
		return
	var scale_factor := clampf(minf(cell_size.x, cell_size.y) / 70.0, 0.55, 1.25)
	var perpendicular := direction.normalized().orthogonal() * 8.0 * scale_factor
	for side: float in [-1.0, 1.0]:
		draw_line(start + perpendicular * side, destination + perpendicular * side, Color("#5A321D"), 8.0 * scale_factor, true)
		draw_line(start + perpendicular * side, destination + perpendicular * side, Color("#D58B3C"), 4.5 * scale_factor, true)
	for step: int in range(1, 8):
		var point := start.lerp(destination, step / 8.0)
		draw_line(point - perpendicular, point + perpendicular, Color("#5A321D"), 6.0 * scale_factor, true)
		draw_line(point - perpendicular, point + perpendicular, Color("#E4A451"), 3.2 * scale_factor, true)


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


func _load_token_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


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
	var token_size := clampf(minf(cell_size.x, cell_size.y) * 0.86, 38.0, 96.0)
	player_token.size = Vector2(token_size, token_size)
	waiting_hero_token.size = Vector2(token_size, token_size)
	player_token.position = _get_token_top_left(displayed_position, player_token)
	waiting_hero_token.position = _get_token_top_left(columns * rows, waiting_hero_token)
	_sync_sprite_pivots()


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
		player_sprite.scale = Vector2.ONE
		player_idle_tween = create_tween().set_loops()
		player_idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		player_idle_tween.tween_property(player_sprite, "scale", Vector2(1.04, 0.97), 0.72)
		player_idle_tween.tween_property(player_sprite, "scale", Vector2.ONE, 0.72)
	if waiting_hero_sprite != null and waiting_hero_sprite.visible:
		waiting_animation_active = true
		waiting_hero_sprite.rotation = -0.085
		waiting_hero_sprite.scale = Vector2.ONE
		waiting_idle_tween = create_tween().set_loops()
		waiting_idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		waiting_idle_tween.tween_property(waiting_hero_sprite, "rotation", 0.085, 0.42)
		waiting_idle_tween.parallel().tween_property(waiting_hero_sprite, "scale", Vector2(1.04, 0.98), 0.42)
		waiting_idle_tween.tween_property(waiting_hero_sprite, "rotation", -0.085, 0.42)
		waiting_idle_tween.parallel().tween_property(waiting_hero_sprite, "scale", Vector2.ONE, 0.42)


func _initials(hero_name: String) -> String:
	var result := ""
	for part: String in hero_name.split(" ", false):
		result += part.left(1).to_upper()
		if result.length() >= 3:
			break
	return result if not result.is_empty() else "H"

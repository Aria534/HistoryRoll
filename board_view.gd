extends Control

const BoardRules = preload("res://board_rules.gd")
const BOARD_FONT: FontFile = preload("res://assets/fonts/BreeSerif-Regular.ttf")
const SHIELD_ICON: Texture2D = preload("res://assets/gameplay_ui/forest_parchment/shield.svg")

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

const FRAME_WIDTH: float = 26.0
const TILE_SKINS: Array[Texture2D] = [
	preload("res://assets/gameplay_ui/forest_parchment/tile_green.svg"),
	preload("res://assets/gameplay_ui/forest_parchment/tile_cream.svg"),
]
const SNAKE_HEADS: Array[Texture2D] = [
	preload("res://assets/gameplay_ui/forest_parchment/snake_green.png"),
]
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
	# Fill the portrait board, using the same cell geometry for every visual
	# and token destination. This never changes catalog numbering or rules.
	var usable_size := Vector2(maxf(1.0, size.x - FRAME_WIDTH * 2.0), maxf(1.0, size.y - FRAME_WIDTH * 2.0))
	return Rect2(Vector2.ONE * FRAME_WIDTH, usable_size)


func _get_token_top_left(tile: int, token: Control) -> Vector2:
	return get_tile_center(maxi(tile, 1)) - token.size / 2.0


func _on_resized() -> void:
	queue_redraw()
	_position_tokens()
	_position_board_die()
	call_deferred("_restart_idle_animations")


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
	_draw_beveled_box(Rect2(outer.position + Vector2(0, 6), outer.size), Color("#32190C"), 24.0)
	_draw_beveled_box(outer, Color("#4B220C"), 23.0)
	_draw_beveled_box(outer.grow(-4), Color("#E5A84E"), 20.0)
	_draw_beveled_box(outer.grow(-8), Color("#FFE3A0"), 17.0)
	_draw_beveled_box(outer.grow(-12), Color("#B16A28"), 14.0)
	_draw_beveled_box(outer.grow(-18), Color("#7C3C18"), 10.0)
	_draw_beveled_box(outer.grow(-23), Color("#45230E"), 6.0)
	for y: float in [outer.position.y + 16.0, outer.end.y - 16.0]:
		draw_line(Vector2(outer.position.x + 44, y), Vector2(outer.end.x - 44, y), Color("#F2C577"), 2.0)


func _draw_beveled_box(rect: Rect2, color: Color, cut: float) -> void:
	var points := PackedVector2Array([
		rect.position + Vector2(cut, 0), Vector2(rect.end.x - cut, rect.position.y),
		Vector2(rect.end.x, rect.position.y + cut), rect.end - Vector2(0, cut),
		rect.end - Vector2(cut, 0), Vector2(rect.position.x + cut, rect.end.y),
		Vector2(rect.position.x, rect.end.y - cut), rect.position + Vector2(0, cut),
	])
	draw_colored_polygon(points, color)


func _draw_frame_vine(center: Vector2, radius: float) -> void:
	# Chunky paired curls, drawn above the tiles rather than hidden by them.
	for curl: int in range(2):
		var origin := center + Vector2(radius * 0.50, -radius * 0.40) * curl
		var curl_radius := radius * (1.0 if curl == 0 else 0.65)
		var points := PackedVector2Array()
		for step: int in range(29):
			var progress := float(step) / 28.0
			var angle := progress * TAU * 1.20
			var distance := curl_radius * (1.0 - progress * 0.82)
			points.append((origin + Vector2(cos(angle), sin(angle)) * distance).snapped(Vector2(2, 2)))
		draw_polyline(points, Color("#3B270E"), curl_radius * 0.64, false)
		draw_polyline(points, Color("#849D32"), curl_radius * 0.43, false)
		draw_polyline(points, Color("#D9D85C"), curl_radius * 0.13, false)


func _draw_corner_vines(board_rect: Rect2) -> void:
	var outer := board_rect.grow(FRAME_WIDTH)
	var radius := clampf(board_rect.size.x * 0.042, 18.0, 38.0)
	for corner: Vector2 in [
		outer.position + Vector2(8, 8), Vector2(outer.end.x - 8, outer.position.y + 8),
		outer.end - Vector2(8, 8), Vector2(outer.position.x + 8, outer.end.y - 8),
	]:
		_draw_frame_vine(corner, radius)


func _draw_rounded_box(rect: Rect2, color: Color, radius: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.corner_detail = 8
	draw_style_box(style, rect)


func _draw_tile_surface(tile: int, tile_rect: Rect2, cell: Vector2i) -> void:
	draw_texture_rect(TILE_SKINS[(cell.x + cell.y) % 2], tile_rect, false)


func _get_tile_color(tile: int, cell: Vector2i) -> Color:
	return Color("#A2BF73") if (cell.x + cell.y) % 2 == 0 else Color("#FFE1A0")


func _draw_tile_content(tile: int, tile_rect: Rect2) -> void:
	var minimum_side: float = minf(tile_rect.size.x, tile_rect.size.y)
	var number_size := clampi(int(minimum_side * 0.28), 12, 46)
	var badge_size := Vector2(minimum_side * 0.57, minimum_side * 0.40)
	var badge := Rect2(tile_rect.position + Vector2.ONE * minimum_side * 0.08, badge_size)
	_draw_number_badge(badge, str(tile), number_size)

	if BoardRules.is_question_tile(board_config, tile):
		var icon_size := clampi(int(minimum_side * 0.42), 20, 36)
		var icon_position := tile_rect.position + Vector2(0.0, tile_rect.size.y * 0.72)
		draw_string(ThemeDB.fallback_font, icon_position, "?", HORIZONTAL_ALIGNMENT_CENTER, tile_rect.size.x, icon_size, Color("#315A70"))
	else:
		var special_type := BoardRules.get_special_tile_type(board_config, tile)
		if not special_type.is_empty():
			_draw_special_icon(special_type, tile_rect, minimum_side)


func _draw_number_badge(rect: Rect2, text: String, font_size: int) -> void:
	var cut := rect.size.y * 0.24
	var points := PackedVector2Array([
		rect.position + Vector2(cut, 0), Vector2(rect.end.x - cut, rect.position.y),
		Vector2(rect.end.x, rect.position.y + cut), rect.end - Vector2(0, cut),
		rect.end - Vector2(cut, 0), Vector2(rect.position.x + cut, rect.end.y),
		Vector2(rect.position.x, rect.end.y - cut), rect.position + Vector2(0, cut),
	])
	draw_colored_polygon(points, Color("#663315"))
	var border_width := clampf(rect.size.y * 0.09, 1.5, 5.5)
	draw_polyline(points + PackedVector2Array([points[0]]), Color("#351B0D"), border_width, false)
	draw_polyline(points + PackedVector2Array([points[0]]), Color("#FFDB66"), border_width * 0.48, false)
	var text_width := BOARD_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := rect.get_center() + Vector2(-text_width * 0.5, (BOARD_FONT.get_ascent(font_size) - BOARD_FONT.get_descent(font_size)) * 0.5)
	draw_string_outline(BOARD_FONT, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color("#32190B"))
	draw_string(BOARD_FONT, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#FFF2C6"))


func _draw_special_icon(tile_type: String, tile_rect: Rect2, minimum_side: float) -> void:
	var center := tile_rect.position + tile_rect.size * Vector2(0.60, 0.66)
	var radius := minimum_side * 0.28
	match tile_type:
		"bonus":
			for spark: int in range(5):
				var angle := -PI * 0.5 + float(spark) * TAU / 5.0
				var point := center + Vector2(cos(angle), sin(angle)) * radius * 1.35
				draw_circle(point, maxf(1.5, radius * 0.07), Color("#FFC743"))
			var star := _make_star(center, radius, radius * 0.45)
			draw_colored_polygon(star, Color("#F6B92C"))
			for index: int in range(10):
				var facet := PackedVector2Array([center, star[index], star[(index + 1) % 10]])
				draw_colored_polygon(facet, Color("#FFF386") if index % 2 == 0 else Color("#F6AA0B"))
			draw_polyline(star + PackedVector2Array([star[0]]), Color("#12334C"), 3.0, true)
			draw_line(center - Vector2(radius * 0.18, radius * 0.48), center - Vector2(radius * 0.42, radius * 0.08), Color("#FFF1A0"), 2.0, true)
		"shield":
			var icon_rect := Rect2(center - Vector2(radius * 0.85, radius), Vector2(radius * 1.7, radius * 2.0))
			draw_texture_rect(SHIELD_ICON, icon_rect, false)
			var shield_star := _make_star(center - Vector2(0, radius * 0.12), radius * 0.56, radius * 0.22)
			draw_colored_polygon(shield_star, Color("#FFD346"))
			draw_polyline(shield_star + PackedVector2Array([shield_star[0]]), Color("#A96C13"), maxf(1.0, radius * 0.04), false)


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
	var scale_factor := clampf(minf(cell_size.x, cell_size.y) / 70.0, 0.55, 2.15)
	var perpendicular := direction.normalized().orthogonal() * 9.0 * scale_factor
	var shadow_offset := Vector2(3.0, 5.0) * scale_factor
	for side: float in [-1.0, 1.0]:
		draw_line(start + perpendicular * side + shadow_offset, destination + perpendicular * side + shadow_offset, Color(0.20, 0.09, 0.03, 0.30), 10.0 * scale_factor, true)
	for side: float in [-1.0, 1.0]:
		draw_line(start + perpendicular * side, destination + perpendicular * side, Color("#48200B"), 10.0 * scale_factor, true)
		draw_line(start + perpendicular * side, destination + perpendicular * side, Color("#E9A438"), 6.8 * scale_factor, true)
		draw_line(start + perpendicular * side - perpendicular.normalized() * 1.0, destination + perpendicular * side - perpendicular.normalized() * 1.0, Color("#FFDD82"), 1.4 * scale_factor, true)
	var rung_count := maxi(3, int(direction.length() / (18.0 * scale_factor)))
	for step: int in range(1, rung_count):
		var point := start.lerp(destination, float(step) / rung_count)
		draw_line(point - perpendicular, point + perpendicular, Color("#4A2818"), 6.5 * scale_factor, true)
		draw_line(point - perpendicular, point + perpendicular, Color("#E7A348"), 3.6 * scale_factor, true)


func _draw_snake(start: Vector2, destination: Vector2, cell_size: Vector2, snake_index: int) -> void:
	var minimum_cell_side := minf(cell_size.x, cell_size.y)
	var head_side := minimum_cell_side * 0.72
	var head_center := start + Vector2(minimum_cell_side * 0.10, cell_size.y * 0.30)
	# Start the body at the illustrated neck; the catalog head tile is unchanged.
	start = head_center + Vector2(0, head_side * 0.25)
	var direction := destination - start
	if direction.length() <= 0.0:
		return
	var body_width := clampf(minimum_cell_side * 0.30, 12.0, 54.0)
	var wave_amplitude := clampf(minimum_cell_side * 0.42, 12.0, 76.0)
	var travel_direction := direction.normalized()
	var perpendicular_direction := travel_direction.orthogonal()
	var wave_count := clampf(direction.length() / minimum_cell_side * 0.55, 0.85, 1.65)
	var phase := float(snake_index % 2) * PI
	var points := PackedVector2Array()
	for step: int in range(97):
		var progress := step / 96.0
		var end_taper := sin(progress * PI)
		var wave_offset := sin(progress * TAU * wave_count + phase) * wave_amplitude * end_taper
		var point := start.lerp(destination, progress) + perpendicular_direction * wave_offset
		points.append(point)
	var body_colors: Array[Array] = [
		[Color("#3A260D"), Color("#83B82A"), Color("#FFE091")],
		[Color("#3A260D"), Color("#97C236"), Color("#FFE699")],
		[Color("#3A260D"), Color("#72A736"), Color("#FFD87F")],
	]
	var colors: Array = body_colors[snake_index % body_colors.size()]
	# Rounded segments safely support short, tightly curved catalog connections.
	# A closed ribbon can self-intersect on those curves and fail triangulation.
	_draw_tapered_snake(points, body_width + 5.0, colors[0])
	_draw_tapered_snake(points, body_width, colors[1])
	var belly_points := PackedVector2Array()
	for index: int in range(points.size()):
		var previous := points[maxi(0, index - 1)]
		var following := points[mini(points.size() - 1, index + 1)]
		var normal := (following - previous).normalized().orthogonal()
		var taper := 1.0 - pow(float(index) / float(points.size() - 1), 2.1)
		belly_points.append(points[index] + normal * body_width * 0.18 * taper)
	_draw_tapered_snake(belly_points, body_width * 0.38, colors[2])

	# Rounded spots make the body read like the friendly snakes in the reference.
	for spot_index: int in range(1, 8):
		var progress := spot_index / 8.0
		var end_taper := sin(progress * PI)
		var wave_offset := sin(progress * TAU * wave_count + phase) * wave_amplitude * end_taper
		var spot_center := start.lerp(destination, progress) + perpendicular_direction * wave_offset
		var taper := 1.0 - progress * progress
		var sample := clampi(int(progress * (points.size() - 1)), 1, points.size() - 2)
		var normal := (points[sample + 1] - points[sample - 1]).normalized().orthogonal()
		var spot_offset := -normal * body_width * 0.18 * taper
		var spot_radius := maxf(1.2, body_width * 0.19 * taper)
		draw_circle(spot_center + spot_offset, spot_radius + 0.8, Color("#74601B"))
		draw_circle(spot_center + spot_offset, spot_radius, Color("#FFC443"))

	var head_rect := Rect2(head_center - Vector2.ONE * head_side * 0.5, Vector2.ONE * head_side)
	draw_texture_rect(SNAKE_HEADS[snake_index % SNAKE_HEADS.size()], head_rect, false)


func _draw_tapered_snake(points: PackedVector2Array, width: float, color: Color, offset := Vector2.ZERO) -> void:
	for index: int in range(points.size()):
		var progress := float(index) / float(points.size() - 1)
		var radius := width * 0.5 * (1.0 - pow(progress, 2.1)) + 0.6
		var point := points[index] + offset
		draw_circle(point, radius, color, true, -1.0, true)
		if index + 1 < points.size():
			draw_line(point, points[index + 1] + offset, color, radius * 2.0, true)


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
	# Keep the hero recognizable as a face portrait without cropping tightly
	# around the cheeks. The wider head-and-shoulder crop gives the hair,
	# headwear, and costume neckline natural breathing room on the board tile.
	var crop_size := floorf(minf(source_size.x * 0.82, source_size.y * 0.50))
	var crop_x := floorf((source_size.x - crop_size) * 0.5)
	var crop_y := floorf(source_size.y * 0.006)
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
	var token_size := clampf(minf(cell_size.x, cell_size.y) * 0.88, 44.0, 124.0)
	player_token.size = Vector2(token_size, token_size)
	waiting_hero_token.size = Vector2(token_size, token_size)
	player_token.position = _get_token_top_left(displayed_position, player_token)
	waiting_hero_token.position = _get_token_top_left(columns * rows, waiting_hero_token)
	_layout_face_sprite(player_sprite, player_token, cell_size)
	_layout_face_sprite(waiting_hero_sprite, waiting_hero_token, cell_size)
	_sync_sprite_pivots()


func _layout_face_sprite(sprite: TextureRect, token: Control, cell_size: Vector2) -> void:
	if sprite == null:
		return
	# Keep the existing token's movement anchor at the cell center, while the
	# face sits below the number badge and stays inside the tile.
	var face_side := minf(token.size.x * 0.96, minf(cell_size.x * 0.78, cell_size.y * 0.54))
	sprite.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	sprite.size = Vector2.ONE * face_side
	sprite.position = token.size * 0.5 - sprite.size * 0.5 + Vector2(0, cell_size.y * 0.20)


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
	waiting_animation_active = false
	if player_idle_tween != null:
		player_idle_tween.kill()
	if waiting_idle_tween != null:
		waiting_idle_tween.kill()
	# Rebuild the resting positions after stopping the old tweens. Resizing or
	# repeated setup must not use an already-bobbing position as the next origin.
	if columns <= 0 or rows <= 0:
		return
	var board_rect := get_board_rect()
	var cell_size := Vector2(board_rect.size.x / columns, board_rect.size.y / rows)
	_layout_face_sprite(player_sprite, player_token, cell_size)
	_layout_face_sprite(waiting_hero_sprite, waiting_hero_token, cell_size)
	_sync_sprite_pivots()
	if player_sprite != null and player_sprite.visible:
		player_sprite.rotation = -0.025
		var player_rest := player_sprite.position
		player_sprite.scale = Vector2.ONE
		player_idle_tween = create_tween().set_loops()
		player_idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		player_idle_tween.tween_property(player_sprite, "rotation", 0.025, 0.68)
		player_idle_tween.parallel().tween_property(player_sprite, "scale", Vector2(1.05, 0.98), 0.68)
		player_idle_tween.parallel().tween_property(player_sprite, "position", player_rest + Vector2(0.0, -3.0), 0.68)
		player_idle_tween.tween_property(player_sprite, "rotation", -0.025, 0.68)
		player_idle_tween.parallel().tween_property(player_sprite, "scale", Vector2.ONE, 0.68)
		player_idle_tween.parallel().tween_property(player_sprite, "position", player_rest, 0.68)
	if waiting_hero_sprite != null and waiting_hero_sprite.visible:
		waiting_animation_active = true
		waiting_hero_sprite.rotation = -0.105
		var waiting_rest := waiting_hero_sprite.position
		var greeting_lift := clampf(waiting_hero_sprite.size.y * 0.08, 2.0, 7.0)
		waiting_hero_sprite.scale = Vector2.ONE
		waiting_idle_tween = create_tween().set_loops()
		waiting_idle_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		waiting_idle_tween.tween_property(waiting_hero_sprite, "rotation", 0.105, 0.5)
		waiting_idle_tween.parallel().tween_property(waiting_hero_sprite, "scale", Vector2(1.035, 0.99), 0.5)
		waiting_idle_tween.parallel().tween_property(waiting_hero_sprite, "position", waiting_rest + Vector2(0.0, -greeting_lift), 0.5)
		waiting_idle_tween.tween_property(waiting_hero_sprite, "rotation", -0.105, 0.5)
		waiting_idle_tween.parallel().tween_property(waiting_hero_sprite, "scale", Vector2.ONE, 0.5)
		waiting_idle_tween.parallel().tween_property(waiting_hero_sprite, "position", waiting_rest, 0.5)


func _initials(hero_name: String) -> String:
	var result := ""
	for part: String in hero_name.split(" ", false):
		result += part.left(1).to_upper()
		if result.length() >= 3:
			break
	return result if not result.is_empty() else "H"

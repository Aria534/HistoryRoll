@tool
extends TextureRect

# Decorative loading artwork only; playable level boards use their own rules.
# Full-image coordinates include the gate, keeping its doorway attached on resize.
const ART_SIZE := Vector2(1536.0, 1024.0)
const ROAD_TOP := 195.0
const NUMBER_FONT := preload("res://assets/splash_ui/hero_board/tile_font.tres")
const LADDER_TEXTURE := preload("res://assets/splash_ui/hero_board/natural_ladder.png")
const LADDER_REGION := Rect2(48, 74, 628, 2031)
# Both ends rest within numbered road faces, away from the centered lettering.
const LADDER_PLACEMENTS := [
	{"bottom": Vector2(725, 740), "top": Vector2(530, 411), "width": 86.0},
	{"bottom": Vector2(985, 932), "top": Vector2(1060, 585), "width": 92.0},
]
# Clockwise face outlines traced from the artwork, in START-to-gate order.
# Curved turns count as tiles too. Adjacent cream faces still have divider seams.
var TILE_POLYGONS: Array[PackedVector2Array] = [
	PackedVector2Array([Vector2(220,855), Vector2(448,855), Vector2(430,960), Vector2(170,950)]),
	PackedVector2Array([Vector2(448,855), Vector2(620,855), Vector2(626,960), Vector2(430,960)]),
	PackedVector2Array([Vector2(620,855), Vector2(784,855), Vector2(804,960), Vector2(626,960)]),
	PackedVector2Array([Vector2(784,855), Vector2(965,850), Vector2(1002,955), Vector2(804,960)]),
	PackedVector2Array([Vector2(965,850), Vector2(1155,853), Vector2(1188,960), Vector2(1002,955)]),
	PackedVector2Array([Vector2(1155,853), Vector2(1285,820), Vector2(1400,870), Vector2(1350,920), Vector2(1188,960)]),
	PackedVector2Array([Vector2(1240,690), Vector2(1345,715), Vector2(1415,780), Vector2(1400,870), Vector2(1285,820), Vector2(1261,795), Vector2(1228,775)]),
	PackedVector2Array([Vector2(1124,690), Vector2(1240,690), Vector2(1228,775), Vector2(1101,775)]),
	PackedVector2Array([Vector2(720,690), Vector2(1124,690), Vector2(1101,775), Vector2(708,775)]),
	PackedVector2Array([Vector2(525,690), Vector2(720,690), Vector2(708,775), Vector2(510,775)]),
	PackedVector2Array([Vector2(350,690), Vector2(525,690), Vector2(510,775), Vector2(335,775)]),
	PackedVector2Array([Vector2(190,685), Vector2(350,690), Vector2(335,775), Vector2(140,745)]),
	PackedVector2Array([Vector2(46,658), Vector2(165,649), Vector2(190,685), Vector2(140,745), Vector2(80,710), Vector2(45,670)]),
	PackedVector2Array([Vector2(46,658), Vector2(62,599), Vector2(100,550), Vector2(205,522), Vector2(240,610), Vector2(165,649)]),
	PackedVector2Array([Vector2(205,522), Vector2(535,526), Vector2(645,532), Vector2(628,615), Vector2(240,610)]),
	PackedVector2Array([Vector2(645,532), Vector2(840,531), Vector2(837,615), Vector2(628,615)]),
	PackedVector2Array([Vector2(840,531), Vector2(1024,531), Vector2(1042,615), Vector2(837,615)]),
	PackedVector2Array([Vector2(1024,531), Vector2(1240,513), Vector2(1290,610), Vector2(1042,615)]),
	PackedVector2Array([Vector2(1240,505), Vector2(1434,509), Vector2(1405,560), Vector2(1360,590), Vector2(1290,610)]),
	PackedVector2Array([Vector2(986,384), Vector2(1200,380), Vector2(1325,405), Vector2(1410,445), Vector2(1434,509), Vector2(1240,505), Vector2(1235,480), Vector2(1196,461), Vector2(975,460)]),
	PackedVector2Array([Vector2(764,384), Vector2(986,384), Vector2(975,460), Vector2(757,461)]),
	PackedVector2Array([Vector2(574,384), Vector2(764,384), Vector2(757,461), Vector2(553,460)]),
	PackedVector2Array([Vector2(361,382), Vector2(574,384), Vector2(553,460), Vector2(325,446)]),
	PackedVector2Array([Vector2(154,340), Vector2(289,348), Vector2(320,369), Vector2(361,382), Vector2(325,446), Vector2(220,420), Vector2(170,380)]),
	PackedVector2Array([Vector2(495,225), Vector2(470,311), Vector2(340,313), Vector2(290,328), Vector2(289,348), Vector2(154,340), Vector2(170,292), Vector2(230,255), Vector2(330,229)]),
	PackedVector2Array([Vector2(495,225), Vector2(669,229), Vector2(656,313), Vector2(470,311)]),
	PackedVector2Array([Vector2(669,229), Vector2(824,229), Vector2(837,314), Vector2(656,313)]),
	PackedVector2Array([Vector2(824,229), Vector2(1005,229), Vector2(1024,312), Vector2(837,314)]),
	PackedVector2Array([Vector2(1005,229), Vector2(1152,228), Vector2(1173,305), Vector2(1024,312)]),
	PackedVector2Array([Vector2(1155,235), Vector2(1235,242), Vector2(1275,264), Vector2(1300,282), Vector2(1265,305), Vector2(1220,313), Vector2(1155,313)]),
]

var TILE_CENTERS: Array[Vector2] = []
var _number_font: FontVariation
var _ink_cache: Dictionary = {}
var _ladder_texture: AtlasTexture


func _ready() -> void:
	_prepare_number_font()
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)
	queue_redraw()


func _prepare_number_font() -> void:
	if TILE_CENTERS.is_empty():
		for polygon: PackedVector2Array in TILE_POLYGONS:
			TILE_CENTERS.append(_polygon_center(polygon))
	if _number_font != null:
		return
	# Keep raster settings local; other screens also use the original Lora font.
	_number_font = NUMBER_FONT.duplicate() as FontVariation
	var font_face := _number_font.base_font.duplicate() as FontFile
	font_face.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font_face.oversampling = 2.0
	_number_font.base_font = font_face


func _polygon_center(polygon: PackedVector2Array) -> Vector2:
	var twice_area := 0.0
	var weighted_sum := Vector2.ZERO
	for index: int in polygon.size():
		var a := polygon[index]
		var b := polygon[(index + 1) % polygon.size()]
		var cross := a.cross(b)
		twice_area += cross
		weighted_sum += (a + b) * cross
	var centroid := weighted_sum / (3.0 * twice_area)
	# A concave bend can put its area centroid beside/outside the usable face.
	# Use the deepest interior center, preferring the centroid on broad flat faces.
	var best := centroid
	var best_score := _center_score(best, polygon, centroid)
	var search := Rect2(polygon[0], Vector2.ZERO)
	for point: Vector2 in polygon:
		search = search.expand(point)
	for step: float in [16.0, 4.0, 1.0]:
		var y := search.position.y
		while y <= search.end.y:
			var x := search.position.x
			while x <= search.end.x:
				var point := Vector2(x, y)
				var score := _center_score(point, polygon, centroid)
				if score > best_score:
					best = point
					best_score = score
				x += step
			y += step
		search = Rect2(best - Vector2.ONE * step, Vector2.ONE * step * 2.0)
	return best


func _center_score(point: Vector2, polygon: PackedVector2Array, centroid: Vector2) -> float:
	if not Geometry2D.is_point_in_polygon(point, polygon):
		return -INF
	var distance := INF
	for index: int in polygon.size():
		var a := polygon[index]
		var edge := polygon[(index + 1) % polygon.size()] - a
		var amount := clampf((point - a).dot(edge) / edge.length_squared(), 0.0, 1.0)
		distance = minf(distance, point.distance_to(a + edge * amount))
	return distance - point.distance_to(centroid) * 0.01

func get_number_layout(index: int) -> Dictionary:
	_prepare_number_font()
	if index < 0 or index >= TILE_CENTERS.size() or size.x <= 0.0 or size.y <= 0.0:
		return {}
	var factor := minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	var origin := (size - ART_SIZE * factor) * 0.5
	var center := origin + TILE_CENTERS[index] * factor
	var font_size := maxi(12, roundi(72.0 * factor))
	var text := str(index + 1)
	var ink := _measure_ink(text, font_size)
	# Center visible ink, including italic overhang, rather than advance/line height.
	var baseline := (center - ink.get_center()).round()
	while font_size > 8 and not _fits_face(index, Rect2(baseline + ink.position, ink.size), origin, factor):
		font_size -= 1
		ink = _measure_ink(text, font_size)
		baseline = (center - ink.get_center()).round()
	return {"text": text, "center": center, "baseline": baseline,
		"bounds": Rect2(baseline + ink.position, ink.size), "font_size": font_size}


func _fits_face(index: int, bounds: Rect2, origin: Vector2, factor: float) -> bool:
	for corner: Vector2 in [bounds.position, Vector2(bounds.end.x, bounds.position.y),
		bounds.end, Vector2(bounds.position.x, bounds.end.y)]:
		if not Geometry2D.is_point_in_polygon((corner - origin) / factor, TILE_POLYGONS[index]):
			return false
	return true

func _measure_ink(text: String, font_size: int) -> Rect2:
	var key := "%s:%d" % [text, font_size]
	if _ink_cache.has(key):
		return _ink_cache[key]
	var line := TextLine.new()
	line.add_string(text, _number_font, font_size)
	var server := TextServerManager.get_primary_interface()
	var bounds := Rect2()
	var has_ink := false
	var advance := 0.0
	for glyph: Dictionary in server.shaped_text_get_glyphs(line.get_rid()):
		var raster_size := Vector2i(glyph.font_size, 0)
		var offset := server.font_get_glyph_offset(glyph.font_rid, raster_size, glyph.index)
		var glyph_size := server.font_get_glyph_size(glyph.font_rid, raster_size, glyph.index)
		for repeat_index: int in int(glyph.repeat):
			if glyph_size.x > 0.0 and glyph_size.y > 0.0:
				var box := Rect2(Vector2(advance, 0.0) + glyph.offset + offset, glyph_size)
				bounds = bounds.merge(box) if has_ink else box
				has_ink = true
			advance += float(glyph.advance)
	_ink_cache[key] = bounds
	return bounds


func _draw() -> void:
	if texture == null or size.x <= 0.0 or size.y <= 0.0:
		return
	_prepare_number_font()
	var factor := minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	var origin := (size - ART_SIZE * factor) * 0.5
	_draw_ladder(origin, factor)
	for index: int in TILE_CENTERS.size():
		var layout := get_number_layout(index)
		draw_string(_number_font, layout.baseline, layout.text, HORIZONTAL_ALIGNMENT_LEFT,
			-1, layout.font_size, Color("#261006"))


func _draw_ladder(origin: Vector2, factor: float) -> void:
	if _ladder_texture == null:
		_ladder_texture = AtlasTexture.new()
		_ladder_texture.atlas = LADDER_TEXTURE
		_ladder_texture.region = LADDER_REGION
		_ladder_texture.filter_clip = true
	for placement: Dictionary in LADDER_PLACEMENTS:
		var bottom: Vector2 = placement.bottom
		var top: Vector2 = placement.top
		var width: float = placement.width
		var direction := top - bottom
		var angle := direction.angle() + PI * 0.5
		var across := Vector2.RIGHT.rotated(angle)
		# Small floor-contact shadows under each rail end anchor the wood to the tiles.
		for end: Vector2 in [bottom, top]:
			var spread := width * (0.38 if end == bottom else 0.32)
			for side: float in [-1.0, 1.0]:
				var foot := end + across * spread * side
				draw_set_transform(origin + foot * factor, 0.0, Vector2(width * 0.13, 3.5) * factor)
				draw_circle(Vector2.ZERO, 1.0, Color(0.22, 0.10, 0.03, 0.25))
		var center := origin + (bottom + top) * 0.5 * factor
		draw_set_transform(center, angle, Vector2.ONE * factor)
		var sprite_rect := Rect2(Vector2(-width * 0.5, -direction.length() * 0.5),
			Vector2(width, direction.length()))
		draw_texture_rect(_ladder_texture, sprite_rect, false)
	# Restore the board's coordinates before the number labels are drawn.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

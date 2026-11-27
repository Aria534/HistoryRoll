@tool
extends TextureRect

# Decorative loading-screen artwork, independent of the playable level boards.
# Coordinates match winding_board_perspective.png after its AtlasTexture crop.
const ART_SIZE := Vector2(1536.0, 859.0)
const NUMBER_FONT := preload("res://assets/splash_ui/hero_board/tile_font.tres")
const TILE_CENTERS: Array[Vector2] = [
	Vector2(324, 759),
	Vector2(555, 751),
	Vector2(738, 751),
	Vector2(902, 751),
	Vector2(1130, 751),
	Vector2(1320, 721),
	Vector2(1404, 624),
	Vector2(1178, 560),
	Vector2(948, 556),
	Vector2(825, 558),
	Vector2(656, 559),
	Vector2(475, 569),
	Vector2(108, 479),
	Vector2(169, 387),
	Vector2(290, 370),
	Vector2(534, 373),
	Vector2(632, 391),
	Vector2(752, 385),
	Vector2(978, 385),
	Vector2(1355, 362),
	Vector2(1350, 262),
	Vector2(1160, 245),
	Vector2(966, 241),
	Vector2(698, 243),
	Vector2(505, 245),
	Vector2(262, 168),
	Vector2(422, 90),
	Vector2(615, 90),
	Vector2(1060, 86),
	Vector2(1234, 79),
]


func _ready() -> void:
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if texture == null or size.x <= 0.0 or size.y <= 0.0:
		return
	# Include KEEP_ASPECT_CENTERED letterboxing when resized in the Editor.
	var factor := minf(size.x / ART_SIZE.x, size.y / ART_SIZE.y)
	var art_size := ART_SIZE * factor
	var art_origin := (size - art_size) * 0.5
	var outline_size := maxi(1, roundi(4.0 * factor))
	for index: int in TILE_CENTERS.size():
		var source_font_size := 60.0 if index == 8 or index == 15 else 74.0
		var font_size := maxi(12, roundi(source_font_size * factor))
		var baseline := (NUMBER_FONT.get_ascent(font_size) - NUMBER_FONT.get_descent(font_size)) * 0.5
		var text := str(index + 1)
		var width := NUMBER_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var point := art_origin + TILE_CENTERS[index] * factor + Vector2(-width * 0.5, baseline)
		draw_string_outline(NUMBER_FONT, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, Color("#FFF8E9"))
		draw_string(NUMBER_FONT, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#321308"))

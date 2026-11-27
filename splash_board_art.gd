@tool
extends TextureRect

# Decorative loading-screen path only; gameplay board rules are unchanged.
# Positions were checked against the 1536x1024 winding_board.png illustration.
const ART_SIZE := Vector2(1536.0, 1024.0)
const NUMBER_FONT := preload("res://assets/fonts/BreeSerif-Regular.ttf")
const TILE_CENTERS: Array[Vector2] = [
	Vector2(250, 909), Vector2(509, 909), Vector2(701, 909),
	Vector2(911, 909), Vector2(1115, 909), Vector2(1318, 909),
	Vector2(1250, 735), Vector2(1106, 735), Vector2(897, 735),
	Vector2(684, 735), Vector2(510, 735), Vector2(252, 735),
	Vector2(280, 532), Vector2(477, 532), Vector2(669, 532),
	Vector2(874, 532), Vector2(1076, 532), Vector2(1304, 552),
	Vector2(1310, 333), Vector2(1180, 315), Vector2(900, 332),
	Vector2(689, 332), Vector2(498, 332), Vector2(287, 332),
	Vector2(300, 125), Vector2(494, 132), Vector2(690, 132),
	Vector2(903, 132), Vector2(1115, 130), Vector2(1327, 130),
]


func _ready() -> void:
	if not resized.is_connected(queue_redraw):
		resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	if texture == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var factor := size.x / ART_SIZE.x
	var outline_size := maxi(1, roundi(4.0 * factor))
	for index: int in TILE_CENTERS.size():
		# Tile 20's clear face is narrower beside the illustrated ladder.
		var font_size := maxi(12, roundi((52.0 if index == 19 else 72.0) * factor))
		var baseline := (NUMBER_FONT.get_ascent(font_size) - NUMBER_FONT.get_descent(font_size)) * 0.5
		var text := str(index + 1)
		var width := NUMBER_FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var point := TILE_CENTERS[index] / ART_SIZE * size
		point += Vector2(-width * 0.5, baseline)
		draw_string_outline(NUMBER_FONT, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_size, Color("#FFF6DA"))
		draw_string(NUMBER_FONT, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#3F1B0B"))

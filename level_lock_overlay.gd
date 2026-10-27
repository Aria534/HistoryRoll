@tool
extends Control

const LOCK_GOLD := Color("#FFD43B")
const LOCK_OUTLINE := Color("#5C3900")
const COVER_BLUE := Color("#214F78")
const COVER_BLUE_DARK := Color("#082B51")
const COVER_HIGHLIGHT := Color("#4B7897")
const TEXT_COLOR := Color("#D6D8D8")
const TEXT_OUTLINE := Color("#0B2B59")
const LOCK_HEIGHT_RATIO := 0.50
const HERO_SURNAMES: PackedStringArray = [
	"LAPU-LAPU",
	"BONIFACIO",
	"RIZAL",
	"LUNA",
	"AQUINO",
	"MABINI",
]

@export_range(1, 6, 1) var level_number: int = 1:
	set(value):
		level_number = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func get_padlock_rect() -> Rect2:
	var icon_size := minf(size.y * LOCK_HEIGHT_RATIO, size.x * 0.20)
	return Rect2((size - Vector2.ONE * icon_size) * 0.5, Vector2.ONE * icon_size)


func get_concealment_rect() -> Rect2:
	return Rect2(size.x * 0.055, size.y * 0.16, size.x * 0.89, size.y * 0.68)


func get_left_text_rect() -> Rect2:
	return Rect2(size.x * 0.08, size.y * 0.22, size.x * 0.325, size.y * 0.56)


func get_right_text_rect() -> Rect2:
	return Rect2(size.x * 0.595, size.y * 0.22, size.x * 0.325, size.y * 0.56)


func get_hero_surname() -> String:
	var index := level_number - 1
	return HERO_SURNAMES[index] if index >= 0 and index < HERO_SURNAMES.size() else "HERO"


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	_draw_name_concealment()
	_draw_locked_text()
	_draw_padlock(get_padlock_rect())


func _draw_name_concealment() -> void:
	var cover_rect := get_concealment_rect()
	var cover := StyleBoxFlat.new()
	cover.bg_color = COVER_BLUE
	cover.border_color = COVER_BLUE_DARK
	var border_width := maxi(2, roundi(size.y * 0.025))
	cover.set_border_width_all(border_width)
	var corner_radius := maxi(8, roundi(cover_rect.size.y * 0.48))
	cover.set_corner_radius_all(corner_radius)
	draw_style_box(cover, cover_rect)
	var highlight_y := cover_rect.position.y + float(border_width) + 2.0
	draw_line(
		Vector2(cover_rect.position.x + cover_rect.size.y * 0.34, highlight_y),
		Vector2(cover_rect.end.x - cover_rect.size.y * 0.34, highlight_y),
		COVER_HIGHLIGHT,
		maxf(1.0, size.y * 0.018),
		true
	)


func _draw_locked_text() -> void:
	var font := FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.variation_embolden = 1.2
	_draw_fitted_text(font, "LEVEL %d -" % level_number, get_left_text_rect())
	_draw_fitted_text(font, get_hero_surname(), get_right_text_rect())


func _draw_fitted_text(font: Font, text: String, rect: Rect2) -> void:
	var font_size := maxi(12, roundi(size.y * 0.245))
	while font_size > 12 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > rect.size.x:
		font_size -= 1
	var baseline_y := rect.get_center().y + (font.get_ascent(font_size) - font.get_descent(font_size)) * 0.5
	var baseline := Vector2(rect.position.x, baseline_y)
	var outline_size := maxi(2, roundi(size.y * 0.028))
	draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, outline_size, TEXT_OUTLINE)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, TEXT_COLOR)


func _draw_padlock(rect: Rect2) -> void:
	var unit := rect.size.y / 54.0
	var center := rect.position + Vector2(27.0, 23.0) * unit
	draw_arc(center, 13.0 * unit, PI, TAU, 24, LOCK_OUTLINE, 9.0 * unit, true)
	draw_arc(center, 13.0 * unit, PI, TAU, 24, LOCK_GOLD, 5.0 * unit, true)

	var outline_box := StyleBoxFlat.new()
	outline_box.bg_color = LOCK_OUTLINE
	outline_box.set_corner_radius_all(maxi(2, roundi(7.0 * unit)))
	draw_style_box(outline_box, Rect2(rect.position + Vector2(4.0, 21.0) * unit, Vector2(46.0, 32.0) * unit))

	var gold_box := StyleBoxFlat.new()
	gold_box.bg_color = LOCK_GOLD
	gold_box.set_corner_radius_all(maxi(2, roundi(5.0 * unit)))
	draw_style_box(gold_box, Rect2(rect.position + Vector2(8.0, 25.0) * unit, Vector2(38.0, 24.0) * unit))

	draw_circle(rect.position + Vector2(27.0, 35.0) * unit, 3.5 * unit, LOCK_OUTLINE, true)
	draw_rect(Rect2(rect.position + Vector2(25.0, 35.0) * unit, Vector2(4.0, 9.0) * unit), LOCK_OUTLINE, true)

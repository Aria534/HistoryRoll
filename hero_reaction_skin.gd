extends RefCounted
## Styles the existing happy/sad answer popup without changing scene nodes.

const FRAME: Texture2D = preload("res://assets/gameplay_ui/reaction_popup/success_frame.png")
const INCORRECT_FRAME: Texture2D = preload("res://assets/gameplay_ui/reaction_popup/incorrect_frame.png")
const LETTERING: Font = preload("res://assets/fonts/TitanOne-Regular.ttf")
const POPUP_PROPERTIES := [
	"anchor_left", "anchor_top", "anchor_right", "anchor_bottom",
	"offset_left", "offset_top", "offset_right", "offset_bottom",
	"custom_minimum_size", "texture_filter",
]

var _popup: PanelContainer
var _face: TextureRect
var _title: Label
var _score: Label
var _content: VBoxContainer
var _face_center: CenterContainer
var _face_frame: PanelContainer
var _defaults: Dictionary = {}
var _active := false
var _frame_texture: Texture2D = FRAME


func configure(popup: PanelContainer, face: TextureRect, title: Label, score: Label) -> void:
	_popup = popup
	_face = face
	_title = title
	_score = score
	_content = popup.get_node("ReactionContent") as VBoxContainer
	_face_center = popup.get_node("ReactionContent/FaceCenter") as CenterContainer
	_face_frame = face.get_parent() as PanelContainer
	for property: String in POPUP_PROPERTIES:
		_defaults[property] = popup.get(property)
	_defaults["panel"] = popup.get_theme_stylebox("panel")
	_defaults["face_panel"] = _face_frame.get_theme_stylebox("panel")
	_defaults["face_minimum"] = _face_frame.custom_minimum_size
	_defaults["center_minimum"] = _face_center.custom_minimum_size
	_defaults["separation"] = _content.get_theme_constant("separation")
	_defaults["title_size"] = title.get_theme_font_size("font_size")
	_defaults["score_size"] = score.get_theme_font_size("font_size")
	_defaults["title_outline"] = title.get_theme_constant("outline_size")
	_defaults["score_outline"] = score.get_theme_constant("outline_size")
	_defaults["title_font"] = title.get_theme_font("font")
	_defaults["score_font"] = score.get_theme_font("font")
	_defaults["title_outline_color"] = title.get_theme_color("font_outline_color")
	_defaults["score_outline_color"] = score.get_theme_color("font_outline_color")


func apply_success() -> void:
	_frame_texture = FRAME
	_active = true
	update_layout()


func apply_incorrect() -> void:
	_frame_texture = INCORRECT_FRAME
	_active = true
	update_layout()


func restore() -> void:
	if not _active:
		return
	_active = false
	_content.add_theme_constant_override("separation", int(_defaults.separation))
	_face_frame.custom_minimum_size = _defaults.face_minimum
	_face_center.custom_minimum_size = _defaults.center_minimum
	_face_frame.add_theme_stylebox_override("panel", _defaults.face_panel)
	_title.add_theme_font_size_override("font_size", int(_defaults.title_size))
	_score.add_theme_font_size_override("font_size", int(_defaults.score_size))
	_title.add_theme_constant_override("outline_size", int(_defaults.title_outline))
	_score.add_theme_constant_override("outline_size", int(_defaults.score_outline))
	_title.add_theme_font_override("font", _defaults.title_font)
	_score.add_theme_font_override("font", _defaults.score_font)
	_title.add_theme_color_override("font_outline_color", _defaults.title_outline_color)
	_score.add_theme_color_override("font_outline_color", _defaults.score_outline_color)
	_popup.add_theme_stylebox_override("panel", _defaults.panel)
	for property: String in POPUP_PROPERTIES:
		_popup.set(property, _defaults[property])


func update_layout() -> void:
	if not _active or not is_instance_valid(_popup):
		return
	var screen := _popup.get_viewport_rect().size
	var ratio := _frame_texture.get_size().aspect()
	var width := minf(minf(screen.x * 0.96, 1000.0), screen.y * 0.68 * ratio)
	var height := width / ratio
	var ui_scale := width / 1000.0
	var separation := maxf(5.0, 10.0 * ui_scale)
	var style := StyleBoxTexture.new()
	style.texture = _frame_texture
	# The art has transparent decoration outside its central colored writing area.
	style.content_margin_left = width * 0.205
	style.content_margin_right = width * 0.205
	style.content_margin_top = height * 0.205
	style.content_margin_bottom = height * 0.19
	_popup.add_theme_stylebox_override("panel", style)
	_popup.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_content.add_theme_constant_override("separation", roundi(separation))
	_title.add_theme_font_override("font", LETTERING)
	_score.add_theme_font_override("font", LETTERING)
	_title.add_theme_color_override("font_outline_color", Color("#35200C"))
	_score.add_theme_color_override("font_outline_color", Color("#3E2A0C"))
	var title_size := maxi(28, roundi(width * 0.072))
	var score_size := maxi(22, roundi(width * 0.044))
	_title.add_theme_font_size_override("font_size", title_size)
	_score.add_theme_font_size_override("font_size", score_size)
	_title.add_theme_constant_override("outline_size", maxi(4, roundi(8.0 * ui_scale)))
	_score.add_theme_constant_override("outline_size", maxi(2, roundi(4.0 * ui_scale)))
	var text_height := _title.get_theme_font("font").get_height(title_size) + _score.get_theme_font("font").get_height(score_size)
	var face_side := minf(height * 0.43, height * 0.605 - text_height - separation * 2.0)
	face_side = maxf(72.0, floorf(face_side))
	_face_center.custom_minimum_size = Vector2(0.0, face_side)
	_face_frame.custom_minimum_size = Vector2.ONE * face_side
	var portrait := StyleBoxFlat.new()
	portrait.bg_color = Color("#FFF0C3")
	portrait.border_color = Color("#FFD15B")
	portrait.set_border_width_all(maxi(3, roundi(7.0 * ui_scale)))
	portrait.set_corner_radius_all(roundi(21.0 * ui_scale))
	portrait.shadow_color = Color("#5A2B0D")
	portrait.shadow_size = maxi(2, roundi(4.0 * ui_scale))
	for side: Side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		portrait.set_content_margin(side, maxf(6.0, 10.0 * ui_scale))
	_face_frame.add_theme_stylebox_override("panel", portrait)
	_popup.custom_minimum_size = Vector2.ZERO
	_popup.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_popup.size = Vector2(width, height)
	_popup.position = (screen - _popup.size) * 0.5
	_popup.pivot_offset = _popup.size * 0.5

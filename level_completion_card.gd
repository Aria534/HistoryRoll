extends PanelContainer
## Presentation only. Scores and progression remain owned by gameplay/ProgressManager.

@onready var shade: ColorRect = $ResultsShade
@onready var canvas: Control = $ResultsMargin/ResultsContent
@onready var artwork: TextureRect = $ResultsMargin/ResultsContent/CardArtwork
@onready var great_job_label: Label = $ResultsMargin/ResultsContent/GreatJobLabel
@onready var level_title: Label = $ResultsMargin/ResultsContent/LevelCompletionTitle
@onready var your_score_heading: Label = $ResultsMargin/ResultsContent/YourScoreHeading
@onready var bonus_score_heading: Label = $ResultsMargin/ResultsContent/BonusScoreHeading
@onready var total_score_heading: Label = $ResultsMargin/ResultsContent/TotalScoreHeading
@onready var your_score_label: Label = $ResultsMargin/ResultsContent/YourScoreValue
@onready var bonus_score_label: Label = $ResultsMargin/ResultsContent/BonusScoreValue
@onready var total_score_label: Label = $ResultsMargin/ResultsContent/TotalScoreValue
@onready var summary_label: Label = $ResultsMargin/ResultsContent/ResultsLabel
@onready var continue_button: Button = $ResultsMargin/ResultsContent/ReturnButton

var _card_rect := Rect2()
var _ui_scale := 1.0
var _showing_error := false
var _entrance_tween: Tween
var _button_styles: Dictionary = {}


func _ready() -> void:
	for style_name: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		_button_styles[style_name] = continue_button.get_theme_stylebox(style_name)
	resized.connect(_apply_layout)
	_apply_layout.call_deferred()


func present_completion(level_number: int, final_score: int, earned_bonus: int) -> void:
	_showing_error = false
	artwork.show()
	for label: Label in _completion_labels():
		label.show()
	summary_label.hide()
	level_title.text = "Level %d Completed" % level_number
	# score already includes bonuses and penalties. Subtract the recorded bonus
	# to show the net non-bonus subtotal; never award or add it a second time.
	# This accounting subtotal can be negative if penalties used bonus points.
	your_score_label.text = format_score(final_score - earned_bonus)
	bonus_score_label.text = format_score(earned_bonus)
	total_score_label.text = format_score(final_score)
	your_score_label.tooltip_text = "Score after deductions, before bonus points."
	bonus_score_label.tooltip_text = "Bonus points already included in the total."
	total_score_label.tooltip_text = "Final score saved for this level."
	for style_name: String in _button_styles:
		continue_button.add_theme_stylebox_override(style_name, _button_styles[style_name])
	continue_button.text = "Continue"
	continue_button.tooltip_text = "Return to Level Selection."
	show()
	_apply_layout()
	_animate_in.call_deferred()


func present_error(message: String) -> void:
	_showing_error = true
	_stop_entrance()
	artwork.hide()
	for label: Label in _completion_labels():
		label.hide()
	summary_label.text = message
	summary_label.show()
	canvas.scale = Vector2.ONE
	canvas.modulate.a = 1.0
	continue_button.tooltip_text = "Return to Level Selection."
	var error_button := StyleBoxFlat.new()
	error_button.bg_color = Color("#236D27")
	error_button.border_color = Color("#FFD45A")
	error_button.set_border_width_all(3)
	error_button.set_corner_radius_all(20)
	for style_name: String in ["normal", "hover", "pressed"]:
		continue_button.add_theme_stylebox_override(style_name, error_button)
	show()
	_apply_layout()
	continue_button.grab_focus()


static func format_score(value: int) -> String:
	var digits := str(value)
	var prefix := "-" if digits.begins_with("-") else ""
	digits = digits.trim_prefix("-")
	var groups: PackedStringArray = []
	while digits.length() > 3:
		groups.insert(0, digits.right(3))
		digits = digits.left(digits.length() - 3)
	groups.insert(0, digits)
	return prefix + ",".join(groups)


func get_card_rect() -> Rect2:
	return _card_rect


func _completion_labels() -> Array[Label]:
	return [
		great_job_label, level_title, your_score_heading, bonus_score_heading,
		total_score_heading, your_score_label, bonus_score_label, total_score_label,
	]


func _apply_layout() -> void:
	if not is_node_ready() or size.x <= 0.0 or size.y <= 0.0:
		return
	var padding := minf(24.0, size.x * 0.025)
	var safe_rect := Rect2(Vector2.ZERO, size).grow(-padding)
	if OS.has_feature("android"):
		var screen_size := Vector2(DisplayServer.screen_get_size())
		var safe_area := Rect2(DisplayServer.get_display_safe_area())
		if screen_size.x > 0.0 and screen_size.y > 0.0 and safe_area.has_area():
			safe_rect = Rect2(safe_area.position / screen_size * size, safe_area.size / screen_size * size).grow(-padding)
	var design_size := artwork.texture.get_size()
	_ui_scale = minf(safe_rect.size.x / design_size.x, safe_rect.size.y / design_size.y)
	var card_size := design_size * _ui_scale
	_card_rect = Rect2(safe_rect.get_center() - card_size * 0.5, card_size)
	if _showing_error:
		_place(summary_label, Rect2(0.12, 0.22, 0.76, 0.35))
		summary_label.add_theme_font_size_override("font_size", maxi(20, roundi(40.0 * _ui_scale)))
		_fit_button(42.0, _card_rect.size * Vector2(0.68, 0.13))
		_place(continue_button, Rect2(0.16, 0.62, 0.68, 0.13))
		return
	_place(artwork, Rect2(0.0, 0.0, 1.0, 1.0))
	canvas.pivot_offset = size * 0.5
	_fit_label(great_job_label, Rect2(0.17, 0.128, 0.66, 0.113), 120.0, 7.0)
	_fit_label(level_title, Rect2(0.225, 0.247, 0.55, 0.082), 72.0)
	_fit_label(your_score_heading, Rect2(0.31, 0.380, 0.38, 0.057), 54.0, 2.0)
	_fit_label(bonus_score_heading, Rect2(0.31, 0.535, 0.38, 0.057), 54.0, 2.0)
	_fit_label(total_score_heading, Rect2(0.31, 0.687, 0.38, 0.057), 54.0, 2.0)
	_fit_label(your_score_label, Rect2(0.405, 0.439, 0.34, 0.073), 74.0)
	_fit_label(bonus_score_label, Rect2(0.405, 0.592, 0.34, 0.073), 74.0)
	_fit_label(total_score_label, Rect2(0.405, 0.745, 0.34, 0.073), 74.0)
	_fit_button(100.0, _card_rect.size * Vector2(0.47, 0.103))
	_place(continue_button, Rect2(0.265, 0.868, 0.47, 0.103))


func _place(control: Control, ratios: Rect2) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	control.position = _card_rect.position + ratios.position * _card_rect.size
	control.size = ratios.size * _card_rect.size


func _fit_label(label: Label, ratios: Rect2, base_size: float, outline: float = 0.0) -> void:
	var box := ratios.size * _card_rect.size
	var font_size := maxi(12, roundi(base_size * _ui_scale))
	var font := label.get_theme_font("font")
	var outline_size := roundi(outline * _ui_scale)
	while font_size > 12 and (
		font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + outline_size * 2.0 > box.x
		or font.get_height(font_size) > box.y
	):
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_constant_override("outline_size", outline_size)
	_place(label, ratios)


func _fit_button(base_size: float, available_size: Vector2) -> void:
	var font_size := maxi(14, roundi(base_size * _ui_scale))
	var font := continue_button.get_theme_font("font")
	while font_size > 14 and (
		font.get_string_size(continue_button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > available_size.x * 0.92
		or font.get_height(font_size) > available_size.y * 0.9
	):
		font_size -= 1
	continue_button.add_theme_font_size_override("font_size", font_size)
	continue_button.add_theme_constant_override("outline_size", maxi(2, roundi(6.0 * _ui_scale)))


func _animate_in() -> void:
	if not is_visible_in_tree() or _showing_error:
		return
	_stop_entrance()
	canvas.scale = Vector2(0.94, 0.94)
	canvas.modulate.a = 0.0
	_entrance_tween = create_tween().set_parallel(true)
	_entrance_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_entrance_tween.tween_property(canvas, "scale", Vector2.ONE, 0.3)
	_entrance_tween.tween_property(canvas, "modulate:a", 1.0, 0.2)
	continue_button.grab_focus()


func _stop_entrance() -> void:
	if _entrance_tween != null and _entrance_tween.is_valid():
		_entrance_tween.kill()

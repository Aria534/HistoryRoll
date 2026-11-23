@tool
extends Control
## Shared visual layout for the existing Settings and Level Selection help overlays.
## Game rules and progression remain owned by their existing gameplay systems.

const DESIGN_SIZE := Vector2(1086, 1448)
const TITLE_FONT = preload("res://assets/fonts/BreeSerif-Regular.ttf")
const BODY_FONT = preload("res://assets/fonts/Roboto-Variable.ttf")
const CONFIRM_ART = preload("res://assets/how_to_play_ui/library/got_it.png")
const BACK_ART = preload("res://assets/level_selection_pixel/parchment_forest/back.svg")
const HINT_ART = preload("res://assets/level_selection_pixel/parchment_forest/icon_base.svg")
const RULES := [
	["1", "", "Answer the multiple-choice question first."],
	["2", "", "Earn 10 points for a correct answer."],
	["3", "", "Lose 2 points for a wrong answer. Your score never goes below zero."],
	["4", "", "Roll the dice after answering."],
	["5", "", "Move your hero by the number shown on the dice."],
	["6", "", "Ladders move you forward."],
	["7", "", "Snakes move you backward unless you have a shield."],
	["8", "", "One shield protects you from one snake."],
	["9", "", "Bonus Tiles can give extra points."],
	["10", "", "Reach the final tile with an exact dice roll."],
	["11", "", "Complete the level to unlock the next one."],
]

@export var heading_path: NodePath = ^"Heading"
@export var rows_path: NodePath = ^"HelpRows"
@export var instructions_path: NodePath = ^"Instructions"
@export var close_button_path: NodePath = ^"CloseHelpButton"

@onready var frame: TextureRect = $HelpFrame
@onready var heading: Label = get_node(heading_path)
@onready var rows: VBoxContainer = get_node(rows_path)
@onready var instructions: Label = get_node(instructions_path)
@onready var close_button: Button = get_node(close_button_path)
@onready var help_back_button: TextureButton = $HelpBackButton
@onready var help_hint_button: Button = $HelpHintButton

var _body_font: FontVariation
var _layout_revision := 0
var _rows_target := Rect2()


func _ready() -> void:
	frame.show_behind_parent = true
	_body_font = FontVariation.new()
	_body_font.base_font = BODY_FONT
	_body_font.variation_embolden = 0.5
	build_rows(RULES)
	instructions.text = "\n".join(RULES.map(func(row: Array) -> String: return "%s. %s" % [row[0], row[2]]))
	instructions.hide()
	help_back_button.texture_normal = BACK_ART
	help_back_button.texture_hover = BACK_ART
	help_back_button.texture_pressed = BACK_ART
	help_back_button.ignore_texture_size = true
	help_back_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	help_back_button.tooltip_text = "Back"
	if not Engine.is_editor_hint():
		help_back_button.pressed.connect(func() -> void: close_button.pressed.emit())
	help_hint_button.text = "?"
	help_hint_button.tooltip_text = "Read the rules below. Choose GOT IT or Back to return."
	if not Engine.is_editor_hint():
		help_hint_button.pressed.connect(func() -> void: rows.grab_focus())
	rows.focus_mode = Control.FOCUS_ALL
	if not resized.is_connected(_update_layout):
		resized.connect(_update_layout)
	_update_layout()


func build_rows(rule_data: Array) -> void:
	if rows.get_child_count() > 0:
		# The saved nodes keep Editor previews populated. Sync their wording
		# with the shared rules without creating duplicate Controls.
		for index in mini(rows.get_child_count(), rule_data.size()):
			var saved_row := rows.get_child(index)
			(saved_row.get_node("Number") as Label).text = str(rule_data[index][0])
			(saved_row.get_node("Description") as Label).text = str(rule_data[index][2])
		return
	for rule: Array in rule_data:
		var row := HBoxContainer.new()
		row.name = "Rule%s" % rule[0]
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rows.add_child(row)

		var number := Label.new()
		number.name = "Number"
		number.text = str(rule[0])
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(number)

		var description := Label.new()
		description.name = "Description"
		description.text = str(rule[2])
		description.mouse_filter = Control.MOUSE_FILTER_IGNORE
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(description)


func _update_layout() -> void:
	if not is_node_ready() or size.x <= 0.0 or size.y <= 0.0:
		return
	var ui_scale := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	var art_rect := Rect2((size - DESIGN_SIZE * ui_scale) * 0.5, DESIGN_SIZE * ui_scale)
	_place(frame, art_rect, Rect2(0, 0, 1086, 1448), ui_scale)
	_place(heading, art_rect, Rect2(275, 154, 536, 110), ui_scale)
	_rows_target = Rect2(art_rect.position + Vector2(235, 325) * ui_scale, Vector2(615, 675) * ui_scale)
	_place(rows, art_rect, Rect2(235, 325, 615, 675), ui_scale)
	_place(instructions, art_rect, Rect2(235, 325, 615, 675), ui_scale)
	_place(close_button, art_rect, Rect2(340, 1035, 406, 136), ui_scale)
	heading.add_theme_font_override("font", TITLE_FONT)
	heading.add_theme_font_size_override("font_size", maxi(22, roundi(64.0 * ui_scale)))
	heading.add_theme_color_override("font_color", Color("FFF0C5"))
	heading.add_theme_color_override("font_outline_color", Color("4D1705"))
	heading.add_theme_constant_override("outline_size", maxi(2, roundi(5.0 * ui_scale)))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rows.add_theme_constant_override("separation", maxi(1, roundi(5.0 * ui_scale)))

	for row: HBoxContainer in rows.get_children():
		row.custom_minimum_size.y = 50.0 * ui_scale
		row.add_theme_constant_override("separation", maxi(6, roundi(20.0 * ui_scale)))
		var number := row.get_child(0) as Label
		var description := row.get_child(1) as Label
		number.custom_minimum_size = Vector2.ONE * 50.0 * ui_scale
		number.add_theme_font_override("font", TITLE_FONT)
		number.add_theme_font_size_override("font_size", maxi(14, roundi(32.0 * ui_scale)))
		number.add_theme_color_override("font_color", Color("FFF0BF"))
		number.add_theme_color_override("font_outline_color", Color("4D2108"))
		number.add_theme_constant_override("outline_size", maxi(1, roundi(3.0 * ui_scale)))
		var coin := StyleBoxFlat.new()
		coin.bg_color = Color("FFBD35")
		coin.border_color = Color("87500B")
		coin.set_border_width_all(maxi(1, roundi(2.0 * ui_scale)))
		coin.set_corner_radius_all(roundi(28.0 * ui_scale))
		coin.shadow_color = Color("6A310777")
		coin.shadow_size = maxi(1, roundi(2.0 * ui_scale))
		number.add_theme_stylebox_override("normal", coin)
		description.add_theme_font_override("font", _body_font)
		description.add_theme_font_size_override("font_size", maxi(12, roundi(28.0 * ui_scale)))
		description.add_theme_color_override("font_color", Color("48200D"))
		description.add_theme_constant_override("line_spacing", maxi(1, roundi(2.0 * ui_scale)))

	close_button.custom_minimum_size = Vector2.ZERO
	close_button.flat = false
	close_button.text = "GOT IT"
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		close_button.add_theme_color_override(color_name, Color("FFF0C5"))
		help_hint_button.add_theme_color_override(color_name, Color("FFF0C5"))
	close_button.add_theme_font_override("font", TITLE_FONT)
	close_button.add_theme_font_size_override("font_size", maxi(22, roundi(64.0 * ui_scale)))
	close_button.add_theme_color_override("font_outline_color", Color("3D2408"))
	close_button.add_theme_constant_override("outline_size", maxi(2, roundi(4.0 * ui_scale)))
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var plate := StyleBoxTexture.new()
		plate.texture = CONFIRM_ART
		plate.modulate_color = Color(1.08, 1.06, 1.0) if state == "hover" or state == "focus" else Color.WHITE
		if state == "pressed":
			plate.modulate_color = Color(0.86, 0.88, 0.76)
		close_button.add_theme_stylebox_override(state, plate)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		close_button.add_theme_color_override(state, Color("FFF2C7"))
		help_hint_button.add_theme_color_override(state, Color("FFF2C7"))
	help_hint_button.add_theme_font_override("font", TITLE_FONT)
	help_hint_button.add_theme_font_size_override("font_size", maxi(24, roundi(64.0 * ui_scale)))
	help_hint_button.add_theme_color_override("font_outline_color", Color("4D2108"))
	help_hint_button.add_theme_constant_override("outline_size", maxi(2, roundi(4.0 * ui_scale)))
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var icon := StyleBoxTexture.new()
		icon.texture = HINT_ART
		icon.modulate_color = Color(1.10, 1.07, 1.0) if state == "hover" or state == "focus" else Color.WHITE
		help_hint_button.add_theme_stylebox_override(state, icon)
	# Apply navigation bounds after fonts/styles so saved Editor theme minimums
	# cannot leave the question button larger than Back on its first layout.
	_place(help_back_button, art_rect, Rect2(64, 56, 110, 110), ui_scale)
	_place(help_hint_button, art_rect, Rect2(912, 56, 110, 110), ui_scale)
	_layout_revision += 1
	call_deferred("_settle_rows", _layout_revision)


func _place(control: Control, art_rect: Rect2, rect: Rect2, ui_scale: float) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	control.position = art_rect.position + rect.position * ui_scale
	control.size = rect.size * ui_scale


func _settle_rows(revision: int) -> void:
	# Wrapped labels initially report heights before the HBox has its final
	# width. Shrink the VBox again after Godot has completed its container pass.
	for index in 2:
		await get_tree().process_frame
		if not is_inside_tree() or revision != _layout_revision:
			return
	for attempt in 5:
		rows.position = _rows_target.position
		rows.size = _rows_target.size
		await get_tree().process_frame
		if not is_inside_tree() or revision != _layout_revision:
			return
		if rows.get_combined_minimum_size().y <= _rows_target.size.y + 0.5:
			break
		for row: HBoxContainer in rows.get_children():
			var description := row.get_child(1) as Label
			var font_size := description.get_theme_font_size("font_size")
			description.add_theme_font_size_override("font_size", maxi(12, font_size - 1))
	rows.position = _rows_target.position
	rows.size = _rows_target.size
extends Control

const MAIN_MENU_SCENE: String = "res://main_menu_tscn.tscn"
const STORY_MODE_SCENE: String = "res://story_mode.tscn"
const LevelCatalog = preload("res://level_catalog.gd")
const TITLE_FONT = preload("res://assets/fonts/TitanOne-Regular.ttf")
const BODY_FONT = preload("res://assets/fonts/Roboto-Variable.ttf")

const GOLD := Color("F5B83B")
const GOLD_LIGHT := Color("FFE09A")
const WOOD_DARK := Color("3B180C")
const WOOD := Color("6E3018")
const PARCHMENT := Color("F7E4B3")
const INK := Color("3A1D12")
const BANNER_RED := Color("8F2E20")
const GREEN := Color("2F7D32")
const LOCKED_GRAY := Color("55575A")

@onready var wood_frame: PanelContainer = %WoodFrame
@onready var title_label: Label = %TitleLabel
@onready var hero_list: VBoxContainer = %HeroList
@onready var status_label: Label = %StatusLabel
@onready var back_button: Button = %BackButton

var progress_manager: Node
var scene_change_handler: Callable


func _ready() -> void:
	if progress_manager == null:
		progress_manager = get_node("/root/ProgressManager")
	_apply_scene_theme()
	back_button.pressed.connect(_on_back_pressed)
	progress_manager.progress_changed.connect(_refresh_collection)
	_refresh_collection()


func _apply_scene_theme() -> void:
	wood_frame.add_theme_stylebox_override(
		"panel",
		_make_style(Color("4A2112E8"), GOLD, 5, 24, Color("160A05A6"), 14)
	)
	title_label.add_theme_stylebox_override(
		"normal",
		_make_style(Color("55230FF5"), GOLD, 5, 26, Color("160A05B8"), 8)
	)
	title_label.add_theme_color_override("font_color", Color("FFF3D2"))
	title_label.add_theme_color_override("font_outline_color", WOOD_DARK)
	title_label.add_theme_constant_override("outline_size", 8)

	status_label.add_theme_stylebox_override(
		"normal",
		_make_style(Color("F8E7BBF5"), Color("C9872A"), 3, 14, Color("2B120878"), 4)
	)
	status_label.add_theme_color_override("font_color", INK)
	status_label.add_theme_color_override("font_outline_color", Color("FFF0C4"))
	status_label.add_theme_constant_override("outline_size", 2)

	back_button.add_theme_color_override("font_color", Color.WHITE)
	back_button.add_theme_color_override("font_hover_color", Color.WHITE)
	back_button.add_theme_color_override("font_pressed_color", GOLD_LIGHT)
	back_button.add_theme_color_override("font_outline_color", WOOD_DARK)
	back_button.add_theme_constant_override("outline_size", 5)
	back_button.add_theme_stylebox_override("normal", _make_style(Color("8E3027"), GOLD, 5, 24, Color("1A0907A8"), 8))
	back_button.add_theme_stylebox_override("hover", _make_style(Color("B64231"), GOLD_LIGHT, 6, 24, Color("1A0907A8"), 8))
	back_button.add_theme_stylebox_override("pressed", _make_style(Color("6D211C"), Color("D69528"), 5, 24))


func _refresh_collection() -> void:
	for child: Node in hero_list.get_children():
		hero_list.remove_child(child)
		child.queue_free()

	for character: Dictionary in LevelCatalog.get_all_characters():
		hero_list.add_child(_build_hero_card(character))

	status_label.text = "Selected Hero: %s" % _get_selected_hero_name()


func _build_hero_card(character: Dictionary) -> Button:
	var character_id := str(character.get("id", ""))
	var level_id := int(character.get("source_level", 0))
	var unlocked: bool = bool(progress_manager.is_character_unlocked(character_id))
	var compact := get_viewport_rect().size.x < 800.0

	var button := Button.new()
	button.name = "HeroCard%d" % level_id
	button.set_meta("character_id", character_id)
	button.set_meta("source_level", level_id)
	button.custom_minimum_size = Vector2(0, 400 if compact else 354)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = not unlocked
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.clip_contents = true

	# Keep the complete educational text on the Button for accessibility and
	# regression coverage. Visible card content is rendered by its child labels.
	button.text = _get_accessible_card_text(character, unlocked)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(color_name, Color.TRANSPARENT)
	button.add_theme_font_size_override("font_size", 1)

	var card_color := Color("F6E3B4") if unlocked else Color("E4D5B5")
	button.add_theme_stylebox_override("normal", _make_style(card_color, GOLD, 4, 18, Color("190B068F"), 7))
	button.add_theme_stylebox_override("hover", _make_style(Color("FFF0C8"), GOLD_LIGHT, 5, 18, Color("190B0699"), 9))
	button.add_theme_stylebox_override("pressed", _make_style(Color("EACB88"), Color("CF8723"), 4, 18))
	button.add_theme_stylebox_override("disabled", _make_style(card_color, Color("B88B45"), 4, 18, Color("190B0673"), 5))

	var margin := MarginContainer.new()
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14 if compact else 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	row.add_child(_build_portrait(character, unlocked, compact))

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 4)
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(details)

	var name_label := _make_label(str(character.get("name", "Hero")), 25 if compact else 30, Color("FFF4D3"), TITLE_FONT)
	name_label.custom_minimum_size.y = 47
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_outline_color", WOOD_DARK)
	name_label.add_theme_constant_override("outline_size", 4)
	name_label.add_theme_stylebox_override("normal", _make_style(BANNER_RED, GOLD, 3, 12))
	details.add_child(name_label)

	var theme_label := _make_label(
		"Level %d — %s" % [level_id, str(character.get("educational_theme", ""))],
		19 if compact else 22,
		INK,
		BODY_FONT
	)
	theme_label.custom_minimum_size.y = 36
	theme_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	theme_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	theme_label.add_theme_stylebox_override("normal", _make_style(Color("E7B755"), Color("B87520"), 2, 9))
	details.add_child(theme_label)
	if compact:
		details.add_child(_build_status_badges(unlocked, true, true))

	details.add_child(_fact_label(str(character.get("description", "")), compact, true))
	details.add_child(_fact_label(
		"KEY CONTRIBUTION (%s): %s" % [
			str(character.get("contribution_year", "")),
			str(character.get("contribution", "")),
		], compact
	))
	details.add_child(_fact_label(
		"DEATH: %s — %s" % [
			str(character.get("death_date", "Unknown")),
			str(character.get("cause_of_death", "Unknown")),
		], compact
	))
	details.add_child(_fact_label("LEGACY: %s" % str(character.get("historical_legacy", "")), compact))

	if not compact:
		row.add_child(_build_status_badges(unlocked, false, false))
	button.pressed.connect(_on_character_pressed.bind(level_id, character_id))
	return button


func _build_portrait(character: Dictionary, unlocked: bool, compact: bool) -> PanelContainer:
	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(132, 0) if compact else Vector2(170, 0)
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.add_theme_stylebox_override(
		"panel",
		_make_style(Color("7E241E"), GOLD if unlocked else Color("9B7A4A"), 5, 18, Color("2D100A78"), 4)
	)

	var portrait := TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var portrait_path := str(character.get("portrait_path", ""))
	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path) as Texture2D
	portrait.modulate = Color.WHITE if unlocked else Color("C8C0B4")
	portrait_frame.add_child(portrait)
	return portrait_frame


func _build_status_badges(unlocked: bool, compact: bool, horizontal: bool) -> BoxContainer:
	var badges: BoxContainer
	if horizontal:
		badges = HBoxContainer.new()
	else:
		badges = VBoxContainer.new()
	badges.custom_minimum_size.x = 0 if horizontal else 174
	badges.add_theme_constant_override("separation", 12)
	badges.alignment = BoxContainer.ALIGNMENT_CENTER
	badges.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var story_badge := _make_badge("STORY\nAVAILABLE", GREEN, GOLD, compact)
	story_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	badges.add_child(story_badge)

	var token_text := "GAMEPLAY\nTOKEN UNLOCKED" if unlocked else "GAMEPLAY\nTOKEN LOCKED"
	var token_color := GREEN if unlocked else LOCKED_GRAY
	var token_border := GOLD if unlocked else Color("A7A7A7")
	var token_badge := _make_badge(token_text, token_color, token_border, compact)
	token_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	badges.add_child(token_badge)
	return badges


func _make_badge(text_value: String, fill: Color, border: Color, compact: bool) -> Label:
	var label := _make_label(text_value, 14 if compact else 17, Color.WHITE, BODY_FONT)
	label.custom_minimum_size.y = 64 if compact else 72
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color("26140D"))
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_stylebox_override("normal", _make_style(fill, border, 3, 12, Color("2A120A66"), 3))
	return label


func _fact_label(text_value: String, compact: bool, description := false) -> Label:
	var label := _make_label(text_value, 15 if compact else 17, INK, BODY_FONT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL if description else Control.SIZE_SHRINK_CENTER
	return label


func _make_label(text_value: String, font_size: int, color: Color, font: Font) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _get_accessible_card_text(character: Dictionary, unlocked: bool) -> String:
	var collection_status := "UNLOCKED" if unlocked else "STORY AVAILABLE — GAMEPLAY TOKEN LOCKED"
	return "%s\nLevel %d — %s\n%s\n%s\nKey contribution (%s): %s\nDeath: %s — %s\nLegacy: %s" % [
		str(character.get("name", "Hero")),
		int(character.get("source_level", 0)),
		str(character.get("educational_theme", "")),
		collection_status,
		str(character.get("description", "")),
		str(character.get("contribution_year", "")),
		str(character.get("contribution", "")),
		str(character.get("death_date", "Unknown")),
		str(character.get("cause_of_death", "Unknown")),
		str(character.get("historical_legacy", "")),
	]


func _make_style(
	fill: Color,
	border: Color,
	border_width: int,
	radius: int,
	shadow_color := Color.TRANSPARENT,
	shadow_size := 0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	style.content_margin_left = 10.0
	style.content_margin_top = 8.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 8.0
	return style


func _get_selected_hero_name() -> String:
	for character: Dictionary in LevelCatalog.get_all_characters():
		if str(character.get("id", "")) == progress_manager.selected_hero:
			return str(character.get("name", "Hero"))
	return "HistoryRoll Explorer"


func _on_character_pressed(source_level: int, character_id: String) -> void:
	if progress_manager.is_character_unlocked(character_id):
		progress_manager.select_hero(character_id)
	if progress_manager.select_story_level(source_level):
		if scene_change_handler.is_valid():
			scene_change_handler.call(STORY_MODE_SCENE)
		else:
			get_tree().change_scene_to_file(STORY_MODE_SCENE)


func _on_back_pressed() -> void:
	if scene_change_handler.is_valid():
		scene_change_handler.call(MAIN_MENU_SCENE)
	else:
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

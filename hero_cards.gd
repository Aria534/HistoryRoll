extends Control

const MAIN_MENU_SCENE: String = "res://main_menu_tscn.tscn"
const STORY_MODE_SCENE: String = "res://hero_story_video_player.tscn"
const HERO_CARDS_MUSIC: String = "res://assets/audio/music/main_menu.ogg"
const LevelCatalog = preload("res://level_catalog.gd")
const TITLE_FONT = preload("res://assets/fonts/BreeSerif-Regular.ttf")
const STORY_FONT = preload("res://assets/fonts/TitanOne-Regular.ttf")
const FRAME_ART = preload("res://assets/hero_cards_ui/heritage_village/frame.png")
const TITLE_ART = preload("res://assets/hero_cards_ui/heritage_village/title_leaf_free.png")
const CARD_ART = preload("res://assets/hero_cards_ui/heritage_village/card.png")
const BACK_ART = preload("res://assets/hero_cards_ui/heritage_village/back_leaf_free.png")
const STORY_ARROW = preload("res://assets/main_menu_pixel/responsive/selection_arrow.svg")
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
@onready var scroll_container: ScrollContainer = $SafeArea/WoodFrame/FrameMargin/Content/ScrollContainer
@onready var status_label: Label = %StatusLabel
@onready var back_button: Button = %BackButton

var progress_manager: Node
var scene_change_handler: Callable
var _portrait_textures: Dictionary[String, Texture2D] = {}


func _ready() -> void:
	if progress_manager == null:
		progress_manager = get_node("/root/ProgressManager")
	_apply_scene_theme()
	resized.connect(_refresh_responsive_layout)
	hero_list.resized.connect(_fit_card_heights)
	back_button.pressed.connect(_on_back_pressed)
	progress_manager.progress_changed.connect(_refresh_collection)
	_play_background_music()
	_refresh_collection()


func _apply_scene_theme() -> void:
	var compact := get_viewport_rect().size.x < 800.0
	var safe_margin := 18 if compact else 28
	var safe_area: MarginContainer = $SafeArea
	safe_area.offset_left = safe_margin
	safe_area.offset_top = safe_margin
	safe_area.offset_right = -safe_margin
	safe_area.offset_bottom = -safe_margin
	var frame_margin: MarginContainer = $SafeArea/WoodFrame/FrameMargin
	for side: String in ["left", "top", "right", "bottom"]:
		frame_margin.add_theme_constant_override("margin_" + side, 10 if compact else 14)
	# Keep Back centered above the lower gold rim, clear of the scrolling cards.
	frame_margin.add_theme_constant_override("margin_bottom", 24 if compact else 28)
	var content: VBoxContainer = $SafeArea/WoodFrame/FrameMargin/Content
	content.add_theme_constant_override("separation", 12)
	hero_list.add_theme_constant_override("separation", 14)
	var width := get_viewport_rect().size.x - safe_margin * 2.0 - 44.0
	var title_height := clampf(width * 0.25, 164.0, 240.0)
	var frame := _make_texture_style(FRAME_ART, 8.0)
	frame.content_margin_top = 0.0
	frame.expand_margin_top = -title_height * 0.82
	frame.texture_margin_left = 64.0
	frame.texture_margin_right = 64.0
	frame.texture_margin_top = 64.0
	frame.texture_margin_bottom = 64.0
	wood_frame.add_theme_stylebox_override("panel", frame)
	var title := _make_texture_style(TITLE_ART, 0.0)
	title.content_margin_left = width * 0.12
	title.content_margin_right = width * 0.12
	title.content_margin_top = title_height * 0.46
	title.content_margin_bottom = title_height * 0.10
	title_label.custom_minimum_size.y = title_height
	title_label.add_theme_stylebox_override("normal", title)
	title_label.add_theme_font_override("font", TITLE_FONT)
	title_label.add_theme_font_size_override("font_size", clampi(int(width * 0.056), 34, 58))
	title_label.add_theme_color_override("font_color", Color("FFF3D2"))
	title_label.add_theme_color_override("font_outline_color", WOOD_DARK)
	title_label.add_theme_constant_override("outline_size", 4)

	status_label.custom_minimum_size.y = 52.0 if compact else 56.0
	status_label.add_theme_font_override("font", TITLE_FONT)
	status_label.add_theme_font_size_override("font_size", 22 if compact else 27)
	status_label.add_theme_stylebox_override("normal", _make_style(Color("FFF0C8"), GOLD, 3, 24, Color("2B120878"), 3))
	status_label.add_theme_color_override("font_color", INK)
	status_label.add_theme_constant_override("outline_size", 0)

	back_button.custom_minimum_size = Vector2(340, 96) if compact else Vector2(440, 104)
	back_button.add_theme_font_override("font", TITLE_FONT)
	back_button.add_theme_font_size_override("font_size", 36 if compact else 44)
	back_button.add_theme_color_override("font_color", Color("FFF3D2"))
	back_button.add_theme_color_override("font_hover_color", Color.WHITE)
	back_button.add_theme_color_override("font_pressed_color", GOLD_LIGHT)
	back_button.add_theme_color_override("font_outline_color", WOOD_DARK)
	back_button.add_theme_constant_override("outline_size", 3)
	for state: String in ["normal", "hover", "pressed"]:
		var back := _make_texture_style(BACK_ART, 12.0)
		back.content_margin_left = 32.0
		back.content_margin_right = 32.0
		if state == "hover":
			back.modulate_color = Color(1.12, 1.08, 1.0)
		elif state == "pressed":
			back.modulate_color = Color(0.86, 0.82, 0.72)
		back_button.add_theme_stylebox_override(state, back)


func _make_texture_style(texture: Texture2D, margin: float) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.content_margin_left = margin
	style.content_margin_top = margin
	style.content_margin_right = margin
	style.content_margin_bottom = margin
	return style


func _refresh_responsive_layout() -> void:
	_apply_scene_theme()
	_refresh_collection()


func _fit_card_heights() -> void:
	if not is_inside_tree():
		return
	var compact := get_viewport_rect().size.x < 800.0
	for child: Node in hero_list.get_children():
		var button := child as Button
		if button == null or button.get_child_count() == 0:
			continue
		var margin := button.get_child(0) as MarginContainer
		var row := margin.get_child(0) as HBoxContainer
		var required := row.get_combined_minimum_size().y
		var height := maxf(400.0 if compact else 310.0, ceilf(required / 0.80))
		# Keep live content inside the painted parchment, clear of its gold rim.
		margin.add_theme_constant_override("margin_top", ceili(height * 0.10))
		margin.add_theme_constant_override("margin_bottom", ceili(height * 0.10))
		if not is_equal_approx(button.custom_minimum_size.y, height):
			button.custom_minimum_size.y = height


func _refresh_collection() -> void:
	for child: Node in hero_list.get_children():
		hero_list.remove_child(child)
		child.queue_free()

	for character: Dictionary in LevelCatalog.get_all_characters():
		hero_list.add_child(_build_hero_card(character))

	status_label.text = "Selected Hero: %s" % _get_selected_hero_name()
	call_deferred("_fit_card_heights")
	call_deferred("_focus_selected_story_card")


func _build_hero_card(character: Dictionary) -> Button:
	var character_id := str(character.get("id", ""))
	var level_id := int(character.get("source_level", 0))
	var unlocked: bool = bool(progress_manager.is_character_unlocked(character_id))
	var compact := get_viewport_rect().size.x < 800.0

	var button := Button.new()
	button.name = "HeroCard%d" % level_id
	button.set_meta("character_id", character_id)
	button.set_meta("source_level", level_id)
	button.custom_minimum_size = Vector2(0, 400 if compact else 310)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Story films remain available while the associated gameplay token is locked.
	button.disabled = false
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.clip_contents = true

	# Keep the complete educational text on the Button for accessibility and
	# regression coverage. Visible card content is rendered by its child labels.
	button.text = _get_accessible_card_text(character, unlocked)
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(color_name, Color.TRANSPARENT)
	button.add_theme_font_size_override("font_size", 1)

	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var card_style := _make_texture_style(CARD_ART, 0.0)
		if state == "hover":
			card_style.modulate_color = Color(1.04, 1.02, 0.96)
		elif state == "pressed":
			card_style.modulate_color = Color(0.94, 0.87, 0.72)
		button.add_theme_stylebox_override(state, card_style)

	var margin := MarginContainer.new()
	button.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	row.add_child(_build_portrait(character, unlocked, compact))

	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 4)
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(details)

	var name_label := _make_label(str(character.get("name", "Hero")), 24 if compact else 28, Color("FFF4D3"), TITLE_FONT)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size.y = 44
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_outline_color", WOOD_DARK)
	name_label.add_theme_constant_override("outline_size", 4)
	var name_style := _make_style(BANNER_RED, GOLD, 3, 12)
	name_style.content_margin_top = 4.0
	name_style.content_margin_bottom = 4.0
	name_label.add_theme_stylebox_override("normal", name_style)
	details.add_child(name_label)

	var theme_label := _make_label(
		"Level %d — %s" % [level_id, str(character.get("educational_theme", ""))],
		18 if compact else 20,
		INK,
		BODY_FONT
	)
	theme_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	theme_label.custom_minimum_size.y = 36
	theme_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	theme_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var theme_style := _make_style(Color("E7B755"), Color("B87520"), 2, 9)
	theme_style.content_margin_top = 4.0
	theme_style.content_margin_bottom = 4.0
	theme_label.add_theme_stylebox_override("normal", theme_style)
	details.add_child(theme_label)

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

	row.add_child(_build_status_badges(unlocked, compact, false, level_id))
	button.pressed.connect(_on_character_pressed.bind(level_id, character_id))
	return button


func _build_portrait(character: Dictionary, unlocked: bool, compact: bool) -> PanelContainer:
	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(108, 0) if compact else Vector2(150, 0)
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.add_theme_stylebox_override(
		"panel",
		_make_style(Color("7E241E"), GOLD, 5, 18, Color("2D100A78"), 4)
	)

	var portrait := TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var portrait_path := str(character.get("portrait_path", ""))
	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		portrait.texture = _get_full_body_portrait(portrait_path)
	portrait.modulate = Color.WHITE
	portrait_frame.add_child(portrait)
	return portrait_frame


func _get_full_body_portrait(path: String) -> Texture2D:
	if _portrait_textures.has(path):
		return _portrait_textures[path]
	var source := load(path) as Texture2D
	if source == null:
		return null
	var texture: Texture2D = source
	var image := source.get_image()
	if image != null and not image.is_empty():
		var used := image.get_used_rect()
		if used.has_area():
			# Remove only transparent padding; keep the complete head-to-toe art.
			var atlas := AtlasTexture.new()
			atlas.atlas = source
			atlas.region = Rect2(used.grow(6).intersection(Rect2i(Vector2i.ZERO, image.get_size())))
			texture = atlas
	_portrait_textures[path] = texture
	return texture

func _build_status_badges(_unlocked: bool, compact: bool, horizontal: bool, level_id: int) -> BoxContainer:
	var badges: BoxContainer
	if horizontal:
		badges = HBoxContainer.new()
	else:
		badges = VBoxContainer.new()
	badges.custom_minimum_size.x = 0 if horizontal else (110 if compact else 150)
	badges.add_theme_constant_override("separation", 12)
	badges.alignment = BoxContainer.ALIGNMENT_CENTER
	badges.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var watched: bool = progress_manager.has_method("is_story_watched") and bool(progress_manager.is_story_watched(level_id))
	var story_badge := _make_badge("STORY\nWATCHED" if watched else "WATCH\nSTORY", GREEN, GOLD, compact)
	story_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	badges.add_child(story_badge)
	return badges


func _make_badge(text_value: String, fill: Color, border: Color, compact: bool) -> Label:
	var label := _make_label(text_value, 14 if compact else 18, Color.WHITE, STORY_FONT)
	label.custom_minimum_size.y = 64 if compact else 80
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color("26140D"))
	label.add_theme_constant_override("outline_size", 2)
	var style := _make_style(fill, border, 4, 15, Color("2A120A66"), 3)
	style.content_margin_left = 38.0 if compact else 46.0
	style.content_margin_right = 8.0
	label.add_theme_stylebox_override("normal", style)
	var arrow := TextureRect.new()
	arrow.texture = STORY_ARROW
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	label.add_child(arrow)
	arrow.anchor_top = 0.5
	arrow.anchor_bottom = 0.5
	arrow.offset_left = 10.0
	arrow.offset_right = 32.0 if compact else 38.0
	arrow.offset_top = -17.0
	arrow.offset_bottom = 17.0
	return label


func _fact_label(text_value: String, compact: bool, description := false) -> Label:
	var label := _make_label(text_value, 16, INK, BODY_FONT)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
	var collection_status := "WATCH STORY"
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


func _focus_selected_story_card() -> void:
	# Allow nested containers and wrapped biographies to finish sizing before
	# asking ScrollContainer to reveal a card. Early geometry can jump to the end.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree() or progress_manager == null or hero_list.get_child_count() == 0:
		return
	var index := clampi(int(progress_manager.selected_story_level) - 1, 0, hero_list.get_child_count() - 1)
	var card := hero_list.get_child(index) as Control
	if card != null:
		if index == 0:
			scroll_container.scroll_vertical = 0
		else:
			scroll_container.ensure_control_visible(card)
		card.grab_focus()


func _play_background_music() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_music"):
		audio_manager.play_music(HERO_CARDS_MUSIC, 0.45)


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

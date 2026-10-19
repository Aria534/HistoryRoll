extends Control

const MAIN_MENU_SCENE: String = "res://main_menu_tscn.tscn"
const LevelCatalog = preload("res://level_catalog.gd")

@onready var hero_list: VBoxContainer = %HeroList
@onready var status_label: Label = %StatusLabel
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	ProgressManager.progress_changed.connect(_refresh_collection)
	_refresh_collection()


func _refresh_collection() -> void:
	for child: Node in hero_list.get_children():
		child.queue_free()
	for character: Dictionary in LevelCatalog.get_all_characters():
		var character_id := str(character.get("id", ""))
		var unlocked := ProgressManager.is_character_unlocked(character_id)
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 130)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 24)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if unlocked:
			var selected_marker := " — SELECTED" if ProgressManager.selected_hero == character_id else ""
			button.text = "%s%s\n%s" % [
				str(character.get("name", "Hero")),
				selected_marker,
				str(character.get("description", "")),
			]
			button.pressed.connect(_on_character_pressed.bind(character_id))
		else:
			button.text = "LOCKED HERO\nComplete Level %d's full progression sequence." % int(character.get("source_level", 0))
			button.disabled = true
		hero_list.add_child(button)
	status_label.text = "Selected hero: %s" % _get_selected_hero_name()


func _get_selected_hero_name() -> String:
	for character: Dictionary in LevelCatalog.get_all_characters():
		if str(character.get("id", "")) == ProgressManager.selected_hero:
			return str(character.get("name", "Hero"))
	return "HistoryRoll Explorer"


func _on_character_pressed(character_id: String) -> void:
	if ProgressManager.select_hero(character_id):
		_refresh_collection()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

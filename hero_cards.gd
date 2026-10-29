extends Control

const MAIN_MENU_SCENE: String = "res://main_menu_tscn.tscn"
const STORY_MODE_SCENE: String = "res://story_mode.tscn"
const LevelCatalog = preload("res://level_catalog.gd")

@onready var hero_list: VBoxContainer = %HeroList
@onready var status_label: Label = %StatusLabel
@onready var back_button: Button = %BackButton

var progress_manager: Node
var scene_change_handler: Callable


func _ready() -> void:
	if progress_manager == null:
		progress_manager = get_node("/root/ProgressManager")
	back_button.pressed.connect(_on_back_pressed)
	progress_manager.progress_changed.connect(_refresh_collection)
	_refresh_collection()


func _refresh_collection() -> void:
	for child: Node in hero_list.get_children():
		child.queue_free()
	for character: Dictionary in LevelCatalog.get_all_characters():
		var character_id := str(character.get("id", ""))
		var unlocked: bool = bool(progress_manager.is_character_unlocked(character_id))
		var button := Button.new()
		button.set_meta("character_id", character_id)
		button.custom_minimum_size = Vector2(0, 150 if int(character.get("source_level", 0)) == 0 else 320)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 24)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var collection_status := "UNLOCKED" if unlocked else "STORY AVAILABLE — GAMEPLAY TOKEN LOCKED"
		button.text = "%s\nLevel %d — %s\n%s\n%s\nKey contribution (%s): %s\nDeath: %s — %s\nLegacy: %s\nCHIBI PORTRAIT PLACEHOLDER — TAP FOR STORY" % [
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
		button.pressed.connect(_on_character_pressed.bind(int(character.get("source_level", 0))))
		hero_list.add_child(button)
	status_label.text = "Selected hero: %s" % _get_selected_hero_name()


func _get_selected_hero_name() -> String:
	for character: Dictionary in LevelCatalog.get_all_characters():
		if str(character.get("id", "")) == progress_manager.selected_hero:
			return str(character.get("name", "Hero"))
	return "HistoryRoll Explorer"


func _on_character_pressed(source_level: int) -> void:
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

extends Control

const HERO_CARDS_SCENE: String = "res://hero_cards.tscn"
const LevelCatalog = preload("res://level_catalog.gd")

@onready var level_label: Label = %LevelLabel
@onready var hero_name_label: Label = %HeroNameLabel
@onready var portrait: TextureRect = %Portrait
@onready var portrait_placeholder_label: Label = %PortraitPlaceholderLabel
@onready var story_text: RichTextLabel = %StoryText
@onready var continue_button: Button = %ContinueButton

var level_data: Dictionary = {}
var level_id: int = 0
var story_available: bool = false
var progress_manager: Node
var scene_change_handler: Callable


func _ready() -> void:
	if progress_manager == null:
		progress_manager = get_node("/root/ProgressManager")
	continue_button.pressed.connect(_on_continue_pressed)
	_load_hero_story()


func _load_hero_story() -> void:
	level_id = int(progress_manager.selected_story_level)
	story_available = LevelCatalog.has_level(level_id)
	level_data = LevelCatalog.get_level(level_id)
	if level_data.is_empty():
		_show_unavailable_story()
		return
	level_label.text = "LEVEL %d — %s" % [level_id, str(level_data.get("educational_theme", "HERO STORY")).to_upper()]
	hero_name_label.text = str(level_data.get("hero_name", "Hero to be confirmed"))
	story_text.text = str(level_data.get(
		"story_text",
		"DEVELOPMENT PLACEHOLDER — Approved educational story content has not been added yet."
	))
	_set_portrait(str(level_data.get("portrait_path", "")))
	continue_button.text = "Back to Hero Cards"
	continue_button.disabled = false


func _set_portrait(path: String) -> void:
	if not path.is_empty() and ResourceLoader.exists(path):
		portrait.texture = load(path) as Texture2D
		portrait_placeholder_label.hide()
	else:
		portrait.texture = null
		portrait_placeholder_label.show()


func _show_unavailable_story() -> void:
	story_available = false
	level_label.text = "STORY UNAVAILABLE"
	hero_name_label.text = ""
	story_text.text = "Choose a Filipino hero from Hero Cards to open their story."
	portrait.texture = null
	portrait.hide()
	portrait_placeholder_label.hide()
	continue_button.text = "Back to Hero Cards"
	continue_button.disabled = false


func _on_continue_pressed() -> void:
	continue_button.disabled = true
	_change_scene(HERO_CARDS_SCENE)


func complete_story() -> bool:
	return story_available


func _change_scene(path: String) -> void:
	if scene_change_handler.is_valid():
		scene_change_handler.call(path)
	else:
		get_tree().change_scene_to_file(path)

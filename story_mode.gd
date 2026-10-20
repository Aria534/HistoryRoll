extends Control

const LEVEL_SELECTION_SCENE: String = "res://level_selection.tscn"
const CHARACTER_UNLOCK_SCENE: String = "res://character_unlock.tscn"
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
	_load_post_level_story()


func _load_post_level_story() -> void:
	level_id = int(progress_manager.pending_progression_level)
	story_available = (
		level_id > 0
		and progress_manager.progression_stage == progress_manager.STAGE_POST_STORY
		and progress_manager.is_board_completed(level_id)
		and not progress_manager.is_story_completed(level_id)
	)
	if not story_available:
		_show_unavailable_story()
		return
	level_data = LevelCatalog.get_level(level_id)
	if level_data.is_empty():
		_show_unavailable_story()
		return
	level_label.text = "LEVEL %d — HERO STORY" % level_id
	hero_name_label.text = str(level_data.get("hero_name", "Hero to be confirmed"))
	story_text.text = str(level_data.get(
		"story_text",
		"DEVELOPMENT PLACEHOLDER — Approved educational story content has not been added yet."
	))
	_set_portrait(str(level_data.get("portrait_path", "")))
	continue_button.text = "Continue"
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
	story_text.text = "Complete the level board and view its results before opening Story Mode."
	portrait.texture = null
	portrait.hide()
	portrait_placeholder_label.hide()
	continue_button.text = "Return to Level Selection"
	continue_button.disabled = false


func _on_continue_pressed() -> void:
	continue_button.disabled = true
	if not story_available:
		_change_scene(LEVEL_SELECTION_SCENE)
		return
	if complete_story():
		_change_scene(CHARACTER_UNLOCK_SCENE)
	else:
		story_text.text = "Unable to record story completion. Please return to Level Selection and resume your progress."
		continue_button.text = "Return to Level Selection"
		story_available = false
		continue_button.disabled = false


func complete_story() -> bool:
	if not story_available:
		return false
	return bool(progress_manager.mark_story_completed(level_id))


func _change_scene(path: String) -> void:
	if scene_change_handler.is_valid():
		scene_change_handler.call(path)
	else:
		get_tree().change_scene_to_file(path)

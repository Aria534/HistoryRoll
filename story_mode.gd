extends Control

const LEVEL_SELECTION_SCENE: String = "res://level_selection.tscn"
const CHARACTER_UNLOCK_SCENE: String = "res://character_unlock.tscn"
const DEFAULT_GAMEPLAY_SCENE: String = "res://gameplay_placeholder.tscn"
const LevelCatalog = preload("res://level_catalog.gd")

@onready var level_label: Label = %LevelLabel
@onready var hero_name_label: Label = %HeroNameLabel
@onready var portrait: TextureRect = %Portrait
@onready var portrait_placeholder_label: Label = %PortraitPlaceholderLabel
@onready var story_text: RichTextLabel = %StoryText
@onready var panel_counter_label: Label = %PanelCounterLabel
@onready var previous_button: Button = %PreviousButton
@onready var next_button: Button = %NextButton
@onready var back_button: Button = %BackButton
@onready var continue_button: Button = %ContinueButton

var level_data: Dictionary = {}
var story_panels: Array = []
var panel_index: int = 0
var is_post_completion_story: bool = false
var progress_manager: Node


func _ready() -> void:
	if progress_manager == null:
		progress_manager = get_node("/root/ProgressManager")
	previous_button.pressed.connect(_on_previous_pressed)
	next_button.pressed.connect(_on_next_pressed)
	back_button.pressed.connect(_on_back_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	_load_selected_level()


func _load_selected_level() -> void:
	level_data = LevelCatalog.get_level(progress_manager.selected_level)
	if level_data.is_empty() or not LevelCatalog.is_level_playable(progress_manager.selected_level):
		level_data = LevelCatalog.get_level(1)
		progress_manager.select_level(1)
	var level_id := int(level_data.get("id", 1))
	is_post_completion_story = (
		progress_manager.story_context == "post_completion"
		and progress_manager.pending_progression_level == level_id
		and progress_manager.progression_stage == progress_manager.STAGE_POST_STORY
	)
	level_label.text = (
		"LEVEL %d — REQUIRED STORY CHAPTER" % level_id
		if is_post_completion_story
		else "LEVEL %d — INTRODUCTION" % level_id
	)
	hero_name_label.text = str(level_data.get("hero_name", "Hero to be confirmed"))
	story_panels = level_data.get(
		"post_story_panels" if is_post_completion_story else "introduction_panels",
		[]
	).duplicate(true)
	if not is_post_completion_story:
		story_panels.push_front("%s\n\n%s" % [
			str(level_data.get("title", "Level %d" % level_id)),
			str(level_data.get("description", "")),
		])
	if story_panels.is_empty():
		story_panels = ["PLACEHOLDER — Approved educational story content has not been added yet."]
	var portrait_path := str(level_data.get("portrait_path", ""))
	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path) as Texture2D
		portrait_placeholder_label.hide()
	else:
		portrait.texture = null
		portrait_placeholder_label.show()
	back_button.disabled = is_post_completion_story
	back_button.text = "Required Chapter" if is_post_completion_story else "Back"
	continue_button.text = "Complete Chapter" if is_post_completion_story else "Start Level"
	panel_index = 0
	_update_story_panel()


func _update_story_panel() -> void:
	story_text.text = str(story_panels[panel_index])
	panel_counter_label.text = "%d / %d" % [panel_index + 1, story_panels.size()]
	previous_button.disabled = panel_index == 0
	next_button.disabled = panel_index >= story_panels.size() - 1
	continue_button.disabled = panel_index < story_panels.size() - 1


func _on_previous_pressed() -> void:
	if panel_index > 0:
		panel_index -= 1
		_update_story_panel()


func _on_next_pressed() -> void:
	if panel_index < story_panels.size() - 1:
		panel_index += 1
		_update_story_panel()


func _on_back_pressed() -> void:
	if is_post_completion_story:
		return
	get_tree().change_scene_to_file(LEVEL_SELECTION_SCENE)


func _on_continue_pressed() -> void:
	if panel_index < story_panels.size() - 1:
		return
	var level_id := int(level_data.get("id", 1))
	if is_post_completion_story:
		if progress_manager.mark_story_completed(level_id):
			get_tree().change_scene_to_file(CHARACTER_UNLOCK_SCENE)
		return
	var gameplay_scene := str(level_data.get("gameplay_scene", DEFAULT_GAMEPLAY_SCENE))
	if not ResourceLoader.exists(gameplay_scene):
		gameplay_scene = DEFAULT_GAMEPLAY_SCENE
	if not ResourceLoader.exists(gameplay_scene):
		push_error("No gameplay scene is available.")
		return
	get_tree().change_scene_to_file(gameplay_scene)

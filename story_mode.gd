extends Control

const HERO_CARDS_SCENE := "res://hero_cards.tscn"
const LevelCatalog = preload("res://level_catalog.gd")

@onready var level_label: Label = %LevelLabel
@onready var hero_name_label: Label = %HeroNameLabel
@onready var story_title_label: Label = %StoryTitleLabel
@onready var portrait: TextureRect = %Portrait
@onready var portrait_placeholder_label: Label = %PortraitPlaceholderLabel
@onready var panel_title_label: Label = %PanelTitleLabel
@onready var story_text: RichTextLabel = %StoryText
@onready var visual_caption: Label = %VisualCaption
@onready var previous_button: Button = %PreviousButton
@onready var panel_counter_label: Label = %PanelCounterLabel
@onready var continue_button: Button = %ContinueButton
@onready var skip_button: Button = %SkipButton
@onready var back_button: Button = %BackButton

var level_data: Dictionary = {}
var level_id := 0
var story_available := false
var panels: Array = []
var current_panel_index := 0
var progress_manager: Node
var scene_change_handler: Callable
var scene_transition_pending := false


func _ready() -> void:
	if progress_manager == null:
		progress_manager = get_node("/root/ProgressManager")
	_connect_once(previous_button.pressed, _on_previous_pressed)
	_connect_once(continue_button.pressed, _on_continue_pressed)
	_connect_once(skip_button.pressed, _on_skip_pressed)
	_connect_once(back_button.pressed, _on_back_pressed)
	_load_hero_story()


func _connect_once(signal_value: Signal, callback: Callable) -> void:
	if not signal_value.is_connected(callback):
		signal_value.connect(callback)


func _load_hero_story() -> void:
	level_id = int(progress_manager.selected_story_level)
	level_data = LevelCatalog.get_level(level_id)
	panels = (level_data.get("panels", []) as Array).duplicate(true)
	story_available = not level_data.is_empty() and panels.size() == 5
	current_panel_index = 0
	if not story_available:
		_show_unavailable_story()
		return

	level_label.text = "LEVEL %d" % level_id
	hero_name_label.text = str(level_data.get("hero_name", "FILIPINO HERO")).to_upper()
	story_title_label.text = str(level_data.get("story_title", "Hero Story"))
	_set_portrait(str(level_data.get("portrait_path", "")))
	_show_panel()


func _show_panel() -> void:
	if not story_available:
		return
	current_panel_index = clampi(current_panel_index, 0, panels.size() - 1)
	var panel: Dictionary = panels[current_panel_index]
	panel_title_label.text = str(panel.get("title", "Story"))
	story_text.text = str(panel.get("text", ""))
	visual_caption.text = str(panel.get("visual", ""))
	panel_counter_label.text = "%d / %d" % [current_panel_index + 1, panels.size()]
	previous_button.disabled = current_panel_index == 0
	continue_button.text = "PLAY LEVEL %d" % level_id if current_panel_index == panels.size() - 1 else "NEXT >"
	continue_button.disabled = false
	skip_button.disabled = false
	back_button.disabled = false


func _set_portrait(path: String) -> void:
	if not path.is_empty() and ResourceLoader.exists(path):
		portrait.texture = load(path) as Texture2D
		portrait.show()
		portrait_placeholder_label.hide()
	else:
		portrait.texture = null
		portrait.show()
		portrait_placeholder_label.show()


func _show_unavailable_story() -> void:
	story_available = false
	level_label.text = "STORY UNAVAILABLE"
	hero_name_label.text = ""
	story_title_label.text = ""
	panel_title_label.text = "Choose a Filipino hero from Hero Cards."
	story_text.text = "This story chapter is not available."
	visual_caption.text = ""
	portrait.texture = null
	portrait.hide()
	portrait_placeholder_label.hide()
	panel_counter_label.text = "0 / 0"
	previous_button.disabled = true
	continue_button.disabled = true
	skip_button.disabled = true
	back_button.disabled = false


func _on_previous_pressed() -> void:
	if scene_transition_pending or not story_available or current_panel_index <= 0:
		return
	current_panel_index -= 1
	_show_panel()


func _on_continue_pressed() -> void:
	if scene_transition_pending or not story_available:
		return
	if current_panel_index < panels.size() - 1:
		current_panel_index += 1
		_show_panel()
		return
	_play_selected_level()


func _on_skip_pressed() -> void:
	if scene_transition_pending or not story_available:
		return
	_play_selected_level()


func _on_back_pressed() -> void:
	if scene_transition_pending:
		return
	_change_scene(HERO_CARDS_SCENE)


func _play_selected_level() -> void:
	if not progress_manager.is_level_unlocked(level_id):
		_show_play_error("Level %d is still locked." % level_id)
		return
	if not LevelCatalog.is_level_playable(level_id):
		_show_play_error("Level %d gameplay is not available yet." % level_id)
		return
	var gameplay_scene := str(level_data.get("gameplay_scene", ""))
	if gameplay_scene.is_empty() or not ResourceLoader.exists(gameplay_scene):
		_show_play_error("The selected gameplay scene is missing.")
		return
	progress_manager.select_level(level_id)
	_change_scene(gameplay_scene)


func _show_play_error(message: String) -> void:
	story_text.text = message
	continue_button.disabled = true
	skip_button.disabled = true
	back_button.disabled = false


func complete_story() -> bool:
	return story_available and current_panel_index == panels.size() - 1


func _change_scene(path: String) -> void:
	if scene_transition_pending:
		return
	scene_transition_pending = true
	previous_button.disabled = true
	continue_button.disabled = true
	skip_button.disabled = true
	back_button.disabled = true
	if scene_change_handler.is_valid():
		scene_change_handler.call(path)
	else:
		var error := get_tree().change_scene_to_file(path)
		if error != OK:
			scene_transition_pending = false
			_show_play_error("Unable to open the requested screen.")

extends Control

const LEVEL_SELECTION_SCENE: String = "res://level_selection.tscn"
const LevelCatalog = preload("res://level_catalog.gd")

@onready var title_label: Label = %TitleLabel
@onready var hero_name_label: Label = %HeroNameLabel
@onready var portrait: TextureRect = %Portrait
@onready var portrait_placeholder_label: Label = %PortraitPlaceholderLabel
@onready var description_label: Label = %DescriptionLabel
@onready var continue_button: Button = %ContinueButton

var progress_manager: Node
var level_id: int = 0
var reward: Dictionary = {}
var has_error: bool = false
var scene_change_handler: Callable


func _ready() -> void:
	if progress_manager == null:
		progress_manager = get_node("/root/ProgressManager")
	continue_button.pressed.connect(_on_continue_pressed)
	level_id = int(progress_manager.pending_progression_level)
	if level_id < 1:
		_show_error("No pending character reward was found.")
		return
	reward = LevelCatalog.get_character_reward(level_id)
	if reward.is_empty() and progress_manager.progression_stage == progress_manager.STAGE_LEVEL_UNLOCK:
		_show_level_unlock()
		return
	if reward.is_empty():
		_show_error("The character reward for Level %d is not configured." % level_id)
		return
	if progress_manager.progression_stage == progress_manager.STAGE_CHARACTER_UNLOCK:
		if not progress_manager.claim_character_reward(level_id):
			_show_error("The required story chapter has not been completed.")
			return
		_show_character_unlock()
	elif progress_manager.progression_stage == progress_manager.STAGE_LEVEL_UNLOCK:
		_show_level_unlock()
	else:
		_show_error("This reward is not available yet.")


func _show_character_unlock() -> void:
	title_label.text = "CHARACTER UNLOCKED!"
	hero_name_label.text = str(reward.get("name", "Hero Placeholder"))
	description_label.text = str(reward.get("description", "Development placeholder."))
	continue_button.text = "Continue"
	_set_portrait(str(reward.get("portrait_path", "")))
	portrait.scale = Vector2(0.88, 0.88)
	portrait.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(portrait, "scale", Vector2.ONE, 0.35)
	tween.tween_property(portrait, "modulate:a", 1.0, 0.35)


func _show_level_unlock() -> void:
	var next_level_id := LevelCatalog.get_next_level_id(level_id)
	title_label.text = "LEVEL %d UNLOCKED!" % next_level_id if next_level_id > 0 else "CONGRATULATIONS!"
	hero_name_label.text = (
		str(reward.get("name", "Hero")) + " joined your collection."
		if not reward.is_empty()
		else "YOU COMPLETED HISTORYROLL!"
	)
	description_label.text = (
		"Level %d is now unlocked and ready to play." % next_level_id
		if next_level_id > 0
		else "You completed all six levels and explored the contributions of important Filipino heroes."
	)
	continue_button.text = "Return to Level Selection"
	_set_portrait(str(reward.get("portrait_path", "")) if not reward.is_empty() else "")


func _set_portrait(path: String) -> void:
	if not path.is_empty() and ResourceLoader.exists(path):
		portrait.texture = load(path) as Texture2D
		portrait_placeholder_label.hide()
	else:
		portrait.texture = null
		portrait_placeholder_label.show()


func _on_continue_pressed() -> void:
	continue_button.disabled = true
	if has_error:
		_change_scene(LEVEL_SELECTION_SCENE)
		return
	if progress_manager.progression_stage == progress_manager.STAGE_CHARACTER_UNLOCK:
		if progress_manager.confirm_character_unlock(level_id):
			_show_level_unlock()
			continue_button.disabled = false
		return
	if progress_manager.progression_stage == progress_manager.STAGE_LEVEL_UNLOCK:
		progress_manager.finish_progression(level_id)
		_change_scene(LEVEL_SELECTION_SCENE)


func _change_scene(path: String) -> void:
	if scene_change_handler.is_valid():
		scene_change_handler.call(path)
	else:
		get_tree().change_scene_to_file(path)


func _show_error(message: String) -> void:
	has_error = true
	title_label.text = "PROGRESSION UNAVAILABLE"
	hero_name_label.text = ""
	description_label.text = message
	portrait.hide()
	portrait_placeholder_label.hide()
	continue_button.text = "Return to Level Selection"
	continue_button.disabled = false

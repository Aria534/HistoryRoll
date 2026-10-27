extends Control

const MAIN_MENU_SCENE: String = "res://main_menu_tscn.tscn"
const STORY_MODE_SCENE: String = "res://story_mode.tscn"
const CHARACTER_UNLOCK_SCENE: String = "res://character_unlock.tscn"
const LevelCatalog = preload("res://level_catalog.gd")

const LOCK_GOLD := Color("#FFD43B")
const LOCK_OUTLINE := Color("#5C3900")
const LOCKED_MODULATE := Color.WHITE
const SELECTED_SCALE := 1.025

@export var hover_scale: float = 1.03
@export var press_scale: float = 0.97
@export var animation_time: float = 0.12

@onready var level_buttons_area: Control = %LevelButtonsArea
@onready var title_banner: TextureRect = %TitleBanner
@onready var selection_label: Label = %SelectionLabel
@onready var back_button: TextureButton = %BackButton
@onready var play_button: TextureButton = %PlayButton

var selected_level_id: int = 0
var level_buttons: Dictionary = {}
var button_tweens: Dictionary = {}
var hovered_buttons: Dictionary = {}
var progress_manager: Node
var scene_change_handler: Callable
var scene_transition_pending := false


func _ready() -> void:
	if progress_manager == null:
		progress_manager = get_node_or_null("/root/ProgressManager")
	_cache_level_buttons()
	if not _validate_required_nodes():
		return
	_connect_button_once(back_button, _on_back_pressed)
	_connect_button_once(play_button, _on_play_pressed)
	_setup_animated_button(back_button)
	_setup_animated_button(play_button)
	if not progress_manager.progress_changed.is_connected(_refresh_levels):
		progress_manager.progress_changed.connect(_refresh_levels)
	for level_id: int in range(1, 7):
		var button: TextureButton = level_buttons[level_id]
		_connect_button_once(button, _on_level_pressed.bind(level_id))
		_setup_animated_button(button)
	_refresh_levels()


func _cache_level_buttons() -> void:
	level_buttons.clear()
	if level_buttons_area == null:
		return
	for level_id: int in range(1, 7):
		var button := level_buttons_area.get_node_or_null("Level%dButton" % level_id) as TextureButton
		if button != null:
			level_buttons[level_id] = button


func _validate_required_nodes() -> bool:
	var missing_nodes: Array[String] = []
	if level_buttons_area == null:
		missing_nodes.append("LevelButtonsArea")
	if title_banner == null:
		missing_nodes.append("TitleBanner")
	if selection_label == null:
		missing_nodes.append("SelectionLabel")
	if back_button == null:
		missing_nodes.append("BackButton")
	if play_button == null:
		missing_nodes.append("PlayButton")
	for level_id: int in range(1, 7):
		if not level_buttons.has(level_id):
			missing_nodes.append("Level%dButton" % level_id)
	if progress_manager == null:
		missing_nodes.append("/root/ProgressManager")
	if not missing_nodes.is_empty():
		push_error("Level Selection is missing required nodes: %s" % ", ".join(missing_nodes))
		return false
	return true


func _refresh_levels() -> void:
	for level: Dictionary in LevelCatalog.get_levels():
		var level_id := int(level.get("id", 0))
		if not level_buttons.has(level_id):
			continue
		var button: TextureButton = level_buttons[level_id]
		var locked: bool = not progress_manager.is_level_unlocked(level_id)
		button.disabled = locked
		button.tooltip_text = _get_level_button_tooltip(level, locked)
		var lock_overlay := button.get_node_or_null("LockOverlay") as Control
		if lock_overlay == null:
			push_error("Level%dButton is missing its permanent LockOverlay." % level_id)
		else:
			lock_overlay.visible = locked
		button.self_modulate = LOCKED_MODULATE if locked else Color.WHITE

	var preferred_level: int = progress_manager.selected_level
	if level_buttons.has(preferred_level) and progress_manager.is_level_unlocked(preferred_level):
		_select_level(preferred_level)
	else:
		selected_level_id = 0
		selection_label.text = "Select an unlocked level"
		play_button.disabled = true
		play_button.tooltip_text = "Select an unlocked level first"


func _get_level_button_tooltip(level: Dictionary, locked: bool) -> String:
	var level_id := int(level.get("id", 0))
	if locked:
		return "LEVEL %d\nLOCKED" % level_id
	var title := str(level.get("title", "Level %d" % level_id))
	if progress_manager.is_level_completed(level_id):
		return "%s\nCOMPLETED" % title.to_upper()
	if progress_manager.has_pending_progression(level_id):
		return "%s\nCONTINUE PROGRESSION" % title.to_upper()
	if not bool(level.get("implemented", false)):
		return "%s\nUNLOCKED — CONTENT COMING SOON" % title.to_upper()
	return "%s\nAVAILABLE" % title.to_upper()


func _connect_button_once(button: BaseButton, callback: Callable) -> void:
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _on_level_pressed(level_id: int) -> void:
	if not progress_manager.is_level_unlocked(level_id):
		selection_label.text = "That level is still locked."
		return
	_select_level(level_id)


func _select_level(level_id: int) -> void:
	if not progress_manager.select_level(level_id):
		return
	selected_level_id = level_id
	var pending: bool = progress_manager.has_pending_progression(level_id)
	var playable := LevelCatalog.is_level_playable(level_id)
	play_button.disabled = not pending and not playable
	play_button.tooltip_text = "Continue Level %d progression" % level_id if pending else "Play Level %d" % level_id
	selection_label.text = (
		"Selected: Level %d" % level_id
		if playable or pending
		else "Level %d is unlocked, but its gameplay content is still pending." % level_id
	)
	for key: Variant in level_buttons:
		var button: TextureButton = level_buttons[key]
		button.self_modulate = LOCKED_MODULATE if button.disabled else Color.WHITE
		button.scale = Vector2.ONE * _get_rest_scale(button)


func _on_play_pressed() -> void:
	if selected_level_id < 1 or not progress_manager.is_level_unlocked(selected_level_id):
		selection_label.text = "Select an unlocked level first."
		play_button.disabled = true
		return
	if progress_manager.has_pending_progression(selected_level_id):
		match progress_manager.progression_stage:
			progress_manager.STAGE_RESULTS:
				if progress_manager.begin_post_level_story(selected_level_id):
					_change_scene(STORY_MODE_SCENE)
			progress_manager.STAGE_POST_STORY:
				_change_scene(STORY_MODE_SCENE)
			progress_manager.STAGE_CHARACTER_UNLOCK, progress_manager.STAGE_LEVEL_UNLOCK:
				_change_scene(CHARACTER_UNLOCK_SCENE)
		return
	if not LevelCatalog.is_level_playable(selected_level_id):
		selection_label.text = "Level %d is unlocked, but its gameplay content is not implemented yet." % selected_level_id
		play_button.disabled = true
		return
	var gameplay_scene := get_gameplay_scene_for_level(selected_level_id)
	if gameplay_scene.is_empty() or not ResourceLoader.exists(gameplay_scene):
		selection_label.text = "Level %d gameplay is unavailable." % selected_level_id
		push_error("Gameplay scene is missing for Level %d: %s" % [selected_level_id, gameplay_scene])
		return
	_change_scene(gameplay_scene)


func get_gameplay_scene_for_level(level_id: int) -> String:
	return str(LevelCatalog.get_level(level_id).get("gameplay_scene", ""))


func _on_back_pressed() -> void:
	_change_scene(MAIN_MENU_SCENE)


func _change_scene(path: String) -> void:
	if scene_transition_pending:
		return
	scene_transition_pending = true
	back_button.disabled = true
	play_button.disabled = true
	if scene_change_handler.is_valid():
		scene_change_handler.call(path)
	else:
		var error := get_tree().change_scene_to_file(path)
		if error != OK:
			scene_transition_pending = false
			back_button.disabled = false
			play_button.disabled = (
				selected_level_id < 1
				or not progress_manager.is_level_unlocked(selected_level_id)
				or (
					not progress_manager.has_pending_progression(selected_level_id)
					and not LevelCatalog.is_level_playable(selected_level_id)
				)
			)
			push_error("Could not open Level Selection destination: %s" % path)


func _setup_animated_button(button: BaseButton) -> void:
	button.pivot_offset = button.size / 2.0
	button.resized.connect(func(): button.pivot_offset = button.size / 2.0)
	button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
	button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
	button.button_down.connect(_on_button_down.bind(button))
	button.button_up.connect(_on_button_up.bind(button))


func _on_button_mouse_entered(button: BaseButton) -> void:
	hovered_buttons[button] = true
	if not button.button_pressed:
		_animate_button(button, _get_rest_scale(button) * hover_scale)


func _on_button_mouse_exited(button: BaseButton) -> void:
	hovered_buttons[button] = false
	if not button.button_pressed:
		_animate_button(button, _get_rest_scale(button))


func _on_button_down(button: BaseButton) -> void:
	_animate_button(button, _get_rest_scale(button) * press_scale)


func _on_button_up(button: BaseButton) -> void:
	var target_scale := _get_rest_scale(button)
	if not DisplayServer.is_touchscreen_available() and hovered_buttons.get(button, false):
		target_scale *= hover_scale
	_animate_button(button, target_scale)


func _animate_button(button: BaseButton, target_scale: float) -> void:
	var current_tween: Tween = button_tweens.get(button)
	if current_tween != null and current_tween.is_valid():
		current_tween.kill()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE * target_scale, animation_time)
	button_tweens[button] = tween


func _get_rest_scale(button: BaseButton) -> float:
	for level_id: Variant in level_buttons:
		if level_buttons[level_id] == button and int(level_id) == selected_level_id:
			return SELECTED_SCALE
	return 1.0

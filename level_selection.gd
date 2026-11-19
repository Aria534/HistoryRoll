extends Control

const MAIN_MENU_SCENE: String = "res://main_menu_tscn.tscn"
const STORY_MODE_SCENE: String = "res://story_mode.tscn"
const CHARACTER_UNLOCK_SCENE: String = "res://character_unlock.tscn"
const LevelCatalog = preload("res://level_catalog.gd")
const SELECTED_SCALE := 1.025
const DESIGN_SIZE := Vector2(1086.0, 1448.0)

@export var hover_scale: float = 1.03
@export var press_scale: float = 0.97
@export var animation_time: float = 0.12

@onready var level_buttons_area: Control = %LevelButtonsArea
@onready var ui_root: Control = %UIRoot
@onready var title_banner: Control = %TitleBanner
@onready var selection_label := get_node_or_null("%SelectionLabel") as Label
@onready var back_button: TextureButton = %BackButton
@onready var help_button: TextureButton = %HelpButton
@onready var help_overlay: Control = %HelpOverlay
@onready var close_help_button: Button = %CloseHelpButton
@onready var play_button: BaseButton = %PlayButton

var selected_level_id: int = 0
var level_buttons: Dictionary = {}
var button_tweens: Dictionary = {}
var hovered_buttons: Dictionary = {}
var progress_manager: Node
var scene_change_handler: Callable
var scene_transition_pending := false
var selection_message := ""


func _ready() -> void:
	_request_music("res://assets/audio/music/level_select.ogg")
	resized.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	if progress_manager == null:
		progress_manager = get_node_or_null("/root/ProgressManager")
	_cache_level_buttons()
	if not _validate_required_nodes():
		return
	_connect_button_once(back_button, _on_back_pressed)
	_connect_button_once(help_button, _on_help_pressed)
	_connect_button_once(close_help_button, _on_close_help_pressed)
	_connect_button_once(play_button, _on_play_pressed)
	_setup_animated_button(back_button)
	_setup_animated_button(help_button)
	_setup_animated_button(close_help_button)
	_setup_animated_button(play_button)
	if not progress_manager.progress_changed.is_connected(_refresh_levels):
		progress_manager.progress_changed.connect(_refresh_levels)
	for level_id: int in range(1, 7):
		var button: BaseButton = level_buttons[level_id]
		_connect_button_once(button, _on_level_pressed.bind(level_id))
		_setup_animated_button(button)
	_refresh_levels()


func _request_music(track_path: String) -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_music"):
		audio_manager.call("play_music", track_path, 0.6)


func _apply_responsive_layout() -> void:
	if ui_root == null or size.x <= 0.0 or size.y <= 0.0:
		return
	var safe_rect := Rect2(Vector2.ZERO, size)
	if OS.has_feature("android"):
		var screen_size := Vector2(DisplayServer.screen_get_size())
		var safe_area := Rect2(DisplayServer.get_display_safe_area())
		if screen_size.x > 0.0 and screen_size.y > 0.0 and safe_area.has_area():
			safe_rect = Rect2(safe_area.position / screen_size * size, safe_area.size / screen_size * size)
	var layout_scale := minf(safe_rect.size.x / DESIGN_SIZE.x, safe_rect.size.y / DESIGN_SIZE.y)
	ui_root.scale = Vector2.ONE * layout_scale
	ui_root.size = safe_rect.size / layout_scale
	ui_root.position = safe_rect.position
	var background := get_node("Background") as TextureRect
	background.size = size
	background.position = Vector2.ZERO


func _cache_level_buttons() -> void:
	level_buttons.clear()
	if level_buttons_area == null:
		return
	for level_id: int in range(1, 7):
		var button := level_buttons_area.get_node_or_null("Level%dButton" % level_id) as BaseButton
		if button != null:
			level_buttons[level_id] = button


func _validate_required_nodes() -> bool:
	var missing_nodes: Array[String] = []
	if ui_root == null:
		missing_nodes.append("UIRoot")
	if level_buttons_area == null:
		missing_nodes.append("LevelButtonsArea")
	if title_banner == null:
		missing_nodes.append("TitleBanner")
	if back_button == null:
		missing_nodes.append("BackButton")
	if help_button == null:
		missing_nodes.append("HelpButton")
	if help_overlay == null:
		missing_nodes.append("HelpOverlay")
	if close_help_button == null:
		missing_nodes.append("CloseHelpButton")
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
		var button: BaseButton = level_buttons[level_id]
		var locked: bool = not progress_manager.is_level_unlocked(level_id)
		if button.has_method("set_locked"):
			button.call("set_locked", locked)
		else:
			button.disabled = locked
		button.tooltip_text = _get_level_button_tooltip(level, locked)
		button.self_modulate = Color.WHITE

	var preferred_level: int = progress_manager.selected_level
	if level_buttons.has(preferred_level) and progress_manager.is_level_unlocked(preferred_level):
		_select_level(preferred_level)
	elif level_buttons.has(1) and progress_manager.is_level_unlocked(1):
		_select_level(1)
	else:
		selected_level_id = 0
		_set_selection_message("Select an unlocked level")
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
		_set_selection_message("That level is still locked.")
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
	_set_selection_message(
		"Selected: Level %d" % level_id
		if playable or pending
		else "Level %d is unlocked, but its gameplay content is still pending." % level_id
	)
	for key: Variant in level_buttons:
		var button: BaseButton = level_buttons[key]
		button.self_modulate = Color.WHITE
		button.scale = Vector2.ONE * _get_rest_scale(button)


func _on_play_pressed() -> void:
	if selected_level_id < 1 or not progress_manager.is_level_unlocked(selected_level_id):
		_set_selection_message("Select an unlocked level first.")
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
		_set_selection_message("Level %d is unlocked, but its gameplay content is not implemented yet." % selected_level_id)
		play_button.disabled = true
		return
	var gameplay_scene := get_gameplay_scene_for_level(selected_level_id)
	if gameplay_scene.is_empty() or not ResourceLoader.exists(gameplay_scene):
		_set_selection_message("Level %d gameplay is unavailable." % selected_level_id)
		push_error("Gameplay scene is missing for Level %d: %s" % [selected_level_id, gameplay_scene])
		return
	_change_scene(gameplay_scene)


func _set_selection_message(message: String) -> void:
	selection_message = message
	if selection_label != null:
		selection_label.text = message


func get_gameplay_scene_for_level(level_id: int) -> String:
	return str(LevelCatalog.get_level(level_id).get("gameplay_scene", ""))


func _on_back_pressed() -> void:
	_change_scene(MAIN_MENU_SCENE)


func _on_help_pressed() -> void:
	help_overlay.visible = true
	close_help_button.grab_focus()


func _on_close_help_pressed() -> void:
	help_overlay.visible = false
	help_button.grab_focus()


func _change_scene(path: String) -> void:
	if scene_transition_pending:
		return
	scene_transition_pending = true
	back_button.disabled = true
	help_button.disabled = true
	play_button.disabled = true
	if scene_change_handler.is_valid():
		scene_change_handler.call(path)
	else:
		var error := get_tree().change_scene_to_file(path)
		if error != OK:
			scene_transition_pending = false
			back_button.disabled = false
			help_button.disabled = false
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
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_sfx"):
		audio_manager.call("play_sfx", "res://assets/audio/sfx/menu_press.ogg", "menu_press")
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

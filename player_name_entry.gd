@tool
extends Control

const ProgressScript = preload("res://progress_manager.gd")
const DESIGN_SIZE := Vector2(1024, 1536)
const NAME_ENTRY_BACKGROUND: Texture2D = preload("res://assets/player_identity/name_entry_background_no_leaves.png")
const LEVEL_SELECTION_SCENE := "res://level_selection.tscn"
const MAIN_MENU_SCENE := "res://main_menu_tscn.tscn"
const CERTIFICATE_SCENE := "res://certificate.tscn"

@onready var presentation: Control = $Presentation
@onready var form: VBoxContainer = %Form
@onready var name_input: LineEdit = %NameInput
@onready var validation_label: Label = %ValidationLabel
@onready var character_count: Label = %CharacterCount
@onready var continue_button: Button = %ContinueButton
@onready var back_button: Button = %BackButton
@onready var certificate_button: Button = %CertificateButton

var progress_manager: Node
var scene_change_handler: Callable
var scene_transition_pending := false
var _keyboard_height := 0

func _ready() -> void:
	$Presentation/Artwork.texture = NAME_ENTRY_BACKGROUND
	name_input.custom_minimum_size = Vector2(544.0, 84.0)
	name_input.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	name_input.mouse_default_cursor_shape = Control.CURSOR_IBEAM
	name_input.focus_mode = Control.FOCUS_ALL
	# Keep a clear caret visible throughout editing, including the first click.
	name_input.caret_blink = false
	name_input.add_theme_constant_override("caret_width", 3)
	resized.connect(_apply_layout)
	_apply_layout()
	_apply_layout.call_deferred()
	if Engine.is_editor_hint():
		set_process(false)
		return
	if progress_manager == null:
		progress_manager = get_node("/root/ProgressManager")
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_music("res://assets/audio/music/main_menu.ogg", 0.45)
	name_input.max_length = ProgressScript.MAX_PLAYER_NAME_LENGTH
	name_input.text = progress_manager.player_name
	name_input.caret_column = name_input.text.length()
	name_input.gui_input.connect(_on_name_input_gui_input)
	name_input.editing_toggled.connect(_on_name_editing_toggled)
	name_input.text_changed.connect(_on_name_changed)
	name_input.text_submitted.connect(func(_value: String): _on_continue_pressed())
	continue_button.pressed.connect(_on_continue_pressed)
	back_button.pressed.connect(func(): _change_scene(MAIN_MENU_SCENE))
	certificate_button.pressed.connect(func(): _save_and_open(CERTIFICATE_SCENE))
	certificate_button.visible = progress_manager.is_certificate_unlocked()
	_on_name_changed(name_input.text)

func _process(_delta: float) -> void:
	if OS.has_feature("android"):
		var keyboard_height := DisplayServer.virtual_keyboard_get_height()
		if keyboard_height != _keyboard_height:
			_keyboard_height = keyboard_height
			_apply_layout()

func _apply_layout() -> void:
	if not is_node_ready() or size.x <= 0.0 or size.y <= 0.0:
		return
	var safe_rect := Rect2(Vector2.ZERO, size)
	if OS.has_feature("android"):
		var screen_size := Vector2(DisplayServer.screen_get_size())
		var safe_area := Rect2(DisplayServer.get_display_safe_area())
		if screen_size.x > 0.0 and screen_size.y > 0.0 and safe_area.has_area():
			safe_rect = Rect2(safe_area.position / screen_size * size, safe_area.size / screen_size * size)
	var ui_scale := minf(safe_rect.size.x / DESIGN_SIZE.x, safe_rect.size.y / DESIGN_SIZE.y)
	presentation.scale = Vector2.ONE * ui_scale
	presentation.size = DESIGN_SIZE
	presentation.position = safe_rect.get_center() - DESIGN_SIZE * ui_scale * 0.5
	# Move the form above the native Android keyboard without scaling the input
	# down or shrinking its touch target. The decorative frame remains still.
	var keyboard_top := size.y
	if _keyboard_height > 0 and get_window().size.y > 0:
		keyboard_top -= float(_keyboard_height) / get_window().size.y * size.y
	var keyboard_open := _keyboard_height > 0
	%WelcomeHeading.hide()
	%Subtitle.visible = not keyboard_open
	var minimum_height := form.get_combined_minimum_size().y
	form.size = Vector2(644.0, minimum_height if keyboard_open else maxf(500.0, minimum_height))
	var form_bottom := presentation.position.y + (610.0 + form.size.y) * ui_scale
	var lift := maxf(0.0, form_bottom - keyboard_top + 24.0 * ui_scale) if _keyboard_height > 0 else 0.0
	form.position.y = 610.0 - lift / ui_scale

func _on_name_editing_toggled(editing: bool) -> void:
	# Keep the ready-to-type marker clear even before the first typed character.
	name_input.caret_force_displayed = editing
	name_input.placeholder_text = "" if editing else "Enter your name..."

func _on_name_input_gui_input(event: InputEvent) -> void:
	if scene_transition_pending or not name_input.editable:
		return
	var pointer_pressed := false
	if event is InputEventMouseButton:
		pointer_pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		pointer_pressed = event.pressed
	if pointer_pressed:
		name_input.grab_focus()
		name_input.edit()

func _on_name_changed(value: String) -> void:
	var error := ProgressScript.get_player_name_error(value)
	continue_button.disabled = not error.is_empty() or scene_transition_pending
	certificate_button.disabled = continue_button.disabled
	character_count.text = "%d / %d" % [value.length(), ProgressScript.MAX_PLAYER_NAME_LENGTH]
	validation_label.text = error if not value.is_empty() else "Use letters, spaces, hyphens or apostrophes."

func _on_continue_pressed() -> void:
	_save_and_open(LEVEL_SELECTION_SCENE)

func _save_and_open(path: String) -> void:
	if scene_transition_pending:
		return
	var error := ProgressScript.get_player_name_error(name_input.text)
	if not error.is_empty():
		validation_label.text = error
		continue_button.disabled = true
		return
	if not progress_manager.set_player_name(name_input.text):
		validation_label.text = "We couldn't save your name. Please try again."
		return
	_change_scene(path)

func _change_scene(path: String) -> void:
	if scene_transition_pending:
		return
	scene_transition_pending = true
	continue_button.disabled = true
	back_button.disabled = true
	certificate_button.disabled = true
	name_input.editable = false
	name_input.release_focus()
	if OS.has_feature("android"):
		DisplayServer.virtual_keyboard_hide()
	if scene_change_handler.is_valid():
		scene_change_handler.call(path)
		return
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		scene_transition_pending = false
		back_button.disabled = false
		name_input.editable = true
		_on_name_changed(name_input.text)
		validation_label.text = "This screen couldn't open. Please try again."

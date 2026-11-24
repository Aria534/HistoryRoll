@tool
extends Control

const ProgressScript = preload("res://progress_manager.gd")
const DESIGN_SIZE := Vector2(1536, 1024)
const LEVEL_SELECTION_SCENE := "res://level_selection.tscn"
const NAME_ENTRY_SCENE := "res://player_name_entry.tscn"

@onready var certificate_canvas: Control = %CertificateCanvas
@onready var player_name_label: Label = %PlayerNameLabel
@onready var status_label: Label = %StatusLabel
@onready var back_button: Button = %BackButton
@onready var name_button: Button = %NameButton
var progress_manager: Node
var scene_change_handler: Callable
var scene_transition_pending := false

func _ready() -> void:
	resized.connect(_apply_layout)
	if Engine.is_editor_hint():
		_apply_layout()
		return
	if progress_manager == null:
		progress_manager = get_node("/root/ProgressManager")
	back_button.pressed.connect(func(): _change_scene(LEVEL_SELECTION_SCENE))
	name_button.pressed.connect(func(): _change_scene(NAME_ENTRY_SCENE))
	progress_manager.progress_changed.connect(_refresh_certificate)
	var audio := get_node_or_null("/root/AudioManager")
	if audio != null:
		audio.play_music("res://assets/audio/music/victory.ogg", 0.45)
	_refresh_certificate()

func _refresh_certificate() -> void:
	var earned: bool = progress_manager.is_certificate_unlocked()
	var saved_name: String = progress_manager.player_name
	var has_name := ProgressScript.get_player_name_error(saved_name).is_empty()
	certificate_canvas.visible = earned and has_name
	player_name_label.text = saved_name if earned and has_name else ""
	name_button.visible = earned and not has_name
	status_label.text = (
		"Your Certificate of Achievement"
		if earned and has_name else
		"Your certificate is earned! Add your name to display it."
		if earned else
		"Complete all six levels to earn your certificate."
	)
	_apply_layout()

func _apply_layout() -> void:
	if not is_node_ready() or size.x <= 0.0 or size.y <= 0.0:
		return
	var safe := Rect2(Vector2.ZERO, size).grow(-24.0)
	if OS.has_feature("android"):
		var screen := Vector2(DisplayServer.screen_get_size())
		var area := Rect2(DisplayServer.get_display_safe_area())
		if screen.x > 0.0 and screen.y > 0.0 and area.has_area():
			safe = Rect2(area.position / screen * size, area.size / screen * size).grow(-24.0)
	var card_scale := minf(safe.size.x / DESIGN_SIZE.x, maxf(1.0, safe.size.y - 260.0) / DESIGN_SIZE.y)
	certificate_canvas.scale = Vector2.ONE * card_scale
	certificate_canvas.size = DESIGN_SIZE
	certificate_canvas.position = safe.get_center() - DESIGN_SIZE * card_scale * 0.5 - Vector2(0, 30)
	status_label.position = Vector2(safe.position.x, maxf(safe.position.y, certificate_canvas.position.y - 94.0))
	status_label.size = Vector2(safe.size.x, 70)
	status_label.add_theme_font_size_override("font_size", clampi(roundi(size.x * 0.04), 20, 40))
	var font := player_name_label.get_theme_font("font")
	var name_size := 64
	while name_size > 20 and font.get_string_size(player_name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x > player_name_label.size.x:
		name_size -= 1
	player_name_label.add_theme_font_size_override("font_size", name_size)
	back_button.size = Vector2(minf(safe.size.x * 0.7, 540.0), 90)
	back_button.position = Vector2(safe.get_center().x - back_button.size.x * 0.5, minf(safe.end.y - 96, certificate_canvas.position.y + DESIGN_SIZE.y * card_scale + 40.0))
	name_button.size = back_button.size
	name_button.position = Vector2(back_button.position.x, maxf(safe.position.y + 160.0, back_button.position.y - 120.0))

func _change_scene(path: String) -> void:
	if scene_transition_pending:
		return
	scene_transition_pending = true
	back_button.disabled = true
	name_button.disabled = true
	if scene_change_handler.is_valid():
		scene_change_handler.call(path)
		return
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		scene_transition_pending = false
		back_button.disabled = false
		name_button.disabled = false
		status_label.text = "This screen couldn't open. Please try again."

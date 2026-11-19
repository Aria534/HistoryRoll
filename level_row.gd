class_name LevelSelectionRow
extends Button

const UNLOCKED_FRAME := preload("res://assets/level_selection_pixel/level_row_unlocked_reference.png")
const LOCKED_FRAME := preload("res://assets/level_selection_pixel/level_row_locked_reference.png")

@export var level_id: int = 1
@export var level_title: String = "LEVEL 1 - LAPU-LAPU"
@export var portrait: Texture2D
@export var row_texture: Texture2D
@export_range(24, 36, 1) var name_font_size: int = 28

@onready var frame_rect: TextureRect = $Frame
@onready var portrait_rect: TextureRect = $Portrait
@onready var name_label: Label = $Name
@onready var lock_icon: Control = $LockIcon
@onready var status_label: Label = $Status


func _ready() -> void:
	name_label.text = level_title
	name_label.add_theme_font_size_override("font_size", name_font_size)
	portrait_rect.texture = portrait
	if row_texture != null:
		# The approved row contains its portrait and lettering. Keep the legacy
		# fields/nodes available without drawing duplicate faces or captions.
		portrait_rect.hide()
		name_label.hide()
	set_locked(disabled)


func set_locked(locked: bool) -> void:
	disabled = locked
	if not is_node_ready():
		return
	lock_icon.visible = locked
	frame_rect.texture = row_texture if row_texture != null else (LOCKED_FRAME if locked else UNLOCKED_FRAME)
	status_label.text = "LOCKED" if locked else "UNLOCKED"
	status_label.modulate = Color("#2A2D30") if locked else Color("#075F3E")
	portrait_rect.self_modulate = Color.WHITE if row_texture != null else (Color(0.68, 0.68, 0.68, 1.0) if locked else Color.WHITE)


func is_lock_visible() -> bool:
	return lock_icon.visible

class_name LevelSelectionRow
extends Button

@export var level_id: int = 1
@export var level_title: String = "LEVEL 1 - LAPU-LAPU"
@export var portrait: Texture2D

@onready var portrait_rect: TextureRect = $Row/PortraitFrame/Portrait
@onready var name_label: Label = $Row/Text/Name
@onready var lock_icon: Control = $Row/State/LockIcon
@onready var status_label: Label = $Row/State/Status


func _ready() -> void:
	name_label.text = level_title
	portrait_rect.texture = portrait
	set_locked(disabled)


func set_locked(locked: bool) -> void:
	disabled = locked
	if not is_node_ready():
		return
	lock_icon.visible = locked
	status_label.text = "LOCKED" if locked else "UNLOCKED"
	status_label.modulate = Color("#2A2D30") if locked else Color("#075F3E")
	portrait_rect.self_modulate = Color(0.58, 0.58, 0.58, 1.0) if locked else Color.WHITE


func is_lock_visible() -> bool:
	return lock_icon.visible

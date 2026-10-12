extends Control

const STORY_MODE_SCENE: String = "res://story_mode.tscn"

@onready var level_label: Label = %LevelLabel
@onready var back_button: Button = %BackButton


func _ready() -> void:
	level_label.text = "LEVEL %d" % ProgressManager.selected_level
	back_button.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(STORY_MODE_SCENE)

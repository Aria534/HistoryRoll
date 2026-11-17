extends Control

const HERO_CARDS_SCENE := "res://hero_cards.tscn"
const MAIN_MENU_MUSIC := "res://assets/audio/music/main_menu.ogg"
const LevelCatalog = preload("res://level_catalog.gd")

const VIDEO_PATHS := {
	1: "res://assets/story_videos/lapulapu_story.ogv",
	2: "res://assets/story_videos/bonifacio_story.ogv",
	3: "res://assets/story_videos/rizal_story.ogv",
	4: "res://assets/story_videos/antonio_luna_story.ogv",
	5: "res://assets/story_videos/melchora_aquino_story.ogv",
	6: "res://assets/story_videos/mabini_story.ogv",
}

const CONTRIBUTIONS := {
	1: "Defended Mactan and became a lasting symbol of courage and resistance to foreign domination.",
	2: "Helped organize the Katipunan and helped launch the struggle for Philippine independence.",
	3: "Used his writings and ideas to awaken Filipino nationalism and encourage reform.",
	4: "Helped organize and strengthen the revolutionary army and the defense of the Philippine Republic.",
	5: "Supported the Revolution by providing food, shelter, care, and assistance to Katipuneros.",
	6: "Helped shape the government and political principles of the First Philippine Republic.",
}

@onready var video_player: VideoStreamPlayer = %VideoPlayer
@onready var controls_layer: Control = %ControlsLayer
@onready var pause_resume_button: Button = %PauseResumeButton
@onready var skip_button: Button = %SkipButton
@onready var progress_bar: ProgressBar = %VideoProgress
@onready var video_status_label: Label = %VideoStatusLabel
@onready var ending_panel: PanelContainer = %EndingPanel
@onready var hero_name_label: Label = %HeroNameLabel
@onready var hero_title_label: Label = %HeroTitleLabel
@onready var contribution_label: Label = %ContributionLabel
@onready var ending_status_label: Label = %EndingStatusLabel
@onready var play_level_button: Button = %PlayLevelButton
@onready var replay_button: Button = %ReplayButton
@onready var back_button: Button = %BackButton
@onready var fade_overlay: ColorRect = %FadeOverlay

var progress_manager: Node
var scene_change_handler: Callable
var level_id := 1
var level_data: Dictionary = {}
var video_path := ""
var video_available := false
var ending_visible := false
var playback_paused := false
var _transitioning := false
var _fade_tween: Tween


func _ready() -> void:
	if progress_manager == null:
		progress_manager = get_node_or_null("/root/ProgressManager")
	_connect_once(pause_resume_button.pressed, _on_pause_resume_pressed)
	_connect_once(skip_button.pressed, _on_skip_pressed)
	_connect_once(play_level_button.pressed, _on_play_level_pressed)
	_connect_once(replay_button.pressed, _on_replay_pressed)
	_connect_once(back_button.pressed, _on_back_pressed)
	_connect_once(video_player.finished, _on_video_finished)
	_suspend_background_music()
	_load_selected_story()


func _process(_delta: float) -> void:
	if not video_available or video_player.stream == null:
		return
	var length := video_player.get_stream_length()
	if length > 0.0:
		progress_bar.value = clampf(video_player.stream_position / length * 100.0, 0.0, 100.0)


func _connect_once(signal_value: Signal, callback: Callable) -> void:
	if not signal_value.is_connected(callback):
		signal_value.connect(callback)


func _load_selected_story() -> void:
	level_id = clampi(int(progress_manager.selected_story_level) if progress_manager != null else 1, 1, 6)
	level_data = LevelCatalog.get_level(level_id)
	video_path = str(VIDEO_PATHS.get(level_id, ""))
	hero_name_label.text = str(level_data.get("hero_name", "FILIPINO HERO")).to_upper()
	hero_title_label.text = str(level_data.get("educational_theme", "HERO STORY")).to_upper()
	contribution_label.text = str(CONTRIBUTIONS.get(level_id, level_data.get("contribution", "")))
	_refresh_level_button()
	_load_video_stream()


func _load_video_stream() -> void:
	video_available = false
	video_player.stop()
	video_player.stream = null
	if not video_path.is_empty() and ResourceLoader.exists(video_path):
		var loaded_stream := load(video_path) as VideoStream
		if loaded_stream != null:
			video_player.stream = loaded_stream
			video_available = true
	if video_available:
		video_status_label.hide()
		replay_button.disabled = false
		_start_video()
	else:
		video_status_label.hide()
		pause_resume_button.disabled = true
		skip_button.disabled = true
		replay_button.disabled = true
		_show_ending(false)
		ending_status_label.text = "STORY VIDEO COMING SOON"


func _start_video() -> void:
	if not video_available:
		return
	ending_visible = false
	playback_paused = false
	ending_panel.hide()
	controls_layer.show()
	video_status_label.hide()
	progress_bar.value = 0.0
	video_player.paused = false
	if video_player.stream != null:
		video_player.play()
	pause_resume_button.disabled = false
	pause_resume_button.text = "PAUSE"
	skip_button.disabled = false
	_fade_from_black()


func _on_pause_resume_pressed() -> void:
	if not video_available or ending_visible:
		return
	playback_paused = not playback_paused
	video_player.paused = playback_paused
	pause_resume_button.text = "RESUME" if playback_paused else "PAUSE"


func _on_skip_pressed() -> void:
	if ending_visible:
		return
	video_player.stop()
	_show_ending(true)


func _on_video_finished() -> void:
	_show_ending(true)


func _show_ending(mark_watched: bool) -> void:
	ending_visible = true
	playback_paused = false
	video_player.stop()
	controls_layer.hide()
	ending_panel.show()
	if mark_watched and progress_manager != null and progress_manager.has_method("mark_story_watched"):
		progress_manager.mark_story_watched(level_id)
	ending_status_label.text = "STORY WATCHED" if _is_story_watched() else "OPTIONAL HERO STORY"
	_refresh_level_button()
	_fade_to_ending()


func _refresh_level_button() -> void:
	var unlocked: bool = progress_manager != null and bool(progress_manager.is_level_unlocked(level_id))
	play_level_button.disabled = not unlocked or not LevelCatalog.is_level_playable(level_id)
	play_level_button.text = "PLAY LEVEL" if not play_level_button.disabled else "LEVEL LOCKED"
	play_level_button.tooltip_text = "" if not play_level_button.disabled else "Complete the previous level to unlock this level."


func _is_story_watched() -> bool:
	return progress_manager != null and progress_manager.has_method("is_story_watched") and progress_manager.is_story_watched(level_id)


func _on_replay_pressed() -> void:
	_start_video()


func _on_play_level_pressed() -> void:
	if progress_manager == null or not progress_manager.is_level_unlocked(level_id):
		ending_status_label.text = "Complete the previous level first."
		return
	if not progress_manager.select_level(level_id):
		return
	var gameplay_scene := str(level_data.get("gameplay_scene", ""))
	if gameplay_scene.is_empty() or not ResourceLoader.exists(gameplay_scene, "PackedScene"):
		ending_status_label.text = "This level is not available yet."
		return
	_change_scene(gameplay_scene)


func _on_back_pressed() -> void:
	_restore_hero_cards_music()
	_change_scene(HERO_CARDS_SCENE)


func _change_scene(path: String) -> void:
	_transitioning = true
	video_player.stop()
	video_player.stream = null
	if scene_change_handler.is_valid():
		scene_change_handler.call(path)
	else:
		var error := get_tree().change_scene_to_file(path)
		if error != OK:
			_transitioning = false
			push_error("Unable to open scene: %s" % path)


func _suspend_background_music() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("stop_music"):
		audio_manager.stop_music(0.35)


func _restore_hero_cards_music() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_music"):
		audio_manager.play_music(MAIN_MENU_MUSIC, 0.45)


func _fade_from_black() -> void:
	_kill_fade()
	fade_overlay.show()
	fade_overlay.modulate.a = 1.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_overlay, "modulate:a", 0.0, 0.35)
	_fade_tween.tween_callback(fade_overlay.hide)


func _fade_to_ending() -> void:
	_kill_fade()
	fade_overlay.show()
	fade_overlay.modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(fade_overlay, "modulate:a", 0.62, 0.25)


func _kill_fade() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null


func _exit_tree() -> void:
	video_player.stop()
	video_player.stream = null
	_kill_fade()

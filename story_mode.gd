extends Control

const HERO_CARDS_SCENE := "res://hero_cards.tscn"
const SETTINGS_PATH := "user://historyroll_settings.cfg"
const LevelCatalog = preload("res://level_catalog.gd")
const StoryData = preload("res://story_data.gd")

@onready var background_layer: TextureRect = %BackgroundLayer
@onready var midground_layer: TextureRect = %MidgroundLayer
@onready var foreground_layer: TextureRect = %ForegroundLayer
@onready var effects_texture: TextureRect = %EffectsTexture
@onready var ambient_light: ColorRect = %AmbientLight
@onready var battle_flash: ColorRect = %BattleFlash
@onready var character_sprite: TextureRect = %CharacterSprite
@onready var dark_overlay: ColorRect = %DarkOverlay
@onready var opening_title: VBoxContainer = %TitleStack
@onready var hero_name_label: Label = %HeroNameLabel
@onready var scene_title_label: Label = %SceneTitleLabel
@onready var story_text: Label = %SubtitleLabel
@onready var progress_indicator: Label = %ProgressIndicator
@onready var skip_button: Button = %SkipButton
@onready var pause_button: Button = %PauseButton
@onready var ending_panel: PanelContainer = %EndingPanel
@onready var ending_title: Label = %EndingTitle
@onready var replay_button: Button = %ReplayButton
@onready var continue_button: Button = %PlayLevelButton
@onready var back_button: Button = %BackButton
@onready var scene_timer: Timer = %SceneTimer
@onready var subtitle_timer: Timer = %SubtitleTimer
@onready var voice_player: AudioStreamPlayer = %VoicePlayer
@onready var music_player: AudioStreamPlayer = %MusicPlayer
@onready var sfx_player: AudioStreamPlayer = %SFXPlayer

var current_panel_index: int:
	get: return current_scene_index
var panels: Array:
	get: return scenes

var story: Dictionary = {}
var scenes: Array = []
var level_data: Dictionary = {}
var level_id := 0
var current_scene_index := 0
var story_available := false
var cinematic_paused := false
var ending_visible := false
var progress_manager: Node
var scene_change_handler: Callable
var scene_transition_pending := false
var motion_tween: Tween
var fade_tween: Tween
var shake_tween: Tween
var environment_tween: Tween
var effects_tween: Tween
var title_tween: Tween
var subtitle_tween: Tween
var transition_tween: Tween
var transition_in_progress := false
var subtitle_cues: Array[String] = []
var subtitle_cue_index := 0


func _ready() -> void:
	if progress_manager == null:
		progress_manager = get_node("/root/ProgressManager")
	voice_player.bus = "Master"
	music_player.bus = "Music"
	sfx_player.bus = "SFX"
	_apply_saved_audio_settings()
	_connect_once(scene_timer.timeout, _on_scene_timeout)
	_connect_once(subtitle_timer.timeout, _on_subtitle_timeout)
	_connect_once(skip_button.pressed, _on_skip_pressed)
	_connect_once(pause_button.pressed, _on_pause_pressed)
	_connect_once(replay_button.pressed, _on_replay_pressed)
	_connect_once(continue_button.pressed, _on_play_level_pressed)
	_connect_once(back_button.pressed, _on_back_pressed)
	_load_hero_story()


func _connect_once(signal_value: Signal, callback: Callable) -> void:
	if not signal_value.is_connected(callback):
		signal_value.connect(callback)


func _apply_saved_audio_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for setting: Array in [["Music", "music_enabled"], ["SFX", "sfx_enabled"]]:
		var bus_index := AudioServer.get_bus_index(str(setting[0]))
		if bus_index >= 0:
			AudioServer.set_bus_mute(bus_index, not bool(config.get_value("audio", str(setting[1]), true)))


func _load_hero_story() -> void:
	level_id = int(progress_manager.selected_story_level)
	level_data = LevelCatalog.get_level(level_id)
	story = StoryData.get_story(level_id)
	scenes = (story.get("scenes", []) as Array).duplicate(true)
	story_available = not level_data.is_empty() and scenes.size() == 6
	current_scene_index = 0
	if not story_available:
		_show_unavailable_story()
		return
	hero_name_label.text = str(story.get("hero_name", "FILIPINO HERO")).to_upper()
	_start_scene(0, true)


func _start_scene(index: int, show_opening := false) -> void:
	if not story_available or index < 0 or index >= scenes.size():
		return
	_stop_scene_media_and_motion()
	ending_visible = false
	ending_panel.hide()
	transition_in_progress = false
	current_scene_index = index
	var scene: Dictionary = scenes[index]
	if show_opening:
		hero_name_label.text = str(story.get("hero_name", "FILIPINO HERO")).to_upper()
		scene_title_label.text = str(story.get("title", "HERO STORY")).get_slice(" - ", 1)
		_show_opening_title()
	else:
		opening_title.hide()
	subtitle_cues = _build_subtitle_cues(str(scene.get("subtitle", "")))
	subtitle_cue_index = 0
	_show_subtitle(subtitle_cues[0] if not subtitle_cues.is_empty() else "")
	progress_indicator.hide()
	_load_layer_texture(background_layer, str(scene.get("background_path", "")))
	_load_layer_texture(midground_layer, str(scene.get("midground_path", "")))
	_load_layer_texture(foreground_layer, str(scene.get("foreground_path", "")))
	_load_layer_texture(effects_texture, str(scene.get("effects_path", "")))
	var character_path := str(scene.get("character_path", ""))
	_set_character_texture(character_path if not character_path.is_empty() else str(story.get("portrait_path", "")))
	_play_optional_audio(voice_player, str(scene.get("voice_path", "")), false)
	_play_optional_audio(sfx_player, str(scene.get("sfx_path", "")), false)
	_play_optional_audio(music_player, str(scene.get("music_path", "")), true)
	_apply_motion(str(scene.get("motion", "pan_right")), bool(scene.get("shake", false)), float(scene.get("duration", 9.0)))
	_apply_environment_motion(str(scene.get("environment", "ambient")), bool(scene.get("shake", false)))
	_fade_from_black()
	var scene_duration := float(scene.get("duration", 9.0))
	scene_timer.start(scene_duration)
	if subtitle_cues.size() > 1:
		subtitle_timer.start(scene_duration / float(subtitle_cues.size()))
	pause_button.text = "PAUSE"
	cinematic_paused = false


func _load_layer_texture(layer: TextureRect, path: String) -> void:
	layer.texture = load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
	layer.visible = layer.texture != null


func _set_character_texture(path: String) -> void:
	character_sprite.texture = load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
	character_sprite.visible = character_sprite.texture != null


func _apply_motion(motion: String, shake: bool, duration: float) -> void:
	var viewport_size := get_viewport_rect().size
	var character_size := Vector2(minf(viewport_size.x * 0.48, 430.0), minf(viewport_size.y * 0.46, 590.0))
	background_layer.position = Vector2(-45.0, -25.0)
	background_layer.scale = Vector2(1.1, 1.1)
	background_layer.pivot_offset = background_layer.size * 0.5
	midground_layer.position = Vector2(-20.0, 0.0)
	foreground_layer.position = Vector2(-35.0, 0.0)
	effects_texture.position = Vector2.ZERO
	character_sprite.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	character_sprite.size = character_size
	character_sprite.pivot_offset = character_size * 0.5
	character_sprite.scale = Vector2.ONE
	character_sprite.rotation = 0.0
	character_sprite.modulate = Color.WHITE
	motion_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	match motion:
		"pan_left":
			character_sprite.position = Vector2(viewport_size.x * 0.62, viewport_size.y * 0.28)
			character_sprite.scale = Vector2(0.72, 0.72)
			motion_tween.tween_property(character_sprite, "position:x", viewport_size.x * 0.78, duration)
			motion_tween.tween_property(background_layer, "position:x", -95.0, duration)
		"zoom_in":
			character_sprite.position = Vector2(viewport_size.x * 0.57, viewport_size.y * 0.24)
			character_sprite.scale = Vector2(0.72, 0.72)
			motion_tween.tween_property(character_sprite, "position:x", viewport_size.x * 0.49, duration)
			motion_tween.tween_property(character_sprite, "scale", Vector2(0.82, 0.82), duration)
			motion_tween.tween_property(background_layer, "scale", Vector2(1.18, 1.18), duration)
		"zoom_out":
			character_sprite.position = Vector2(viewport_size.x * 0.34, viewport_size.y * 0.25)
			character_sprite.scale = Vector2(0.9, 0.9)
			background_layer.scale = Vector2(1.2, 1.2)
			motion_tween.tween_property(background_layer, "scale", Vector2(1.08, 1.08), duration)
			motion_tween.tween_property(character_sprite, "scale", Vector2(0.78, 0.78), duration)
		"character_enter":
			character_sprite.position = Vector2(-character_size.x, viewport_size.y * 0.27)
			character_sprite.modulate.a = 0.0
			motion_tween.tween_property(character_sprite, "position:x", viewport_size.x * 0.25, duration * 0.3)
			motion_tween.tween_property(character_sprite, "modulate:a", 1.0, duration * 0.18)
			motion_tween.tween_property(background_layer, "scale", Vector2(1.17, 1.17), duration)
		"darken":
			character_sprite.position = Vector2(viewport_size.x * 0.48, viewport_size.y * 0.3)
			character_sprite.scale = Vector2(0.72, 0.72)
			motion_tween.tween_property(character_sprite, "position:x", viewport_size.x * 0.38, duration)
			motion_tween.tween_property(ambient_light, "color:a", 0.015, duration * 0.65)
			motion_tween.tween_property(background_layer, "position:y", -70.0, duration)
		"legacy":
			character_sprite.position = Vector2(viewport_size.x * 0.31, viewport_size.y * 0.27)
			character_sprite.scale = Vector2(0.78, 0.78)
			motion_tween.tween_property(character_sprite, "position:x", viewport_size.x * 0.37, duration)
			motion_tween.tween_property(character_sprite, "scale", Vector2(0.86, 0.86), duration)
			motion_tween.tween_property(background_layer, "scale", Vector2(1.16, 1.16), duration)
		"battle":
			character_sprite.position = Vector2(viewport_size.x * 0.18, viewport_size.y * 0.25)
			character_sprite.scale = Vector2(0.88, 0.88)
			motion_tween.tween_property(character_sprite, "position:x", viewport_size.x * 0.28, duration)
			motion_tween.tween_property(background_layer, "position:x", -88.0, duration)
		_:
			character_sprite.position = Vector2(-character_size.x * 0.65, viewport_size.y * 0.25)
			character_sprite.scale = Vector2(0.82, 0.82)
			motion_tween.tween_property(character_sprite, "position:x", viewport_size.x * 0.2, duration * 0.42)
			motion_tween.tween_property(background_layer, "position:x", 12.0, duration)
	motion_tween.tween_property(midground_layer, "position:x", 28.0 if motion != "pan_left" else -55.0, duration)
	motion_tween.tween_property(foreground_layer, "position:x", 52.0 if motion != "pan_left" else -75.0, duration)
	motion_tween.tween_property(effects_texture, "position:x", 18.0 if motion != "pan_left" else -28.0, duration)
	if shake:
		shake_tween = create_tween().set_loops(6)
		shake_tween.tween_property(background_layer, "position:y", -20.0, 0.08)
		shake_tween.tween_property(background_layer, "position:y", -30.0, 0.08)
		shake_tween.tween_property(background_layer, "position:y", -25.0, 0.08)


func _apply_environment_motion(environment: String, battle: bool) -> void:
	ambient_light.color.a = 0.025
	battle_flash.color.a = 0.0
	environment_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var peak_alpha := 0.085
	if environment == "writing":
		peak_alpha = 0.055
	elif environment == "fire":
		peak_alpha = 0.12
	environment_tween.tween_property(ambient_light, "color:a", peak_alpha, 1.4)
	environment_tween.tween_property(ambient_light, "color:a", 0.025, 1.6)
	if battle:
		effects_tween = create_tween().set_loops(4)
		effects_tween.tween_interval(0.35)
		effects_tween.tween_property(battle_flash, "color:a", 0.11, 0.08)
		effects_tween.tween_property(battle_flash, "color:a", 0.0, 0.16)


func _show_opening_title() -> void:
	opening_title.show()
	opening_title.modulate.a = 1.0
	if title_tween and title_tween.is_valid():
		title_tween.kill()
	title_tween = create_tween()
	title_tween.tween_interval(2.2)
	title_tween.tween_property(opening_title, "modulate:a", 0.0, 0.7)
	title_tween.tween_callback(opening_title.hide)


func _show_subtitle(text_value: String) -> void:
	story_text.text = text_value
	story_text.modulate.a = 0.0
	if subtitle_tween and subtitle_tween.is_valid():
		subtitle_tween.kill()
	subtitle_tween = create_tween()
	subtitle_tween.tween_property(story_text, "modulate:a", 1.0, 0.28)


func _fade_from_black() -> void:
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	dark_overlay.color.a = 0.72
	fade_tween = create_tween()
	fade_tween.tween_property(dark_overlay, "color:a", 0.0, 0.65)


func _play_optional_audio(player: AudioStreamPlayer, path: String, keep_existing: bool) -> void:
	if path.is_empty() or not ResourceLoader.exists(path):
		if not keep_existing:
			player.stop()
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	if keep_existing and player.stream == stream and player.playing:
		return
	player.stream = stream
	player.play()


func _on_scene_timeout() -> void:
	if current_scene_index + 1 < scenes.size():
		_transition_to_scene(current_scene_index + 1)
	else:
		_transition_to_ending()


func _transition_to_scene(next_index: int) -> void:
	if transition_in_progress:
		return
	transition_in_progress = true
	subtitle_timer.stop()
	if subtitle_tween and subtitle_tween.is_valid():
		subtitle_tween.kill()
	subtitle_tween = create_tween()
	subtitle_tween.tween_property(story_text, "modulate:a", 0.0, 0.25)
	transition_tween = create_tween()
	transition_tween.tween_property(dark_overlay, "color:a", 0.78, 0.42).set_trans(Tween.TRANS_SINE)
	transition_tween.tween_callback(_start_scene.bind(next_index, false))


func _transition_to_ending() -> void:
	if transition_in_progress:
		return
	transition_in_progress = true
	transition_tween = create_tween()
	transition_tween.set_parallel(true)
	transition_tween.tween_property(dark_overlay, "color:a", 0.9, 0.55)
	transition_tween.tween_property(story_text, "modulate:a", 0.0, 0.3)
	transition_tween.chain().tween_callback(_show_ending.bind(true))


func _on_subtitle_timeout() -> void:
	subtitle_cue_index += 1
	if subtitle_cue_index >= subtitle_cues.size():
		subtitle_timer.stop()
		return
	_show_subtitle(subtitle_cues[subtitle_cue_index])


func _build_subtitle_cues(narration: String) -> Array[String]:
	var cues: Array[String] = []
	for raw_part: String in narration.split(". ", false):
		var cue := raw_part.strip_edges()
		if cue.is_empty():
			continue
		if not cue.ends_with(".") and not cue.ends_with("!") and not cue.ends_with("?"):
			cue += "."
		for readable_cue: String in _split_long_subtitle(cue):
			cues.append(readable_cue)
	return cues


func _split_long_subtitle(cue: String) -> Array[String]:
	if cue.length() <= 86:
		return [cue]
	var midpoint := int(cue.length() / 2)
	var candidates: Array[int] = []
	var comma_index := cue.find(", ", 28)
	var and_index := cue.find(" and ", 28)
	if comma_index > 0:
		candidates.append(comma_index + 1)
	if and_index > 0:
		candidates.append(and_index + 1)
	if candidates.is_empty():
		return [cue]
	var split_index := candidates[0]
	for candidate: int in candidates:
		if absi(candidate - midpoint) < absi(split_index - midpoint):
			split_index = candidate
	return [cue.substr(0, split_index).strip_edges(), cue.substr(split_index).strip_edges()]


func _show_ending(mark_watched: bool) -> void:
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()
	_stop_scene_media_and_motion()
	transition_in_progress = false
	ending_visible = true
	ending_title.text = str(story.get("title", "HERO STORY"))
	ending_panel.show()
	skip_button.hide()
	pause_button.hide()
	if mark_watched and progress_manager.has_method("mark_story_watched"):
		progress_manager.mark_story_watched(level_id)
	continue_button.disabled = not progress_manager.is_level_unlocked(level_id) or not LevelCatalog.is_level_playable(level_id)
	continue_button.text = "PLAY LEVEL %d" % level_id if not continue_button.disabled else "LEVEL %d LOCKED" % level_id


func _on_skip_pressed() -> void:
	if story_available and not ending_visible:
		_show_ending(false)


func _on_pause_pressed() -> void:
	if not story_available or ending_visible:
		return
	cinematic_paused = not cinematic_paused
	scene_timer.paused = cinematic_paused
	subtitle_timer.paused = cinematic_paused
	voice_player.stream_paused = cinematic_paused
	music_player.stream_paused = cinematic_paused
	sfx_player.stream_paused = cinematic_paused
	if motion_tween and motion_tween.is_valid():
		if cinematic_paused: motion_tween.pause()
		else: motion_tween.play()
	if shake_tween and shake_tween.is_valid():
		if cinematic_paused: shake_tween.pause()
		else: shake_tween.play()
	for tween: Tween in [environment_tween, effects_tween, title_tween, subtitle_tween, transition_tween]:
		if tween and tween.is_valid():
			if cinematic_paused: tween.pause()
			else: tween.play()
	pause_button.text = "RESUME" if cinematic_paused else "PAUSE"


func _on_replay_pressed() -> void:
	skip_button.show()
	pause_button.show()
	_start_scene(0, true)


func _on_play_level_pressed() -> void:
	_play_selected_level()


func _on_back_pressed() -> void:
	if not scene_transition_pending:
		_change_scene(HERO_CARDS_SCENE)


func _play_selected_level() -> void:
	if scene_transition_pending:
		return
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
	ending_title.text = message
	continue_button.disabled = true


func complete_story() -> bool:
	return ending_visible and progress_manager.has_method("is_story_watched") and progress_manager.is_story_watched(level_id)


func _show_unavailable_story() -> void:
	story_available = false
	hero_name_label.text = "STORY UNAVAILABLE"
	scene_title_label.text = "Choose a Filipino hero from Hero Cards."
	story_text.text = "This short film is not available."
	progress_indicator.text = ""
	skip_button.disabled = true
	pause_button.disabled = true


func _stop_scene_media_and_motion() -> void:
	scene_timer.stop()
	subtitle_timer.stop()
	voice_player.stop()
	sfx_player.stop()
	if motion_tween and motion_tween.is_valid():
		motion_tween.kill()
	if shake_tween and shake_tween.is_valid():
		shake_tween.kill()
	for tween: Tween in [environment_tween, effects_tween, title_tween, subtitle_tween]:
		if tween and tween.is_valid():
			tween.kill()


func _change_scene(path: String) -> void:
	if scene_transition_pending:
		return
	scene_transition_pending = true
	_stop_scene_media_and_motion()
	if scene_change_handler.is_valid():
		scene_change_handler.call(path)
	else:
		var error := get_tree().change_scene_to_file(path)
		if error != OK:
			scene_transition_pending = false
			_show_play_error("Unable to open the requested screen.")

extends SceneTree

const StoryData = preload("res://story_data.gd")
const StoryModeScene = preload("res://story_mode.tscn")
const HeroCardsScene = preload("res://hero_cards.tscn")
const ProgressManagerScript = preload("res://progress_manager.gd")
const SAVE_PATH := "user://historyroll_story_cinematic_test.json"

var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	_test_story_data()
	await _test_all_hero_card_routes()
	await _test_player_controls_and_save()
	await _test_locked_level_protection()
	await _test_layout(Vector2i(1024, 1536), "story_cinematic_1024x1536.png")
	await _test_layout(Vector2i(720, 1280), "story_cinematic_720x1280.png")
	_cleanup()
	print("Story Mode cinematic tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _test_story_data() -> void:
	for level_id: int in range(1, 7):
		var story := StoryData.get_story(level_id)
		var scenes: Array = story.get("scenes", [])
		_check(not story.is_empty(), "Level %d has cinematic story data" % level_id)
		_check(scenes.size() == 6, "Level %d has exactly six cinematic scenes" % level_id)
		_check(StoryData.get_total_duration(level_id) >= 50.0 and StoryData.get_total_duration(level_id) <= 70.0, "Level %d duration is 50-70 seconds" % level_id)
		for scene: Dictionary in scenes:
			_check(not str(scene.get("subtitle", "")).is_empty(), "Level %d scene has synchronized subtitle text" % level_id)
			_check(not str(scene.get("motion", "")).is_empty(), "Level %d scene has motion direction" % level_id)
			_check(str(scene.get("background_path", "")).contains("Philippine Bay"), "Level %d scene avoids the retired fantasy-castle placeholder" % level_id)
			_check(scene.has("midground_path") and scene.has("foreground_path") and scene.has("effects_path"), "Level %d scene exposes replaceable cinematic layer paths" % level_id)
		_check(str((scenes[5] as Dictionary).get("subtitle", "")).to_lower().contains("contribution"), "Level %d final scene clearly states the hero's contribution" % level_id)


func _test_all_hero_card_routes() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = SAVE_PATH
	var requested: Array[String] = []
	var cards = HeroCardsScene.instantiate()
	cards.progress_manager = progress
	cards.scene_change_handler = func(path: String) -> void: requested.append(path)
	get_root().add_child(cards)
	await process_frame
	for index: int in range(6):
		var button := cards.hero_list.get_child(index) as Button
		_check(not button.disabled, "Hero Card %d exposes WATCH STORY" % (index + 1))
		requested.clear()
		button.pressed.emit()
		_check(progress.selected_story_level == index + 1, "Hero Card %d selects the correct story" % (index + 1))
		_check(requested == ["res://story_mode.tscn"], "Hero Card %d opens Story Mode" % (index + 1))
	cards.queue_free()
	progress.free()
	await process_frame


func _test_player_controls_and_save() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = SAVE_PATH
	progress.selected_story_level = 1
	var requested: Array[String] = []
	var story = StoryModeScene.instantiate()
	story.progress_manager = progress
	story.scene_change_handler = func(path: String) -> void: requested.append(path)
	get_root().add_child(story)
	await process_frame
	_check(story.current_scene_index == 0 and story.scenes.size() == 6, "Story begins at scene 1 of 6")
	_check(story.story_text.max_lines_visible == 2, "mobile subtitles are limited to two lines")
	_check(not story.progress_indicator.visible, "internal sequence numbers are never shown to the player")
	_check(story.midground_layer is TextureRect and story.foreground_layer is TextureRect, "StoryPlayer uses replaceable texture layers instead of color-only fake layers")
	_check(story.voice_player.bus == "Master" and story.music_player.bus == "Music" and story.sfx_player.bus == "SFX", "narration, music, and SFX use separate audio buses")
	var character_start: Vector2 = story.character_sprite.position
	var camera_start: Vector2 = story.background_layer.position
	story.motion_tween.custom_step(0.7)
	_check(story.character_sprite.position.distance_to(character_start) > 1.0, "character moves continuously within the shot")
	_check(story.background_layer.position.distance_to(camera_start) > 1.0, "camera framing moves continuously within the shot")
	story.pause_button.pressed.emit()
	_check(story.cinematic_paused and story.scene_timer.paused, "Pause stops cinematic timing")
	story.pause_button.pressed.emit()
	_check(not story.cinematic_paused and not story.scene_timer.paused, "Resume restarts cinematic timing")
	story.skip_button.pressed.emit()
	_check(story.ending_visible and not progress.is_story_watched(1), "Skip opens ending without falsely recording a full watch")
	story.replay_button.pressed.emit()
	_check(story.current_scene_index == 0 and not story.ending_visible, "Replay restarts from scene 1")
	story._on_scene_timeout()
	_check(story.transition_in_progress and story.current_scene_index == 0, "sequence boundary begins a crossfade instead of an abrupt replacement")
	story.transition_tween.custom_step(0.5)
	await process_frame
	_check(story.current_scene_index == 1, "crossfade continues into the next timeline sequence")
	story._show_ending(true)
	_check(story.ending_visible and progress.is_story_watched(1), "natural completion saves watched status")
	story.continue_button.pressed.emit()
	_check(requested == ["res://gameplay_placeholder.tscn"], "Play Level launches the selected unlocked level")
	story.queue_free()
	await process_frame
	var reloaded = ProgressManagerScript.new()
	reloaded.save_path = SAVE_PATH
	reloaded.load_progress()
	_check(reloaded.is_story_watched(1), "watched status survives save reload")
	reloaded.free()
	progress.free()


func _test_locked_level_protection() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = SAVE_PATH
	progress.selected_story_level = 2
	var requested: Array[String] = []
	var story = StoryModeScene.instantiate()
	story.progress_manager = progress
	story.scene_change_handler = func(path: String) -> void: requested.append(path)
	get_root().add_child(story)
	await process_frame
	story._show_ending(false)
	_check(story.continue_button.disabled, "locked story cannot launch locked gameplay")
	story._play_selected_level()
	_check(requested.is_empty(), "Story Mode never bypasses level unlocking")
	story.queue_free()
	progress.free()
	await process_frame


func _test_layout(viewport_size: Vector2i, filename: String) -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = SAVE_PATH
	progress.selected_story_level = 1
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var story = StoryModeScene.instantiate()
	story.progress_manager = progress
	viewport.add_child(story)
	await process_frame
	await process_frame
	await create_timer(0.8).timeout
	for control: Control in [story.skip_button, story.pause_button, story.story_text]:
		_check(_inside(control.get_global_rect(), viewport_size), "%s keeps %s on-screen" % [viewport_size, control.name])
	_check(not story.skip_button.get_global_rect().intersects(story.pause_button.get_global_rect()), "%s keeps touch controls separate" % viewport_size)
	var image: Image = viewport.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path("user://%s" % filename)) if image != null and not image.is_empty() else ERR_CANT_CREATE
	_check(error == OK, "%s rendered capture is saved" % filename)
	story.queue_free()
	viewport.queue_free()
	progress.free()
	await process_frame


func _inside(rect: Rect2, viewport_size: Vector2i) -> bool:
	return rect.position.x >= -0.1 and rect.position.y >= -0.1 and rect.end.x <= viewport_size.x + 0.1 and rect.end.y <= viewport_size.y + 0.1


func _check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS: %s" % message)
	else:
		failed += 1
		push_error("FAIL: %s" % message)


func _cleanup() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

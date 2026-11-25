extends SceneTree

const HeroCardsScene = preload("res://hero_cards.tscn")
const VideoPlayerScene = preload("res://hero_story_video_player.tscn")
const VideoPlayerScript = preload("res://hero_story_video_player.gd")
const ProgressManagerScript = preload("res://progress_manager.gd")
const SAVE_PATH := "user://historyroll_story_video_test.json"

var passed := 0
var failed := 0

func _init() -> void: call_deferred("_run")

func _run() -> void:
	_cleanup()
	var audio := get_root().get_node("AudioManager")
	var saved_sfx: bool = audio.is_sfx_enabled()
	audio.set_sfx_enabled(true, false)
	_test_mappings()
	await _test_all_card_routes()
	await _test_player_flow()
	await _test_locked_level()
	await _test_layout(Vector2i(1024, 1536), "hero_story_video_1024x1536.png")
	await _test_layout(Vector2i(720, 1280), "hero_story_video_720x1280.png")
	if OS.get_cmdline_user_args().has("--full-playback"):
		await _test_natural_completion()
	audio.stop_music(0.0)
	audio.set_sfx_enabled(saved_sfx, false)
	_cleanup()
	print("Hero Story video tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)

func _test_mappings() -> void:
	var expected := ["lapulapu_story.ogv", "bonifacio_story.ogv", "rizal_story.ogv", "antonio_luna_story.ogv", "melchora_aquino_story.ogv", "mabini_story.ogv"]
	for level_id: int in range(1, 7):
		_check(str(VideoPlayerScript.VIDEO_PATHS.get(level_id, "")).get_file() == expected[level_id - 1], "Level %d maps to %s" % [level_id, expected[level_id - 1]])
		_check(not str(VideoPlayerScript.CONTRIBUTIONS.get(level_id, "")).is_empty(), "Level %d has ending contribution text" % level_id)

func _test_all_card_routes() -> void:
	var progress = ProgressManagerScript.new(); progress.save_path = SAVE_PATH
	var requested: Array[String] = []
	var cards = HeroCardsScene.instantiate(); cards.progress_manager = progress
	cards.scene_change_handler = func(path: String) -> void: requested.append(path)
	get_root().add_child(cards); await process_frame
	for index: int in range(6):
		requested.clear()
		(cards.hero_list.get_child(index) as Button).pressed.emit()
		_check(progress.selected_story_level == index + 1, "Hero Card %d selects its video" % (index + 1))
		_check(requested == ["res://hero_story_video_player.tscn"], "Hero Card %d opens the reusable player" % (index + 1))
	cards.progress_manager = null; cards.queue_free(); await process_frame; progress.free()

func _test_player_flow() -> void:
	var progress = ProgressManagerScript.new(); progress.save_path = SAVE_PATH; progress.selected_story_level = 1
	var requested: Array[String] = []
	var player = VideoPlayerScene.instantiate(); player.progress_manager = progress
	player.scene_change_handler = func(path: String) -> void: requested.append(path)
	get_root().add_child(player); await process_frame
	_check(player.video_path.ends_with("lapulapu_story.ogv"), "Lapulapu opens the correct video path")
	await create_timer(0.6).timeout
	_check(player.video_available and player.video_player.is_playing() and not player.ending_visible, "installed Lapulapu movie starts automatically")
	_check(player.video_player.stream is VideoStreamTheora and player.video_player.stream_position > 0.0, "the actual Ogg Theora movie is decoded and advances")
	_check(not progress.is_story_watched(1), "opening the movie alone does not mark it watched")
	print("Native video duration: ", player.video_player.get_stream_length())
	await _check_video_audio(player)
	player.video_player.paused = false; player._on_pause_resume_pressed()
	_check(player.playback_paused and player.pause_resume_button.text == "RESUME", "Pause preserves the stream and shows Resume")
	var paused_at: float = player.video_player.stream_position
	await create_timer(0.2).timeout
	_check(is_equal_approx(paused_at, player.video_player.stream_position), "Pause freezes the actual playback position")
	player._on_pause_resume_pressed()
	_check(not player.playback_paused and player.pause_resume_button.text == "PAUSE", "Resume continues the same stream")
	player._on_skip_pressed()
	_check(player.ending_visible and progress.is_story_watched(1), "Skip opens ending options and saves watched status")
	_check(progress.highest_unlocked_level == 1, "watching a story does not unlock levels")
	player._on_replay_pressed()
	_check(not player.ending_visible and player.controls_layer.visible, "Replay restores playback controls")
	player._on_video_finished()
	_check(player.ending_visible and player.ending_status_label.text == "STORY WATCHED", "video finish opens the watched ending panel")
	player._on_play_level_pressed()
	_check(requested == ["res://gameplay_placeholder.tscn"], "Play Level opens unlocked gameplay")
	requested.clear(); player._on_back_pressed()
	_check(requested == ["res://hero_cards.tscn"], "Back returns to Hero Cards")
	player.progress_manager = null; player.queue_free(); await process_frame
	var reloaded = ProgressManagerScript.new(); reloaded.save_path = SAVE_PATH; reloaded.load_progress()
	_check(reloaded.is_story_watched(1), "watched status persists after restart")
	reloaded.free(); progress.free()

func _test_locked_level() -> void:
	var progress = ProgressManagerScript.new(); progress.save_path = SAVE_PATH; progress.selected_story_level = 2
	var requested: Array[String] = []
	var player = VideoPlayerScene.instantiate(); player.progress_manager = progress
	player.scene_change_handler = func(path: String) -> void: requested.append(path)
	get_root().add_child(player); await process_frame
	_check(not player.video_available and player.ending_visible and player.ending_status_label.text.contains("COMING SOON"), "other missing hero movies keep the safe placeholder")
	_check(not progress.is_story_watched(2), "missing movie does not mark the story watched")
	_check(player.play_level_button.disabled and player.play_level_button.text == "LEVEL LOCKED", "locked level keeps Play Level disabled")
	player._on_play_level_pressed()
	_check(requested.is_empty() and progress.highest_unlocked_level == 1, "story never bypasses level progression")
	player.progress_manager = null; player.queue_free(); await process_frame; progress.free()

func _test_layout(viewport_size: Vector2i, filename: String) -> void:
	var progress = ProgressManagerScript.new(); progress.save_path = SAVE_PATH; progress.selected_story_level = 1
	var viewport := SubViewport.new(); viewport.size = viewport_size; viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var player = VideoPlayerScene.instantiate(); player.progress_manager = progress; viewport.add_child(player)
	await create_timer(0.6).timeout
	var playing_rect: Rect2 = player.video_player.get_global_rect()
	var texture: Texture2D = player.video_player.get_video_texture()
	_check(texture != null and is_equal_approx(playing_rect.size.aspect(), texture.get_size().aspect()), "%s preserves the movie aspect ratio without stretching" % viewport_size)
	_check(_inside(playing_rect, viewport_size), "%s shows the complete landscape movie inside the portrait game" % viewport_size)
	await RenderingServer.frame_post_draw
	var playing_image := viewport.get_texture().get_image()
	_check(playing_image != null and playing_image.save_png("user://hero_story_playing_%dx%d.png" % [viewport_size.x, viewport_size.y]) == OK, "actual video frame capture is saved")
	player._show_ending(false)
	await create_timer(0.3).timeout
	for control: Control in [player.ending_panel, player.hero_name_label, player.hero_title_label, player.contribution_label, player.play_level_button, player.replay_button, player.back_button]:
		var rect: Rect2 = control.get_global_rect()
		_check(control.is_visible_in_tree() and rect.size.x >= 44.0 and rect.size.y >= 24.0 and _inside(rect, viewport_size), "%s keeps visible %s on-screen" % [viewport_size, control.name])
	var video_rect: Rect2 = player.video_player.get_global_rect()
	_check(_inside(video_rect, viewport_size), "%s keeps the video inside the portrait canvas" % viewport_size)
	_check(is_equal_approx(video_rect.size.aspect(), 16.0 / 9.0), "%s retains the installed movie native ratio" % viewport_size)
	var image := viewport.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path("user://%s" % filename)) if image != null and not image.is_empty() else ERR_CANT_CREATE
	_check(error == OK, "%s placeholder capture is saved" % filename)
	player.progress_manager = null; player.queue_free(); viewport.queue_free(); await process_frame; progress.free()


func _check_video_audio(player: Node) -> void:
	var bus_index := AudioServer.get_bus_index("SFX")
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 2.0
	var effect_index := AudioServer.get_bus_effect_count(bus_index)
	AudioServer.add_bus_effect(bus_index, capture)
	await create_timer(1.4).timeout
	var samples := capture.get_buffer(capture.get_frames_available())
	var peak := 0.0
	for sample: Vector2 in samples:
		peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
	AudioServer.remove_bus_effect(bus_index, effect_index)
	_check(player.video_player.bus == &"SFX" and not samples.is_empty() and peak > 0.0001, "actual movie audio reaches its existing audio bus")
	_check(not get_root().get_node("AudioManager").is_music_playing(), "global music does not overlap the movie audio")
	print("Movie audio capture: %d frames, peak %.4f." % [samples.size(), peak])


func _test_natural_completion() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = SAVE_PATH
	progress.selected_story_level = 1
	var player = VideoPlayerScene.instantiate()
	player.progress_manager = progress
	get_root().add_child(player)
	var start := Time.get_ticks_msec()
	while not player.ending_visible and Time.get_ticks_msec() - start < 160000:
		await create_timer(1.0).timeout
		var seconds := (Time.get_ticks_msec() - start) / 1000
		if seconds % 30 == 0:
			print("Natural movie playback: %d seconds." % seconds)
	var elapsed := float(Time.get_ticks_msec() - start) / 1000.0
	_check(player.video_available and player.ending_visible, "actual movie reaches its natural finished signal")
	_check(elapsed >= 137.0 and elapsed < 155.0, "complete original movie plays before showing the ending")
	_check(progress.is_story_watched(1) and progress.highest_unlocked_level == 1, "natural completion records watched status without unlocking gameplay")
	_check(player.replay_button.visible and not player.replay_button.disabled, "natural ending retains a functional Replay option")
	print("Natural movie completion after %.3f seconds." % elapsed)
	player.progress_manager = null
	player.queue_free()
	await process_frame
	progress.free()


func _inside(rect: Rect2, viewport_size: Vector2i) -> bool:
	return rect.position.x >= -0.1 and rect.position.y >= -0.1 and rect.end.x <= viewport_size.x + 0.1 and rect.end.y <= viewport_size.y + 0.1

func _check(condition: bool, message: String) -> void:
	if condition: passed += 1; print("PASS: ", message)
	else: failed += 1; push_error("FAIL: %s" % message)

func _cleanup() -> void:
	if FileAccess.file_exists(SAVE_PATH): DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

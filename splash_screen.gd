extends Control

const MAIN_MENU_SCENE := "res://main_menu_tscn.tscn"

@export_range(0.0, 5.0, 0.05) var fade_in_duration := 0.45
@export_range(0.0, 30.0, 0.05) var hold_duration := 8.1
@export_range(0.0, 30.0, 0.1) var minimum_intro_duration := 9.0
@export_range(0.0, 5.0, 0.05) var fade_out_duration := 0.45
@export_range(0.0, 5.0, 0.05) var minimum_skip_delay := 0.45

@onready var presentation: Control = %Presentation
@onready var logo: TextureRect = %Logo
@onready var fade_overlay: ColorRect = %FadeOverlay
@onready var explorers: TextureRect = $Presentation/Explorers
@onready var tagline: Label = $Presentation/Tagline
@onready var subject: Label = $Presentation/Subject
@onready var loading_label: Label = $Presentation/LoadingLabel
@onready var loading_bar: ProgressBar = $Presentation/LoadingBar

var scene_change_handler: Callable
var _elapsed := 0.0
var _transitioning := false
var _sequence_tween: Tween
var _menu_scene: PackedScene
var _load_requested := false
var _load_failed := false
var _skip_requested := false
var _scene_opened := false
var _resource_progress := 0.0


func _ready() -> void:
	fade_overlay.show()
	fade_overlay.modulate.a = 1.0
	presentation.modulate.a = 0.0
	logo.scale = Vector2(0.9, 0.9)
	resized.connect(_update_layout)
	_update_layout()
	_begin_menu_load()
	call_deferred("_start_sequence")


func _process(delta: float) -> void:
	_elapsed += delta
	_poll_menu_load()
	_update_loading_progress()
	if _skip_requested and not _transitioning and _menu_scene != null:
		skip_splash()


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning or _elapsed < minimum_skip_delay:
		return
	var requested_skip := false
	if event is InputEventScreenTouch:
		requested_skip = event.pressed
	elif event is InputEventMouseButton:
		requested_skip = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventKey:
		requested_skip = event.pressed and not event.echo
	if requested_skip:
		get_viewport().set_input_as_handled()
		skip_splash()


func _start_sequence() -> void:
	if _transitioning or is_queued_for_deletion():
		return
	_update_layout()
	_set_logo_pivot()
	_sequence_tween = create_tween().set_parallel(true)
	_sequence_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_sequence_tween.tween_property(fade_overlay, "modulate:a", 0.0, fade_in_duration)
	_sequence_tween.tween_property(presentation, "modulate:a", 1.0, fade_in_duration)
	_sequence_tween.tween_property(logo, "scale", Vector2.ONE, fade_in_duration)
	_sequence_tween.chain().tween_interval(hold_duration)
	_sequence_tween.chain().tween_callback(skip_splash)


func _begin_menu_load() -> void:
	_load_failed = false
	_menu_scene = null
	_resource_progress = 0.0
	loading_bar.value = 0.0
	loading_label.text = "LOADING HISTORYROLL..."
	loading_label.hide()
	$Presentation/LoadingBanner.hide()
	var error := ResourceLoader.load_threaded_request(MAIN_MENU_SCENE, "PackedScene")
	if error != OK:
		_report_load_failure("Unable to request the Main Menu: %s" % error_string(error))
		return
	_load_requested = true


func _poll_menu_load() -> void:
	if not _load_requested or _load_failed or _menu_scene != null:
		return
	var progress: Array = []
	match ResourceLoader.load_threaded_get_status(MAIN_MENU_SCENE, progress):
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not progress.is_empty():
				_resource_progress = maxf(_resource_progress, clampf(float(progress[0]), 0.0, 0.99))
		ResourceLoader.THREAD_LOAD_LOADED:
			_menu_scene = ResourceLoader.load_threaded_get(MAIN_MENU_SCENE) as PackedScene
			_load_requested = false
			if _menu_scene == null:
				_report_load_failure("The Main Menu resource is not a valid PackedScene.")
				return
			_resource_progress = 1.0
			if _skip_requested:
				skip_splash()
		_:
			_report_load_failure("The HistoryRoll Main Menu could not be loaded.")


func _update_loading_progress() -> void:
	# Overall startup progress includes the requested presentation time and the
	# real resource load. Neither requirement can finish the bar on its own.
	var fill_duration := maxf(0.0, minimum_intro_duration - fade_out_duration)
	var time_progress := clampf(_elapsed / fill_duration, 0.0, 1.0) if fill_duration > 0.0 else 1.0
	loading_bar.value = minf(_resource_progress, time_progress) * 100.0


func _report_load_failure(message: String) -> void:
	_load_requested = false
	_load_failed = true
	_transitioning = false
	loading_label.text = "LOAD FAILED - TAP TO RETRY"
	loading_label.show()
	$Presentation/LoadingBanner.show()
	fade_overlay.modulate.a = 0.0
	presentation.modulate.a = 1.0
	_update_layout()
	push_error(message)


func skip_splash() -> void:
	if _transitioning or _scene_opened:
		return
	if _load_failed:
		_begin_menu_load()
	_skip_requested = true
	# Input cannot shorten the requested nine-second intro, including fade-out.
	var earliest_fade := maxf(0.0, minimum_intro_duration - fade_out_duration)
	if _menu_scene == null or _elapsed < earliest_fade:
		return
	_transitioning = true
	if _sequence_tween != null and _sequence_tween.is_valid():
		_sequence_tween.kill()
	fade_overlay.show()
	var fade := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fade.tween_property(fade_overlay, "modulate:a", 1.0, fade_out_duration)
	fade.tween_callback(_open_main_menu)


func _open_main_menu() -> void:
	if _scene_opened or _menu_scene == null:
		return
	_scene_opened = true
	if scene_change_handler.is_valid():
		scene_change_handler.call(MAIN_MENU_SCENE)
		return
	var error := get_tree().change_scene_to_packed(_menu_scene)
	if error != OK:
		_scene_opened = false
		_report_load_failure("Unable to open the HistoryRoll Main Menu: %s" % error_string(error))


func _update_layout() -> void:
	if not is_node_ready() or size.x <= 0.0 or size.y <= 0.0:
		return
	var safe := Rect2(Vector2.ZERO, size).grow(-minf(24.0, size.x * 0.022))
	if OS.has_feature("android"):
		var screen_size := Vector2(DisplayServer.screen_get_size())
		var device_safe := Rect2(DisplayServer.get_display_safe_area())
		if screen_size.x > 0.0 and screen_size.y > 0.0 and device_safe.has_area():
			safe = Rect2(device_safe.position / screen_size * size, device_safe.size / screen_size * size).grow(-12.0)
	for control: Control in [logo, explorers, tagline, subject, loading_label, loading_bar, $Presentation/SubjectBanner, $Presentation/LoadingBanner]:
		control.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	var scale_factor := safe.size.x / 1086.0
	var logo_width := safe.size.x * 0.88
	logo.size = Vector2(logo_width, logo_width / logo.texture.get_size().aspect())
	logo.position = Vector2(safe.get_center().x - logo.size.x * 0.5, safe.position.y + safe.size.y * 0.008)
	var gap := maxf(8.0, safe.size.y * 0.008)
	tagline.position = Vector2(safe.position.x + safe.size.x * 0.09, logo.position.y + logo.size.y + gap)
	tagline.size = Vector2(safe.size.x * 0.82, safe.size.y * 0.038)
	_fit_caption(tagline, 48.0 * scale_factor)
	var subject_banner := $Presentation/SubjectBanner as TextureRect
	subject_banner.position = Vector2(safe.position.x + safe.size.x * 0.12, tagline.position.y + tagline.size.y + gap)
	subject_banner.size = Vector2(safe.size.x * 0.76, safe.size.y * 0.052)
	subject.position = subject_banner.position + Vector2(subject_banner.size.x * 0.035, 0.0)
	subject.size = subject_banner.size * Vector2(0.93, 1.0)
	_fit_caption(subject, 34.0 * scale_factor)
	var loading_banner := $Presentation/LoadingBanner as TextureRect
	loading_banner.size = Vector2(safe.size.x * 0.56, safe.size.y * 0.055)
	loading_banner.position = Vector2(safe.get_center().x - loading_banner.size.x * 0.5, safe.end.y - safe.size.y * 0.09)
	loading_label.position = loading_banner.position + Vector2(loading_banner.size.x * 0.04, 0.0)
	loading_label.size = loading_banner.size * Vector2(0.92, 1.0)
	_fit_caption(loading_label, 40.0 * scale_factor)
	var bar_frame := $Presentation/LoadingBarFrame as TextureRect
	bar_frame.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	bar_frame.size = Vector2(safe.size.x * 0.75, safe.size.y * 0.043)
	bar_frame.position = Vector2(safe.get_center().x - bar_frame.size.x * 0.5, loading_banner.position.y - gap * 1.8 - bar_frame.size.y)
	var inset := maxf(4.0, bar_frame.size.y * 0.16)
	loading_bar.size = bar_frame.size - Vector2.ONE * inset * 2.0
	loading_bar.position = bar_frame.position + Vector2.ONE * inset
	var clear_top := subject_banner.position.y + subject_banner.size.y + gap * 1.5
	var explorer_height := minf(safe.size.y * 0.395, bar_frame.position.y - clear_top - gap)
	var explorer_width := explorer_height * explorers.texture.get_size().aspect()
	explorers.size = Vector2(explorer_width, explorer_height)
	explorers.position = Vector2(safe.position.x + safe.size.x * 0.035, bar_frame.position.y - gap - explorer_height)
	_set_logo_pivot()


func _fit_caption(label: Label, requested_size: float) -> void:
	var font_size := maxi(14, roundi(requested_size))
	var font := label.get_theme_font("font")
	while font_size > 12 and (
		font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > label.size.x - 8.0
		or font.get_height(font_size) > label.size.y * 0.92
	):
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)


func _set_logo_pivot() -> void:
	logo.pivot_offset = logo.size * 0.5

extends SceneTree

const HeroDatabase = preload("res://hero_database.gd")
const LevelCatalog = preload("res://level_catalog.gd")
const LevelSelectionScene = preload("res://level_selection.tscn")
const ProgressManagerScript = preload("res://progress_manager.gd")
const StoryModeScene = preload("res://story_mode.tscn")

const SAVE_PATH := "user://historyroll_story_mode_panels_test.json"

var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup()
	_test_story_data()
	_cleanup()
	print("Legacy Story Mode content tests: %d passed, %d failed. Cinematic behavior is covered by story_mode_cinematic_test.gd." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _test_story_data() -> void:
	var expected_titles := [
		"Defender of Mactan",
		"Katipunan and Revolution",
		"Reform, Writing, and Nationalism",
		"Discipline and Defense",
		"Mother of the Revolution",
		"Mind of the Revolution",
	]
	for level_id: int in range(1, 7):
		var story := HeroDatabase.get_story_for_level(level_id)
		var panels: Array = story.get("panels", [])
		_check(str(story.get("story_title", "")) == expected_titles[level_id - 1], "Level %d uses the approved story title" % level_id)
		_check(panels.size() == 5, "Level %d contains exactly five story panels" % level_id)
		for panel_index: int in range(panels.size()):
			var panel: Dictionary = panels[panel_index]
			_check(not str(panel.get("title", "")).is_empty(), "Level %d panel %d has a title" % [level_id, panel_index + 1])
			_check(not str(panel.get("text", "")).is_empty(), "Level %d panel %d has story text" % [level_id, panel_index + 1])
			_check(not str(panel.get("visual", "")).is_empty(), "Level %d panel %d has a visual direction" % [level_id, panel_index + 1])


func _test_panel_navigation() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = SAVE_PATH
	progress.selected_story_level = 1
	var story = StoryModeScene.instantiate()
	story.progress_manager = progress
	get_root().add_child(story)
	await process_frame

	_check(story.story_available, "Level 1 Story Mode loads")
	_check(story.current_panel_index == 0, "Story Mode begins on panel 1")
	_check(story.panel_counter_label.text == "1 / 5", "panel counter begins at 1 / 5")
	_check(story.previous_button.disabled, "Previous is disabled on the first panel")
	_check(story.panel_title_label.text == "Leader of Mactan", "Level 1 first panel uses the approved title")

	story.continue_button.pressed.emit()
	_check(story.current_panel_index == 1 and story.panel_counter_label.text == "2 / 5", "Next advances to panel 2")
	story.previous_button.pressed.emit()
	_check(story.current_panel_index == 0, "Previous returns to panel 1")
	for _step: int in range(4):
		story.continue_button.pressed.emit()
	_check(story.current_panel_index == 4, "four Next presses reach panel 5")
	_check(story.continue_button.text == "PLAY LEVEL 1", "final panel replaces Next with Play Level")
	_check(story.complete_story(), "complete_story reports completion only at the final panel")

	story.queue_free()
	progress.free()
	await process_frame


func _test_optional_routes() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = SAVE_PATH
	progress.selected_story_level = 1
	var requested: Array[String] = []
	var story = StoryModeScene.instantiate()
	story.progress_manager = progress
	story.scene_change_handler = func(path: String) -> void: requested.append(path)
	get_root().add_child(story)
	await process_frame
	story.skip_button.pressed.emit()
	_check(requested == ["res://gameplay_placeholder.tscn"], "Skip Story enters the unlocked gameplay level")
	story.queue_free()
	await process_frame

	requested.clear()
	story = StoryModeScene.instantiate()
	story.progress_manager = progress
	story.scene_change_handler = func(path: String) -> void: requested.append(path)
	get_root().add_child(story)
	await process_frame
	story.back_button.pressed.emit()
	_check(requested == ["res://hero_cards.tscn"], "Back to Hero Card returns to Hero Cards")
	story.queue_free()
	progress.free()
	await process_frame


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
	story.skip_button.pressed.emit()
	_check(requested.is_empty(), "Story Mode cannot bypass a locked level")
	_check(story.story_text.text.contains("still locked"), "locked-level attempt shows clear feedback")
	story.queue_free()
	progress.free()
	await process_frame


func _test_direct_level_entry() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = SAVE_PATH
	var requested: Array[String] = []
	var selection = LevelSelectionScene.instantiate()
	selection.progress_manager = progress
	selection.scene_change_handler = func(path: String) -> void: requested.append(path)
	get_root().add_child(selection)
	await process_frame
	selection._select_level(1)
	selection.play_button.pressed.emit()
	_check(requested == ["res://gameplay_placeholder.tscn"], "Level Selection enters unlocked gameplay without requiring Story Mode")
	selection.queue_free()
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
	story.scene_change_handler = func(_path: String) -> void: pass
	viewport.add_child(story)
	await process_frame
	await process_frame
	for control: Control in [story.previous_button, story.continue_button, story.skip_button, story.back_button]:
		_check(_inside(control.get_global_rect(), viewport_size), "%s keeps %s on-screen" % [viewport_size, control.name])
	_check(not story.previous_button.get_global_rect().intersects(story.continue_button.get_global_rect()), "%s keeps story navigation controls separate" % viewport_size)
	var image: Image = viewport.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path("user://%s" % filename)) if image != null and not image.is_empty() else ERR_CANT_CREATE
	_check(error == OK, "%s capture is saved" % filename)
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

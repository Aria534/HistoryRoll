extends SceneTree

const MainMenuScene = preload("res://main_menu_tscn.tscn")

var _passed := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var requested_scenes: Array[String] = []
	var quit_state := {"requested": false}
	var menu := MainMenuScene.instantiate()
	menu.scene_change_handler = func(path: String): requested_scenes.append(path)
	menu.quit_handler = func(): quit_state["requested"] = true
	get_root().add_child(menu)
	await process_frame

	var background := menu.get_node("LiveBackground") as AnimatedSprite2D
	var plants := menu.get_node("AnimatedPlants") as Node2D
	_check(background != null, "stationary LiveBackground exists")
	_check(plants != null, "AnimatedPlants controller exists")
	_check(not menu.has_node("HistoryRollLogo"), "deleted HistoryRollLogo node was not recreated")
	_check(plants.motion_enabled, "foliage animation is enabled by default")
	_check(plants.sway_strength >= 1.0, "default sway strength is visibly meaningful")

	var expected_plants: Array[String] = [
		"PlantTopLeft", "PlantTopRight", "PlantLeft", "PlantRight",
		"PlantBottomLeft", "PlantBottomRight",
	]
	var starting_rotations: Dictionary = {}
	for plant_name: String in expected_plants:
		var plant := plants.get_node_or_null(plant_name) as Sprite2D
		_check(plant != null, "%s exists" % plant_name)
		if plant != null:
			_check(plant.texture != null, "%s has a transparent foliage texture" % plant_name)
			_check(plant.visible and plant.is_visible_in_tree(), "%s is visible" % plant_name)
			starting_rotations[plant_name] = plant.rotation

	var button_names: Array[String] = [
		"StartButton", "HeroCardsButton", "SettingsButton", "QuitButton",
	]
	for button_name: String in button_names:
		var button := menu.get_node_or_null(button_name) as TextureButton
		_check(button != null, "%s remains in the Main Menu" % button_name)
		if button != null:
			_check(not button.disabled, "%s remains enabled" % button_name)
			_check(button.pressed.get_connections().size() == 1, "%s keeps one navigation callback" % button_name)

	_check(menu._validate_required_buttons(), "all required Main Menu TextureButtons resolve")
	_check(ResourceLoader.exists("res://settings.tscn"), "Settings scene exists")
	menu.start_button.pressed.emit()
	_check(requested_scenes == ["res://level_selection.tscn"], "Start opens Level Selection")
	menu._scene_transition_pending = false
	menu._set_buttons_disabled(false)
	requested_scenes.clear()
	menu.hero_cards_button.pressed.emit()
	_check(requested_scenes == ["res://hero_cards.tscn"], "Hero Cards opens the existing Hero Cards scene")
	menu._scene_transition_pending = false
	menu._set_buttons_disabled(false)
	requested_scenes.clear()
	menu.settings_button.pressed.emit()
	menu.settings_button.pressed.emit()
	_check(requested_scenes == ["res://settings.tscn"], "Settings opens its scene exactly once during repeated input")
	menu._scene_transition_pending = false
	menu._set_buttons_disabled(false)
	menu.quit_button.pressed.emit()
	_check(bool(quit_state["requested"]), "Quit requests application exit")

	var background_position := background.position
	var background_scale := background.scale
	var background_rotation := background.rotation
	await create_timer(1.25).timeout
	_check(background.position.is_equal_approx(background_position), "background position remains stationary")
	_check(background.scale.is_equal_approx(background_scale), "background scale remains stationary")
	_check(is_equal_approx(background.rotation, background_rotation), "background rotation remains stationary")

	var moved_count := 0
	for plant_name: String in expected_plants:
		var plant := plants.get_node(plant_name) as Sprite2D
		if not is_equal_approx(plant.rotation, float(starting_rotations[plant_name])):
			moved_count += 1
	_check(moved_count == expected_plants.size(), "all six foliage groups animate independently")

	var maximum_travel: Dictionary = {}
	for plant_name: String in expected_plants:
		maximum_travel[plant_name] = 0.0
	plants.reset_motion_for_test()
	for sample: int in range(360):
		plants._process(1.0 / 60.0)
		for plant_name: String in expected_plants:
			var plant := plants.get_node(plant_name) as Sprite2D
			maximum_travel[plant_name] = maxf(
				float(maximum_travel[plant_name]),
				plant.position.distance_to(plants._base_positions[plant])
			)
	for plant_name: String in expected_plants:
		_check(float(maximum_travel[plant_name]) >= 4.5, "%s has visibly meaningful lateral travel" % plant_name)
	_check(not is_equal_approx(
		(plants.get_node("PlantLeft") as Sprite2D).rotation,
		(plants.get_node("PlantRight") as Sprite2D).rotation
	), "left and right foliage use independent phases")

	plants.motion_enabled = false
	for plant_name: String in expected_plants:
		var plant := plants.get_node(plant_name) as Sprite2D
		_check(plant.position.is_equal_approx(plants._base_positions[plant]), "%s returns to its neutral position" % plant_name)
		_check(is_equal_approx(plant.rotation, float(plants._base_rotations[plant])), "%s returns to its neutral rotation" % plant_name)

	plants.motion_enabled = true
	for iteration: int in range(10000):
		plants._process(1.0 / 60.0)
	var drift_is_bounded := true
	for plant_name: String in expected_plants:
		var plant := plants.get_node(plant_name) as Sprite2D
		if plant.position.distance_to(plants._base_positions[plant]) > plants.horizontal_displacement * 1.2:
			drift_is_bounded = false
	_check(drift_is_bounded, "long-running animation remains bounded without drift")

	menu.queue_free()
	await process_frame
	print("Main Menu foliage tests: %d passed, %d failed." % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", description)
	else:
		_failed += 1
		push_error("FAIL: %s" % description)

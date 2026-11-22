extends SceneTree

const HeroCardsScene = preload("res://hero_cards.tscn")

var passed := 0
var failed := 0


class MockProgress:
	extends Node
	signal progress_changed
	var selected_hero := "historyroll_explorer"
	var selected_story_level := 0
	var unlocked_characters: Array[String] = []
	var watched_stories: Array[int] = []

	func is_story_watched(level_id: int) -> bool:
		return watched_stories.has(level_id)

	func is_character_unlocked(character_id: String) -> bool:
		return unlocked_characters.has(character_id)

	func select_hero(character_id: String) -> bool:
		if not is_character_unlocked(character_id):
			return false
		selected_hero = character_id
		progress_changed.emit()
		return true

	func select_story_level(level_id: int) -> bool:
		selected_story_level = level_id
		return level_id >= 1 and level_id <= 6


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _capture(Vector2i(1024, 1536), "hero_cards_1024x1536.png")
	await _capture(Vector2i(720, 1280), "hero_cards_720x1280.png")
	await _capture(Vector2i(1080, 1920), "hero_cards_1080x1920.png")
	await _capture(Vector2i(1080, 2400), "hero_cards_1080x2400.png")
	var audio: Node = get_root().get_node_or_null("AudioManager")
	if audio != null:
		audio.stop_music(0.0)
	await process_frame
	await process_frame
	print("Hero Cards design tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _capture(viewport_size: Vector2i, filename: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)

	var progress := MockProgress.new()
	var cards = HeroCardsScene.instantiate()
	cards.progress_manager = progress
	viewport.add_child(cards)
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	print("Hero viewport %s initial scroll: %d, viewport height: %.1f, first cards: %s" % [viewport_size, cards.scroll_container.scroll_vertical, cards.scroll_container.size.y, [cards.hero_list.get_child(0).size.y, cards.hero_list.get_child(1).size.y, cards.hero_list.get_child(2).size.y]])
	_check(cards.scroll_container.scroll_vertical == 0, "%s fresh Hero Cards starts at the first hero" % viewport_size)
	_check_card_layout(cards, viewport_size)

	_check(cards.title_label.text == "FILIPINO HERO", "title omits Collection at %s" % viewport_size)
	_check(cards.hero_list.get_child_count() == 6, "all six hero cards render at %s" % viewport_size)
	_check(cards.back_button.custom_minimum_size.y >= 80.0, "Back button remains touch friendly at %s" % viewport_size)
	for child: Node in cards.hero_list.get_children():
		_check(child is Button, "hero entry remains an interactive Button")
		if child is Button:
			var button := child as Button
			_check(not button.disabled, "%s keeps WATCH STORY available independently of gameplay unlocks" % button.name)
			_check(not button.text.contains("GAMEPLAY TOKEN"), "%s removes the gameplay-token status text" % button.name)
			_check(button.get_meta("character_id", "") != "", "%s preserves its hero ID" % button.name)
			_check(_has_loaded_portrait(button), "%s displays its existing chibi portrait" % button.name)

	var image: Image = viewport.get_texture().get_image()
	var save_error := image.save_png(ProjectSettings.globalize_path("user://%s" % filename)) if image != null and not image.is_empty() else ERR_CANT_CREATE
	_check(save_error == OK, "%s rendered capture is saved" % filename)
	await _test_routes(cards, progress, viewport)
	cards.scroll_container.ensure_control_visible(cards.hero_list.get_child(5))
	await process_frame
	await process_frame
	var last: Control = cards.hero_list.get_child(5)
	_check(cards.scroll_container.get_global_rect().intersects(last.get_global_rect()), "%s can scroll to the sixth hero" % viewport_size)
	await RenderingServer.frame_post_draw
	image = viewport.get_texture().get_image()
	_check(image != null and image.save_png("user://" + filename.trim_suffix(".png") + "_last_heroes.png") == OK, "%s lower hero cards capture is saved" % viewport_size)

	cards.progress_manager = null
	cards.queue_free()
	viewport.queue_free()
	await process_frame
	progress.free()


func _labels(node: Node) -> Array[Label]:
	var result: Array[Label] = []
	if node is Label:
		result.append(node as Label)
	for child: Node in node.get_children():
		result.append_array(_labels(child))
	return result


func _check_card_layout(cards, viewport_size: Vector2i) -> void:
	_check(cards.get_node("Background").texture.resource_path.ends_with("heritage_village/background.png"), "%s uses the reference village scenery" % viewport_size)
	_check(cards.title_label.get_theme_stylebox("normal") is StyleBoxTexture, "%s displays the illustrated book crest" % viewport_size)
	_check(cards.back_button.get_theme_stylebox("normal") is StyleBoxTexture, "%s displays the reference Back artwork" % viewport_size)
	for child: Node in cards.hero_list.get_children():
		var button := child as Button
		var rect := button.get_global_rect()
		for label: Label in _labels(button):
			_check(rect.grow(0.5).encloses(label.get_global_rect()), "%s %s lettering stays within the card" % [viewport_size, button.name])
		var portrait: TextureRect = button.get_child(0).get_child(0).get_child(0).get_child(0)
		var atlas := portrait.texture as AtlasTexture
		_check(atlas != null and atlas.atlas.resource_path.ends_with("_chibi.png"), "%s %s retains its full-body hero artwork" % [viewport_size, button.name])
		if atlas != null:
			_check(atlas.region.encloses(Rect2(atlas.atlas.get_image().get_used_rect())), "%s %s retains all nontransparent portrait pixels" % [viewport_size, button.name])
		_check(portrait.modulate.is_equal_approx(Color.WHITE), "%s %s story portrait keeps its original colors" % [viewport_size, button.name])
	if viewport_size == Vector2i(1024, 1536):
		var third: Control = cards.hero_list.get_child(2)
		_check(third.get_global_rect().end.y <= cards.scroll_container.get_global_rect().end.y + 1.0, "reference-size layout fits the first three hero cards")


func _test_routes(cards, progress: MockProgress, viewport: SubViewport) -> void:
	var requested: Array[String] = []
	cards.scene_change_handler = func(path: String) -> void: requested.append(path)
	var first := cards.hero_list.get_child(0) as Button
	var story_label: Label = first.get_child(0).get_child(0).get_child(2).get_child(0)
	var point := story_label.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	viewport.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = point
	press.pressed = true
	viewport.push_input(press, true)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = point
	viewport.push_input(release, true)
	_check(requested == ["res://hero_story_video_player.tscn"] and progress.selected_story_level == 1, "pointer input on Watch Story reaches the existing player route")
	_check(progress.selected_hero == "historyroll_explorer", "watching a locked hero never selects its gameplay token")
	for index: int in range(6):
		requested.clear()
		(cards.hero_list.get_child(index) as Button).pressed.emit()
		_check(requested == ["res://hero_story_video_player.tscn"] and progress.selected_story_level == index + 1, "Hero Card %d retains its correct story route" % (index + 1))
	requested.clear()
	var first_id := str(first.get_meta("character_id"))
	progress.unlocked_characters.append(first_id)
	progress.watched_stories.append(1)
	first.pressed.emit()
	await process_frame
	await process_frame
	await process_frame
	_check(progress.selected_hero == first_id, "an unlocked hero can still be selected")
	_check(requested == ["res://hero_story_video_player.tscn"] and progress.selected_story_level == 1, "unlocked hero still opens its own story")
	_check(cards.status_label.text == "Selected Hero: Lapulapu", "selected-hero strip refreshes after selection")
	var watched_badge: Label = cards.hero_list.get_child(0).get_child(0).get_child(0).get_child(2).get_child(0)
	_check(watched_badge.text == "STORY\nWATCHED", "returning players retain the watched-story indicator")
	requested.clear()
	cards.back_button.pressed.emit()
	_check(requested == ["res://main_menu_tscn.tscn"], "Back retains the Main Menu route")


func _has_loaded_portrait(node: Node) -> bool:
	if node is TextureRect and (node as TextureRect).texture != null:
		return true
	for child: Node in node.get_children():
		if _has_loaded_portrait(child):
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("PASS: %s" % message)
	else:
		failed += 1
		push_error("FAIL: %s" % message)

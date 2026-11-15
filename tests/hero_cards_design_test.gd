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

	cards.progress_manager = null
	cards.queue_free()
	viewport.queue_free()
	await process_frame
	progress.free()


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

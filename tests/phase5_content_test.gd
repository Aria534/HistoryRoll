extends SceneTree

const DiceRoller = preload("res://dice_roller.gd")
const HeroCardsScene = preload("res://hero_cards.tscn")
const HeroDatabase = preload("res://hero_database.gd")
const LevelCatalog = preload("res://level_catalog.gd")
const ProgressManagerScript = preload("res://progress_manager.gd")
const QuestionBank = preload("res://quiz_question_bank.gd")

const EXPECTED_HERO_IDS: Array[String] = [
	"lapulapu", "andres_bonifacio", "jose_rizal", "gabriela_silang", "emilio_aguinaldo",
]
const EXPECTED_THEMES: Array[String] = [
	"Filipino Heroes",
	"Philippine Revolution Heroes",
	"National Heroes and Their Contributions",
	"Women Heroes",
	"Heroes of Philippine Independence",
	"Final Filipino Hero Challenge",
]

var _passed: int = 0
var _failed: int = 0
var _save_path: String = "user://historyroll_phase5_content.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if HeroDatabase.get_hero("antonio_luna").size() > 0:
		_test_final_roster()
		print("Phase 5 final-roster tests: %d passed, %d failed." % [_passed, _failed])
		quit(0 if _failed == 0 else 1)
		return
	_cleanup()
	_test_hero_database_and_levels()
	_test_question_banks()
	await _test_collection_and_selection()
	_test_final_level_no_reward_path()
	_cleanup()
	print("Phase 5 content tests: %d passed, %d failed." % [_passed, _failed])
	quit(0 if _failed == 0 else 1)


func _test_final_roster() -> void:
	_check(HeroDatabase.get_heroes().size() == 6, "final database contains six heroes")
	_check(HeroDatabase.get_hero("antonio_luna").get("associated_level") == 4, "Antonio Luna maps to Level 4")
	_check(HeroDatabase.get_hero("melchora_aquino").get("associated_level") == 5, "Melchora Aquino maps to Level 5")
	_check(HeroDatabase.get_hero("apolinario_mabini").get("associated_level") == 6, "Apolinario Mabini maps to Level 6")
	_check(LevelCatalog.get_all_characters().size() == 6, "Hero Cards exposes the six-hero roster")


func _test_hero_database_and_levels() -> void:
	_check(LevelCatalog.get_levels().size() == 6, "catalog contains all six official levels")
	var seen_ids: Dictionary = {}
	for level_id: int in range(1, 7):
		var level := LevelCatalog.get_level(level_id)
		_check(str(level.get("educational_theme", "")) == EXPECTED_THEMES[level_id - 1], "Level %d has the approved educational theme" % level_id)
		if level_id <= 5:
			var hero_id := str(level.get("hero_id", ""))
			_check(hero_id == EXPECTED_HERO_IDS[level_id - 1], "Level %d maps to the approved hero" % level_id)
			_check(not seen_ids.has(hero_id), "hero ID %s is unique" % hero_id)
			seen_ids[hero_id] = true
			var hero := HeroDatabase.get_hero(hero_id)
			for field: String in ["hero_name", "contribution", "contribution_year", "death_date", "cause_of_death", "historical_legacy", "story_text", "portrait_path", "references"]:
				_check(hero.has(field), "%s contains required field %s" % [hero_id, field])
			var word_count := str(hero.get("story_text", "")).split(" ", false).size()
			_check(word_count >= 100 and word_count <= 150, "%s story is approximately 100-150 words (%d)" % [hero_id, word_count])
			_check((hero.get("references", []) as Array).size() >= 1, "%s includes an authoritative reference" % hero_id)
			_check(str(hero.get("references", [""])[0]).contains("nhcp.gov.ph"), "%s references NHCP" % hero_id)
		else:
			_check(str(level.get("hero_id", "")).is_empty(), "Level 6 does not invent a sixth hero")
			_check(LevelCatalog.get_character_reward(6).is_empty(), "Level 6 has no character reward")
	_check(str(HeroDatabase.get_hero("lapulapu").get("death_date", "")) == "Unknown", "Lapulapu death date is not invented")
	_check(str(HeroDatabase.get_hero("emilio_aguinaldo").get("cause_of_death", "")).begins_with("Unknown"), "Aguinaldo medical cause is not invented")


func _test_question_banks() -> void:
	var all_ids: Dictionary = {}
	for level_id: int in range(1, 7):
		var regular := QuestionBank.get_questions_for_level(level_id, "regular")
		var bonus := QuestionBank.get_questions_for_level(level_id, "bonus")
		_check(regular.size() >= 15, "Level %d has at least 15 regular questions" % level_id)
		_check(bonus.size() >= 5, "Level %d has at least 5 bonus questions" % level_id)
		for question: Dictionary in regular + bonus:
			var question_id := str(question.get("question_id", ""))
			_check(not question_id.is_empty() and not all_ids.has(question_id), "question ID %s is present and unique" % question_id)
			all_ids[question_id] = true
			_check(int(question.get("level", 0)) == level_id, "%s belongs to Level %d" % [question_id, level_id])
			_check((question.get("choices", []) as Array).size() == 4, "%s has exactly four choices" % question_id)
			var correct_index := int(question.get("correct_index", -1))
			_check(correct_index >= 0 and correct_index < 4, "%s has a valid correct-answer index" % question_id)
			_check(EXPECTED_HERO_IDS.has(str(question.get("hero_id", ""))), "%s uses a featured hero ID" % question_id)


func _test_collection_and_selection() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = _save_path
	_check(progress.unlocked_characters == [progress.DEFAULT_HERO_ID], "only the default explorer starts unlocked")
	_check(not progress.select_hero("lapulapu"), "locked Lapulapu cannot be selected")

	var collection = HeroCardsScene.instantiate()
	collection.progress_manager = progress
	get_root().add_child(collection)
	await process_frame
	var locked_lapulapu := _find_character_button(collection, "lapulapu")
	_check(locked_lapulapu != null and locked_lapulapu.disabled, "Hero Cards displays Lapulapu as locked initially")

	_check(progress.record_board_completion(1, 100, {"position": 100}), "Level 1 board completion is accepted")
	_check(progress.begin_post_level_story(1), "Level 1 advances to post-game story")
	_check(progress.mark_story_completed(1), "Lapulapu story completion is recorded")
	_check(progress.claim_character_reward(1), "Lapulapu character reward is claimed")
	await process_frame
	await process_frame
	var unlocked_lapulapu := _find_character_button(collection, "lapulapu")
	_check(unlocked_lapulapu != null and not unlocked_lapulapu.disabled, "Hero Cards refreshes Lapulapu to unlocked")
	_check(unlocked_lapulapu.text.contains("27 April 1521"), "unlocked Hero Card shows contribution timing")
	_check(unlocked_lapulapu.text.contains("Death: Unknown"), "unlocked Hero Card shows verified death status")
	unlocked_lapulapu.pressed.emit()
	_check(progress.selected_hero == "lapulapu", "unlocked Lapulapu can be selected")

	var before_selection_roller = DiceRoller.new(7351)
	var selected_hero_rolls: Array[int] = []
	for roll_index: int in range(30):
		selected_hero_rolls.append(before_selection_roller.roll())
	var comparison_roller = DiceRoller.new(7351)
	var comparison_rolls: Array[int] = []
	for roll_index: int in range(30):
		comparison_rolls.append(comparison_roller.roll())
	_check(selected_hero_rolls == comparison_rolls, "selected hero does not alter seeded dice results")

	var reloaded = ProgressManagerScript.new()
	reloaded.save_path = _save_path
	reloaded.load_progress()
	_check(reloaded.is_character_unlocked("lapulapu"), "Lapulapu unlock survives restart")
	_check(reloaded.selected_hero == "lapulapu", "selected hero survives restart")
	collection.queue_free()
	await process_frame
	progress.free()
	reloaded.free()


func _test_final_level_no_reward_path() -> void:
	var progress = ProgressManagerScript.new()
	progress.save_path = _save_path
	progress.board_completed_levels.append(6)
	progress.pending_progression_level = 6
	progress.progression_stage = progress.STAGE_POST_STORY
	_check(progress.mark_story_completed(6), "Level 6 story completes without a character reward")
	_check(progress.progression_stage == progress.STAGE_LEVEL_UNLOCK, "Level 6 advances directly to final confirmation")
	_check(progress.is_level_completed(6), "Level 6 is marked complete")
	_check(not progress.claimed_character_rewards.has(6), "Level 6 does not claim an invented character")
	progress.free()


func _find_character_button(collection: Node, character_id: String) -> Button:
	for child: Node in collection.hero_list.get_children():
		if child is Button and str(child.get_meta("character_id", "")) == character_id:
			return child as Button
	return null


func _cleanup() -> void:
	if FileAccess.file_exists(_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_path))


func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", description)
	else:
		_failed += 1
		push_error("FAIL: %s" % description)

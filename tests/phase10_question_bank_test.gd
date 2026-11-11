extends SceneTree

const GameplayScene = preload("res://gameplay_placeholder.tscn")
const GameplayScript = preload("res://gameplay_placeholder.gd")
const LevelCatalog = preload("res://level_catalog.gd")
const QuizQuestionBank = preload("res://quiz_question_bank.gd")
const QuizSession = preload("res://quiz_session.gd")

const EXPECTED_ACTIVE_COUNTS := [47, 49, 45, 44, 45, 47]
const EXPECTED_REVIEW_COUNTS := [3, 1, 5, 6, 5, 3]
const EXPECTED_TILES := [20, 30, 40, 50, 100, 100]

var passed := 0
var failed := 0


class MockProgress:
	extends Node
	var selected_level := 1
	func record_board_completion(_level: int, _score: int, _statistics: Dictionary) -> bool: return true
	func finish_level_results(_level: int) -> bool: return true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_bank_integrity()
	_test_session_randomization()
	await _test_gameplay_choices_and_scoring(Vector2i(720, 1280))
	await _test_gameplay_choices_and_scoring(Vector2i(1080, 2400))
	print("Phase 10 question-bank tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _test_bank_integrity() -> void:
	var validation_errors := QuizQuestionBank.validate_bank()
	_check(validation_errors.is_empty(), "question-bank structural validation passes: %s" % "; ".join(validation_errors))
	_check(QuizQuestionBank.get_source_question_count() == 300, "bank contains exactly 300 source questions")
	_check(QuizQuestionBank.get_active_question_count() == 277, "277 historically validated questions are active")
	_check(QuizQuestionBank.get_review_questions().size() == 23, "23 uncertain questions remain review-only")
	var all_ids: Dictionary = {}
	var all_question_text: Dictionary = {}
	for level_id: int in range(1, 7):
		var source := QuizQuestionBank.get_source_questions_for_level(level_id)
		var active := QuizQuestionBank.get_active_questions_for_level(level_id)
		var review := QuizQuestionBank.get_review_questions(level_id)
		_check(source.size() == 50, "Level %d preserves exactly 50 source questions" % level_id)
		_check(active.size() == EXPECTED_ACTIVE_COUNTS[level_id - 1], "Level %d exposes the expected validated gameplay pool" % level_id)
		_check(review.size() == EXPECTED_REVIEW_COUNTS[level_id - 1], "Level %d exposes the expected review-only count" % level_id)
		_check(int(LevelCatalog.get_level(level_id).board.columns) * int(LevelCatalog.get_level(level_id).board.rows) == EXPECTED_TILES[level_id - 1], "Level %d keeps its approved board size" % level_id)
		for question: Dictionary in source:
			var question_id := str(question.get("id", ""))
			var question_text := str(question.get("question", ""))
			var choices: Array = question.get("choices", [])
			var question_format := str(question.get("type", ""))
			_check(not all_ids.has(question_id), "%s has a globally unique ID" % question_id)
			all_ids[question_id] = true
			var normalized := question_text.to_lower().replace(" ", "")
			_check(not all_question_text.has(normalized), "%s is not unintended duplicate wording" % question_id)
			all_question_text[normalized] = true
			_check(not question_text.is_empty(), "%s has question text" % question_id)
			_check(choices.size() == (3 if question_format == "multiple_choice" else 2), "%s has the correct number of choices" % question_id)
			for choice: Variant in choices:
				_check(not str(choice).strip_edges().is_empty(), "%s has no empty choice" % question_id)
			if bool(question.get("active", false)):
				var correct_index := int(question.get("correct_index", -1))
				_check(correct_index >= 0 and correct_index < choices.size(), "%s has a valid active answer index" % question_id)
			else:
				_check(int(question.get("correct_index", 0)) == -1, "%s has no invented answer key while under review" % question_id)


func _test_session_randomization() -> void:
	var source := QuizQuestionBank.get_active_questions_for_level(1)
	var session = QuizSession.new()
	_check(session.configure(source, true), "randomized Level 1 session configures")
	var seen: Dictionary = {}
	var previous_id := ""
	for index: int in range(source.size()):
		var question := session.next_question()
		var question_id := str(question.get("question_id", ""))
		_check(not seen.has(question_id), "question %d does not repeat before pool exhaustion" % (index + 1))
		seen[question_id] = true
		previous_id = question_id
	var reshuffled := session.next_question()
	_check(seen.has(str(reshuffled.get("question_id", ""))), "session reshuffles after exhausting the active pool")
	_check(str(reshuffled.get("question_id", "")) != previous_id, "reshuffle avoids an immediate boundary repeat")

	var first_question: Dictionary = QuizQuestionBank.get_active_questions_for_level(1)[0]
	var fixed_session = QuizSession.new()
	_check(fixed_session.configure([first_question], false), "three-choice session configures")
	var current := fixed_session.next_question()
	var correct_index := int(current.get("correct_index", -1))
	_check(bool(fixed_session.submit_answer(correct_index).get("correct", false)), "three-choice correct answer validates")
	_check(not bool(fixed_session.submit_answer(correct_index).get("accepted", true)), "duplicate submission is rejected")

	var true_false_question: Dictionary = {}
	for question: Dictionary in QuizQuestionBank.get_active_questions_for_level(1):
		if str(question.get("question_format", "")) == "true_false":
			true_false_question = question
			break
	var true_false_session = QuizSession.new()
	_check(true_false_session.configure([true_false_question], false), "two-choice True/False session configures")
	_check(true_false_session.next_question().get("choices", []).size() == 2, "True/False keeps exactly two choices")


func _test_gameplay_choices_and_scoring(viewport_size: Vector2i) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	get_root().add_child(viewport)
	var progress := MockProgress.new()
	var game = GameplayScene.instantiate()
	game.progress_manager = progress
	game.shuffle_questions = false
	viewport.add_child(game)
	await process_frame
	await process_frame
	var label := "%dx%d" % [viewport_size.x, viewport_size.y]
	_check(game.state == GameplayScript.GameplayState.QUESTION, "%s starts with a question before rolling" % label)
	_check(game.current_question.get("choices", []).size() == 3, "%s first source question has three choices" % label)
	_check(game.answer_buttons[0].visible and game.answer_buttons[1].visible and game.answer_buttons[2].visible, "%s displays all three multiple-choice buttons" % label)
	_check(not game.answer_buttons[3].visible, "%s hides the unused fourth multiple-choice button" % label)
	_check(game.question_label.autowrap_mode != TextServer.AUTOWRAP_OFF, "%s question text wraps" % label)
	for index: int in range(3):
		_check(game.answer_buttons[index].size.y >= 70.0, "%s visible answer %d remains touch-friendly" % [label, index + 1])
		_check(_rect_inside(game.answer_buttons[index].get_global_rect(), viewport_size), "%s visible answer %d stays on-screen" % [label, index + 1])
	game.question_label.text = "Why couldn't the Spanish ships get close to the shore of Mactan?"
	game._apply_question_typography([
		"Shallow water and coral reefs blocked them",
		"The sea was too deep",
		"Large rocks crashed their ships",
	])
	_check(game.question_label.get_theme_font_size("font_size") == 26, "%s long Mactan question uses fitted parchment typography" % label)
	_check(game.question_label.custom_minimum_size.y >= 78.0, "%s long Mactan question receives enough yellow-panel height" % label)
	_check(game.answer_buttons[0].get_theme_font_size("font_size") == 18, "%s long Mactan choices fit inside their green buttons" % label)
	_check(_rect_inside(game.roll_button.get_global_rect(), viewport_size), "%s Roll Dice control stays fully on-screen" % label)
	_check(not game.board_panel.get_global_rect().intersects(game.quiz_panel.get_global_rect()), "%s board and quiz panel do not overlap" % label)
	var correct_index := int(game.current_question.get("correct_index", -1))
	game.answer_buttons[correct_index].pressed.emit()
	_check(game.score == 10, "%s correct answer awards 10 points" % label)
	_check(game.state == GameplayScript.GameplayState.READY_TO_ROLL and not game.roll_button.disabled, "%s correct answer enables one dice roll" % label)
	game.answer_buttons[correct_index].pressed.emit()
	_check(game.score == 10, "%s duplicate correct submission cannot score twice" % label)

	# Advance through Q2 and Q4 to the first active True/False item, Q5.
	game._begin_question("regular")
	game._begin_question("regular")
	game._begin_question("regular")
	_check(game.current_question.get("question_format", "") == "true_false", "%s reaches a True/False source question" % label)
	_check(game.answer_buttons[0].visible and game.answer_buttons[1].visible, "%s displays both True/False buttons" % label)
	_check(not game.answer_buttons[2].visible and not game.answer_buttons[3].visible, "%s hides both unused True/False buttons" % label)
	var tf_correct := int(game.current_question.get("correct_index", -1))
	var wrong_index := 1 - tf_correct
	game.answer_buttons[wrong_index].pressed.emit()
	_check(game.score == 8, "%s incorrect answer deducts 2 without blocking play" % label)
	_check(game.state == GameplayScript.GameplayState.READY_TO_ROLL and not game.roll_button.disabled, "%s incorrect answer also enables one dice roll" % label)
	_check(game.score >= 0, "%s score floor remains zero or higher" % label)
	game.progress_manager = null
	game.queue_free()
	viewport.queue_free()
	await process_frame
	progress.free()


func _check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
		print("PASS: ", description)
	else:
		failed += 1
		push_error("FAIL: %s" % description)


func _rect_inside(rect: Rect2, viewport_size: Vector2i) -> bool:
	return rect.position.x >= 0.0 and rect.position.y >= 0.0 and rect.end.x <= viewport_size.x and rect.end.y <= viewport_size.y

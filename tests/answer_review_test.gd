extends "res://tests/level_completion_test.gd"

const QuizSessionScript = preload("res://quiz_session.gd")
const QuestionBank = preload("res://quiz_question_bank.gd")
const AnswerReview = preload("res://answer_review.gd")
const REVIEW_SAVE := "user://historyroll_answer_review_test.json"


func _run() -> void:
	_cleanup()
	_test_answer_history()
	_test_save_compatibility()
	var progress = ProgressScript.new()
	progress.save_path = REVIEW_SAVE
	for level_id: int in range(1, 7):
		await _test_review_level(level_id, progress)
	await _test_replay_and_perfect_run(progress)
	await _test_all_wrong(progress)
	await _test_long_review_layout()
	await _test_all_question_layouts()
	progress.free()
	_cleanup()
	var audio: Node = get_root().get_node_or_null("AudioManager")
	if audio != null:
		audio.stop_music(0.0)
	await create_timer(1.1).timeout
	await process_frame
	print("Answer review tests: %d passed, %d failed." % [passed, failed])
	quit(0 if failed == 0 else 1)


func _test_answer_history() -> void:
	var pool: Array = QuestionBank.get_questions_for_level(1)
	var session = QuizSessionScript.new()
	_check(session.configure([pool[0]], false), "a validated real question configures")
	_check(not session.submit_answer(0).accepted and session.get_answer_history().is_empty(), "answering before a question cannot create history")
	var question: Dictionary = session.next_question()
	var wrong_index: int = (int(question.correct_index) + 1) % question.choices.size()
	_check(not session.submit_answer(-1).accepted and session.get_answer_history().is_empty(), "invalid choice cannot create history")
	_check(session.submit_answer(wrong_index).accepted, "a wrong answer is accepted once")
	_check(not session.submit_answer(wrong_index).accepted and session.get_answer_history().size() == 1, "duplicate submissions cannot duplicate review entries")
	var history: Array[Dictionary] = session.get_answer_history()
	_check(history[0].selected_answer == question.choices[wrong_index] and history[0].correct_answer == question.choices[question.correct_index], "history snapshots both the chosen and validated correct answer")
	history[0].question_text = "changed outside the session"
	_check(session.get_answer_history()[0].question_text == question.question_text, "callers cannot mutate saved answer history")
	session.next_question()
	session.submit_answer(wrong_index)
	_check(session.get_answer_history().size() == 2, "separate wrong attempts of the same question are both retained")
	var review := AnswerReview.from_statistics(1, {"answer_history": session.get_answer_history()})
	_check(review.correct_answers == 0 and review.incorrect_answers == 2 and review.mistakes.size() == 2, "review totals come from actual accepted attempts")
	_check(session.configure([pool[0]], false) and session.get_answer_history().is_empty(), "a new quiz session clears earlier attempts")
	session.next_question()
	session.submit_answer(int(question.correct_index))
	review = AnswerReview.from_statistics(1, {"answer_history": session.get_answer_history()})
	_check(review.correct_answers == 1 and review.incorrect_answers == 0 and review.mistakes.is_empty(), "a perfect run contains no fabricated mistakes")
	var legacy := AnswerReview.from_statistics(1, {"correct_answers": 2, "incorrect_answers": 1})
	_check(legacy.correct_answers == 2 and legacy.incorrect_answers == 1 and legacy.mistakes.is_empty(), "legacy totals never invent unavailable question details")
	_check(AnswerReview.from_saved([], 1).is_empty(), "invalid saved review container is rejected")


func _test_save_compatibility() -> void:
	var data := {
		"version": 3, "player_name": "Maria", "highest_unlocked_level": 2,
		"completed_levels": [1], "board_completed_levels": [1],
		"best_scores": {"1": 42}, "selected_level": 1,
	}
	_write_save(data)
	var before := FileAccess.get_file_as_string(REVIEW_SAVE)
	var progress = ProgressScript.new()
	progress.save_path = REVIEW_SAVE
	progress.load_progress()
	_check(progress.player_name == "Maria" and progress.is_level_unlocked(2) and int(progress.best_scores["1"]) == 42, "old version-3 player name, unlocks and scores survive")
	_check(progress.get_level_answer_review(1).is_empty(), "older saves load without fabricated review history")
	_check(FileAccess.get_file_as_string(REVIEW_SAVE) == before, "loading an older version-3 save does not rewrite it")
	progress.free()
	var session = QuizSessionScript.new()
	session.configure([QuestionBank.get_questions_for_level(1)[0]], false)
	var question: Dictionary = session.next_question()
	session.submit_answer((int(question.correct_index) + 1) % question.choices.size())
	var good := AnswerReview.from_statistics(1, {"answer_history": session.get_answer_history()})
	var damaged := JSON.parse_string(JSON.stringify(good)) as Dictionary
	damaged.mistakes.append(null)
	damaged.mistakes.append({"level": 1, "question_id": 99})
	data["level_answer_reviews"] = {"1": damaged, "2": good, "invalid": good, "99": good}
	_write_save(data)
	progress = ProgressScript.new()
	progress.save_path = REVIEW_SAVE
	progress.load_progress()
	_check(progress.get_level_answer_review(1).mistakes.size() == 1, "corrupt review entries are ignored while valid entries survive")
	_check(progress.level_answer_reviews.size() == 1 and not progress.is_level_completed(2), "invalid or uncompleted level reviews cannot create progress")
	progress.free()
	_cleanup()


func _test_review_level(level_id: int, progress: Node) -> void:
	_check(progress.select_level(level_id), "Level %d retains sequential access" % level_id)
	var fixture := await _fixture(level_id, Vector2i(720, 1280), progress)
	await _answer_and_roll(fixture.game, true, false)
	var first_wrong := await _answer_and_roll(fixture.game, false, false)
	var last_wrong := await _answer_and_roll(fixture.game, false, true)
	var game = fixture.game
	var card = game.results_panel
	await create_timer(0.4).timeout
	_check(game.correct_answers == 1 and game.incorrect_answers == 2 and game.score == 6, "Level %d preserves actual counts and existing scoring" % level_id)
	_check(card.summary_label.visible and card.summary_label.text == "Correct: 1     Incorrect: 2", "Level %d completion visibly shows both totals" % level_id)
	_check(fixture.progress.completion_calls == 1 and progress.is_level_completed(level_id), "Level %d saves its completion once" % level_id)
	var review: Dictionary = progress.get_level_answer_review(level_id)
	_check(review.correct_answers == 1 and review.incorrect_answers == 2 and review.mistakes.size() == 2, "Level %d saves its own completed-attempt review" % level_id)
	review.mistakes.clear()
	_check(progress.get_level_answer_review(level_id).mistakes.size() == 2, "Level %d stored review is protected from caller mutation" % level_id)
	var saved_before := JSON.stringify(progress.level_answer_reviews)
	if level_id == 1:
		await _capture(fixture.viewport, "answer_totals_720x1280.png")
	var expected: Array[Dictionary] = [first_wrong, last_wrong]
	for index: int in range(expected.size()):
		_click(fixture.viewport, game.return_button.get_global_rect().get_center())
		await process_frame
		var text: String = card.summary_label.text
		_check(card.great_job_label.text == "Answer Review" and card._review_index == index, "Level %d opens review page %d" % [level_id, index + 1])
		_check(text.contains(expected[index].question_text) and text.contains("Your answer: " + expected[index].selected_answer) and text.contains("Correct answer: " + expected[index].correct_answer), "Level %d page %d shows the actual question, mistake and correction" % [level_id, index + 1])
		_check(fixture.requested.is_empty() and fixture.progress.finish_calls == 0, "review pages do not leave the level early")
		_check(game.roll_button.disabled and game.back_button.disabled, "board controls stay disabled during review")
		_check_review_layout(card, Vector2i(720, 1280))
		if index == 0:
			await _capture(fixture.viewport, "answer_review_level_%d_720x1280.png" % level_id)
			if level_id == 1:
				fixture.viewport.size = Vector2i(1024, 1536)
				for frame in 4: await process_frame
				_check_review_layout(card, Vector2i(1024, 1536))
				await _capture(fixture.viewport, "answer_review_1024x1536.png")
				fixture.viewport.size = Vector2i(720, 1280)
				for frame in 4: await process_frame
	_check(game.return_button.text == "Continue" and JSON.stringify(progress.level_answer_reviews) == saved_before, "review finishes without altering saved totals or answers")
	_click(fixture.viewport, game.return_button.get_global_rect().get_center())
	_click(fixture.viewport, game.return_button.get_global_rect().get_center())
	game.return_button.pressed.emit()
	var destination := "res://certificate.tscn" if level_id == 6 else "res://level_selection.tscn"
	_check(fixture.requested == [destination] and fixture.progress.finish_calls == 1, "Level %d review preserves its final destination exactly once" % level_id)
	_check(game.score == 6 and fixture.progress.completion_calls == 1, "reading corrections never changes scores or re-awards completion")
	await _dispose(fixture)
	var reloaded = ProgressScript.new()
	reloaded.save_path = REVIEW_SAVE
	reloaded.load_progress()
	var restored: Dictionary = reloaded.get_level_answer_review(level_id)
	_check(restored.correct_answers == 1 and restored.incorrect_answers == 2 and restored.mistakes.size() == 2, "Level %d review survives restart" % level_id)
	reloaded.free()


func _answer_and_roll(game: Node, correct: bool, finish: bool) -> Dictionary:
	var question: Dictionary = game.current_question
	var choice := int(question.correct_index)
	if not correct:
		choice = (choice + 1) % question.choices.size()
	var previous_count: int = game.quiz_session.get_answer_history().size()
	game.answer_buttons[choice].pressed.emit()
	game.answer_buttons[choice].pressed.emit()
	_check(game.quiz_session.get_answer_history().size() == previous_count + 1, "repeated answer clicks still record one accepted attempt")
	var snapshot: Dictionary = game.quiz_session.get_answer_history().back()
	if finish:
		game.player_position = game.tile_count - 1
		game.board_view.set_player_position_immediate(game.player_position)
	var roll: Array[int] = [1]
	game.set_controlled_dice_results(roll)
	game.roll_button.pressed.emit()
	for frame in 600:
		if game.state == GameplayScript.GameplayState.QUESTION or game.state == GameplayScript.GameplayState.LEVEL_COMPLETE:
			break
		await process_frame
	_check(game.state == (GameplayScript.GameplayState.LEVEL_COMPLETE if finish else GameplayScript.GameplayState.QUESTION), "the answered turn resolves through real movement")
	return snapshot


func _test_replay_and_perfect_run(progress: Node) -> void:
	var reward_count: int = progress.claimed_character_rewards.size()
	var other_review := JSON.stringify(progress.get_level_answer_review(2))
	var fixture := await _fixture(1, Vector2i(720, 1280), progress)
	await _finish_valid(fixture.game)
	var latest: Dictionary = progress.get_level_answer_review(1)
	_check(latest.correct_answers == 1 and latest.incorrect_answers == 0 and latest.mistakes.is_empty(), "replay replaces the previous attempt instead of mixing totals")
	_check(progress.claimed_character_rewards.size() == reward_count and JSON.stringify(progress.get_level_answer_review(2)) == other_review, "replay preserves other reviews and unique rewards")
	_click(fixture.viewport, fixture.game.return_button.get_global_rect().get_center())
	_check(fixture.requested == ["res://level_selection.tscn"], "a perfect run continues directly without empty review pages")
	await _dispose(fixture)


func _test_all_wrong(progress: Node) -> void:
	var fixture := await _fixture(1, Vector2i(720, 1280), progress)
	await _finish_valid(fixture.game, false)
	_check(fixture.game.results_label.text == "Correct: 0     Incorrect: 1" and fixture.game.score == 0, "all-wrong run shows honest counts and preserves score floor")
	_click(fixture.viewport, fixture.game.return_button.get_global_rect().get_center())
	_check(fixture.game.results_panel._review_mode and fixture.requested.is_empty(), "an all-wrong run still reviews its incorrect answer")
	_click(fixture.viewport, fixture.game.return_button.get_global_rect().get_center())
	_check(fixture.requested == ["res://level_selection.tscn"], "single-question review continues after its correction")
	await _dispose(fixture)


func _test_long_review_layout() -> void:
	var longest: Dictionary = {}
	var longest_choice := 0
	var longest_size := 0
	for level_id: int in range(1, 7):
		for question: Dictionary in QuestionBank.get_questions_for_level(level_id):
			for index: int in range(question.choices.size()):
				if index == int(question.correct_index): continue
				var length: int = str(question.question_text).length() + str(question.choices[index]).length() + str(question.choices[question.correct_index]).length()
				if length > longest_size:
					longest_size = length
					longest = question
					longest_choice = index
	var fixture := await _fixture(int(longest.level), Vector2i(720, 1280))
	var game = fixture.game
	game.quiz_session.configure([longest], false)
	game._begin_question("regular")
	game.answer_buttons[longest_choice].pressed.emit()
	game.player_position = game.tile_count - 1
	game.board_view.set_player_position_immediate(game.player_position)
	var roll: Array[int] = [1]
	game.set_controlled_dice_results(roll)
	game.roll_button.pressed.emit()
	for frame in 600:
		if game.state == GameplayScript.GameplayState.LEVEL_COMPLETE: break
		await process_frame
	await create_timer(0.4).timeout
	_click(fixture.viewport, game.return_button.get_global_rect().get_center())
	await process_frame
	_check_review_layout(game.results_panel, Vector2i(720, 1280))
	await _capture(fixture.viewport, "answer_review_longest_720x1280.png")
	await _dispose(fixture)


func _test_all_question_layouts() -> void:
	var fixture := await _fixture(1, Vector2i(720, 1280))
	var card = fixture.game.results_panel
	var session = QuizSessionScript.new()
	for viewport_size: Vector2i in [Vector2i(720, 1280), Vector2i(1024, 1536)]:
		fixture.viewport.size = viewport_size
		for frame in 4: await process_frame
		var layout_failures: Array[String] = []
		var checked := 0
		for level_id: int in range(1, 7):
			for question: Dictionary in QuestionBank.get_questions_for_level(level_id):
				for choice: int in range(question.choices.size()):
					if choice == int(question.correct_index): continue
					session.configure([question], false)
					session.next_question()
					session.submit_answer(choice)
					card.present_completion(level_id, 0, 0, {"answer_history": session.get_answer_history()})
					card.advance_review()
					await process_frame
					var label: Label = card.summary_label
					var panel := label.get_theme_stylebox("normal")
					var content_width := label.size.x - panel.get_content_margin(SIDE_LEFT) - panel.get_content_margin(SIDE_RIGHT)
					var content_height := label.size.y - panel.get_content_margin(SIDE_TOP) - panel.get_content_margin(SIDE_BOTTOM)
					var font := label.get_theme_font("font")
					var font_size := label.get_theme_font_size("font_size")
					var text_height := font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, content_width, font_size).y
					if font_size < 18 or text_height > content_height + 1.0 or label.get_global_rect().intersects(card.continue_button.get_global_rect()) or not card.get_card_rect().encloses(label.get_global_rect()):
						layout_failures.append("%s choice %d" % [question.question_id, choice])
					checked += 1
		_check(layout_failures.is_empty(), "all %d validated question/wrong-choice reviews fit at %dx%d" % [checked, viewport_size.x, viewport_size.y])
		for item: String in layout_failures.slice(0, 5):
			print("Layout failure: ", item)
	await _dispose(fixture)



func _check_review_layout(card: Node, viewport_size: Vector2i) -> void:
	var label: Label = card.summary_label
	var style := label.get_theme_stylebox("normal")
	var width := label.size.x - style.get_content_margin(SIDE_LEFT) - style.get_content_margin(SIDE_RIGHT)
	var height := label.size.y - style.get_content_margin(SIDE_TOP) - style.get_content_margin(SIDE_BOTTOM)
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	_check(font_size >= 18 and font.get_multiline_string_size(label.text, HORIZONTAL_ALIGNMENT_CENTER, width, font_size).y <= height + 1.0, "complete review text fits at a readable font size")
	_check(_inside(label.get_global_rect(), viewport_size) and card.get_card_rect().encloses(label.get_global_rect()), "review text remains inside its card and portrait screen")
	_check(_inside(card.continue_button.get_global_rect(), viewport_size) and not label.get_global_rect().intersects(card.continue_button.get_global_rect()), "review does not overlap Continue")


func _write_save(data: Dictionary) -> void:
	var file := FileAccess.open(REVIEW_SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))


func _cleanup() -> void:
	if FileAccess.file_exists(REVIEW_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(REVIEW_SAVE))

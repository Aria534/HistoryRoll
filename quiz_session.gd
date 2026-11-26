extends RefCounted

var _questions: Array[Dictionary] = []
var _order: Array[int] = []
var _cursor: int = -1
var _answered: bool = false
var _answer_history: Array[Dictionary] = []


func configure(source_questions: Array, shuffle_questions: bool = true) -> bool:
	_questions.clear()
	_order.clear()
	_answer_history.clear()
	_cursor = -1
	_answered = false

	for raw_question: Variant in source_questions:
		if raw_question is Dictionary and _is_valid_question(raw_question):
			_questions.append((raw_question as Dictionary).duplicate(true))

	for index: int in range(_questions.size()):
		_order.append(index)
	if shuffle_questions:
		_order.shuffle()
	return not _questions.is_empty()


func next_question() -> Dictionary:
	if _questions.is_empty():
		return {}
	_cursor += 1
	if _cursor >= _order.size():
		var previous_question_index := _order[-1]
		_cursor = 0
		_order.shuffle()
		if _order.size() > 1 and _order[0] == previous_question_index:
			var swap_index := 1 + randi() % (_order.size() - 1)
			var temporary_index := _order[0]
			_order[0] = _order[swap_index]
			_order[swap_index] = temporary_index
	_answered = false
	return get_current_question()


func get_current_question() -> Dictionary:
	if _cursor < 0 or _cursor >= _order.size():
		return {}
	return _questions[_order[_cursor]].duplicate(true)


func submit_answer(choice_index: int) -> Dictionary:
	if _answered:
		return {"accepted": false, "correct": false}
	var question := get_current_question()
	var choices: Array = question.get("choices", [])
	if question.is_empty() or choice_index < 0 or choice_index >= choices.size():
		return {"accepted": false, "correct": false}

	_answered = true
	var correct := choice_index == int(question.get("correct_index", -1))
	# Copy the accepted answer now, before the next question or UI can change.
	_answer_history.append({
		"level": int(question.get("level", 0)),
		"question_id": str(question.get("question_id", "")),
		"question_text": str(question.get("question_text", "")),
		"selected_index": choice_index,
		"correct_index": int(question.get("correct_index", -1)),
		"selected_answer": str(choices[choice_index]),
		"correct_answer": str(choices[int(question.correct_index)]),
		"correct": correct,
	})
	return {
		"accepted": true,
		"correct": correct,
		"explanation": str(question.get("explanation", "")),
		"correct_index": int(question.get("correct_index", -1)),
	}


func get_answer_history() -> Array[Dictionary]:
	return _answer_history.duplicate(true)


func _is_valid_question(question: Dictionary) -> bool:
	var choices: Variant = question.get("choices", [])
	var correct_index := int(question.get("correct_index", -1))
	var question_format := str(question.get("question_format", ""))
	var choices_are_valid: bool = choices is Array and choices.size() >= 2 and choices.size() <= 4
	if question_format == "multiple_choice":
		choices_are_valid = choices is Array and choices.size() == 3
	elif question_format == "true_false":
		choices_are_valid = choices is Array and choices.size() == 2
	return (
		not str(question.get("question_id", "")).is_empty()
		and int(question.get("level", 0)) >= 1
		and not str(question.get("hero_id", "")).is_empty()
		and ["regular", "bonus"].has(str(question.get("question_type", "")))
		and not str(question.get("question_text", "")).is_empty()
		and choices_are_valid
		and correct_index >= 0
		and correct_index < choices.size()
	)

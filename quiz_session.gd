extends RefCounted

var _questions: Array[Dictionary] = []
var _order: Array[int] = []
var _cursor: int = -1
var _answered: bool = false


func configure(source_questions: Array, shuffle_questions: bool = true) -> bool:
	_questions.clear()
	_order.clear()
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
		_cursor = 0
		_order.shuffle()
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
	if question.is_empty() or choice_index < 0 or choice_index >= 4:
		return {"accepted": false, "correct": false}

	_answered = true
	var correct := choice_index == int(question.get("correct_index", -1))
	return {
		"accepted": true,
		"correct": correct,
		"explanation": str(question.get("explanation", "")),
		"correct_index": int(question.get("correct_index", -1)),
	}


func _is_valid_question(question: Dictionary) -> bool:
	var choices: Variant = question.get("choices", [])
	var correct_index := int(question.get("correct_index", -1))
	return (
		not str(question.get("question_id", "")).is_empty()
		and int(question.get("level", 0)) >= 1
		and not str(question.get("question_text", "")).is_empty()
		and choices is Array
		and choices.size() == 4
		and correct_index >= 0
		and correct_index < 4
	)

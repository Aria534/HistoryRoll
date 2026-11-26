extends RefCounted
## JSON-safe snapshots for the most recently completed attempt of each level.


static func from_statistics(level_id: int, statistics: Dictionary) -> Dictionary:
	var mistakes: Array[Dictionary] = []
	var correct := 0
	var incorrect := 0
	var history: Variant = statistics.get("answer_history", null)
	if history is Array:
		for raw_entry: Variant in history:
			var entry := _copy_answer(raw_entry, level_id)
			if entry.is_empty():
				continue
			if bool(entry.correct):
				correct += 1
			else:
				incorrect += 1
				mistakes.append(entry)
	else:
		# Earlier saves contain totals only; never invent their missing answers.
		correct = _count(statistics.get("correct_answers", 0))
		incorrect = _count(statistics.get("incorrect_answers", 0))
	return {
		"level_id": level_id,
		"correct_answers": correct,
		"incorrect_answers": incorrect,
		"mistakes": mistakes,
	}


static func from_saved(value: Variant, level_id: int) -> Dictionary:
	if not value is Dictionary or _count(value.get("level_id", 0)) != level_id:
		return {}
	var mistakes: Array[Dictionary] = []
	var raw_mistakes: Variant = value.get("mistakes", [])
	if raw_mistakes is Array:
		for raw_entry: Variant in raw_mistakes:
			var entry := _copy_answer(raw_entry, level_id)
			if not entry.is_empty() and not bool(entry.correct):
				mistakes.append(entry)
	return {
		"level_id": level_id,
		"correct_answers": _count(value.get("correct_answers", 0)),
		"incorrect_answers": maxi(_count(value.get("incorrect_answers", 0)), mistakes.size()),
		"mistakes": mistakes,
	}


static func _copy_answer(value: Variant, level_id: int) -> Dictionary:
	if not value is Dictionary or _count(value.get("level", 0)) != level_id:
		return {}
	for field: String in ["question_id", "question_text", "selected_answer", "correct_answer"]:
		if not value.get(field, null) is String or str(value[field]).strip_edges().is_empty():
			return {}
	var selected := _answer_index(value.get("selected_index", null))
	var correct := _answer_index(value.get("correct_index", null))
	if selected < 0 or correct < 0:
		return {}
	return {
		"level": level_id,
		"question_id": str(value.question_id),
		"question_text": str(value.question_text),
		"selected_index": selected,
		"correct_index": correct,
		"selected_answer": str(value.selected_answer),
		"correct_answer": str(value.correct_answer),
		"correct": selected == correct,
	}


static func _answer_index(value: Variant) -> int:
	if not (value is int or value is float):
		return -1
	if not is_finite(float(value)) or float(value) < 0.0 or float(value) > 3.0 or float(value) != floorf(float(value)):
		return -1
	return int(value)


static func _count(value: Variant) -> int:
	if not (value is int or value is float) or not is_finite(float(value)):
		return 0
	return maxi(0, int(value))

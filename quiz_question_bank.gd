extends RefCounted

const DATA_PATH := "res://data/quiz_questions.json"
const EXPECTED_LEVELS := 6
const EXPECTED_QUESTIONS_PER_LEVEL := 50
const EXPECTED_SOURCE_QUESTION_COUNT := 300
const HERO_IDS := {
	1: "lapulapu",
	2: "andres_bonifacio",
	3: "jose_rizal",
	4: "antonio_luna",
	5: "melchora_aquino",
	6: "apolinario_mabini",
}

static var _source_cache: Array[Dictionary] = []
static var _load_attempted := false
static var _load_error := ""


# Returns only historically validated questions that are safe for gameplay.
# The question_type argument is retained for compatibility with existing calls.
static func get_questions_for_level(level_id: int, question_type: String = "regular") -> Array:
	if question_type != "regular":
		return []
	var questions: Array = []
	for source: Dictionary in _get_source_records():
		if int(source.get("level", 0)) != level_id or not bool(source.get("active", false)):
			continue
		questions.append(_to_runtime_question(source))
	return questions


static func get_active_questions_for_level(level_id: int) -> Array:
	return get_questions_for_level(level_id, "regular")


# Source records include review-only questions so document completeness can be
# audited independently from the active gameplay pool.
static func get_source_questions_for_level(level_id: int) -> Array:
	var questions: Array = []
	for source: Dictionary in _get_source_records():
		if int(source.get("level", 0)) == level_id:
			questions.append(source.duplicate(true))
	return questions


static func get_review_questions(level_id: int = 0) -> Array:
	var questions: Array = []
	for source: Dictionary in _get_source_records():
		if str(source.get("validation_status", "")) != "needs_review":
			continue
		if level_id == 0 or int(source.get("level", 0)) == level_id:
			questions.append(source.duplicate(true))
	return questions


static func get_source_question_count() -> int:
	return _get_source_records().size()


static func get_active_question_count() -> int:
	var count := 0
	for source: Dictionary in _get_source_records():
		if bool(source.get("active", false)):
			count += 1
	return count


static func get_load_error() -> String:
	_get_source_records()
	return _load_error


static func validate_bank() -> PackedStringArray:
	var errors := PackedStringArray()
	var records := _get_source_records()
	if not _load_error.is_empty():
		errors.append(_load_error)
		return errors
	if records.size() != EXPECTED_SOURCE_QUESTION_COUNT:
		errors.append("Expected %d source questions, found %d." % [EXPECTED_SOURCE_QUESTION_COUNT, records.size()])

	var ids: Dictionary = {}
	var normalized_questions: Dictionary = {}
	var level_counts: Dictionary = {}
	for source: Dictionary in records:
		var question_id := str(source.get("id", ""))
		var level_id := int(source.get("level", 0))
		var hero_id := str(source.get("hero_id", ""))
		var question_format := str(source.get("type", ""))
		var question_text := str(source.get("question", "")).strip_edges()
		var choices: Variant = source.get("choices", [])
		var correct_index := int(source.get("correct_index", -1))
		var status := str(source.get("validation_status", ""))

		if question_id.is_empty():
			errors.append("A source question has no ID.")
		elif ids.has(question_id):
			errors.append("Duplicate question ID: %s." % question_id)
		else:
			ids[question_id] = true
		if level_id < 1 or level_id > EXPECTED_LEVELS:
			errors.append("%s has invalid level %d." % [question_id, level_id])
		else:
			level_counts[level_id] = int(level_counts.get(level_id, 0)) + 1
			if hero_id != str(HERO_IDS.get(level_id, "")):
				errors.append("%s is assigned to the wrong hero." % question_id)
		if question_text.is_empty():
			errors.append("%s has empty question text." % question_id)
		else:
			var normalized := question_text.to_lower().replace(" ", "")
			if normalized_questions.has(normalized):
				errors.append("Duplicate question text: %s and %s." % [normalized_questions[normalized], question_id])
			else:
				normalized_questions[normalized] = question_id
		if not choices is Array:
			errors.append("%s choices are not an array." % question_id)
			continue
		var expected_choices := 3 if question_format == "multiple_choice" else 2
		if not ["multiple_choice", "true_false"].has(question_format):
			errors.append("%s has invalid question type '%s'." % [question_id, question_format])
		elif choices.size() != expected_choices:
			errors.append("%s has %d choices; expected %d." % [question_id, choices.size(), expected_choices])
		for choice: Variant in choices:
			if str(choice).strip_edges().is_empty():
				errors.append("%s contains an empty answer choice." % question_id)
		if status == "verified":
			if not bool(source.get("active", false)):
				errors.append("%s is verified but inactive." % question_id)
			if correct_index < 0 or correct_index >= choices.size():
				errors.append("%s has an invalid verified answer index." % question_id)
		elif status == "needs_review":
			if bool(source.get("active", true)) or correct_index != -1:
				errors.append("%s must remain inactive without an answer key." % question_id)
			if str(source.get("validation_issue", "")).is_empty():
				errors.append("%s has no validation issue explanation." % question_id)
		else:
			errors.append("%s has invalid validation status '%s'." % [question_id, status])

	for level_id: int in range(1, EXPECTED_LEVELS + 1):
		if int(level_counts.get(level_id, 0)) != EXPECTED_QUESTIONS_PER_LEVEL:
			errors.append("Level %d has %d source questions instead of %d." % [
			level_id, int(level_counts.get(level_id, 0)), EXPECTED_QUESTIONS_PER_LEVEL,
		])
	return errors


static func _get_source_records() -> Array[Dictionary]:
	if _load_attempted:
		return _source_cache
	_load_attempted = true
	if not FileAccess.file_exists(DATA_PATH):
		_load_error = "Question-bank data is missing: %s" % DATA_PATH
		return _source_cache
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not parsed is Dictionary:
		_load_error = "Question-bank JSON could not be parsed."
		return _source_cache
	var raw_questions: Variant = parsed.get("questions", [])
	if not raw_questions is Array:
		_load_error = "Question-bank JSON has no questions array."
		return _source_cache
	for raw_question: Variant in raw_questions:
		if raw_question is Dictionary:
			_source_cache.append((raw_question as Dictionary).duplicate(true))
	return _source_cache


static func _to_runtime_question(source: Dictionary) -> Dictionary:
	var choices: Array = source.get("choices", []).duplicate(true)
	var correct_index := int(source.get("correct_index", -1))
	var correct_answer := str(choices[correct_index]) if correct_index >= 0 and correct_index < choices.size() else ""
	return {
		"question_id": str(source.get("id", "")),
		"question_type": "regular",
		"question_format": str(source.get("type", "")),
		"level": int(source.get("level", 0)),
		"hero_id": str(source.get("hero_id", "")),
		"question_text": str(source.get("question", "")),
		"choices": choices,
		"correct_index": correct_index,
		"explanation": "The validated answer is %s." % correct_answer,
		"source_number": int(source.get("source_number", 0)),
		"source_document": str(source.get("source_document", "")),
		"validation_status": "verified",
	}

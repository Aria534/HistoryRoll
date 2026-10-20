extends RefCounted

const LEVELS: Array = [
	{
		"id": 1,
		"title": "Level 1",
		"description": "A development journey introducing Filipino heroes and their contributions.",
		"hero_name": "Hero to be confirmed",
		"portrait_path": "",
		"story_text": "DEVELOPMENT PLACEHOLDER — APPROVED STORY CONTENT PENDING\n\nThis single post-level story screen will present the featured Filipino hero's historical background, important contributions, and significance in Philippine history. Final educational text and artwork have not yet been approved and will replace this clearly labeled placeholder.",
		"character_reward": {
			"id": "level_1_hero_placeholder",
			"name": "Level 1 Hero (Placeholder)",
			"description": "Development placeholder awaiting approved hero content and portrait.",
			"portrait_path": "",
		},
		"gameplay_scene": "res://gameplay_placeholder.tscn",
		"implemented": true,
		"question_fixture_set": "level_1_test",
		"correct_answer_points": 100,
		"incorrect_answer_points": 0,
		"snake_score_penalty": 50,
		"allow_negative_score": false,
		"maximum_shield_charges": 0,
		"maximum_effect_depth": 12,
		"resolve_destination_effects": true,
		"board": {
			"columns": 10,
			"rows": 10,
			"exact_finish": true,
			"question_tiles": [6, 14, 23, 34, 46, 58, 67, 76, 84, 97],
			"special_tiles": {
				"bonus": [12, 35, 57, 77, 92],
				"shield": [8, 26, 45, 65, 85],
			},
			"snakes": {
				17: 7,
				54: 34,
				62: 19,
				64: 60,
				87: 24,
				93: 73,
				95: 75,
				99: 78,
			},
			"ladders": {
				4: 14,
				9: 31,
				20: 38,
				28: 84,
				40: 59,
				51: 67,
				63: 81,
				71: 91,
			},
		},
	},
	{
		"id": 2,
		"title": "Level 2",
		"description": "Unlocked after completing the full Level 1 learning sequence.",
		"implemented": false,
	},
	{"id": 3, "title": "Level 3", "description": "Future content.", "implemented": false},
	{"id": 4, "title": "Level 4", "description": "Future content.", "implemented": false},
	{"id": 5, "title": "Level 5", "description": "Future content.", "implemented": false},
	{"id": 6, "title": "Level 6", "description": "Future content.", "implemented": false},
]


static func get_levels() -> Array:
	return LEVELS.duplicate(true)


static func get_level(level_id: int) -> Dictionary:
	for level: Dictionary in LEVELS:
		if int(level.get("id", 0)) == level_id:
			return level.duplicate(true)
	return {}


static func has_level(level_id: int) -> bool:
	return not get_level(level_id).is_empty()


static func is_level_playable(level_id: int) -> bool:
	return bool(get_level(level_id).get("implemented", false))


static func get_character_reward(level_id: int) -> Dictionary:
	return get_level(level_id).get("character_reward", {}).duplicate(true)


static func get_all_characters() -> Array:
	var characters: Array = [{
		"id": "historyroll_explorer",
		"name": "HistoryRoll Explorer",
		"description": "Default playable explorer.",
		"portrait_path": "",
		"source_level": 0,
	}]
	for level: Dictionary in LEVELS:
		var reward: Dictionary = level.get("character_reward", {})
		if not reward.is_empty():
			var entry := reward.duplicate(true)
			entry["source_level"] = int(level.get("id", 0))
			characters.append(entry)
	return characters


static func get_next_level_id(level_id: int) -> int:
	var next_level_id := level_id + 1
	return next_level_id if has_level(next_level_id) else 0


static func get_highest_level_id() -> int:
	var highest_level_id := 0
	for level: Dictionary in LEVELS:
		highest_level_id = max(highest_level_id, int(level.get("id", 0)))
	return highest_level_id

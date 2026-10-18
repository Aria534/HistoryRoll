extends RefCounted

const LEVELS: Array = [
	{
		"id": 1,
		"title": "Level 1",
		"hero_name": "Hero to be confirmed",
		"portrait_path": "",
		"story_panels": [
			"PLACEHOLDER — HISTORICAL INTRODUCTION\n\nApproved educational story content has not been added yet.",
			"PLACEHOLDER — HISTORICAL CONTRIBUTIONS\n\nVerified information about this hero's contributions will appear here.",
		],
		"gameplay_scene": "res://gameplay_placeholder.tscn",
		"question_fixture_set": "level_1_test",
		"board": {
			"columns": 10,
			"rows": 10,
			"exact_finish": true,
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


static func get_next_level_id(level_id: int) -> int:
	var next_level_id := level_id + 1
	return next_level_id if has_level(next_level_id) else 0


static func get_highest_level_id() -> int:
	var highest_level_id := 0
	for level: Dictionary in LEVELS:
		highest_level_id = max(highest_level_id, int(level.get("id", 0)))
	return highest_level_id

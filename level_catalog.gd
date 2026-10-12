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
	},
]


static func get_levels() -> Array:
	return LEVELS.duplicate(true)


static func get_level(level_id: int) -> Dictionary:
	for level: Dictionary in LEVELS:
		if int(level.get("id", 0)) == level_id:
			return level.duplicate(true)
	return {}

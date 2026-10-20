extends RefCounted

const HeroDatabase = preload("res://hero_database.gd")

const LEVELS: Array = [
	{
		"id": 1,
		"title": "Level 1 - Filipino Heroes",
		"description": "Meet Lapulapu and learn about the defense of Mactan in 1521.",
		"educational_theme": "Filipino Heroes",
		"hero_id": "lapulapu",
		"gameplay_scene": "res://gameplay_placeholder.tscn",
		"implemented": true,
		"question_bank": "level_1_lapulapu",
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
		"title": "Level 2 - Philippine Revolution Heroes",
		"description": "Learn about Andres Bonifacio, the Katipunan, and the Philippine Revolution.",
		"educational_theme": "Philippine Revolution Heroes",
		"hero_id": "andres_bonifacio",
		"question_bank": "level_2_bonifacio",
		"implemented": false,
	},
	{
		"id": 3,
		"title": "Level 3 - National Heroes and Their Contributions",
		"description": "Study Jose Rizal's writings, reform work, and contribution to Filipino nationalism.",
		"educational_theme": "National Heroes and Their Contributions",
		"hero_id": "jose_rizal",
		"question_bank": "level_3_rizal",
		"implemented": false,
	},
	{
		"id": 4,
		"title": "Level 4 - Women Heroes",
		"description": "Discover Maria Josefa Gabriela Silang's leadership in the Ilocos resistance.",
		"educational_theme": "Women Heroes",
		"hero_id": "gabriela_silang",
		"question_bank": "level_4_gabriela_silang",
		"implemented": false,
	},
	{
		"id": 5,
		"title": "Level 5 - Heroes of Philippine Independence",
		"description": "Learn about Emilio Aguinaldo and the 1898 proclamation of independence.",
		"educational_theme": "Heroes of Philippine Independence",
		"hero_id": "emilio_aguinaldo",
		"question_bank": "level_5_aguinaldo",
		"implemented": false,
	},
	{
		"id": 6,
		"title": "Level 6 - Final Filipino Hero Challenge",
		"description": "Review the lives, contributions, and legacies of the five featured heroes.",
		"educational_theme": "Final Filipino Hero Challenge",
		"hero_id": "",
		"hero_name": "Mixed Review",
		"story_text": "The final challenge reviews five Filipino heroes and their different paths of service. Lapulapu defended Mactan in 1521; his death details are not reliably documented. Andres Bonifacio founded the Katipunan in 1892 and was executed in 1897. Jose Rizal's novels of 1887 and 1891 encouraged reform and nationhood before his execution in 1896. Maria Josefa Gabriela Silang led the Ilocos resistance in 1763 and was executed that same year. Emilio Aguinaldo proclaimed independence in 1898, became president of the First Philippine Republic, and died in 1964; the cited NHCP marker does not state a medical cause. Their stories show courage through leadership, writing, organization, and public service. Remembering both their achievements and their deaths helps us study history carefully, respectfully, and honestly.",
		"portrait_path": "",
		"question_bank": "level_6_mixed_review",
		"implemented": false,
	},
]


static func get_levels() -> Array:
	return LEVELS.duplicate(true)


static func get_level(level_id: int) -> Dictionary:
	for level: Dictionary in LEVELS:
		if int(level.get("id", 0)) == level_id:
			var result := level.duplicate(true)
			var hero_id := str(result.get("hero_id", ""))
			if not hero_id.is_empty():
				var hero := HeroDatabase.get_hero(hero_id)
				for key: Variant in hero:
					result[key] = hero[key]
				result["character_reward"] = _hero_to_character(hero)
			return result
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
	for hero: Dictionary in HeroDatabase.get_heroes():
		characters.append(_hero_to_character(hero))
	return characters


static func _hero_to_character(hero: Dictionary) -> Dictionary:
	if hero.is_empty():
		return {}
	return {
		"id": str(hero.get("hero_id", "")),
		"name": str(hero.get("hero_name", "Hero")),
		"description": str(hero.get("short_biography", "")),
		"portrait_path": str(hero.get("portrait_path", "")),
		"source_level": int(hero.get("associated_level", 0)),
		"educational_theme": str(hero.get("educational_theme", "")),
		"contribution": str(hero.get("contribution", "")),
		"contribution_year": str(hero.get("contribution_year", "")),
		"death_date": str(hero.get("death_date", "Unknown")),
		"cause_of_death": str(hero.get("cause_of_death", "Unknown")),
		"historical_legacy": str(hero.get("historical_legacy", "")),
		"references": hero.get("references", []).duplicate(true),
	}


static func get_next_level_id(level_id: int) -> int:
	var next_level_id := level_id + 1
	return next_level_id if has_level(next_level_id) else 0


static func get_highest_level_id() -> int:
	var highest_level_id := 0
	for level: Dictionary in LEVELS:
		highest_level_id = max(highest_level_id, int(level.get("id", 0)))
	return highest_level_id

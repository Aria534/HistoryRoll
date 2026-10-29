extends RefCounted

const HeroDatabase = preload("res://hero_database.gd")

# Bonus points remain zero until the designer approves a value.
const LEVELS: Array = [
	{"id":1,"title":"Level 1 - Lapulapu","description":"Learn about Lapulapu and the defense of Mactan.","educational_theme":"Lapulapu","hero_id":"lapulapu","waiting_hero_id":"andres_bonifacio","gameplay_scene":"res://gameplay_placeholder.tscn","implemented":true,"correct_answer_points":10,"incorrect_answer_penalty":2,"bonus_points":0,"allow_negative_score":false,"maximum_shield_charges":0,"maximum_effect_depth":12,"resolve_destination_effects":true,"question_bank_status":"development_content_15_of_50","board":{"columns":5,"rows":4,"exact_finish":true,"question_tiles":[],"special_tiles":{"bonus":[5],"shield":[15]},"snakes":{17:7,19:12},"ladders":{3:11,6:14,9:18}}},
	{"id":2,"title":"Level 2 - Andres Bonifacio","description":"Learn about Andres Bonifacio and the Katipunan.","educational_theme":"Andres Bonifacio","hero_id":"andres_bonifacio","waiting_hero_id":"jose_rizal","gameplay_scene":"res://gameplay_placeholder.tscn","implemented":true,"correct_answer_points":10,"incorrect_answer_penalty":2,"bonus_points":0,"allow_negative_score":false,"maximum_shield_charges":0,"maximum_effect_depth":12,"resolve_destination_effects":true,"question_bank_status":"development_content_15_of_50","board":{"columns":6,"rows":5,"exact_finish":true,"question_tiles":[],"special_tiles":{"bonus":[6],"shield":[18]},"snakes":{14:4,23:10,28:17},"ladders":{3:12,8:20,16:25,22:29}}},
	{"id":3,"title":"Level 3 - Jose Rizal","description":"Study Jose Rizal's writings and reform work.","educational_theme":"Jose Rizal","hero_id":"jose_rizal","waiting_hero_id":"antonio_luna","gameplay_scene":"res://gameplay_placeholder.tscn","implemented":true,"correct_answer_points":10,"incorrect_answer_penalty":2,"bonus_points":0,"allow_negative_score":false,"maximum_shield_charges":0,"maximum_effect_depth":12,"resolve_destination_effects":true,"question_bank_status":"development_content_15_of_50","board":{"columns":8,"rows":5,"exact_finish":true,"question_tiles":[],"special_tiles":{"bonus":[7,31],"shield":[14]},"snakes":{15:5,24:12,34:18,38:27},"ladders":{3:11,9:21,17:29,26:36}}},
	{"id":4,"title":"Level 4 - Antonio Luna","description":"Learn about General Antonio Luna's service to the Philippine Republic.","educational_theme":"Antonio Luna","hero_id":"antonio_luna","waiting_hero_id":"melchora_aquino","gameplay_scene":"res://gameplay_placeholder.tscn","implemented":true,"correct_answer_points":10,"incorrect_answer_penalty":2,"bonus_points":0,"allow_negative_score":false,"maximum_shield_charges":0,"maximum_effect_depth":12,"resolve_destination_effects":true,"question_bank_status":"development_placeholders_pending_50_approved_questions","board":{"columns":10,"rows":5,"exact_finish":true,"question_tiles":[],"special_tiles":{"bonus":[8,34],"shield":[21,43]},"snakes":{16:6,27:13,36:22,44:30,48:39},"ladders":{3:14,11:24,19:32,28:41,37:47}}},
	{"id":5,"title":"Level 5 - Melchora Aquino","description":"Learn how Melchora Aquino supported the Katipunan.","educational_theme":"Melchora Aquino","hero_id":"melchora_aquino","waiting_hero_id":"apolinario_mabini","gameplay_scene":"res://gameplay_placeholder.tscn","implemented":true,"correct_answer_points":10,"incorrect_answer_penalty":2,"bonus_points":0,"allow_negative_score":false,"maximum_shield_charges":0,"maximum_effect_depth":12,"resolve_destination_effects":true,"question_bank_status":"development_placeholders_pending_50_approved_questions","board":{"columns":10,"rows":10,"exact_finish":true,"question_tiles":[],"special_tiles":{"bonus":[12,48,84],"shield":[26,59,93]},"snakes":{17:7,34:15,54:31,67:45,87:62,98:78},"ladders":{4:14,9:29,22:41,38:58,63:81,72:91}}},
	{"id":6,"title":"Level 6 - Apolinario Mabini","description":"Learn about Apolinario Mabini's political thought and service.","educational_theme":"Apolinario Mabini","hero_id":"apolinario_mabini","waiting_hero_id":"","gameplay_scene":"res://gameplay_placeholder.tscn","implemented":true,"correct_answer_points":10,"incorrect_answer_penalty":2,"bonus_points":0,"allow_negative_score":false,"maximum_shield_charges":0,"maximum_effect_depth":12,"resolve_destination_effects":true,"question_bank_status":"development_placeholders_pending_50_approved_questions","board":{"columns":10,"rows":10,"exact_finish":true,"question_tiles":[],"special_tiles":{"bonus":[9,40,69],"shield":[24,53,88]},"snakes":{18:6,32:12,49:28,62:39,76:55,91:70,99:79},"ladders":{3:20,14:35,27:46,44:66,58:82,73:96}}},
]

static func get_levels() -> Array: return LEVELS.duplicate(true)

static func get_level(level_id: int) -> Dictionary:
	for level: Dictionary in LEVELS:
		if int(level.get("id", 0)) == level_id:
			var result := level.duplicate(true)
			var hero := HeroDatabase.get_hero(str(result.get("hero_id", "")))
			for key: Variant in hero: result[key] = hero[key]
			result["character_reward"] = _hero_to_character(hero)
			var waiting := HeroDatabase.get_hero(str(result.get("waiting_hero_id", "")))
			result["waiting_hero_name"] = str(waiting.get("hero_name", "FINAL TROPHY"))
			return result
	return {}

static func has_level(level_id: int) -> bool: return not get_level(level_id).is_empty()
static func is_level_playable(level_id: int) -> bool: return bool(get_level(level_id).get("implemented", false))
static func get_character_reward(level_id: int) -> Dictionary: return get_level(level_id).get("character_reward", {}).duplicate(true)

static func get_all_characters() -> Array:
	var characters: Array = []
	for hero: Dictionary in HeroDatabase.get_heroes(): characters.append(_hero_to_character(hero))
	return characters

static func _hero_to_character(hero: Dictionary) -> Dictionary:
	if hero.is_empty(): return {}
	return {"id":str(hero.get("hero_id","")),"name":str(hero.get("hero_name","Hero")),"description":str(hero.get("short_biography","")),"portrait_path":str(hero.get("portrait_path","")),"source_level":int(hero.get("associated_level",0)),"educational_theme":str(hero.get("educational_theme","")),"contribution":str(hero.get("contribution","")),"contribution_year":str(hero.get("contribution_year","")),"death_date":str(hero.get("death_date","Unknown")),"cause_of_death":str(hero.get("cause_of_death","Unknown")),"historical_legacy":str(hero.get("historical_legacy","")),"references":hero.get("references",[]).duplicate(true)}

static func get_next_level_id(level_id: int) -> int: return level_id + 1 if has_level(level_id + 1) else 0
static func get_highest_level_id() -> int: return 6

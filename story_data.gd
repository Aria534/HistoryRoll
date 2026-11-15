extends RefCounted

const PLACEHOLDER_BACKGROUND := "res://assets/background/Dreamy Philippine Bay Boardwalk.png"
const LAPULAPU_REFERENCE := "res://assets/story/lapulapu/lapulapu_reference.png"
const SCENE_DURATION := 9.0

static var STORIES: Dictionary = {
	1: {
		"hero_id": "lapulapu", "hero_name": "Lapulapu", "title": "LAPULAPU - DEFENDER OF MACTAN",
		"portrait_path": LAPULAPU_REFERENCE,
		"ending_contribution": "Defended Mactan and became an enduring symbol of resistance to foreign domination.",
		"scenes": [
			_cinematic_scene("Mactan Before Conflict", "Lapulapu was one of the leaders of Mactan, where his people lived independently.", "Lapulapu was one of the leaders of Mactan.", 9.0, "res://assets/story/lapulapu/shot_01_mactan_sunrise.png", "res://assets/story/lapulapu/audio/shot_01_narration.wav", "pan_right", "ocean", false, false),
			_cinematic_scene("Arrival of Magellan", "In 1521, Ferdinand Magellan's expedition arrived in the islands.", "In 1521, Magellan's expedition arrived in the islands.", 9.0, "res://assets/story/lapulapu/shot_02_expedition_arrives.png", "res://assets/story/lapulapu/audio/shot_02_narration.wav", "pan_left", "ocean", false, false),
			_cinematic_scene("Lapulapu Refuses", "Lapulapu refused to submit to foreign authority and chose to defend Mactan.", "Lapulapu chose to defend Mactan.", 9.0, "res://assets/story/lapulapu/shot_03_defense.png", "res://assets/story/lapulapu/audio/shot_03_narration.wav", "character_enter", "ambient", false, true),
			_cinematic_scene("Battle of Mactan", "On April 27, 1521, Lapulapu's warriors fought Magellan's forces.", "April 27, 1521 - Battle of Mactan", 9.0, "res://assets/story/lapulapu/shot_04_battle.png", "res://assets/story/lapulapu/audio/shot_04_narration.wav", "battle", "battle", true, false),
			_cinematic_scene("Retreat", "Magellan was killed during the battle, and his remaining forces withdrew.", "Magellan was killed, and his forces withdrew.", 9.0, "res://assets/story/lapulapu/shot_05_retreat.png", "res://assets/story/lapulapu/audio/shot_05_narration.wav", "zoom_out", "ocean", false, false),
			_cinematic_scene("Contribution and Legacy", "Lapulapu's contribution was his defense of Mactan. He became a symbol of courage and resistance.", "Lapulapu became a symbol of courage and resistance.", 9.0, "res://assets/story/lapulapu/shot_06_legacy.png", "res://assets/story/lapulapu/audio/shot_06_narration.wav", "legacy", "ocean", false, true),
		],
	},
	2: {
		"hero_id": "andres_bonifacio", "hero_name": "Andres Bonifacio", "title": "ANDRES BONIFACIO - REVOLUTIONARY LEADER",
		"portrait_path": "res://assets/gameplay_chibis/bonifacio_chibi.png",
		"ending_contribution": "Helped organize the Katipunan and helped launch the revolution for independence.",
		"scenes": [
			_hero_scene("andres_bonifacio", 1, "Colonial Hardship", "Andres Bonifacio saw the hardships and injustices experienced by Filipinos under Spanish rule.", "pan_right", "ambient"),
			_hero_scene("andres_bonifacio", 2, "A Hope for Freedom", "He believed that Filipinos deserved freedom and the right to govern themselves.", "zoom_in", "ambient"),
			_hero_scene("andres_bonifacio", 3, "The Katipunan", "In 1892, Bonifacio helped establish the Katipunan.", "pan_left", "fire"),
			_hero_scene("andres_bonifacio", 4, "Organizing Members", "He helped unite Filipinos and prepared them to fight for independence.", "zoom_out", "ambient"),
			_hero_scene("andres_bonifacio", 5, "The Revolution Begins", "In 1896, the Philippine Revolution began, and Bonifacio became one of its important leaders.", "battle", "battle", true),
			_hero_scene("andres_bonifacio", 6, "Contribution and Legacy", "Bonifacio's contribution was organizing the Katipunan and helping begin the struggle for Philippine independence.", "legacy", "ambient"),
		],
	},
	3: {
		"hero_id": "jose_rizal", "hero_name": "Jose Rizal", "title": "JOSE RIZAL - THE POWER OF THE PEN",
		"portrait_path": "res://assets/gameplay_chibis/rizal_chibi.png",
		"ending_contribution": "Used his writings and ideas to inspire nationalism and reform.",
		"scenes": [
			_hero_scene("jose_rizal", 1, "Education", "Jose Rizal believed that education and knowledge could help improve society.", "zoom_out", "writing"),
			_hero_scene("jose_rizal", 2, "Witnessing Injustice", "He saw the injustices experienced by Filipinos under Spanish colonial rule.", "pan_left", "ambient"),
			_hero_scene("jose_rizal", 3, "Noli Me Tangere", "He wrote Noli Me Tangere to expose abuses and problems in society.", "zoom_in", "writing"),
			_hero_scene("jose_rizal", 4, "El Filibusterismo", "He later wrote El Filibusterismo and continued calling for reform and dignity.", "pan_right", "writing"),
			_hero_scene("jose_rizal", 5, "Sacrifice", "Rizal was executed on December 30, 1896, but his ideas continued to inspire Filipinos.", "darken", "ambient"),
			_hero_scene("jose_rizal", 6, "Contribution and Legacy", "Rizal's contribution was using his writings to awaken Filipino nationalism and encourage reform.", "legacy", "writing"),
		],
	},
	4: {
		"hero_id": "antonio_luna", "hero_name": "Antonio Luna", "title": "ANTONIO LUNA - DEFENDER OF THE REPUBLIC",
		"portrait_path": "res://assets/gameplay_chibis/luna_chibi.png",
		"ending_contribution": "Helped organize and strengthen the revolutionary army and the defense of the Republic.",
		"scenes": [
			_hero_scene("antonio_luna", 1, "Scholar and Scientist", "Antonio Luna was a scientist, writer, and scholar before becoming a military leader.", "zoom_out", "writing"),
			_hero_scene("antonio_luna", 2, "Joining the Cause", "He later dedicated his knowledge and abilities to the cause of Philippine independence.", "pan_right", "ambient"),
			_hero_scene("antonio_luna", 3, "Military Planning", "Luna became known for careful military planning and discipline.", "zoom_in", "writing"),
			_hero_scene("antonio_luna", 4, "Army Discipline", "He worked to organize and strengthen the Filipino army.", "pan_left", "battle"),
			_hero_scene("antonio_luna", 5, "Defending the Republic", "He helped defend the Philippine Republic during the Philippine-American War.", "battle", "battle", true),
			_hero_scene("antonio_luna", 6, "Contribution and Legacy", "Antonio Luna's contribution was strengthening the revolutionary army through discipline, strategy, and leadership.", "legacy", "ambient"),
		],
	},
	5: {
		"hero_id": "melchora_aquino", "hero_name": "Melchora Aquino", "title": "MELCHORA AQUINO - MOTHER OF THE REVOLUTION",
		"portrait_path": "res://assets/gameplay_chibis/aquino_chibi.png",
		"ending_contribution": "Supported the Revolution by helping Katipuneros with food, shelter, and care.",
		"scenes": [
			_hero_scene("melchora_aquino", 1, "Community Life", "Melchora Aquino, also known as Tandang Sora, lived a simple life before becoming an important supporter of the Revolution.", "zoom_out", "ambient"),
			_hero_scene("melchora_aquino", 2, "Welcoming Revolutionaries", "When Filipino revolutionaries needed support, she welcomed them.", "pan_left", "ambient"),
			_hero_scene("melchora_aquino", 3, "Food, Shelter, and Care", "She provided food, shelter, and care for tired and wounded revolutionaries.", "zoom_in", "fire"),
			_hero_scene("melchora_aquino", 4, "Courage in Danger", "Helping the Katipuneros placed her own safety at risk.", "pan_right", "ambient"),
			_hero_scene("melchora_aquino", 5, "Arrest and Exile", "She was arrested and later exiled because of her support for the Revolution.", "darken", "ocean"),
			_hero_scene("melchora_aquino", 6, "Contribution and Legacy", "Melchora Aquino's contribution was supporting the Revolution through care, courage, and compassion.", "legacy", "ambient"),
		],
	},
	6: {
		"hero_id": "apolinario_mabini", "hero_name": "Apolinario Mabini", "title": "APOLINARIO MABINI - MIND OF THE REVOLUTION",
		"portrait_path": "res://assets/gameplay_chibis/mabini_chibi.png",
		"ending_contribution": "Helped shape the revolutionary government through law, leadership, and political ideas.",
		"scenes": [
			_hero_scene("apolinario_mabini", 1, "Education", "Apolinario Mabini worked hard to gain an education and became one of the country's important political thinkers.", "zoom_out", "writing"),
			_hero_scene("apolinario_mabini", 2, "Strength of Mind", "Even after becoming paralyzed, Mabini continued to serve the country through his ideas.", "pan_right", "writing"),
			_hero_scene("apolinario_mabini", 3, "Adviser Role", "He became an important adviser during the revolutionary period.", "zoom_in", "ambient"),
			_hero_scene("apolinario_mabini", 4, "Building Government", "He helped guide the government of the First Philippine Republic.", "pan_left", "writing"),
			_hero_scene("apolinario_mabini", 5, "Exile", "Even after facing imprisonment and exile, Mabini remained committed to Philippine independence.", "darken", "ocean"),
			_hero_scene("apolinario_mabini", 6, "Contribution and Legacy", "Mabini's contribution was helping shape the government and political principles of the First Philippine Republic.", "legacy", "writing"),
		],
	},
}


static func _hero_scene(hero_id: String, scene_number: int, scene_title: String, narration: String, motion: String, environment: String, shake := false) -> Dictionary:
	var base_path := "res://assets/story/%s" % hero_id
	return {
		"title": scene_title,
		"narration": narration,
		"subtitle": narration,
		"duration": SCENE_DURATION,
		"background_path": "%s/shot_%02d.png" % [base_path, scene_number],
		"midground_path": "",
		"foreground_path": "",
		"effects_path": "",
		"character_path": "",
		"show_character": false,
		"voice_path": "%s/audio/shot_%02d_narration.wav" % [base_path, scene_number],
		"music_path": "",
		"sfx_path": "",
		"motion": motion,
		"environment": environment,
		"shake": shake,
		"placeholder_visual": false,
	}


static func _cinematic_scene(scene_title: String, narration: String, subtitle: String, duration: float, background_path: String, voice_path: String, motion: String, environment: String, shake: bool, show_character: bool) -> Dictionary:
	return {
		"title": scene_title,
		"narration": narration,
		"subtitle": subtitle,
		"duration": duration,
		"background_path": background_path,
		"midground_path": "",
		"foreground_path": "",
		"effects_path": "",
		"character_path": LAPULAPU_REFERENCE if show_character else "",
		"show_character": show_character,
		"voice_path": voice_path,
		"music_path": "",
		"sfx_path": "",
		"motion": motion,
		"environment": environment,
		"shake": shake,
		"placeholder_visual": false,
	}


static func _scene(scene_title: String, subtitle: String, motion: String, shake := false, character_path := "") -> Dictionary:
	var environment := "ambient"
	var normalized_title := scene_title.to_lower()
	if normalized_title.contains("mactan") or normalized_title.contains("expedition") or normalized_title.contains("retreat"):
		environment = "ocean"
	elif normalized_title.contains("battle") or normalized_title.contains("revolution") or normalized_title.contains("training") or normalized_title.contains("defend"):
		environment = "battle"
	elif normalized_title.contains("writing") or normalized_title.contains("noli") or normalized_title.contains("filibusterismo") or normalized_title.contains("scholar") or normalized_title.contains("planning") or normalized_title.contains("republic"):
		environment = "writing"
	elif normalized_title.contains("food") or normalized_title.contains("tandang") or normalized_title.contains("katipunan"):
		environment = "fire"
	return {
		"title": scene_title,
		"subtitle": subtitle,
		"duration": SCENE_DURATION,
		"background_path": PLACEHOLDER_BACKGROUND,
		"midground_path": "",
		"foreground_path": "",
		"effects_path": "",
		"character_path": character_path,
		"voice_path": "",
		"music_path": "",
		"sfx_path": "",
		"motion": motion,
		"environment": environment,
		"shake": shake,
		"placeholder_visual": true,
	}


static func get_story(level_id: int) -> Dictionary:
	if not STORIES.has(level_id):
		return {}
	return (STORIES[level_id] as Dictionary).duplicate(true)


static func get_total_duration(level_id: int) -> float:
	var total := 0.0
	for scene: Dictionary in get_story(level_id).get("scenes", []):
		total += float(scene.get("duration", 0.0))
	return total

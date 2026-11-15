extends RefCounted

const PLACEHOLDER_BACKGROUND := "res://assets/background/Dreamy Philippine Bay Boardwalk.png"
const SCENE_DURATION := 9.0

static var STORIES: Dictionary = {
	1: {
		"hero_id": "lapulapu", "hero_name": "Lapulapu", "title": "LAPULAPU - DEFENDER OF MACTAN",
		"portrait_path": "res://assets/gameplay_chibis/lapulapu_chibi.png",
		"scenes": [
			_scene("Early Mactan", "Lapulapu was one of the leaders of Mactan, a community that valued its independence.", "pan_right"),
			_scene("The Expedition Arrives", "In 1521, Ferdinand Magellan arrived in the islands and formed alliances with some local rulers.", "zoom_in"),
			_scene("Defending Mactan", "Lapulapu refused to submit and chose to defend Mactan and his people.", "character_enter"),
			_scene("Battle of Mactan", "On April 27, 1521, Lapulapu's warriors fought Magellan's forces in the Battle of Mactan.", "battle", true),
			_scene("The Expedition Retreats", "Magellan was killed during the battle, and his forces withdrew.", "pan_left"),
			_scene("A Lasting Symbol", "Lapulapu's contribution was his defense of Mactan. He became a lasting symbol of courage and resistance to foreign domination.", "legacy"),
		],
	},
	2: {
		"hero_id": "andres_bonifacio", "hero_name": "Andres Bonifacio", "title": "ANDRES BONIFACIO - REVOLUTIONARY LEADER",
		"portrait_path": "res://assets/gameplay_chibis/bonifacio_chibi.png",
		"scenes": [
			_scene("Colonial Hardship", "During Spanish colonial rule, many Filipinos experienced hardship, inequality, and injustice.", "pan_right"),
			_scene("A Hope for Freedom", "Andres Bonifacio believed that Filipinos deserved freedom and the right to govern themselves.", "zoom_in"),
			_scene("The Katipunan", "In 1892, Bonifacio helped establish the Katipunan, a secret organization seeking Philippine independence.", "character_enter"),
			_scene("Uniting Filipinos", "He helped organize and inspire Filipinos to unite and fight against colonial rule.", "pan_left"),
			_scene("The Revolution Begins", "In 1896, the Revolution began, and Bonifacio became one of its most important leaders.", "battle", true),
			_scene("The Supremo's Legacy", "Bonifacio's contribution was helping organize the Katipunan and helping begin the fight for Philippine independence.", "legacy", false, "res://assets/gameplay_chibis/bonifacio_wave.png"),
		],
	},
	3: {
		"hero_id": "jose_rizal", "hero_name": "Jose Rizal", "title": "JOSE RIZAL - THE POWER OF THE PEN",
		"portrait_path": "res://assets/gameplay_chibis/rizal_chibi.png",
		"scenes": [
			_scene("Learning and Knowledge", "Jose Rizal believed that education and knowledge could help improve society.", "zoom_out"),
			_scene("Speaking Against Injustice", "He saw the problems and injustices experienced by Filipinos under Spanish colonial rule.", "pan_left"),
			_scene("Noli Me Tangere", "In 1887, Rizal published Noli Me Tangere, exposing abuses and problems in colonial society.", "character_enter"),
			_scene("El Filibusterismo", "He later wrote El Filibusterismo and continued calling for reform and greater dignity for Filipinos.", "pan_right"),
			_scene("Sacrifice", "Rizal was executed on December 30, 1896, but his ideas continued to inspire Filipinos.", "darken"),
			_scene("The Power of Ideas", "Rizal's contribution was using education and writing to awaken Filipino nationalism and encourage reform.", "legacy", false, "res://assets/gameplay_chibis/rizal_wave.png"),
		],
	},
	4: {
		"hero_id": "antonio_luna", "hero_name": "Antonio Luna", "title": "ANTONIO LUNA - DEFENDER OF THE REPUBLIC",
		"portrait_path": "res://assets/gameplay_chibis/luna_chibi.png",
		"scenes": [
			_scene("Scholar and Scientist", "Antonio Luna was a scientist, writer, and scholar before becoming a military leader.", "zoom_out"),
			_scene("Serving the Filipino Cause", "As the struggle for independence continued, Luna dedicated his knowledge and skills to the country.", "pan_right"),
			_scene("Military Planning", "He worked to improve the organization and strategy of the Filipino army.", "character_enter"),
			_scene("Training and Discipline", "Luna emphasized discipline, training, and careful military planning.", "pan_left"),
			_scene("Defending the Republic", "He helped lead the defense of the Philippine Republic during the Philippine-American War.", "battle", true),
			_scene("Defender of the Republic", "Antonio Luna's contribution was helping organize and strengthen the revolutionary army and its defense of the Republic.", "legacy", false, "res://assets/gameplay_chibis/luna_wave.png"),
		],
	},
	5: {
		"hero_id": "melchora_aquino", "hero_name": "Melchora Aquino", "title": "MELCHORA AQUINO - MOTHER OF THE REVOLUTION",
		"portrait_path": "res://assets/gameplay_chibis/aquino_chibi.png",
		"scenes": [
			_scene("Tandang Sora", "Melchora Aquino, known as Tandang Sora, lived a simple life before becoming an important supporter of the Revolution.", "zoom_out"),
			_scene("Helping the Katipunan", "When the Revolution began, members of the Katipunan came to her for help.", "pan_left"),
			_scene("Food, Shelter, and Care", "She provided food, shelter, and care for wounded and tired revolutionaries.", "character_enter"),
			_scene("Courage in Danger", "Helping the Katipuneros placed her own safety at risk.", "zoom_in"),
			_scene("Arrest and Exile", "She was arrested and later exiled because of her support for the revolutionaries.", "darken"),
			_scene("Mother of the Revolution", "Melchora Aquino's contribution was supporting the Revolution through food, shelter, care, courage, and compassion.", "legacy", false, "res://assets/gameplay_chibis/aquino_wave.png"),
		],
	},
	6: {
		"hero_id": "apolinario_mabini", "hero_name": "Apolinario Mabini", "title": "APOLINARIO MABINI - MIND OF THE REVOLUTION",
		"portrait_path": "res://assets/gameplay_chibis/mabini_chibi.png",
		"scenes": [
			_scene("A Determined Student", "Apolinario Mabini worked hard to study law and became one of the country's great political thinkers.", "zoom_out"),
			_scene("Strength of Mind", "Even after becoming paralyzed, Mabini continued to study, write, and serve the country.", "pan_right"),
			_scene("Adviser to the Revolution", "He became an important adviser to Emilio Aguinaldo during the revolutionary period.", "character_enter"),
			_scene("Guiding the Republic", "He helped guide the government of the First Philippine Republic and promoted responsible leadership.", "pan_left"),
			_scene("Principles in Exile", "Even when imprisoned and exiled, Mabini remained committed to Philippine independence.", "darken"),
			_scene("Mind of the Revolution", "Mabini's contribution was helping shape the government, laws, and political principles of the First Philippine Republic.", "legacy", false, "res://assets/gameplay_chibis/mabini_wave.png"),
		],
	},
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

extends RefCounted

# Development-only fixtures. These are not an approved final question bank.
const QUESTIONS: Array = [
	{
		"question_id": "TEST-L1-001",
		"level": 1,
		"hero_id": "jose_rizal",
		"question_text": "TEST FIXTURE: Which novel was written by José Rizal?",
		"choices": ["Noli Me Tangere", "Florante at Laura", "Ibong Adarna", "Biag ni Lam-ang"],
		"correct_index": 0,
		"explanation": "Test fixture: José Rizal wrote Noli Me Tangere.",
	},
	{
		"question_id": "TEST-L1-002",
		"level": 1,
		"hero_id": "jose_rizal",
		"question_text": "TEST FIXTURE: Who wrote El Filibusterismo?",
		"choices": ["Andrés Bonifacio", "José Rizal", "Emilio Aguinaldo", "Apolinario Mabini"],
		"correct_index": 1,
		"explanation": "Test fixture: El Filibusterismo was written by José Rizal.",
	},
	{
		"question_id": "TEST-L1-003",
		"level": 1,
		"hero_id": "andres_bonifacio",
		"question_text": "TEST FIXTURE: Andrés Bonifacio is closely associated with which revolutionary society?",
		"choices": ["La Liga Filipina", "Katipunan", "Propaganda Movement", "Malolos Congress"],
		"correct_index": 1,
		"explanation": "Test fixture: Andrés Bonifacio was a leader of the Katipunan.",
	},
	{
		"question_id": "TEST-L1-004",
		"level": 1,
		"hero_id": "emilio_aguinaldo",
		"question_text": "TEST FIXTURE: Philippine independence was declared in Kawit, Cavite on which date?",
		"choices": ["June 12, 1898", "August 26, 1896", "December 30, 1896", "July 4, 1946"],
		"correct_index": 0,
		"explanation": "Test fixture: Philippine independence was declared on June 12, 1898.",
	},
]


static func get_questions_for_level(level_id: int) -> Array:
	var matches: Array = []
	for question: Dictionary in QUESTIONS:
		if int(question.get("level", 0)) == level_id:
			matches.append(question.duplicate(true))
	return matches

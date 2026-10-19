extends RefCounted

# Development-only fixtures. These are not an approved final question bank.
const QUESTIONS: Array = [
	{
		"question_id": "TEST-L1-REG-001",
		"question_type": "regular",
		"level": 1,
		"hero_id": "jose_rizal",
		"question_text": "TEST FIXTURE: Which novel was written by Jose Rizal?",
		"choices": ["Noli Me Tangere", "Florante at Laura", "Ibong Adarna", "Biag ni Lam-ang"],
		"correct_index": 0,
		"explanation": "Test fixture: Jose Rizal wrote Noli Me Tangere.",
	},
	{
		"question_id": "TEST-L1-REG-002",
		"question_type": "regular",
		"level": 1,
		"hero_id": "jose_rizal",
		"question_text": "TEST FIXTURE: Who wrote El Filibusterismo?",
		"choices": ["Andres Bonifacio", "Jose Rizal", "Emilio Aguinaldo", "Apolinario Mabini"],
		"correct_index": 1,
		"explanation": "Test fixture: El Filibusterismo was written by Jose Rizal.",
	},
	{
		"question_id": "TEST-L1-REG-003",
		"question_type": "regular",
		"level": 1,
		"hero_id": "andres_bonifacio",
		"question_text": "TEST FIXTURE: Andres Bonifacio is closely associated with which revolutionary society?",
		"choices": ["La Liga Filipina", "Katipunan", "Propaganda Movement", "Malolos Congress"],
		"correct_index": 1,
		"explanation": "Test fixture: Andres Bonifacio was a leader of the Katipunan.",
	},
	{
		"question_id": "TEST-L1-REG-004",
		"question_type": "regular",
		"level": 1,
		"hero_id": "emilio_aguinaldo",
		"question_text": "TEST FIXTURE: Philippine independence was declared in Kawit, Cavite on which date?",
		"choices": ["June 12, 1898", "August 26, 1896", "December 30, 1896", "July 4, 1946"],
		"correct_index": 0,
		"explanation": "Test fixture: Philippine independence was declared on June 12, 1898.",
	},
	{
		"question_id": "TEST-L1-BONUS-001",
		"question_type": "bonus",
		"level": 1,
		"hero_id": "jose_rizal",
		"question_text": "TEST BONUS FIXTURE: In which place was Jose Rizal exiled?",
		"choices": ["Dapitan", "Kawit", "Malolos", "Tondo"],
		"correct_index": 0,
		"explanation": "Test fixture: Jose Rizal was exiled in Dapitan.",
	},
	{
		"question_id": "TEST-L1-BONUS-002",
		"question_type": "bonus",
		"level": 1,
		"hero_id": "andres_bonifacio",
		"question_text": "TEST BONUS FIXTURE: What title is commonly associated with Andres Bonifacio?",
		"choices": ["The Great Plebeian", "The Sublime Paralytic", "Brains of the Revolution", "Hero of Tirad Pass"],
		"correct_index": 0,
		"explanation": "Test fixture: Andres Bonifacio is commonly called The Great Plebeian.",
	},
]


static func get_questions_for_level(level_id: int, question_type: String = "regular") -> Array:
	var matches: Array = []
	for question: Dictionary in QUESTIONS:
		if int(question.get("level", 0)) == level_id and str(question.get("question_type", "regular")) == question_type:
			matches.append(question.duplicate(true))
	return matches

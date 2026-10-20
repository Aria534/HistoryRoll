extends RefCounted

# Source-reviewed offline question profiles. Each fact produces one regular
# question, while alternate wording supplies five more regular and five bonus
# questions per hero level. Level 6 mixes the five featured heroes.
const PROFILES: Dictionary = {
	1: {
		"hero_id": "lapulapu",
		"facts": [
			["Who is the featured hero of Level 1?", "Which leader is remembered for defending Mactan in 1521?", "Lapulapu", ["Andres Bonifacio", "Jose Rizal", "Emilio Aguinaldo"], "Lapulapu led the defense of Mactan in 1521."],
			["Where did Lapulapu and his warriors fight Magellan's expedition?", "The 1521 battle led by Lapulapu happened on which island?", "Mactan", ["Corregidor", "Palawan", "Mindoro"], "The Battle of Mactan took place on Mactan island."],
			["When did the Battle of Mactan take place?", "Which date is connected with Lapulapu's defense of Mactan?", "27 April 1521", ["12 June 1898", "30 December 1896", "7 July 1892"], "The Battle of Mactan took place on 27 April 1521."],
			["Whose expedition was defeated at the Battle of Mactan?", "Lapulapu's forces resisted an expedition led by whom?", "Ferdinand Magellan", ["Miguel Lopez de Legazpi", "Andres Bonifacio", "Jose Rizal"], "Ferdinand Magellan led the expedition defeated at Mactan."],
			["What did Lapulapu defend against Magellan's claim of foreign authority?", "Why is Lapulapu remembered as a defender of independence?", "The freedom of Mactan", ["A Spanish trading company", "The Malolos Congress", "A foreign military base"], "Lapulapu defended Mactan's freedom and refused foreign authority."],
			["What happened to Ferdinand Magellan during the Battle of Mactan?", "Which outcome is supported by the Mactan historical marker?", "He was killed in the battle", ["He became ruler of Mactan", "He joined Lapulapu", "He returned to Spain unharmed"], "Magellan was killed during the encounter with Lapulapu's warriors."],
			["How does the NHCP marker describe Lapulapu's position in Mactan?", "Which statement about Lapulapu is historically careful?", "He was one of Mactan's leaders", ["He was president of the Philippines", "He founded the Katipunan", "He wrote Noli Me Tangere"], "The NHCP marker identifies Lapulapu as one of the leaders of Mactan."],
			["What does Lapulapu's legacy mainly represent?", "Lapulapu remains a symbol of which value?", "Courage and resistance to foreign rule", ["Colonial taxation", "Foreign conquest", "Royal succession in Spain"], "Lapulapu is remembered for courage and resistance to foreign control."],
			["What is reliably known about Lapulapu's death date?", "Why does HistoryRoll list Lapulapu's death date as Unknown?", "It is not reliably documented", ["It was 27 April 1521", "It was 12 June 1898", "It was 10 May 1897"], "Reliable surviving records do not establish Lapulapu's death date."],
			["Who completed the first circumnavigation after Magellan's death?", "Which navigator brought the Victoria back to Spain in 1522?", "Juan Sebastian Elcano", ["Lapulapu", "Jose Rizal", "Diego Silang"], "Juan Sebastian Elcano commanded the Victoria on the voyage back to Spain."],
		],
	},
	2: {
		"hero_id": "andres_bonifacio",
		"facts": [
			["Who founded the revolutionary Katipunan?", "Which hero became the Supremo of the Katipunan?", "Andres Bonifacio", ["Jose Rizal", "Lapulapu", "Emilio Aguinaldo"], "Andres Bonifacio founded and led the Katipunan."],
			["When was the Katipunan founded?", "Which date marks the founding of the Katipunan?", "7 July 1892", ["27 April 1521", "12 June 1898", "30 December 1896"], "The Katipunan was founded on 7 July 1892."],
			["What title is closely associated with Andres Bonifacio?", "What did members call Bonifacio as leader of the Katipunan?", "Supremo", ["Governor-General", "Datu", "Illustrado"], "Bonifacio is remembered as the Supremo of the Katipunan."],
			["Which movement did Bonifacio help begin in August 1896?", "Bonifacio led the opening of which struggle against Spain?", "The Philippine Revolution", ["The first circumnavigation", "The Ilocos Revolt of 1762", "The declaration of 1946"], "Bonifacio helped lead the Philippine Revolution beginning in 1896."],
			["Where was Andres Bonifacio born?", "Which Manila district was Bonifacio's birthplace?", "Tondo", ["Kawit", "Dapitan", "Mactan"], "Bonifacio was born in Tondo, Manila."],
			["What was the main goal of the Katipunan?", "What did the Katipunan seek for the Philippines?", "Independence from Spain", ["Rule by Magellan", "A return to colonial control", "A Spanish royal title"], "The Katipunan sought an independent Philippines."],
			["Which place did Bonifacio's forces attack on 30 August 1896?", "The 1896 attack on the Spanish powder magazine happened at which place?", "San Juan del Monte", ["Mactan", "Bagumbayan", "Palanan"], "Bonifacio led an attack at San Juan del Monte on 30 August 1896."],
			["When did Andres Bonifacio die?", "Which date is recorded for Bonifacio's execution?", "10 May 1897", ["20 September 1763", "6 February 1964", "30 December 1896"], "Bonifacio was executed on 10 May 1897."],
			["How did Andres Bonifacio die?", "Which statement correctly describes Bonifacio's death?", "He was executed by shooting after a military trial", ["He died at the Battle of Mactan", "He died of an undocumented illness", "He was executed at Bagumbayan in 1896"], "Bonifacio was tried by a military court and shot at Mount Buntis."],
			["What lasting title recognizes Bonifacio's revolutionary role?", "Bonifacio is often honored as the father of what event?", "Father of the Philippine Revolution", ["Father of the first circumnavigation", "Founder of the First Republic", "Author of El Filibusterismo"], "Bonifacio is remembered as the Father of the Philippine Revolution."],
		],
	},
	3: {
		"hero_id": "jose_rizal",
		"facts": [
			["Which hero wrote Noli Me Tangere and El Filibusterismo?", "Who used novels to expose abuses under Spanish colonial rule?", "Jose Rizal", ["Andres Bonifacio", "Lapulapu", "Emilio Aguinaldo"], "Jose Rizal wrote both novels."],
			["When was Noli Me Tangere published?", "Which year is linked to Rizal's Noli Me Tangere?", "1887", ["1521", "1763", "1898"], "Noli Me Tangere was published in 1887."],
			["When was El Filibusterismo published?", "Which year is linked to Rizal's El Filibusterismo?", "1891", ["1863", "1896", "1901"], "El Filibusterismo was published in 1891."],
			["What problem did Rizal's novels expose?", "What did Rizal criticize through his writing?", "Colonial oppression and abuses", ["The defense of Mactan", "The first circumnavigation", "The making of the Philippine flag"], "Rizal's novels described colonial oppression and abuses."],
			["What kind of change did Rizal publicly advocate?", "Which method best describes Rizal's reform advocacy?", "Peaceful reform", ["Foreign conquest", "Personal rule as king", "Control by another colony"], "Rizal advocated nonviolent reform and equal treatment."],
			["When was Jose Rizal executed?", "Which date is observed in memory of Rizal's martyrdom?", "30 December 1896", ["10 May 1897", "12 June 1898", "20 September 1763"], "Rizal was executed on 30 December 1896."],
			["Where was Jose Rizal executed?", "Bagumbayan, the site of Rizal's execution, is now associated with which city?", "Manila", ["Cebu", "Vigan", "Kawit"], "Rizal was executed at Bagumbayan in Manila."],
			["How did Jose Rizal die?", "Which statement correctly describes Rizal's death?", "He was executed by firing squad", ["He died in the Battle of Mactan", "He died at Veterans Memorial Hospital", "His death is not documented"], "Spanish colonial authorities executed Rizal by firing squad."],
			["What did Rizal's martyrdom help strengthen?", "Rizal's writings and death inspired a stronger sense of what?", "Filipino nationhood", ["Spanish royal power", "European expansion", "Colonial division"], "Rizal's martyrdom strengthened Filipino nationhood."],
			["Which profession was Jose Rizal trained in?", "Besides being a writer, Rizal practiced which profession?", "Physician", ["Ship captain", "Governor-General", "Military judge"], "Rizal was a physician as well as a writer and educator."],
		],
	},
	4: {
		"hero_id": "gabriela_silang",
		"facts": [
			["Who continued the Ilocos revolt after Diego Silang's assassination?", "Which woman led the Ilocos resistance in 1763?", "Maria Josefa Gabriela Silang", ["Gregoria de Jesus", "Marcela Agoncillo", "Melchora Aquino"], "Gabriela Silang continued the uprising after Diego Silang died."],
			["In which region did Gabriela Silang lead resistance?", "Gabriela Silang's leadership is most closely connected with which area?", "Ilocos", ["Bicol", "Palawan", "Mindanao"], "Gabriela Silang led resistance in the Ilocos region."],
			["Who was Gabriela Silang's husband and fellow revolt leader?", "Whose uprising did Gabriela continue in 1763?", "Diego Silang", ["Andres Bonifacio", "Jose Rizal", "Emilio Aguinaldo"], "She continued the revolt after her husband Diego Silang was assassinated."],
			["When was Diego Silang assassinated?", "Which event led Gabriela Silang to take command of the uprising?", "28 May 1763", ["27 April 1521", "10 May 1897", "12 June 1898"], "Diego Silang was assassinated on 28 May 1763."],
			["What did Gabriela Silang do after Diego's death?", "How did Gabriela respond after the revolt lost its leader?", "She continued and led the uprising", ["She joined Magellan's expedition", "She wrote Noli Me Tangere", "She declared independence in Kawit"], "Gabriela took leadership and continued the resistance."],
			["What leadership distinction is associated with Gabriela Silang?", "Gabriela is recognized as the first woman to do what in Philippine history?", "Lead a revolt in the Philippines", ["Serve as colonial governor", "Complete a world voyage", "Write the Malolos Constitution"], "NHCP identifies her as the first woman to lead a revolt in the Philippines."],
			["When was Gabriela Silang executed?", "Which date marks Gabriela Silang's death?", "20 September 1763", ["30 December 1896", "10 May 1897", "6 February 1964"], "Gabriela Silang was executed on 20 September 1763."],
			["How did Gabriela Silang die?", "Which statement correctly describes Gabriela Silang's death?", "She was executed by hanging", ["She died naturally in old age", "She died at the Battle of Mactan", "Her cause of death is unknown"], "Spanish colonial authorities captured and executed her by hanging."],
			["Who captured Gabriela Silang before her execution?", "Gabriela's execution was ordered under which colonial power?", "Spanish colonial authorities", ["The Katipunan", "Mactan's warriors", "The First Philippine Republic"], "Spanish colonial forces captured her and colonial authorities executed her."],
			["What does Gabriela Silang's legacy especially show?", "Gabriela Silang is an important symbol of what?", "Women's courage and leadership", ["Foreign colonial rule", "Silence in public life", "European exploration"], "Her legacy highlights women's leadership in the struggle for freedom."],
		],
	},
	5: {
		"hero_id": "emilio_aguinaldo",
		"facts": [
			["Who proclaimed Philippine independence in Kawit in 1898?", "Which revolutionary leader became president of the First Philippine Republic?", "Emilio Aguinaldo", ["Lapulapu", "Jose Rizal", "Andres Bonifacio"], "Emilio Aguinaldo proclaimed independence and became the republic's president."],
			["Where was Emilio Aguinaldo born?", "Which Cavite town is home to the Aguinaldo Shrine?", "Kawit", ["Tondo", "Mactan", "Dapitan"], "Aguinaldo was born in Kawit, Cavite."],
			["In which year did Aguinaldo join the Katipunan?", "When did Aguinaldo enter the Katipunan under the name Magdalo?", "1895", ["1521", "1763", "1901"], "Aguinaldo joined the Katipunan in 1895."],
			["In which province did Aguinaldo lead revolutionary victories in 1896?", "Kawit, Imus, and Bacoor connect Aguinaldo's early victories with which province?", "Cavite", ["Ilocos Sur", "Cebu", "Batanes"], "Aguinaldo led revolutionary victories in Cavite."],
			["When was Philippine independence proclaimed in Kawit?", "Which date is linked to Aguinaldo's proclamation of independence?", "12 June 1898", ["30 December 1896", "10 May 1897", "27 April 1521"], "Philippine independence was proclaimed on 12 June 1898."],
			["What national office did Aguinaldo hold from 1899 to 1901?", "Aguinaldo served as the first holder of which office?", "President of the Republic of the Philippines", ["Spanish Governor-General", "Supremo of the Katipunan", "Chief of Mactan"], "Aguinaldo was president of the First Philippine Republic."],
			["Which later war did Aguinaldo lead Filipino forces in?", "After the war against Spain, Aguinaldo led forces in which conflict?", "The Filipino-American War", ["The Battle of Mactan", "The Ilocos Revolt", "The Seven Years' War in Europe"], "Aguinaldo led Filipino forces during the Filipino-American War."],
			["Where was Aguinaldo captured in 1901?", "Which Isabela town is linked to Aguinaldo's capture?", "Palanan", ["Kawit", "Tondo", "Bagumbayan"], "Aguinaldo was captured in Palanan, Isabela, on 23 March 1901."],
			["When did Emilio Aguinaldo die?", "Which date is recorded on Aguinaldo's NHCP marker?", "6 February 1964", ["20 September 1763", "10 May 1897", "30 December 1896"], "Aguinaldo died on 6 February 1964."],
			["What medical cause of Aguinaldo's death is stated by the cited NHCP marker?", "Why does HistoryRoll list Aguinaldo's cause of death as Unknown?", "No medical cause is stated", ["Execution by firing squad", "Death in the Battle of Mactan", "Execution by hanging"], "The cited NHCP marker records the hospital and date, but not a medical cause."],
		],
	},
}


static func get_questions_for_level(level_id: int, question_type: String = "regular") -> Array:
	if level_id == 6:
		return _get_mixed_questions(question_type)
	var profile: Dictionary = PROFILES.get(level_id, {})
	if profile.is_empty():
		return []
	var facts: Array = profile.get("facts", [])
	var questions: Array = []
	if question_type == "bonus":
		for fact_index: int in range(5, 10):
			questions.append(_build_question(level_id, str(profile.get("hero_id", "")), fact_index, facts[fact_index], true, fact_index - 5, "bonus"))
	else:
		for fact_index: int in range(facts.size()):
			questions.append(_build_question(level_id, str(profile.get("hero_id", "")), fact_index, facts[fact_index], false, fact_index, "regular"))
		for fact_index: int in range(5):
			questions.append(_build_question(level_id, str(profile.get("hero_id", "")), fact_index, facts[fact_index], true, fact_index + 10, "regular"))
	return questions


static func _get_mixed_questions(question_type: String) -> Array:
	var questions: Array = []
	for level_id: int in range(1, 6):
		var profile: Dictionary = PROFILES[level_id]
		var facts: Array = profile["facts"]
		if question_type == "bonus":
			questions.append(_build_question(6, str(profile["hero_id"]), 4, facts[4], true, level_id - 1, "bonus"))
		else:
			for fact_index: int in range(3):
				questions.append(_build_question(6, str(profile["hero_id"]), fact_index, facts[fact_index], fact_index % 2 == 1, (level_id - 1) * 3 + fact_index, "regular"))
	return questions


static func _build_question(level_id: int, hero_id: String, fact_index: int, fact: Array, alternate: bool, sequence: int, question_type: String) -> Dictionary:
	var correct_slot := sequence % 4
	var choices: Array = (fact[3] as Array).duplicate()
	choices.insert(correct_slot, str(fact[2]))
	return {
		"question_id": "HR-L%d-%s-%03d" % [level_id, "BON" if question_type == "bonus" else "REG", sequence + 1],
		"question_type": question_type,
		"level": level_id,
		"hero_id": hero_id,
		"question_text": str(fact[1] if alternate else fact[0]),
		"choices": choices,
		"correct_index": correct_slot,
		"explanation": str(fact[4]),
		"fact_index": fact_index,
	}

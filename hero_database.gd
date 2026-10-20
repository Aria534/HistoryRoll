extends RefCounted

# Shared, offline educational content. Historical claims are tied to the
# authoritative references stored with each entry. Empty portrait paths use
# the existing safe placeholder until approved, licensed artwork is supplied.
const HEROES: Array[Dictionary] = [
	{
		"hero_id": "lapulapu",
		"hero_name": "Lapulapu",
		"associated_level": 1,
		"educational_theme": "Filipino Heroes",
		"short_biography": "A leader of Mactan who defended his community from Ferdinand Magellan's expedition in 1521.",
		"contribution": "Led the defense of Mactan and resisted foreign control.",
		"contribution_year": "27 April 1521",
		"death_date": "Unknown",
		"cause_of_death": "Unknown - surviving reliable records do not document when or how Lapulapu died.",
		"historical_legacy": "Remembered as an early symbol of courage, independence, and resistance to foreign rule.",
		"story_text": "Lapulapu was one of the leaders of Mactan. On 27 April 1521, he and the warriors of Mactan defended their community against the expedition led by Ferdinand Magellan. Lapulapu refused to accept the authority that Magellan claimed for the king of Spain. During the Battle of Mactan, his forces defeated the invaders, and Magellan was killed. This victory made Lapulapu an enduring symbol of courage and the defense of freedom. Reliable surviving records do not tell us the date or cause of Lapulapu's death, so these details remain unknown. His legacy is larger than one battle: Filipinos remember him as an early leader who stood for his people's independence and showed that foreign power could be resisted.",
		"portrait_path": "",
		"references": [
			"https://philhistoricsites.nhcp.gov.ph/registry_database/lapulapu-2/",
			"https://philhistoricsites.nhcp.gov.ph/registry_database/lapulapu/",
		],
	},
	{
		"hero_id": "andres_bonifacio",
		"hero_name": "Andres Bonifacio y de Castro",
		"associated_level": 2,
		"educational_theme": "Philippine Revolution Heroes",
		"short_biography": "Founder and Supremo of the Katipunan who helped begin the Philippine Revolution against Spain.",
		"contribution": "Founded the Katipunan in 1892 and led the opening of the Philippine Revolution in 1896.",
		"contribution_year": "7 July 1892 and August 1896",
		"death_date": "10 May 1897",
		"cause_of_death": "Executed by shooting at Mount Buntis, Maragondon, Cavite, after a military trial.",
		"historical_legacy": "Remembered as the Supremo of the Katipunan and the Father of the Philippine Revolution.",
		"story_text": "Andres Bonifacio y de Castro was born in Tondo, Manila. On 7 July 1892, he helped found the Katipunan, a secret movement that sought Philippine independence from Spain. As its Supremo, he encouraged Filipinos to unite and led the beginning of the wider revolution in August 1896. Bonifacio believed ordinary people could work together for freedom. After disagreements within the revolutionary movement, he and his brother Procopio were tried by a military court. They were executed by shooting at Mount Buntis in Maragondon, Cavite, on 10 May 1897. His death was a political execution, not an illness or natural death. Bonifacio is remembered as the Father of the Philippine Revolution and as a leader who helped turn the desire for freedom into organized action.",
		"portrait_path": "",
		"references": [
			"https://philhistoricsites.nhcp.gov.ph/registry_database/andres-bonifacio-30-nobyembre-1863-10-mayo-1897/",
			"https://philhistoricsites.nhcp.gov.ph/registry_database/where-bonifacio-was-court-martialled/",
		],
	},
	{
		"hero_id": "jose_rizal",
		"hero_name": "Jose Rizal y Mercado",
		"associated_level": 3,
		"educational_theme": "National Heroes and Their Contributions",
		"short_biography": "Physician, writer, reform advocate, and patriot whose works strengthened Filipino nationalism.",
		"contribution": "Exposed colonial abuses through Noli Me Tangere and El Filibusterismo and advocated peaceful reform.",
		"contribution_year": "1887 and 1891",
		"death_date": "30 December 1896",
		"cause_of_death": "Executed by firing squad at Bagumbayan, Manila, under the Spanish colonial government.",
		"historical_legacy": "His writings and martyrdom strengthened Filipino nationhood and inspired the struggle for freedom.",
		"story_text": "Jose Rizal y Mercado was a Filipino physician, writer, educator, and reform advocate. His novels Noli Me Tangere, published in 1887, and El Filibusterismo, published in 1891, described abuses under Spanish colonial rule. Rizal used learning and writing to call for peaceful reforms and equal treatment of Filipinos. Spanish authorities later accused him of supporting rebellion. He was executed by firing squad at Bagumbayan in Manila on 30 December 1896. His death was an execution, not a natural death. Rizal's ideas and sacrifice strengthened the Filipino sense of nationhood and inspired many people during the struggle for freedom. He is remembered not only for his death, but also for showing how education, courage, and responsible writing can help a nation seek justice and dignity.",
		"portrait_path": "",
		"references": [
			"https://philhistoricsites.nhcp.gov.ph/registry_database/jose-rizal-1861-1896/",
			"https://philhistoricsites.nhcp.gov.ph/registry_database/jose-rizal-paco-cemetery/",
		],
	},
	{
		"hero_id": "gabriela_silang",
		"hero_name": "Maria Josefa Gabriela Silang",
		"associated_level": 4,
		"educational_theme": "Women Heroes",
		"short_biography": "A courageous Ilocano leader who continued the revolt after the assassination of Diego Silang.",
		"contribution": "Led the Ilocos resistance against Spanish colonial rule in 1763.",
		"contribution_year": "1763",
		"death_date": "20 September 1763",
		"cause_of_death": "Captured by Spanish colonial forces and executed by hanging.",
		"historical_legacy": "Recognized as the first woman to lead a revolt in the Philippines and a symbol of women's leadership.",
		"story_text": "Maria Josefa Gabriela Silang was an Ilocano leader during resistance to Spanish colonial rule. Her husband, Diego Silang, led the Ilocos revolt of 1762 to 1763. After Diego was assassinated on 28 May 1763, Gabriela continued the uprising instead of giving up. She organized and led her followers through difficult battles, showing that women could take major leadership roles in the struggle for freedom. Spanish forces later captured her. Gabriela was executed by hanging on 20 September 1763. Her death was an execution by the colonial government, not an illness or natural death. She is remembered as the first woman to lead a revolt in the Philippines. Her courage and leadership remain important symbols of resistance, equality, and the powerful role of Filipino women in the nation's history.",
		"portrait_path": "",
		"references": [
			"https://philhistoricsites.nhcp.gov.ph/registry_database/maria-josefa-gabriela-silang-1723-1763/",
			"https://philhistoricsites.nhcp.gov.ph/registry_database/pasong-diego-gabriela-silang/",
		],
	},
	{
		"hero_id": "emilio_aguinaldo",
		"hero_name": "Emilio Aguinaldo y Famy",
		"associated_level": 5,
		"educational_theme": "Heroes of Philippine Independence",
		"short_biography": "Revolutionary leader, independence leader, and first president of the Republic of the Philippines.",
		"contribution": "Led revolutionary forces, proclaimed Philippine independence, and served as president of the First Philippine Republic.",
		"contribution_year": "12 June 1898 and 1899-1901",
		"death_date": "6 February 1964",
		"cause_of_death": "Unknown - the cited NHCP marker records his death at Veterans Memorial Hospital but does not state a medical cause.",
		"historical_legacy": "Remembered for his central role in the Revolution, the 1898 independence proclamation, and the First Philippine Republic.",
		"story_text": "Emilio Aguinaldo y Famy was a leader in the Philippine Revolution against Spain. In 1896, he led successful revolutionary actions in Cavite. He later returned from exile and proclaimed Philippine independence in Kawit, Cavite, on 12 June 1898. Aguinaldo became president of the First Philippine Republic in 1899 and led Filipino forces during the Filipino-American War until his capture in 1901. He died at Veterans Memorial Hospital in Quezon City on 6 February 1964. The cited NHCP historical marker does not give a medical cause of death, so the exact cause is listed as unknown here. Aguinaldo's career included difficult and debated events, but his role in the Revolution, the independence proclamation, and the establishment of the First Philippine Republic remains historically significant.",
		"portrait_path": "",
		"references": [
			"https://philhistoricsites.nhcp.gov.ph/registry_database/emilio-aguinaldo-y-famy-1869-1964-kawit/",
			"https://philhistoricsites.nhcp.gov.ph/registry_database/emilio-aguinaldo-shrine/",
		],
	},
]


static func get_hero(hero_id: String) -> Dictionary:
	for hero: Dictionary in HEROES:
		if str(hero.get("hero_id", "")) == hero_id:
			return hero.duplicate(true)
	return {}


static func get_hero_for_level(level_id: int) -> Dictionary:
	for hero: Dictionary in HEROES:
		if int(hero.get("associated_level", 0)) == level_id:
			return hero.duplicate(true)
	return {}


static func get_heroes() -> Array:
	return HEROES.duplicate(true)

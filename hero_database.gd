extends RefCounted

# Offline, Grade 6-readable summaries. Portrait paths remain empty until
# approved licensed chibi artwork is supplied.
const HEROES: Array[Dictionary] = [
	{"hero_id":"lapulapu","hero_name":"Lapulapu","associated_level":1,"educational_theme":"Defense of Mactan","short_biography":"A leader of Mactan who defended his community from Ferdinand Magellan's expedition in 1521.","contribution":"Led the defense of Mactan and resisted foreign control.","contribution_year":"27 April 1521","death_date":"Unknown","cause_of_death":"Unknown - surviving reliable records do not document when or how Lapulapu died.","historical_legacy":"Remembered as an early symbol of courage, independence, and resistance to foreign rule.","story_text":"Lapulapu was one of the leaders of Mactan. On 27 April 1521, he and the warriors of Mactan defended their community against the expedition led by Ferdinand Magellan. Lapulapu refused to accept the foreign authority claimed by the expedition. His forces won the Battle of Mactan, where Magellan was killed. Reliable surviving records do not establish the date or cause of Lapulapu's death, so these details remain unknown. Filipinos remember him as an early symbol of courage, independence, and resistance to foreign control.","portrait_path":"res://assets/gameplay_chibis/lapulapu_chibi.png","references":["https://philhistoricsites.nhcp.gov.ph/registry_database/lapulapu-2/"]},
	{"hero_id":"andres_bonifacio","hero_name":"Andres Bonifacio y de Castro","associated_level":2,"educational_theme":"Katipunan and Revolution","short_biography":"Founder and Supremo of the Katipunan who helped begin the Philippine Revolution.","contribution":"Founded the Katipunan in 1892 and led the opening of the Revolution in 1896.","contribution_year":"7 July 1892 and August 1896","death_date":"10 May 1897","cause_of_death":"Executed by shooting at Mount Buntis after a military trial.","historical_legacy":"Remembered as the Supremo and Father of the Philippine Revolution.","story_text":"Andres Bonifacio y de Castro helped found the Katipunan on 7 July 1892. The movement sought Philippine independence from Spain. As Supremo, he encouraged Filipinos to unite and helped begin the wider Revolution in August 1896. After disagreements within the revolutionary movement, Bonifacio and his brother Procopio were tried by a military court. They were executed by shooting at Mount Buntis on 10 May 1897. His death was an execution, not an illness or natural death. Bonifacio is remembered as the Father of the Philippine Revolution and as a leader who organized ordinary people for freedom.","portrait_path":"res://assets/gameplay_chibis/bonifacio_chibi.png","references":["https://philhistoricsites.nhcp.gov.ph/registry_database/andres-bonifacio-30-nobyembre-1863-10-mayo-1897/"]},
	{"hero_id":"jose_rizal","hero_name":"Jose Rizal y Mercado","associated_level":3,"educational_theme":"Reform and Nationalism","short_biography":"Physician, writer, reform advocate, and patriot whose works strengthened Filipino nationalism.","contribution":"Exposed colonial abuses through Noli Me Tangere and El Filibusterismo.","contribution_year":"1887 and 1891","death_date":"30 December 1896","cause_of_death":"Executed by firing squad at Bagumbayan, Manila.","historical_legacy":"His writings and martyrdom strengthened Filipino nationhood.","story_text":"Jose Rizal y Mercado was a physician, writer, educator, and reform advocate. Noli Me Tangere, published in 1887, and El Filibusterismo, published in 1891, described abuses under Spanish colonial rule. Rizal called for peaceful reform and equal treatment. Spanish authorities executed him by firing squad at Bagumbayan on 30 December 1896. His death was an execution, not a natural death. His writings and sacrifice strengthened Filipino nationhood and showed how education and responsible writing can help a nation seek justice.","portrait_path":"res://assets/gameplay_chibis/rizal_chibi.png","references":["https://philhistoricsites.nhcp.gov.ph/registry_database/jose-rizal-1861-1896/"]},
	{"hero_id":"antonio_luna","hero_name":"Antonio Luna","associated_level":4,"educational_theme":"Military Leadership","short_biography":"A scientist, writer, and general who organized the army of the First Philippine Republic.","contribution":"Founded the Academia Militar and served as chief commander of the Republic's army.","contribution_year":"1898-1899","death_date":"5 June 1899","cause_of_death":"Killed in Cabanatuan, Nueva Ecija.","historical_legacy":"Remembered for discipline, military organization, and defense of the Philippine Republic.","story_text":"Antonio Luna was born in Manila on 29 October 1866. He earned a doctorate in pharmacy in Madrid and wrote for La Solidaridad. In 1898 he founded La Independencia and the Academia Militar. In February 1899, he became chief commander of the army of the Philippine Republic. Luna worked to build a disciplined force during the Filipino-American War. He was killed in Cabanatuan, Nueva Ecija, on 5 June 1899. His death was a violent killing, not an illness or natural death. He is remembered for military organization, discipline, scientific learning, and service to the Republic.","portrait_path":"res://assets/gameplay_chibis/luna_chibi.png","references":["https://philhistoricsites.nhcp.gov.ph/registry_database/antonio-luna-1866-1899/"]},
	{"hero_id":"melchora_aquino","hero_name":"Melchora Aquino de Ramos","associated_level":5,"educational_theme":"Mother of the Revolution","short_biography":"Known as Tandang Sora, she fed Katipuneros and cared for wounded revolutionaries.","contribution":"Supported the Katipunan by providing food, shelter, and care for the wounded.","contribution_year":"1896","death_date":"20 February 1919","cause_of_death":"The cited NHCP marker records her death but does not state a medical cause.","historical_legacy":"Honored as the Mother of the Philippine Revolution for her courage and care.","story_text":"Melchora Aquino de Ramos, known as Tandang Sora, was born in Banlat on 6 January 1812. During the Revolution in 1896, she gave food to Katipuneros led by Andres Bonifacio and cared for wounded revolutionaries. Spanish authorities arrested her and exiled her to Guam. She returned to the Philippines in 1903. She died on 20 February 1919. The cited NHCP marker does not state a medical cause, so it is not presented as known. She is honored as the Mother of the Philippine Revolution because her courage, generosity, and care supported people fighting for freedom.","portrait_path":"res://assets/gameplay_chibis/aquino_chibi.png","references":["https://philhistoricsites.nhcp.gov.ph/registry_database/melchora-aquino-tandang-sora/"]},
	{"hero_id":"apolinario_mabini","hero_name":"Apolinario Mabini y Maranan","associated_level":6,"educational_theme":"Political Thought and Government","short_biography":"A lawyer, political thinker, chief adviser, and prime minister of the First Philippine Republic.","contribution":"Wrote important political documents and served as chief adviser and prime minister.","contribution_year":"1898-1899","death_date":"13 May 1903","cause_of_death":"Died of cholera in Manila.","historical_legacy":"Remembered as a principled political thinker and the Brains of the Revolution.","story_text":"Apolinario Mabini y Maranan was born in Tanauan, Batangas, on 23 July 1864. He studied law and wrote important political works. In 1898 he became a chief adviser to Emilio Aguinaldo. In 1899 he served as prime minister and secretary of foreign affairs of the First Philippine Republic. American authorities later exiled him to Guam. He returned in February 1903 and refused a post in the colonial government. Mabini died of cholera in Manila on 13 May 1903. He is remembered as a principled political thinker whose writing and public service helped guide the young Republic.","portrait_path":"res://assets/gameplay_chibis/mabini_chibi.png","references":["https://philhistoricsites.nhcp.gov.ph/registry_database/apolinario-mabini-national-monument/","https://philhistoricsites.nhcp.gov.ph/registry_database/dating-libingan-ni-apolinario-mabini-1903/"]},
]

# Optional five-panel Story Mode chapters. Gameplay remains available from
# Level Selection without requiring these chapters to be viewed first.
const STORY_CHAPTERS: Dictionary = {
	"lapulapu": {
		"story_title": "Defender of Mactan",
		"panels": [
			{"title":"Leader of Mactan","text":"Lapulapu was one of the leaders of Mactan in the early 1500s. He defended the independence of his community and refused to recognize foreign authority over his people.","visual":"Coastal Mactan village, sea, native houses, and Lapulapu standing near the shore."},
			{"title":"The Arrival of Magellan","text":"In 1521, Ferdinand Magellan arrived in the islands as part of a Spanish expedition. Some local leaders formed alliances with the expedition, but Lapulapu refused to submit to its demands.","visual":"Ships approaching the Philippine coast while villagers watch from the shore."},
			{"title":"Preparing to Defend Mactan","text":"Lapulapu and the warriors of Mactan prepared to defend their community. They faced Magellan's forces when the expedition attacked Mactan.","visual":"Lapulapu and Mactan warriors preparing near the shoreline."},
			{"title":"Battle of Mactan","text":"On April 27, 1521, the Battle of Mactan took place. Lapulapu's warriors resisted Magellan's forces, and Magellan was killed during the battle.","visual":"A respectful, non-graphic view of the Battle of Mactan."},
			{"title":"Legacy of Resistance","text":"Lapulapu became remembered as an early symbol of resistance to foreign domination. His defense of Mactan is remembered as an important event in Philippine history.","visual":"Lapulapu overlooking the coast with a sunrise behind him."},
		],
	},
	"andres_bonifacio": {
		"story_title": "Katipunan and Revolution",
		"panels": [
			{"title":"A Man from Tondo","text":"Andres Bonifacio was born in Tondo, Manila, on November 30, 1863. Despite facing difficulties in life, he continued learning through reading and self-study.","visual":"Young Bonifacio in old Manila with books nearby."},
			{"title":"Founding the Katipunan","text":"On July 7, 1892, Bonifacio helped establish the Katipunan. It was a secret organization that sought to unite Filipinos and gain independence from Spanish rule.","visual":"A quiet nighttime Katipunan meeting with documents and candles."},
			{"title":"The Revolution Begins","text":"In August 1896, the Philippine Revolution against Spain expanded into open conflict. Bonifacio became one of the leaders who encouraged Filipinos to fight for freedom.","visual":"Bonifacio standing with Katipunan members holding flags."},
			{"title":"Fighting for Independence","text":"Bonifacio took part in revolutionary activities and led forces during the early period of the revolution. On August 30, 1896, revolutionary forces attacked San Juan del Monte.","visual":"Bonifacio leading revolutionaries toward San Juan del Monte."},
			{"title":"The Supremo's Legacy","text":"Bonifacio died in Maragondon, Cavite, on May 10, 1897. He is remembered as the Supremo of the Katipunan and one of the important leaders of the Philippine Revolution.","visual":"Bonifacio's silhouette with the Katipunan flag behind him."},
		],
	},
	"jose_rizal": {
		"story_title": "Reform, Writing, and Nationalism",
		"panels": [
			{"title":"A Young Scholar","text":"Jose Rizal was born in Calamba, Laguna, on June 19, 1861. He became a physician, writer, artist, and scholar who studied both in the Philippines and abroad.","visual":"Young Rizal reading beside books and writing materials."},
			{"title":"Writing for Reform","text":"Rizal used his writings to expose abuses and problems under Spanish colonial rule. His novel Noli Me Tangere was published in 1887.","visual":"Rizal writing at a desk beside a copy of Noli Me Tangere."},
			{"title":"El Filibusterismo","text":"Rizal later published El Filibusterismo in 1891. His writings encouraged Filipinos to think about reform, injustice, and the future of their country.","visual":"Open books, a printing press, and Filipino readers."},
			{"title":"Exile and Arrest","text":"Rizal was exiled to Dapitan in 1892. In 1896, he was arrested again and eventually imprisoned at Fort Santiago in Manila.","visual":"A transition from a peaceful Dapitan scene to Fort Santiago."},
			{"title":"A Lasting Legacy","text":"Rizal was executed at Bagumbayan on December 30, 1896. His writings and sacrifice became powerful symbols of Filipino nationalism and the struggle for freedom.","visual":"Rizal standing peacefully at sunrise with books and the Philippine landscape behind him."},
		],
	},
	"antonio_luna": {
		"story_title": "Discipline and Defense",
		"panels": [
			{"title":"Scholar and Scientist","text":"Antonio Luna was born in Manila on October 29, 1866. He studied pharmacy and later earned a doctorate from the Universidad Central de Madrid.","visual":"Young Luna surrounded by books, laboratory equipment, and study materials."},
			{"title":"Writing for the Filipino Cause","text":"While in Spain, Luna joined the Propaganda Movement and wrote for La Solidaridad. He used the pen to express ideas about reform and conditions in the Philippines.","visual":"Luna writing an article beside newspapers and letters."},
			{"title":"Returning to the Philippines","text":"Luna returned to the Philippines in 1898. He established the newspaper La Independencia, which spoke against American occupation.","visual":"Luna beside a printing press and copies of La Independencia."},
			{"title":"Building a Stronger Army","text":"Luna helped organize and strengthen the military of the Philippine Republic. He established a military academy and became a commanding general of the Philippine forces in 1899.","visual":"Luna training Filipino soldiers with maps and military plans."},
			{"title":"General Luna's Legacy","text":"Antonio Luna was killed in Cabanatuan, Nueva Ecija, on June 5, 1899. He is remembered for his discipline, military leadership, and efforts to strengthen the defense of the Philippine Republic.","visual":"Luna standing beside a Philippine flag and a military map."},
		],
	},
	"melchora_aquino": {
		"story_title": "Mother of the Revolution",
		"panels": [
			{"title":"Tandang Sora","text":"Melchora Aquino was born in Banlat, Caloocan, on January 6, 1812. She later became widely known as Tandang Sora.","visual":"A traditional Filipino community with Melchora Aquino near her home."},
			{"title":"Helping the Katipuneros","text":"When the revolution began, Melchora Aquino supported members of the Katipunan. She provided food and helped care for wounded revolutionaries.","visual":"Tandang Sora preparing food while wounded Katipuneros receive care."},
			{"title":"A Courageous Supporter","text":"Her support for the revolution placed her in danger. Even at an advanced age, she continued helping those involved in the struggle against Spanish rule.","visual":"Melchora Aquino quietly assisting Katipunan members."},
			{"title":"Arrest and Exile","text":"Spanish authorities arrested Melchora Aquino in 1896. She was later exiled to Guam because of her support for the revolutionaries.","visual":"Tandang Sora leaving the Philippines by ship, shown respectfully."},
			{"title":"Mother of the Revolution","text":"Melchora Aquino eventually returned to the Philippines in 1903. She is remembered as the Mother of the Revolution because of the care and assistance she gave to Filipino revolutionaries.","visual":"Elderly Tandang Sora surrounded by younger Filipinos, with a warm Philippine sunrise."},
		],
	},
	"apolinario_mabini": {
		"story_title": "Mind of the Revolution",
		"panels": [
			{"title":"From Tanauan to Manila","text":"Apolinario Mabini was born in Tanauan, Batangas, on July 23, 1864. Coming from a modest family, he worked hard in his studies and completed his law education in 1894.","visual":"Young Mabini studying with books inside a simple Filipino home."},
			{"title":"Facing a Difficult Challenge","text":"In 1896, Mabini became paralyzed. His physical condition did not prevent him from continuing to study, write, and take part in the struggle for Philippine independence.","visual":"Mabini writing at a desk with books and papers around him."},
			{"title":"Adviser to the Revolution","text":"In 1898, Mabini became a chief adviser to Emilio Aguinaldo. His knowledge of law and government helped guide important decisions during the creation of the Philippine Republic.","visual":"Mabini reviewing documents and maps during a government meeting."},
			{"title":"Serving the Republic","text":"In 1899, Mabini served as Prime Minister and Secretary of Foreign Affairs of the Philippine Republic. He also wrote important political works explaining his ideas about government, citizenship, and national responsibility.","visual":"Mabini writing official documents with the Philippine flag nearby."},
			{"title":"A Life of Principle","text":"Mabini was arrested by American forces and later exiled to Guam in 1901. He returned to the Philippines in 1903 and died in Manila on May 13 of the same year. He is remembered for his intelligence, patriotism, and commitment to Philippine independence.","visual":"Mabini with books and government documents as a sunrise appears behind the Philippine landscape."},
		],
	},
}

static func get_hero(hero_id: String) -> Dictionary:
	for hero: Dictionary in HEROES:
		if str(hero.get("hero_id", "")) == hero_id: return hero.duplicate(true)
	return {}

static func get_hero_for_level(level_id: int) -> Dictionary:
	for hero: Dictionary in HEROES:
		if int(hero.get("associated_level", 0)) == level_id: return hero.duplicate(true)
	return {}

static func get_story_for_level(level_id: int) -> Dictionary:
	var hero := get_hero_for_level(level_id)
	var hero_id := str(hero.get("hero_id", ""))
	if not STORY_CHAPTERS.has(hero_id):
		return {}
	return (STORY_CHAPTERS[hero_id] as Dictionary).duplicate(true)

static func get_heroes() -> Array: return HEROES.duplicate(true)

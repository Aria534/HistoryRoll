# HistoryRoll Phase 10 Question-Bank Validation

## Summary

| Level | Hero | Source | Verified and active | Needs review |
|---|---|---:|---:|---:|
| 1 | Lapulapu | 50 | 47 | 3 |
| 2 | Andres Bonifacio | 50 | 49 | 1 |
| 3 | Jose Rizal | 50 | 45 | 5 |
| 4 | Antonio Luna | 50 | 44 | 6 |
| 5 | Melchora Aquino | 50 | 45 | 5 |
| 6 | Apolinario Mabini | 50 | 47 | 3 |
| **Total** |  | **300** | **277** | **23** |

All 300 supplied questions remain in `data/quiz_questions.json` as source records. The 23 items below use `correct_index: -1`, `active: false`, and `validation_status: needs_review`; they are excluded from gameplay until corrected and approved. Original wording and choices are retained in `source_question` and `source_choices`.

## Review-only questions

| ID | Issue and recommended correction |
|---|---|
| HR-L1-Q03 | “First national hero” is not the wording of the NHCP marker. Rewrite using the supported phrase “first Filipino to repel European aggression,” or add an approved source. |
| HR-L1-Q32 | Mactan Strait does not surround the entire island. Ask which strait separates Mactan from Cebu instead. |
| HR-L1-Q42 | Identify the exact coin or banknote series and denomination, supported by a BSP source. |
| HR-L2-Q48 | None of the three options correctly answers the university question. Replace the entire item. |
| HR-L3-Q08 | Authorship of *Sa Aking Mga Kabata* is disputed. Remove or explicitly teach the dispute. |
| HR-L3-Q09 | The alleged favorite pet and animal names need an authoritative source. |
| HR-L3-Q16 | The exact language count varies across accounts. Use a sourced, qualified formulation. |
| HR-L3-Q17 | Replace “Doctor of Medicine” with Rizal’s documented Licentiate qualifications. |
| HR-L3-Q36 | Rizal did not lead the Katipunan. Ask about the actual charges of rebellion, sedition, and conspiracy. |
| HR-L4-Q10 | Luna’s documented medical research concerned malaria, not the yellow-fever example in the answer. |
| HR-L4-Q32 | The alleged last words vary by retelling and are not securely documented. |
| HR-L4-Q36 | The question asks for one province, but the answer names municipalities in multiple provinces. |
| HR-L4-Q41 | The alleged famous portrait by Juan Luna needs a museum/catalog citation. |
| HR-L4-Q42 | The quote is associated with modern dramatization and lacks reliable primary attribution. |
| HR-L4-Q44 | The answer lists generic medals, not a specific award historically tied to Luna. |
| HR-L5-Q33 | The claim about declining pensions and financial aid needs an authoritative citation. |
| HR-L5-Q34 | The document’s March 2, 1919 date conflicts with NHCP markers recording February 1919. Correct and approve the date before activation. |
| HR-L5-Q42 | The precise menu of foods is not sufficiently supported for one factual answer. |
| HR-L5-Q47 | The claim that the Banlat home was burned by Spanish forces needs authoritative verification. |
| HR-L5-Q48 | Specify the issuing government body and exact “Tandang Sora Award”; the current premise is too vague. |
| HR-L6-Q16 | Mabini advised the Republic and wrote constitutional programs, but Congress drafted the Malolos Constitution; it was not a document proclaimed in Kawit. |
| HR-L6-Q34 | The exact “thousands attended” funeral claim needs an authoritative citation. |
| HR-L6-Q37 | Cite the specific proclamation or ordinance and clarify the geographic scope of the birthday holiday. |

## Primary validation references

- NHCP Registry: [Lapulapu](https://philhistoricsites.nhcp.gov.ph/registry_database/lapulapu/)
- NHCP Registry: [Mactan—Magellan-Elcano Expedition Route](https://philhistoricsites.nhcp.gov.ph/registry_database/mactan-ruta-ng-ekspedisyon-magallanes-elcano-sa-pilipinas/)
- NHCP Registry: [Andres Bonifacio](https://philhistoricsites.nhcp.gov.ph/registry_database/andres-bonifacio-30-nobyembre-1863-10-mayo-1897-2/)
- NHCP Registry: [Jose Rizal—Calamba Church](https://philhistoricsites.nhcp.gov.ph/registry_database/jose-rizal-1861-1896-calamba-church/)
- NHCP Registry: [Rizal Shrine, Fort Santiago](https://philhistoricsites.nhcp.gov.ph/registry_database/rizal-shrine-fort-santiago/)
- NHCP Registry: [Antonio Luna](https://philhistoricsites.nhcp.gov.ph/registry_database/antonio-luna-1866-1899/)
- NHCP Registry: [Birthplace of Antonio Luna](https://philhistoricsites.nhcp.gov.ph/registry_database/sinilangang-pook-ni-heneral-antonio-luna-1866-1899/)
- NHCP Registry: [Melchora Aquino](https://philhistoricsites.nhcp.gov.ph/registry_database/melchora-aquino-tandang-sora/)
- NHCP Registry: [Tandang Sora National Shrine](https://philhistoricsites.nhcp.gov.ph/registry_database/ang-dambana-ni-melchora-tandang-sora-aquino-6-enero-1812-19-pebrero-1919/)
- NHCP Registry: [Birthplace of Mabini](https://philhistoricsites.nhcp.gov.ph/registry_database/birthplace-of-mabini/)
- NHCP Registry: [Apolinario Mabini National Monument](https://philhistoricsites.nhcp.gov.ph/registry_database/apolinario-mabini-national-monument/)
- NHCP Registry: [Mabini Shrine, PUP](https://philhistoricsites.nhcp.gov.ph/registry_database/mabini-shrine-pup/)

## Runtime policy

- Gameplay loads only `verified` and `active` records for the selected level.
- No questions are mixed between heroes or levels.
- Multiple-choice questions display three buttons.
- True/False questions display two buttons.
- The fourth existing button is hidden and disabled when unused.
- Questions shuffle without repetition until the active pool is exhausted, then reshuffle.
- Correct answers add 10 points; incorrect answers deduct 2 points without going below zero.
- Both outcomes unlock exactly one dice roll; duplicate submissions are rejected.

# Leaf-free gold quiz popup

Applied to the existing shared HistoryRoll gameplay popup on 21 November 2026 using the user's cream/gold question-panel reference. This is a close visual recreation with live question and choice text, not a pixel-identical image extraction.

## Files

Created in res://assets/gameplay_ui/quiz_gold/:

- frame.png: transparent cream parchment, gold frame/curls, brown footer, red sun banners and a simple sun crest. No leaves, laurels, flowers or vines.
- answer.png: transparent blank green answer button with a thick gold rim and brown shadow. No foliage, icons or baked text.
- Godot .import descriptors and this README.

Modified:

- res://gameplay_placeholder.tscn: reuses QuizPanel, QuestionLabel, Answers and all four native answer buttons, with the two new textures, cream/gold styling and the existing Titan One font. The question is vertically centered; answer captions remain white with a dark outline.
- res://gameplay_placeholder.gd: fits wrapped question/answer text using the actual theme font and available width. Removes the obsolete leading newline used for the former thatched frame. Enlarges answer rows when needed and reserves 24 percent of popup height for the crest/top and 30 percent for the curls/footer.
- res://tests/gameplay_redesign_layout_test.gd: verifies the new textures, text bounds, separation from decorative artwork, and rendered True/False, three-choice, four-choice and long-choice layouts.

Existing nodes, signal handlers, popup entrance/exit Tweens, question-bank content, answer submission guards, score rules, happy/sad reactions, sounds, dice behavior, boards, hero tokens, progression, saves, navigation, Main Menu and Settings are retained. No new scene, node, Autoload or input action was added. Existing gameplay popup artwork is kept in its original location.

All six levels share this scene and receive the same popup skin. Two or three choices use one row; four choices use a 2x2 grid. Longer text receives more height while the popup remains within the tested portrait screen. The Roll Dice control remains at the bottom of gameplay, outside the question panel. Old instruction and dice-card rows inside the popup remain hidden.

Native Button states use the same blank illustrated texture with small hover/press/disabled color variations. Existing correct/incorrect tinting remains controlled by the original answer handler.

## Verification actually performed

Godot 4.7.1 desktop, Compatibility renderer; Dummy audio:

| Suite | Passed | Failed | Exit |
| --- | ---: | ---: | ---: |
| tests/gameplay_redesign_layout_test.gd | 677 | 0 | 0 |
| tests/question_first_redesign_test.gd | 115 | 0 | 0 |
| tests/question_popup_test.gd | 12 | 0 | 0 |
| Total | 804 | 0 | |

- Imported the PNGs successfully and checked the project scripts/scene in the headless Editor.
- Rendered all six levels at 1024x1536, Level 1 at 720x1280, 1080x1920 and 1080x2400, and Level 6 at 720x1280.
- Rendered separate 720x1280 examples with two, three, four and long answer choices. These are display-only test fixtures and do not change or replace the approved production question bank.
- Visually reviewed the final 720x1280 festival and four-choice examples and the actual Level 1 question at 1024x1536. Reviewed the long-choice layout during refinement.
- Checked wrapped lettering against the actual allocated control sizes, buttons inside the frame, separation between question and answers, clearance below the crest, and clearance above the footer/curls.
- An earlier 649-check layout run passed but visual inspection showed a four-choice heading close to the sun crest. Proportional safe margins were then added and the final expanded 677-check suite passed.
- Preserved correct/incorrect scoring, duplicate answer protection, popup closing, next-turn questions, actual pointer input, one roll per rapid-click sequence, on-board die/movement agreement and Back navigation.
- git diff --check passed. Final gameplay/UI test logs contain no script, missing-resource or rendering errors.

Actual user files were not reset or modified. Settings SHA-256 remained 27A5E3EDB4F0918F4713B9A2E16709CBA02FD6030E50457B85C632D2581AA45D; progress SHA-256 remained 7493D1B3ABDBF9A8A779E9D7357E7D94AA4CE9BD523818A374DB58F346D384CC.

Remaining environment messages: the small headless popup-flow suite logs one ObjectDB instance at shutdown and exits with code 0. The import-only Editor logs this machine's existing external-text-editor launch error and exits with code 0. AudioManager continues reporting built-in fallbacks for missing .ogg tracks. Physical Android input, performance, safe areas and audible audio were not tested.

Captures are saved to user://quiz_gold_festival_720x1280.png, quiz_gold_true_false_720x1280.png, quiz_gold_four_choices_720x1280.png, quiz_gold_long_choices_720x1280.png, and the existing gameplay_level_* captures.

## Manual check

1. Stop the prior running game and press F5.
2. Open an available level through Start Game and PLAY.
3. Confirm the modal popup has the new cream/gold frame, red sun banners and green/gold answer buttons, with no leaf ornaments.
4. Submit one answer. Confirm its score/reaction and that the popup closes.
5. Press the bottom Roll Dice button and confirm movement and the next popup.

No Inspector setup or manual signal wiring is required.

Run:

- Godot --path . --script res://tests/gameplay_redesign_layout_test.gd --audio-driver Dummy
- Godot --headless --path . --script res://tests/question_first_redesign_test.gd --audio-driver Dummy
- Godot --headless --path . --script res://tests/question_popup_test.gd --audio-driver Dummy

## Artwork provenance and final prompts

The built-in imagegen tool produced both PNGs using the user's latest question-popup reference as Image 1. They requested transparent backgrounds and were copied intact into this folder. No CLI/API fallback or raster pixel editing was used.

### frame.png

Use case: precise-object-edit. Asset type: a transparent blank question-popup frame for the existing Godot mobile educational game HistoryRoll. Image 1 is the user's newest question-popup reference and is the exact design reference. Recreate ONLY the illustrated popup FRAME, with every leaf removed: rich gold beveled rectangular border with warm dark-brown outline and bottom drop shadow, cream parchment question area, a deep reddish-brown wooden lower band, thick golden curled scroll tips at both bottom corners, small angular gold corner caps at the top, and two vertical red hanging ribbons near the upper left and upper right sides, each with a simple golden Philippine sun emblem. At the top center use a SMALL SIMPLE ROUND GOLDEN SUN CREST with short straight rays, replacing the reference's flower/leaf fan and laurel sprigs. The central cream area must remain very spacious and COMPLETELY BLANK for live question text and 2-4 answer buttons. Width to height about 2.6:1. The wood band occupies only the bottom 16 percent; the entire large inner area above is uninterrupted cream parchment, including where the separately rendered green answer buttons will appear. Keep the complete outer frame, sun crest and bottom curls within the canvas with narrow transparent margins. Match Image 1's polished friendly hand-drawn mobile-game illustration, soft warm gold highlights, chunky dark-brown outlines and rich cream/red/brown palette. REMOVE ALL LEAVES, GREEN FOLIAGE, GOLDEN LAURELS, PETALS, FLOWERS and vines. Do not include answer buttons, any text, numbers, board, dice, background scenery, icons other than the two sun emblems, extra objects or watermark. Real transparent alpha outside the frame. One frame only.

### answer.png

Use case: precise-object-edit. Asset type: a single blank answer-button texture for the existing HistoryRoll quiz popup. Image 1 is the user's newest uploaded popup reference and is the exact answer-button style reference. Recreate ONLY ONE of its green answer buttons, completely blank: chunky horizontally rounded rectangle with rich dark leaf-green fill, lighter green upper inset gloss, thick polished golden-yellow beveled rim, strong dark-chocolate outline and a compact warm brown lower shadow. Shape should be a rounded rectangle with moderately curved corners, NOT a pill and not a wooden sign. Wide horizontal proportions about 3.5:1, fully visible with very narrow transparent padding. Match Image 1's friendly polished illustrated mobile-game UI, thick clear outlines, warm gold highlights, strong readable silhouette. The center must be completely empty for dynamic Godot answer text, with no decorative shapes inside. ABSOLUTELY NO LEAVES, LAURELS, foliage, vines, flowers, icons, words, letters, numbers, patterns, scenery or watermark. Preserve actual transparent alpha outside the button. Deliver ONE blank green-and-gold button only.

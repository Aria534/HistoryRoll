# Library How to Play design

Implemented 22 November 2026 from the user's final leaf-free library reference.

## Files and integration

- `frame.png`: blank illustrated library, open book, red/gold title plaque and pale parchment board.
- `got_it.png`: separate blank green/gold confirmation capsule, with no leaves or side ornaments.
- Both files live at `res://assets/how_to_play_ui/library/`. Original generated pixels and alpha were preserved.
- `how_to_play_panel.gd` is an @tool script supplying one shared layout in both the Godot Editor and running game. All eleven numbered rule rows are saved as actual scene nodes; the script synchronizes wording without creating duplicates.
- `settings.tscn` reuses its existing HowToPlayOverlay/HelpAspect/Canvas, HelpFrame, Heading, Instructions, HelpRows and CloseHelpButton. The Canvas now uses the shared script. The existing Settings frame, Music/SFX controls and Back destination were preserved.
- `settings.gd` preserves HELP_ROWS and _build_help_rows names while delegating saved-row synchronization to the shared help layout.
- `level_selection.tscn` reuses HelpOverlay/Panel/Margin/Content and the existing Heading, Instructions and CloseHelpButton paths. Panel, Margin and Content are now Controls so the shared artwork coordinates can position their contents. HelpFrame, HelpRows and the two top help controls were added inside this existing overlay. The level rows, locks, main PLAY control, title/background and gameplay routes were not redesigned.
- Original Instructions Labels remain hidden as readable text/data without drawing duplicate text. Native Back and GOT IT buttons close the existing overlay through its original close callback; the question icon focuses the instructions and has an explanatory tooltip.
- The Help overlay uses an opaque dark backing so the Level Selection PLAY button cannot appear behind the portrait art in tall windows. Pointer checks confirm that the open overlay blocks underlying PLAY input.
- The layout preserves the illustration's 3:4 proportions and centers it inside portrait viewports. Font sizes and wrapped rows adapt to available space after Godot's container layout passes.
- Existing Bree Serif/Roboto fonts and parchment-forest SVG navigation artwork were reused.
- No new Autoload, scene-navigation controller, online service, save schema or gameplay system.

## Rules preserved

The user's image is the visual reference. Its incorrect instructional text was corrected to the actual code:
- Correct answer: +10 points.
- Wrong answer: -2 points, never below zero.
- Answer first; either result allows the roll.
- Ladders, snakes, shields and exact-roll completion retain their current meanings.
- Bonus wording says that tiles **can** give extra points; existing level bonus values were not changed.
- Eleven numbered rows consolidate the old Settings overlay's twelve rows by combining its two opening question/answer instructions.

No score values, dice logic, board layout, character rewards, level-unlock rules or historical data were modified.

## Verification executed

Godot 4.7.1 stable on Windows, rendered desktop tests:

| Suite | Passed | Failed |
| --- | ---: | ---: |
| tests/how_to_play_design_test.gd | 1132 | 0 |
| tests/settings_design_test.gd | 303 | 0 |
| tests/level_selection_layout_test.gd | 645 | 0 |
| tests/level_selection_test.gd | 97 | 0 |
| tests/how_to_play_design_test.gd (Editor mode) | 53 | 0 |
| Total | 2230 | 0 |

All five runs exited 0. The new suite checks both actual Settings and Level Selection scenes at 1024×1536, 720×1280, 1086×1448, 1080×1920, 1080×2340 and 1080×2400. Checks cover wrapped-text bounds, all eleven rows, title fitting, scoring consistency against all six catalog levels, absence of an extra PLAY button, pointer Back/GOT IT actions, focus restoration, question-icon focus and blocked background PLAY input. Existing suites verify Music/SFX toggles and persistence, level locks/unlocks and saved progression, main-menu entry and navigation.

Rendered captures are saved to `user://how_to_play_library_settings_<width>x<height>.png` and `user://how_to_play_library_levels_<width>x<height>.png`. Settings and Level Selection renders at 1024×1536, Settings at 720×1280 and Level Selection at 1086×1448 were visually reviewed.

Real save hashes remained unchanged:
- `historyroll_settings.cfg`: `27A5E3EDB4F0918F4713B9A2E16709CBA02FD6030E50457B85C632D2581AA45D`
- `historyroll_progress.json`: `7493D1B3ABDBF9A8A779E9D7357E7D94AA4CE9BD523818A374DB58F346D384CC`

Known environment messages: headless editor import reports this machine's external text-editor launch failure and falls back to Godot's internal editor. Some test processes report one ObjectDB instance at shutdown, consistent with the existing procedural-audio fallback teardown warning. No script parse errors were observed in the completed suites. The custom Editor-mode render test also emitted native Editor progress-dialog/current_window messages while completing all checks. Physical Android testing has not been performed.

## Manual verification

1. Let Godot import the two new PNGs and shared script.
2. Run the game, open Settings and choose How to Play.
3. Verify the library art, leaf-free open-book title, numbered rules and green GOT IT button.
4. Press GOT IT and confirm you return to Settings; reopen and use the top Back icon.
5. Open Level Selection, press its question icon and verify the same help design. Its Back/GOT IT controls return to Level Selection without starting a level.
6. Confirm Music/SFX controls and the original Level Selection PLAY button work after closing help.


## Editor / PNG preview content fix

The first implementation constructed its instruction rows only during runtime, leaving the raw artwork and normal 2D Editor preview without their content. The fix saves Rule1 through Rule11, Number and Description Labels inside both existing scenes, and enables only the shared visual-layout script with @tool. It does not run the parent Settings or Level Selection gameplay scripts in the Editor.

- `preview_with_instructions.png` is the complete 1086×1448 Godot Editor-mode render, including the title, all eleven numbered rules, top icons and GOT IT. Open this PNG to preview the finished screen. It is a preview export, not the gameplay background texture.
- `frame.png` and `got_it.png` remain separate blank graphics so text can stay readable and editable in Godot.
- To inspect the scene in the 2D Editor, open `settings.tscn` and temporarily show `HowToPlayOverlay`, or open `level_selection.tscn` and show `UIRoot/HelpOverlay`. Restore the overlay's hidden state before saving if it should start closed.
- The Editor test directly rendered both panels with `Engine.is_editor_hint()` active: 53 checks passed.
- Runtime tests now verify that each PackedScene already contains all eleven rules before ready callbacks, and follow actual Main Menu -> Settings/Level Selection -> How to Play routes. Their main-game captures are `user://how_to_play_main_game_settings.png` and `user://how_to_play_main_game_levels.png`.
- Editor captures are `user://how_to_play_editor_settings_1086x1448.png` and `user://how_to_play_editor_levels_1086x1448.png`.
- The new complete PNG preview is a Godot rendering export. No artwork was regenerated for this follow-up.

## Generation record

Provider: built-in image generation tool under the imagegen skill.
Reference: the user's latest How to Play library image, supplied as the single reference image for each generation (`num_last_images_to_include: 1`).
Both calls requested `transparent_background: true`. The selected generated outputs were copied into the two final workspace asset paths above; no image editing through Python or an external image service was used. Title, rules, numbers and confirmation text are live Godot controls, rather than baked into either PNG.

### Final frame.png prompt

Use case: ui-mockup. Asset type: blank illustrated How to Play library UI backing for an existing portrait Godot mobile game. Image 1 is the user's newest reference and is the main visual and composition reference. Recreate its warm polished Philippine history library presentation at portrait 3:4 aspect ratio, with only a very narrow transparent outer margin. Keep the arched wooden library window at upper left looking onto a Philippine flag and stone bell tower, wooden beams and bookshelves, small glowing brass lantern on the left, a sepia illustration of Jose Rizal and the Philippine Revolution framed at upper right, a sepia historical stone fort illustration lower right, a globe on the right, rolled parchments and a map at bottom left, feather quill/inkpot and closed red/blue books at bottom right, polished wooden desk at bottom. Center a large pale cream parchment board with rounded corners, thick bright gold beveled edging and restrained gold corner scroll flourishes, spanning approximately x=17%-83%, y=20%-76%. Above the parchment put a wide dark-red plaque with thick gold edging spanning x=24%-77%, y=10%-20%, with an open cream book centered above it. The red title plaque must be completely BLANK. The entire parchment center must be completely EMPTY, with a calm uniform pale cream color; actual numbered rules will be live Godot text. Leave room around y=73%-80% for a separate green confirmation button but DO NOT draw that button. NO leaves, NO laurels, NO foliage anywhere around the title or button area. REMOVE all PLAY buttons and all bottom extra controls. Do not draw top-left Back or top-right question-mark icons; native buttons will be placed there. No words, letters, numbers, numbered coins, question marks, arrows, rules, captions, open-button outlines or watermarks anywhere. Keep the same friendly hand-painted illustrated game aesthetic, thick dark-brown outlines, warm gold/red/brown/cream colors, soft readable contrast. Entire frame, book and all desk props visible without cropped edges. True transparent alpha only outside the board/library outer silhouette; the illustrated library and parchment interiors are opaque.

### Final got_it.png prompt

Use case: ui-mockup. Asset type: a single transparent blank green confirmation-button plate for the HistoryRoll How to Play screen. Image 1 is the user's latest How to Play library reference; match the reference GOT IT button precisely in shape and materials. Create only one wide green capsule button with rounded ends, a bright green top gloss, darker green lower shading, a thick polished double gold/cream beveled border, a chunky dark-brown outline and compact lower shadow. About 3.5:1 overall. Entire green center must be completely BLANK because a native Godot Button will draw GOT IT as live text. No leaves, no laurels, no foliage, no side ornaments, no arrows, no checkmark, no text, no letters, no numbers, no other objects, no background scenery, no watermark. Entire capsule fully visible and tightly framed with minimal transparent padding. Warm polished friendly illustrated mobile game style. Actual transparent alpha outside the button silhouette.


## Background and navigation fit - 23 November 2026

- Moved the existing Back and question controls inward to (64, 56) and (912, 56) on the 1086x1448 design canvas. Their 110x110 bounds now sit on opaque artwork rather than its transparent rounded corners.
- Reduced question lettering from 80 to 64 design pixels and applied both navigation bounds after font/style overrides. This prevents saved Editor font minimums from enlarging the question button during its first layout pass.
- Settings HelpAspect now uses AspectRatioContainer.STRETCH_FIT (2). Both available width and height constrain the illustration, keeping the full background, title, Back and question controls visible in shorter development windows.
- Existing library PNG artwork, all eleven rules, GOT IT, Back behavior and Settings/Level Selection entry routes are retained. No images were regenerated.
- Refreshed preview_with_instructions.png from the actual Godot Editor-mode Settings help render.

Final verification executed with Godot 4.7.1:
- Runtime How to Play suite: 1374 passed, 0 failed; exit 0.
- Editor preview suite: 59 passed, 0 failed; exit 0.
- Total: 1433 passed, 0 failed.
- Runtime renders cover Settings and Level Selection at 1024x1536, 720x1280, 1086x1448, 1080x1920, 1080x2340, 1080x2400 and 1024x1055 (short development window).
- New checks sample background alpha underneath each navigation control, compare the button bounds, and check actual main-game control visibility after navigating from Main Menu.
- Reviewed the phone render, complete Editor preview and actual main-game Settings help capture. Pointer tests retain question focus, Back/GOT IT closing and blocking of underlying PLAY.
- Final logs contain no script/parse errors. Editor-mode runs still report current_window/external-editor configuration and shutdown RID/ObjectDB warnings.
- Settings and progress SHA-256 values remain unchanged. Physical Android testing was not performed.

Run the existing project, open Settings -> How to Play or Level Selection -> ?, and check both top icons. No Inspector changes are required.

## Level Selection question-button content - 23 November 2026

The existing Level Selection question button opens its existing HelpOverlay. level_selection.gd now explicitly refreshes the panel from HowToPlayPanel.RULES on every open, the same shared eleven-rule source used by Settings, and exposes a How to Play tooltip. No duplicate panel, rules database, nodes or gameplay controller was created.

Executed focused verification: tests/how_to_play_design_test.gd -- --quick, 234 passed / 0 failed, exit 0. Both Settings and Level Selection were rendered, all eleven visible rule rows checked, and actual Main Menu entry plus question-icon, Back and GOT IT pointer interactions exercised. The actual main-game Level Selection help capture was visually reviewed. The run has no script/parse errors; one existing ObjectDB shutdown warning remains. Physical Android testing was not performed.

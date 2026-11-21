# Heritage Courtyard Level Selection

Applied to the existing HistoryRoll scene on 21 November 2026 using the user's Philippine heritage courtyard reference. This is a close visual recreation assembled from separate artwork and live controls, not a pixel-identical extraction.

## Integration

Created in res://assets/level_selection_pixel/heritage_courtyard/:

- background.png: opaque cobblestone courtyard, bahay-na-bato balcony, church facade/tower, Philippine flag, sky, trees, cart wheel, jar and edge props.
- title.png: transparent open book, gold rays, burgundy ribbon and blank red/gold title plaque, without laurel leaves.
- play.png: transparent rounded red/gold PLAY button and triangle, without leaves on either side.
- Matching Godot .import descriptors and this README.

Modified:

- res://level_selection.tscn: points its existing background/title/PLAY controls at the new artwork, places the book crest above the level list, and renders the existing live title in cream with a dark outline. Generated alpha is preserved with linear filtering for these new controls.
- res://level_row.tscn: vertically centers the existing LockIcon with 0.5 anchors and +/-48 offsets. Its size and horizontal margin are preserved.
- res://tests/level_selection_test.gd: verifies the new artwork while retaining fresh-player, automatic unlock and persistence coverage.
- res://tests/level_selection_layout_test.gd: checks title lettering bounds and separation from Level 1, preserves rendered navigation/state coverage, and stops procedural audio before test teardown.

No new scene, node, Autoload, input action or duplicate control was created. Existing row names, individual Editor positioning, portraits, live complete hero names, frame textures, button animations, ProgressManager, selected-level logic, saves, gameplay, Main Menu and Settings are retained. Fresh players have Level 1 unlocked and five locked levels; returning players keep their legitimate saved unlocks.

The title and PLAY contain no leaf ornaments. Natural scenery foliage remains, as in the reference. The prior Parchment Forest assets are retained. The existing Back and Help controls retain their artwork and functionality.

CHOOSE YOUR LEVEL remains a live Label. The title asset contains no baked text. PLAY is rendered once in its PNG; the existing PlayLabel remains hidden. Bree Serif remains the licensed project font for live headings and hero names. The reference's original typeface was not identified, so an exact font match is not claimed.

## Padlock correction

The existing Level 4 row has a -4-unit top offset, making it 148 units high while the other rows are 144. The former fixed lock position was centered only for 144-unit rows and failed the centering assertion in all six viewport captures. Center anchors now keep the lock centered for both sizes without changing the manually positioned row.

## Verification actually performed

Godot 4.7.1 desktop, Compatibility renderer; Dummy audio:

| Suite | Passed | Failed | Exit |
| --- | ---: | ---: | ---: |
| tests/level_selection_test.gd | 97 | 0 | 0 |
| tests/level_selection_layout_test.gd | 645 | 0 | 0 |
| Total | 742 | 0 | |

- Imported all three PNGs successfully. Background is 1024x1536; title and PLAY are 2172x724. Original output files and alpha were copied intact; no CLI/API fallback or raster pixel editing was used.
- Rendered 1024x1536, 720x1280, 1086x1448, 1080x1920, 1080x2340 and 1080x2400.
- Visually reviewed actual Godot renders at 1024x1536 and 720x1280 and the actual-project Main Menu entry capture.
- Verified title fits its plaque, six complete names fit, portraits have text spacing, locks fit and stay centered, fresh-player state has exactly five locks, and returning-player unlocks retain full colors.
- Verified Level 2 unlocks after Level 1 completion and Level 3 after Level 2; isolated test-save reloads preserve these unlocks.
- Actual pointer events reach PLAY and request the existing gameplay scene once. Help opens/closes. Actual Main Menu navigation opens this scene using the real Autoload; Back restores Main Menu.
- An initial layout run reported 639 passes and six failures, all for Level 4 lock centering; the final run after the anchor correction passed all 645 checks.
- git diff --check passed.

The actual player's settings SHA-256 remained 27A5E3EDB4F0918F4713B9A2E16709CBA02FD6030E50457B85C632D2581AA45D. The progress SHA-256 remained 7493D1B3ABDBF9A8A779E9D7357E7D94AA4CE9BD523818A374DB58F346D384CC.

Remaining environment messages: the headless state suite logs one ObjectDB instance at shutdown and exits with code 0. The import-only Editor logs this machine's existing external-text-editor launch error and exits with code 0. AudioManager still reports its built-in fallback for missing .ogg tracks. Final gameplay/UI test logs contain no script, missing-resource or rendering errors.

Physical Android input, device safe areas, device performance and audible audio were not tested.

Captures: user://level_selection_1024x1536.png, user://level_selection_720x1280.png, corresponding portrait sizes, user://level_selection_returning_1024x1536.png, and user://level_selection_actual_project.png.

## Manual check

1. Stop the previous running game and press F5.
2. Let the loading intro finish, then choose Start Game.
3. Confirm the courtyard, leaf-free book title and leaf-free red PLAY button.
4. Check names and locks. Existing saved unlocks remain in effect.
5. Open Help, close it, select an available level, press PLAY and return through Back.

No Inspector setup, signal wiring or save reset is needed.

Run with the installed Godot executable:

- Godot --headless --path . --script res://tests/level_selection_test.gd --audio-driver Dummy
- Godot --path . --script res://tests/level_selection_layout_test.gd --audio-driver Dummy

## Final image-generation prompts

All three assets used the built-in imagegen tool with the user's latest uploaded reference as Image 1. The title and PLAY requested transparent backgrounds; the scenery requested an opaque background.

### background.png

Use case: precise-object-edit. Asset type: opaque portrait scenery plate for the existing Godot mobile game HistoryRoll Level Selection. Image 1 is the user's newest uploaded level-selection reference and is the exact composition/style reference. Recreate ONLY its Philippine heritage courtyard environment, extending the areas hidden by all removed UI: warm old cobblestone plaza/path receding through the center, timber-and-stone bahay-na-bato balcony building along the left side, a richly detailed weathered colonial stone church facade and bell tower along the right side, a Philippine flag hanging at the right edge, blue sky with small soft clouds and green tree canopy framing upper corners. Bottom left an old wooden cart wheel and earthenware jar; bottom right a low nipa awning and a few stacked closed books at the edge; lush tropical greenery around the scene edges. Keep the center calm and naturally continuous for six separately rendered level buttons. Match the reference's warm, polished storybook game illustration with chunky dark-brown outlines, gold/ochre accents, rich leafy greens and soft painterly pixel-style shading. Portrait ratio 2:3. Remove ALL title/banner/logo, book crest, golden leaves attached to UI, back/help icons, portraits, level cards, locks, numbers, lettering and PLAY button. No people, no text, no game interface baked into the scenery. Natural environmental tree leaves remain. Fully opaque edge-to-edge artwork, no watermark.

### title.png

Use case: precise-object-edit. Asset type: a single transparent title crest/banner asset for the existing HistoryRoll Level Selection screen. Image 1 is the user's newest uploaded reference and is the precise title design reference. Recreate ONLY the upper book-and-ribbon title crest, but REMOVE ALL GOLDEN LAUREL LEAVES FROM BOTH SIDES. Keep the open cream historical book at top center with golden rays behind it, a layered deep red and burgundy ribbon curling behind the title, and the central dark reddish-brown horizontal title plaque with a thick polished gold/ochre beveled rim, dark-brown outline and tiny gold diamond below its center. The central plaque must be COMPLETELY BLANK because the existing Godot Label will render CHOOSE YOUR LEVEL. Keep a wide, flat spacious blank horizontal lettering area in the LOWER HALF; book and rays rise above it. Ratio about 3.3:1 overall, entire crest including rays and ribbon ends fully visible with minimal transparent margins. Match Image 1's warm polished storybook-game illustration, chunky brown outline, softly shaded gold trim and cream/red palette, compatible with pixel-style hero cards. No leaves, no laurels, no flowers anywhere on this crest. No text, letters, numbers, separate icons, scenery, portraits or watermark. Real transparent alpha outside the crest; no white or colored backdrop. Deliver ONE crest only.

### play.png

Use case: precise-object-edit. Asset type: one transparent PLAY button for the existing HistoryRoll Level Selection screen. Image 1 is the user's newest uploaded reference and is the precise PLAY style reference. Recreate ONLY the bottom red PLAY button, but REMOVE ALL GOLDEN LAUREL LEAVES ON ITS LEFT AND RIGHT. Keep a chunky horizontally rounded capsule shape, rich dark-red/burgundy inner fill, subtle bright red upper gloss, double cream-and-polished-gold bevel rim, dark chocolate outline and small bottom shadow. Put the golden yellow right-pointing play triangle on the left and large cream bold serif lettering with dark-brown outline/shadow reading EXACTLY 'PLAY' centered to its right. Match the exact overall visual style of Image 1: warm polished storybook mobile-game art, strong readable silhouettes, soft gold highlights. Width to height approximately 3.3:1. Button must be entirely visible, tightly framed with a narrow transparent margin. NO leaves, no laurels, no flowers, no vines, no ornaments sticking out from either side, no extra text, no scenery, no watermark. Actual transparent alpha outside the button silhouette.

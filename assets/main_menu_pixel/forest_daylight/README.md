# Daylight Forest Main Menu

Applied to the existing HistoryRoll menu on 20 November 2026 from the user's bright-blue-sky pixel-art reference. The final action is Quit, using the existing QuitButton and quit callback.

## Integration

Created in this folder:
- background.png: blue sky, trees, tropical mountains, grass, daisies, stepping-stone path, lantern and books on the left pillar.
- logo.png: separate HISTORY / ROLL parchment logo, quill and small golden sun.
- explorers.png: transparent pair of full-body Filipino chibi explorers.
- Godot .import descriptors for each PNG and this README.

Modified:
- res://main_menu_tscn.gd: responsive logo, button spacing and independent explorer placement.
- res://main_menu_tscn.tscn: references to these three PNGs, AtlasTexture crop regions and matching editor defaults.
- res://tests/main_menu_redesign_test.gd: new scenery path and current Quit/foreground descriptions.

Reused unchanged:
- The four native StartButton, HeroCardsButton, SettingsButton and QuitButton nodes, plus their Caption, ActionIcon and PlankArt children.
- assets/main_menu_pixel/forest_story/wooden_button.png, play.svg, cards.svg, settings.svg, quit.svg and pixel_cutout.gdshader.
- Existing Bree Serif font and its existing SIL Open Font License.

No nodes were added, deleted, renamed or reparented. The legacy HistoryRollLogo node was not recreated. Old menu assets are retained. The submitted image is a visual reference, not a pixel-identical asset extraction.

Labels remain live text: Start Game, Hero Cards, Settings, Quit. Buttons keep their Tween hover/press/release behavior, sound requests, input-transparent decorative children and single-transition protection. Start Game opens Level Selection, Hero Cards opens the existing cards scene, Settings opens the existing Settings scene, and Quit requests application exit.

The background stays stationary and covers the viewport without stretching. The logo and two explorer figures preserve their source aspect ratios. The lantern/books are part of the background, not duplicated in the character sprite. Wider scenery is naturally cropped on tall phone displays. The complete explorers remain inside the screen with a visible path below them.

## Verification

Executed in Godot 4.7.1 desktop:
- tests/main_menu_redesign_test.gd: 370 assertions passed, 0 failed.
- tests/main_menu_foliage_test.gd: 12 assertions passed, 0 failed.
- Total: 382 assertions passed, 0 failed.
- Rendered 1086x1448, 1024x1536, 720x1280, 1080x1920, 1080x2340 and 1080x2400.
- Visually reviewed the reference-size, phone and tall-phone renders.
- Checked all four labels and routes, Quit callback, icon hit-testing, hover/press/release animation, live resize and a simulated touchscreen tap.
- Checked Music OFF, Sound Effects OFF, retained music stream, Settings persistence and stationary scenery.
- git diff --check passed.
- The actual player progress SHA-256 remained 7493D1B3ABDBF9A8A779E9D7357E7D94AA4CE9BD523818A374DB58F346D384CC.
- The pre-existing user edit to level_selection.tscn was preserved byte-for-byte: SHA-256 3EE30DCFB61D462B79E457CCEB48A1C2DC1CED97A8A8AF4445B8281B83641562.

Existing ObjectDB shutdown warnings remain in the test runs (two/four instances). The headless Editor import also reports this machine's existing external-text-editor launch configuration warning. The menu tests reported no script, shader, missing-resource or runtime errors. Physical Android testing was not performed.

Captures: user://main_menu_1086x1448.png, user://main_menu_720x1280.png and corresponding main_menu_WIDTHxHEIGHT.png files.

Manual verification: stop the running game, press F5, let the existing splash screen finish, then verify the Main Menu. Hover/press each wooden sign, open Level Selection, Hero Cards and Settings, return to the menu, and press Quit. No Inspector changes are required.

Reusable commands:
- Godot --path . --script res://tests/main_menu_redesign_test.gd --audio-driver Dummy
- Godot --headless --path . --script res://tests/main_menu_foliage_test.gd

## Image generation and prompts

The built-in image_gen tool was used; no CLI/API fallback. Selected PNG outputs were copied into this project folder without editing their raster pixels. AtlasTexture regions fit transparent padding, and the existing shader provides crisp alpha edges.

### background.png

Use case: precise-object-edit. Asset type: opaque portrait background plate for the EXISTING Godot HistoryRoll menu, ratio 3:4. Input image 1 is the user's NEW desired bright-blue-sky main menu and is the composition target. Images 2 and 3 are old logo/foreground assets for context only. Image 4 is the old muted-green runtime menu which must be changed, not copied. Recreate ONLY the scenery from image 1, extending it naturally behind removed UI and characters. Bright clear cyan-blue sky with white/cream pixel clouds; big leafy tree canopies and trunks framing upper corners and sides, distant layered blue and green tropical Philippine mountains. Green grass clearing, leafy plants, small white daisies and rocks. A winding light tan stepping-stone path leads from the middle distance down the CENTER all the way to the bottom edge. At lower LEFT keep the short weathered stone pillar with two red/gold books and a glowing brass lantern, approximately y=70%-85%; bottom-left rock and foliage. Keep quiet scenery at lower center-left and lower right for separate character sprites. REMOVE BOTH explorers. REMOVE ALL UI: no logo, scroll, sun emblem/rays, wooden signs, menu buttons, ropes, action icons, letters, numbers or any text. Do not include a low sun in the sky; a sun emblem will be part of the separate logo. Match image 1's crisp 16-bit pixel-art clusters, warm dark brown outlines, vibrant but comfortable blue/green/gold palette, cheerful educational adventure look. Full bleed opaque background, no framing border, no watermark.

### logo.png

Use case: background-extraction. Asset type: standalone transparent HistoryRoll logo for the existing mobile game's Main Menu. Image 1 is the NEW desired blue-sky menu reference; Image 2 is the existing separate logo. Images 3/4/5 are contextual old foreground/old screen/new scenery. Recreate ONLY the logo from image 1 in the same crisp warm pixel-art style: golden parchment scroll with rolled ends, thick rich dark-brown pixel outline/shadow; huge golden-yellow word HISTORY on the first line and cream-white word ROLL on the second line; cream feather quill rising at upper right. Include the small golden half sun with five short gold/orange rays rising above the center of the scroll, as in image 1. Keep the silhouette wide and compact, the same relative scale of lettering, quill, parchment and sun. Text MUST read exactly HISTORY and ROLL, no extra letters. Isolate the COMPLETE logo, sun and quill together on real transparent alpha. Approximate total silhouette ratio 2.3:1, minimal transparent padding. No sky, scenery, buttons, people, extra symbols or watermark. Pixel-art clusters and flat pixel shading, not vector or smooth 3D.

### explorers.png

Initial prompt: Use case: precise-object-edit. Asset type: transparent wide foreground sprite group for HistoryRoll's existing Main Menu. Image 1 is the existing two Filipino explorer characters; image 2 is the NEW bright pixel-art background for style and lighting. Recreate ONLY the TWO children as smaller fully visible FULL-BODY chibi figures, naturally standing on the same baseline. Boy at left, around 25% of canvas width: straw sun hat, brown hair, friendly smile, cream short-sleeve shirt, red neck scarf, brown shorts, backpack and brown hiking boots, holding an unfolded old parchment map at chest/waist. Girl at right, around 77% of canvas width: long brown hair, small white flower at ear, cream blouse, red skirt and history book. Preserve friendly expressions, pixel-art shading and transparency. No scenery, lantern, books on ground, UI or lettering.

Selected refinement prompt: Refine this transparent game sprite group with ONE targeted change: make both children stockier, shorter CHIBI proportions, about TWO heads tall from hat/hair to feet, so the combined two-figure silhouette is approximately 1.8:1 width-to-height. Keep both complete full bodies, the boy's straw hat/map/backpack/boots and the girl's white flower/book/red skirt. Broaden their heads slightly and shorten their torsos and legs; retain appealing natural anatomy and the warm friendly expressions. Boy stays left, girl stays right, same standing baseline with an open center gap. Preserve this exact crisp brown-outlined warm pixel-art style and clothing palette. No scenery, no lantern, no books on ground, no extra props or ground strip. Real transparent alpha around and between both figures. Keep small transparent padding, no cropped hat, hair or feet. No lettering or UI. Deliver the two children only.

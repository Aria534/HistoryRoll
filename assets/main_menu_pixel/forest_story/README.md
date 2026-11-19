# Forest Story Main Menu

Applied to the existing HistoryRoll menu on 20 November 2026, using the user's warm pixel-art reference.

## Files and integration
- Four new generated PNGs in this folder: forest background, two-line parchment logo, blank wooden plank, and the two-explorer foreground with lantern/books.
- Four project-native SVG action icons: play, cards, settings and quit.
- pixel_cutout.gdshader renders crisp alpha edges while preserving CanvasItem fades and press tinting. Source PNGs retain their original alpha.
- Existing scene: res://main_menu_tscn.tscn.
- Existing controller: res://main_menu_tscn.gd.
- Regression entry point: res://tests/main_menu_redesign_test.gd.

StartButton, HeroCardsButton, SettingsButton and QuitButton remain native TextureButtons with their existing callbacks and Tween animation. Each has a PlankArt child for the decorative rope/leaf area, an ActionIcon and the existing Caption. The touch rectangle follows the sign body; the decorative children ignore input. The logo and bottom explorers remain separate artwork and keep their aspect ratios. Editor defaults match the project's 1024x1536 canvas; runtime layout adapts to portrait viewports and the existing Android safe-area helper.

The navigation remains:
- Start Game -> Level Selection.
- Hero Cards -> Hero Cards.
- Settings -> existing Settings.
- Quit -> quits the game.

The existing AudioManager music request and Music/SFX preferences remain in use. Gameplay, progression, hero data, saves and other scenes were not modified. The legacy HistoryRollLogo node was not recreated. Earlier menu assets are retained.

No Godot Inspector setup is needed. Run F5 to use the menu through the existing splash screen, or F6 from the existing menu scene.

## Typography
Labels use Bree Serif with a Godot FontVariation embolden setting, cream fill and brown outline/shadow. This is an approximate recreation; the reference's original typeface was not identified.
The font is in assets/fonts/BreeSerif-Regular.ttf, with its SIL Open Font License and TypeTogether attribution in assets/fonts/BreeSerif-OFL.txt.
Source: https://github.com/google/fonts/tree/main/ofl/breeserif

## Executed verification
Godot 4.7.1 desktop:
- Main Menu rendered layout/navigation/settings/input suite: 370 assertions passed, 0 failed.
- Stationary scenery, navigation connections and Music/SFX ON/OFF suite: 12 assertions passed, 0 failed.
- Total: 382 assertions passed, 0 failed.
- Rendered 720x1280, 1080x1920, 1080x2340, 1080x2400, 1024x1536 and the reference's 1086x1448.
- Reviewed native-reference, phone and tall-phone captures visually.
- Tested pointer clicks through the action icons, one-time navigation, Quit callback, hover/press/release behavior, live resizing, and a simulated touch tap.
- Launched the actual project through its existing splash screen; no script/shader/runtime errors appeared in the boot log.
- Real player progress file's SHA-256 stayed unchanged.
- Test runs and the startup smoke run still report pre-existing ObjectDB shutdown warnings. Headless editor imports also report this machine's existing external-text-editor launch configuration warning.
- No physical Android testing was performed.

Reusable test commands:
Godot --path . --script res://tests/main_menu_redesign_test.gd --audio-driver Dummy
Godot --headless --path . --script res://tests/main_menu_foliage_test.gd

Captures are written to user://main_menu_WIDTHxHEIGHT.png.

## Artwork prompts
Built-in image_gen was used with the uploaded menu as reference. These assets are visual recreations, not pixel-identical extractions. No image API/CLI fallback was used.

### background.png
Use case: precise-object-edit. Asset type: opaque portrait background plate for an existing mobile game. Input image 1 is the user's desired HistoryRoll Main Menu. Recreate its warm pixel-art forest landscape and exact palette: muted sage green mountain layers, sun and golden rays behind the upper center, softly glowing yellow-green light, pixel clouds, tree canopies framing top corners and sides, tropical plants and grass around bottom rocks. Remove ALL menu interface, lettering, logo, parchment, quill, wooden signs, ropes, icons and button-attached leaves. ALSO remove the two child explorers, lantern and book stack; those will be separate foreground art. Fill the removed regions naturally with quiet forest/mountain scenery, leaving the center uncluttered. Match the reference's large crisp pixel clusters, warm brown outlines, golden sunlight and cozy educational adventure atmosphere. No text, no UI, no people, no watermark. Full bleed portrait 3:4.

### logo.png
Use case: background-extraction. Asset type: separate transparent game logo PNG. Input image 1 is the user's desired menu. Recreate only its logo closely: rolled golden parchment scroll, warm dark brown outlines and shadows, large chunky golden-yellow word "HISTORY" on the first line and cream-white word "ROLL" on the second line, small cream feather quill at upper right, in that exact warm pixel-art style. Keep the big two-line lettering, sunlit edges, curled scroll ends and the same overall proportions. Do not include the sun rays or green scenery; these belong to the background. Single logo, centered on a wide horizontal canvas, minimal transparent margins, genuinely transparent outside the artwork. Exact text, no other lettering. Crisp deliberate pixel clusters, no smooth vector or glossy 3D styling.

### wooden_button.png
Use case: precise-object-edit. Asset type: transparent reusable TextureButton background for the four menu actions. Input image 1 is the desired menu. Recreate one horizontal hanging wooden plank sign matching its Start Game/Hero Cards wooden sign: warm russet orange-brown wood grain, gold top-edge highlights, dark brown chunky pixel-art outline and lower shadow, rounded/chipped corners, small golden rope loops near the two upper and lower corners, a few small green leaves attached at the left and right ends. Single plank, long horizontal shape, approximately 4.8:1 including trim. Leave the ENTIRE front surface blank: NO WORDS, NO LETTERS, NO ICONS, NO symbols. Text and icons will be rendered separately by the game. Make its center broad and calm enough for a cream-colored label and left icon. Minimal transparent margins. Genuine transparent alpha around the plank, ropes and leaves. Same crisp pixel clusters and warm shading as reference, no background, no extra boards.

### explorers.png
Use case: background-extraction. Asset type: transparent wide foreground illustration for the bottom of a portrait menu. Input image 1 is the user's desired menu. Closely recreate ONLY the bottom foreground group: cheerful Filipino chibi boy explorer in broad straw hat, red neck scarf, cream shirt, shorts, brown backpack and boots, holding an old parchment map; smiling Filipina chibi girl with long brown hair and a small white flower at her ear, cream blouse and red skirt, holding a brown history book with a small golden sun motif. At far left include the warm glowing brass lantern and stack of red/brown books on the weathered stone ledge. Keep the same proportions, poses, friendly faces, clothing colors, reference's warm crisp pixel art with chunky brown outlines. Include a little bottom-edge stone and foliage so the group sits naturally at the bottom of the screen. Maintain the original composition: lantern/books on left, boy at center-left, girl on right, with all heads and key objects fully visible. A single wide foreground group with minimal empty border and genuine transparency above/between figures and outside the group. No scenery, no sky, no mountains, no title, no menu signs, no text, no watermark. Do not add people.

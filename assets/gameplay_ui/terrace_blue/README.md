# Terrace Blue gameplay skin

Recreates the user's supplied blue/cream rice-terrace gameplay reference with independent artwork and working Godot controls.

## Artwork and provenance
The five PNGs were produced with the built-in image_gen tool, using the uploaded reference. The landscape is scenery only. The logo and three friendly snake heads retain transparent alpha. This is a visual recreation, not a pixel-identical extraction.
The SVGs are project-native scalable UI artwork: two tile skins, back arrow, die, status strip, button base, and HUD icons. Tile numbers, snakes' curved bodies, ladders, board frame, special icons and hero movement remain rendered from live board data.

## Integration
- Shared scene: res://gameplay_placeholder.tscn
- Renderer: res://board_view.gd
- Layout: res://gameplay_placeholder.gd::_update_gameplay_layout
- No Autoload, input action, save schema, progression, question data or board mapping changes.
- All six levels keep their configured tile counts and connections.
- Correct/wrong scoring, question-first popup, chibi reactions and the matching on-board die remain functional.
- Roll Dice stays disabled until a question is answered and during a turn.
- The Back icon remains a native Button and returns to Level Selection.
- No editor setup is needed; the existing level navigation opens this shared scene.
- Original visual resources are retained so this skin can be revised without losing earlier artwork.

## Font
UI serif lettering uses Lora Italic, weight 700, via Godot FontVariation. This is a close visual choice, not a claim that the source typeface was identified.
Source: https://github.com/google/fonts/tree/main/ofl/lora
The unmodified variable font is saved as assets/fonts/Lora-Italic.ttf; its SIL Open Font License and attribution are in assets/fonts/Lora-OFL.txt.
Other screens retain their fonts.

## Verification
Run with Godot 4.7.1:
- --headless --path . --script res://tests/question_first_redesign_test.gd
- --headless --path . --script res://tests/question_popup_test.gd
- --path . --script res://tests/gameplay_redesign_layout_test.gd --audio-driver Dummy

The layout test renders all six boards at 1024x1536, plus Level 1 at 720x1280, 1080x1920 and 1080x2400, and Level 6 at 720x1280. It saves both popup and playable-board captures to user://gameplay_level_*_ready.png, and checks bounds, separation, square cells, live tokens and answering-to-roll behavior.
The tests use mock progress or isolated test save paths, not the player's actual progress.
Desktop captures do not constitute physical Android testing.

Verified in Godot 4.7.1 on 19 November 2026:
- Gameplay regression: 115 assertions passed, 0 failed.
- Question popup: 12 assertions passed, 0 failed.
- Rendered layouts and pointer controls: 415 assertions passed, 0 failed.
- Total: 542 assertions passed, 0 failed. Final test logs contain no script or rendering errors.
- Actual pointer input reaches Answer, Roll Dice and the round Back icon. Rapid double clicks produce one turn. Back loads the real Level Selection scene.
- The actual player progress file's SHA-256 was unchanged before and after verification.
- A pre-existing one-instance ObjectDB shutdown warning remains in the popup/layout test runs. The headless editor import also reports this machine's external-editor launch configuration warning; gameplay runs do not report it.
- Physical Android performance, touch input and device safe areas remain unverified.

Manual check: run the project, start Level 1, answer the popup, press Roll Dice, compare the on-board die with movement, then use the round Back icon. The larger levels use this same scene automatically. No Inspector changes are required.

## Image prompts (built-in tool)
### background.png
Use case: precise-object-edit. Asset type: portrait mobile game background scenery, approximately 3:4. Input image 1 is the user's gameplay design reference. Reproduce ONLY its Philippine rice terraces landscape and atmosphere as a clean background plate, extending scenery naturally behind removed UI. Bright cyan sky and white fluffy clouds, layered blue mountain ridges, sunrise in the upper right, lush green terraces on both sides of a valley, two small nipa huts at lower right, bushes and trees. Match the reference's cheerful polished outlined cartoon illustration and blue-green-gold palette. Remove ALL interface: no board, no tiles, no snakes, no ladders, no numbers, no title, no back arrow, no buttons, no icons, no text. Keep center calm for a large game board. Full bleed opaque background.

### logo.png
Use case: background-extraction. Asset type: separate transparent wide logo PNG for Godot. Input image 1 is the gameplay reference. Isolate/recreate only the HISTORYROLL logo at the top: large bold slightly arched cream-white uppercase slab-serif letters with dark navy thick outline and deep blue shadow, on the aqua/teal curled parchment scroll with cream band and gold rim. Exact text: "HISTORYROLL". Match its shape, proportions, color, scroll ends and polished cartoon look closely. Logo centered filling a wide horizontal canvas with minimal empty margins. Everything outside logo genuinely transparent. No landscape, no sun, no buttons, no board, no other text.

### snake_orange.png
Use case: background-extraction. Asset type: transparent game snake head sprite. Input image 1 is the user's board reference. Recreate ONLY the cute orange/yellow smiling snake HEAD plus a very short neck from the left side of that reference. Large shiny black eyes with white highlights, soft orange spots, cream muzzle, pink cheeks, friendly open smile with tiny red tongue, thick smooth dark navy outline, polished rounded cartoon game art. Upright head in three-quarter view looking slightly right; do not rotate. Single head centered, fills square canvas with very little transparent margin. No full snake body, no background, no tile, no text, no border. Actual transparent alpha.

### snake_green.png
Use case: background-extraction. Asset type: transparent game snake head sprite. Input image 1 is the user's board reference. Recreate ONLY the cute lime-green/yellow smiling snake HEAD plus a very short neck from the top-right of that reference. Large shiny black eyes with white highlights, soft green spots, cream muzzle, pink cheeks, friendly open smile with tiny red tongue, thick smooth dark navy outline, polished rounded cartoon game art. Upright head in three-quarter view looking slightly left; do not rotate. Single head centered, fills square canvas with very little transparent margin. No full snake body, no background, no tile, no text, no border. Actual transparent alpha.

### snake_blue.png
Use case: background-extraction. Asset type: transparent game snake head sprite. Input image 1 is the user's board reference. Recreate ONLY the cute sky-blue smiling snake HEAD plus a very short neck from the lower-right of that reference. Large shiny black eyes with white highlights, blue spots, cream muzzle, pink cheeks, friendly open smile with tiny red tongue, thick smooth dark navy outline, polished rounded cartoon game art. Upright head in three-quarter view looking slightly right; do not rotate. Single head centered, fills square canvas with very little transparent margin. No full snake body, no background, no tile, no text, no border. Actual transparent alpha.

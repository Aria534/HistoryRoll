# Parchment Forest Level Selection

Applied to the existing HistoryRoll project on 20 November 2026, using the user's warm pixel-art Level Selection reference.

## Integration
Modified files:
- level_selection.tscn: parchment title, forest scenery, six framed chibi portraits, wooden controls and PLAY artwork.
- level_selection.gd: fit the new scenery to the viewport; progression and navigation remain unchanged.
- level_row.tscn: shared parchment frame, separate portrait/name, cream-and-gold padlock.
- level_row.gd: optional separate-artwork mode, name fitting and Editor preview.
- tests/level_selection_test.gd and tests/level_selection_layout_test.gd: state, layout, persistence and navigation coverage.

The existing level button nodes, exported fields, class and navigation callbacks are retained. No ProgressManager, save schema, hero database, gameplay rules, quiz content or Main Menu files were changed.
Fresh progress enables Level 1 and locks Levels 2–6. Returning players retain their saved unlocks. Locks are driven by ProgressManager and disappear automatically when an existing progression rule unlocks a level; they are not baked into the row artwork.
Each row remains independently positionable in Godot's 2D Editor. The reusable row previews its exported name and portrait in the Editor. The optional embedded-artwork mode is retained for compatibility.

Names are live labels, not generated lettering:
LEVEL 1 - LAPU-LAPU
LEVEL 2 - ANDRES BONIFACIO
LEVEL 3 - JOSE RIZAL
LEVEL 4 - ANTONIO LUNA
LEVEL 5 - MELCHORA AQUINO
LEVEL 6 - APOLINARIO MABINI

## Assets
This folder contains 10 generated PNGs: background, blank title scroll, blank row panel, PLAY button and six framed portraits.
Three new project-native SVGs provide the wooden Back icon, Help icon base and cream/gold padlock.
The existing assets/main_menu_pixel/forest_story/pixel_cutout.gdshader is reused for crisp alpha edges. Original PNGs retain their alpha; their margins are fitted with Godot AtlasTexture regions.
Earlier level-selection assets remain available.

Bree Serif is reused from assets/fonts/BreeSerif-Regular.ttf, with its existing SIL Open Font License at assets/fonts/BreeSerif-OFL.txt. It provides consistent brown serif lettering, as a close visual choice; the reference's original typeface was not identified.

## Executed verification
Godot 4.7.1 desktop:
- Fresh-state/sequential-unlock/persistence suite: 95 assertions passed, 0 failed.
- Rendered layout/navigation suite: 585 assertions passed, 0 failed.
- Total: 680 assertions passed, 0 failed.
- Rendered 1024x1536, 720x1280, 1086x1448, 1080x1920, 1080x2340 and 1080x2400.
- Checked full names, portrait spacing, padlock alignment, five fresh-player locks, Help layout, PLAY hit testing and duplicate-transition protection.
- Verified Level 2 unlock after Level 1 completion, Level 3 unlock after Level 2, and persistence after reloading isolated test saves.
- Rendered returning-player progress with Levels 1–3 unlocked.
- Actual Main Menu navigation opened this Level Selection scene with the real Autoload, saved an actual-project capture, and returned through Back.
- The actual player save's SHA-256 was unchanged before and after testing.
- Final test logs contained no script, shader or runtime errors. Existing ObjectDB shutdown warnings remain; the headless Editor import also reports this machine's existing external-editor launch configuration warning.
- Physical Android device testing was not performed.

Run:
Godot --headless --path . --script res://tests/level_selection_test.gd
Godot --path . --script res://tests/level_selection_layout_test.gd --audio-driver Dummy

Captures are saved to user://level_selection_*.png, including level_selection_reference_1086x1448.png, level_selection_returning_1024x1536.png and level_selection_actual_project.png.
No Inspector setup is required. F5 -> Start Game opens the updated scene. Verify five padlocks on fresh progress, open/close Help, press PLAY for Level 1, then return using Back.

## Artwork prompts
Built-in image_gen was used with the uploaded design as the reference. These are visual recreations, not pixel-identical extractions. No CLI/API fallback was used. Portraits are stylized game illustrations.

### background.png
Use case: precise-object-edit. Asset type: opaque 3:4 portrait scenery plate. Input image 1 is the user's requested level-selection reference. Copy its background closely: muted sage green sky, small warm cream pixel clouds, tropical trees and leafy canopy at both upper corners, green mountain layers, pale sunlit peak at right, grassy fields/terraces, a weathered ivy-covered stone church/bell-tower ruin at the right, palm trees at left, lantern and a red book on a stone ledge at the bottom left, large rocks and plants at bottom right. Remove ALL interface, text, buttons, portraits, padlocks, title banner and UI frames. Fill those regions naturally with calm sky/mountain/field scenery. Warm pixel-art mobile educational game illustration matching input image 1: muted sage-green Philippine forest, cream parchment, warm brown outlines, golden edge highlights, large deliberate pixel clusters, friendly rounded chibi style. No smooth vector aesthetic, no glossy blue UI. Full bleed. No people, no text, no UI.

### title.png
Use case: precise-object-edit. Asset type: transparent blank title banner. Input image 1 is the reference. Closely recreate ONLY the cream/gold parchment title scroll at the top, wide horizontal shape with gently uneven upper edge, curled lower ends, dark brown outline, warm orange shading. Leave the ENTIRE parchment blank, no text or symbols; the game will render "CHOOSE YOUR LEVEL" separately. Warm pixel-art mobile educational game illustration matching input image 1: muted sage-green Philippine forest, cream parchment, warm brown outlines, golden edge highlights, large deliberate pixel clusters, friendly rounded chibi style. No smooth vector aesthetic, no glossy blue UI. Canvas wide, minimal empty margins, actual transparency outside the scroll. No background, no other objects.

### row.png
Use case: precise-object-edit. Asset type: transparent blank horizontal level-row UI panel. Input image 1 is the reference. Recreate ONLY the long cream parchment nameplate behind each hero name. Pale warm yellow parchment center, caramel inner trim and highlights, sturdy dark-brown wood outline/shadow, clipped/beveled right corners, subtle golden curling Filipino-style scroll ornament at the right end. Long rectangular nameplate, approximately 6:1. The left edge is simple and will be covered by a separate portrait frame. No portrait frame in this asset. Leave the center and left entirely blank: NO TEXT, NO LETTERS, NO numbers, NO hero, NO padlock, NO stars. Warm pixel-art mobile educational game illustration matching input image 1: muted sage-green Philippine forest, cream parchment, warm brown outlines, golden edge highlights, large deliberate pixel clusters, friendly rounded chibi style. No smooth vector aesthetic, no glossy blue UI. One panel only, transparent outside the panel, minimal empty margins, no backdrop.

### play.png
Use case: background-extraction. Asset type: transparent mobile game PLAY button artwork. Input image 1 is the reference. Closely recreate its bottom-center PLAY button: wide chunky brown wooden horizontal button with clipped/beveled corners, double golden-orange and cream rim, thick dark brown pixel outline and bottom shadow. At left a cream/golden play triangle; at center-right large bold cream slab-serif lettering with dark brown shadow spelling exactly "PLAY". Warm pixel-art mobile educational game illustration matching input image 1: muted sage-green Philippine forest, cream parchment, warm brown outlines, golden edge highlights, large deliberate pixel clusters, friendly rounded chibi style. No smooth vector aesthetic, no glossy blue UI. Match shape, proportions, lettering and icon placement. One button centered, minimal transparent margins, true transparency outside. No scenery or extra objects.

### lapulapu.png
Use case: background-extraction. Asset type: transparent square hero portrait icon for a reusable level-selection button. Input image 1 is the user's requested design. Recreate ONLY its portrait of Lapu-Lapu, friendly young-adult Filipino chibi hero, tan skin, red headband tied at the side, medium-length black hair, cream/orange patterned precolonial collar, no hat. Head-and-shoulders bust, turned slightly to the right, warm brown eyes and friendly expression. Place the portrait INSIDE the same large gold octagonal frame as the reference, bright cream-gold bevel, thick brown pixel outline, warm brown inset background. Keep the frame shape and visual proportions consistent across the six hero icons. Warm pixel-art mobile educational game illustration matching input image 1: muted sage-green Philippine forest, cream parchment, warm brown outlines, golden edge highlights, large deliberate pixel clusters, friendly rounded chibi style. No smooth vector aesthetic, no glossy blue UI. Portrait fills the octagon; no whole body, no scenery, no name, no letters, no numbers, no lock or stars. One framed portrait centered with little empty margin and actual transparent alpha outside the octagon.

### bonifacio.png
Use case: background-extraction. Asset type: transparent square hero portrait icon for a reusable level-selection button. Input image 1 is the user's requested design. Recreate ONLY its portrait of Andres Bonifacio, friendly young-adult Filipino chibi hero, tan skin, short parted black hair, cream camisa and red neckerchief. Head-and-shoulders bust, turned slightly to the right, warm brown eyes and friendly expression. Place the portrait INSIDE the same large gold octagonal frame as the reference, bright cream-gold bevel, thick brown pixel outline, warm brown inset background. Keep the frame shape and visual proportions consistent across the six hero icons. Warm pixel-art mobile educational game illustration matching input image 1: muted sage-green Philippine forest, cream parchment, warm brown outlines, golden edge highlights, large deliberate pixel clusters, friendly rounded chibi style. No smooth vector aesthetic, no glossy blue UI. Portrait fills the octagon; no whole body, no scenery, no name, no letters, no numbers, no lock or stars. One framed portrait centered with little empty margin and actual transparent alpha outside the octagon.

### rizal.png
Use case: background-extraction. Asset type: transparent square hero portrait icon for a reusable level-selection button. Input image 1 is the user's requested design. Recreate ONLY its portrait of Jose Rizal, friendly young-adult Filipino chibi hero, tan skin, neatly side-parted short black hair, black suit and white collared shirt. Head-and-shoulders bust, turned slightly to the right, warm brown eyes and friendly expression. Place the portrait INSIDE the same large gold octagonal frame as the reference, bright cream-gold bevel, thick brown pixel outline, warm brown inset background. Keep the frame shape and visual proportions consistent across the six hero icons. Warm pixel-art mobile educational game illustration matching input image 1: muted sage-green Philippine forest, cream parchment, warm brown outlines, golden edge highlights, large deliberate pixel clusters, friendly rounded chibi style. No smooth vector aesthetic, no glossy blue UI. Portrait fills the octagon; no whole body, no scenery, no name, no letters, no numbers, no lock or stars. One framed portrait centered with little empty margin and actual transparent alpha outside the octagon.

### luna.png
Use case: background-extraction. Asset type: transparent square hero portrait icon for a reusable level-selection button. Input image 1 is the user's requested design. Recreate ONLY its portrait of Antonio Luna, friendly adult Filipino chibi general, tan skin, distinctive black mustache, cream military cap with navy band and small gold emblem, blue military coat with golden trim. Head-and-shoulders bust, turned slightly to the right, warm brown eyes and friendly expression. Place the portrait INSIDE the same large gold octagonal frame as the reference, bright cream-gold bevel, thick brown pixel outline, warm brown inset background. Keep the frame shape and visual proportions consistent across the six hero icons. Warm pixel-art mobile educational game illustration matching input image 1: muted sage-green Philippine forest, cream parchment, warm brown outlines, golden edge highlights, large deliberate pixel clusters, friendly rounded chibi style. No smooth vector aesthetic, no glossy blue UI. Portrait fills the octagon; no whole body, no scenery, no name, no letters, no numbers, no lock or stars. One framed portrait centered with little empty margin and actual transparent alpha outside the octagon.

### aquino.png
Use case: background-extraction. Asset type: transparent square hero portrait icon for a reusable level-selection button. Input image 1 is the user's requested design. Recreate ONLY its portrait of Melchora Aquino, kind elderly Filipina chibi woman, gray hair swept into a low bun, cream blouse with warm yellow collar, gentle smile. Head-and-shoulders bust, turned slightly to the right, warm brown eyes and friendly expression. Place the portrait INSIDE the same large gold octagonal frame as the reference, bright cream-gold bevel, thick brown pixel outline, warm brown inset background. Keep the frame shape and visual proportions consistent across the six hero icons. Warm pixel-art mobile educational game illustration matching input image 1: muted sage-green Philippine forest, cream parchment, warm brown outlines, golden edge highlights, large deliberate pixel clusters, friendly rounded chibi style. No smooth vector aesthetic, no glossy blue UI. Portrait fills the octagon; no whole body, no scenery, no name, no letters, no numbers, no lock or stars. One framed portrait centered with little empty margin and actual transparent alpha outside the octagon.

### mabini.png
Use case: background-extraction. Asset type: transparent square hero portrait icon for a reusable level-selection button. Input image 1 is the user's requested design. Recreate ONLY its portrait of Apolinario Mabini, thoughtful adult Filipino chibi man, tan skin, neatly parted black hair, black formal coat and cream collared shirt, friendly calm expression. Head-and-shoulders bust, turned slightly to the right, warm brown eyes and friendly expression. Place the portrait INSIDE the same large gold octagonal frame as the reference, bright cream-gold bevel, thick brown pixel outline, warm brown inset background. Keep the frame shape and visual proportions consistent across the six hero icons. Warm pixel-art mobile educational game illustration matching input image 1: muted sage-green Philippine forest, cream parchment, warm brown outlines, golden edge highlights, large deliberate pixel clusters, friendly rounded chibi style. No smooth vector aesthetic, no glossy blue UI. Portrait fills the octagon; no whole body, no scenery, no name, no letters, no numbers, no lock or stars. One framed portrait centered with little empty margin and actual transparent alpha outside the octagon.

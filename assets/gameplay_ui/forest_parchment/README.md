# Forest Parchment gameplay skin

Applied to the existing shared gameplay screen from the user's green/wood pixel-art reference on 20 November 2026.

## Integration

- Existing scene: res://gameplay_placeholder.tscn.
- Existing layout/controller: res://gameplay_placeholder.gd.
- Existing live renderer: res://board_view.gd.
- Updated visual regression: res://tests/gameplay_redesign_layout_test.gd.
- New assets in this folder: three PNGs and eight SVGs, plus Godot import descriptors.
- PNGs: background.png, snake_green.png, roll_base.png.
- SVGs: back.svg, die.svg, person.svg, trophy.svg, shield.svg, status_base.svg, tile_green.svg, tile_cream.svg.
- No new Autoloads, nodes, scene hierarchy, input actions, or save schema. The 21 November refinement changes only Level 1 to a single functional snake; higher-level counts and other rules remain intact.
- Original blue gameplay artwork is retained.

The shared renderer draws green/parchment tiles, brown/gold number badges, a layered wooden frame with corner vines, golden ladders and friendly green snakes. All connections and numbering still come from the catalog. The six levels retain 20, 30, 40, 50, 100 and 100 tiles. Snake counts are now 1, 4, 5, 6, 7 and 8, with the original ladder counts unchanged. Level 1 retains only 17 -> 7; the removed 16 -> 10 and 19 -> 12 effects are removed from the actual catalog as well as the drawing. The reference is recreated as a functioning UI; it is not a pixel-identical extraction. The grid now fills the taller portrait board rather than forcing square cells. Tile surfaces, badges, hero movement targets, snakes and ladders use the same fitted rectangular cell geometry. The fitted cell geometry changes presentation only. The separate, explicitly requested Level 1 snake reduction updates its catalog mapping; higher-level mappings, dice generation, scoring, effects and progression are preserved.

The existing HistoryRollBrand node is hidden for the reference's open-sky composition, not deleted or recreated. Back stays top left; Position/Score/Shield remain below the board; the wooden Roll Dice button stays lower on screen. Existing face portraits are approximately 12-14% larger, with unchanged token movement anchors. Finish heroes on Levels 1-5 continuously sway and bob with a stronger greeting. Rebuilding an animation restores its resting position first, preventing cumulative drift on repeated setup or resize. Level 6 retains the existing final trophy because there is no next hero. Question-first popups, score reactions, score rules, audio requests, saves, navigation and level unlocking remain unchanged.

The button is still a native Button with live text and a separate input-transparent die icon. Inspection of roll_base.png and actual Godot renders confirmed it already has no leaves; no raster edit or replacement was needed. Its generated wood base contains no baked lettering. Roll Dice remains disabled until the question is answered and while the turn is running. Numbers are larger live Bree Serif badges; the bolder roll caption uses the existing Lora Italic font with weight 700. Both licensed fonts were already in assets/fonts; no font download or new font license is involved.

## Reference-proportion refinement

The board occupies 49% of viewport height at the reference position, with a thicker 26-unit wood/gold frame and chunky paired vine curls drawn above its tile edges. Tile surfaces use the existing native SVG system with soft sage/cream shading and curling ornaments. Snake bodies have a curved offset belly, golden spots and heads positioned below their badges. The Shield tile displays a gold star on its blue shield. Hero face sprites sit below their numbers while their existing movement anchors remain at tile centers, preserving movement and idle animations. Back artwork is reduced to 76% of its smaller button, whose touch area remains at least 76 design units. HUD icons are aligned beside their live captions after container layout. No new image-generation call or raster asset was needed for this refinement.

## Verification

Latest verification executed using Godot 4.7.1 on 21 November 2026:
- tests/question_first_redesign_test.gd: 115 assertions passed, 0 failed.
- tests/phase6_levels_test.gd: 47 assertions passed, 0 failed.
- tests/gameplay_redesign_layout_test.gd: 487 assertions passed, 0 failed; final process exit code 0. Checks include larger face sizes, actual finish rotation/bobbing, stable restart origins, the single Level 1 snake, leaf-free button skin and real pointer input/navigation.
- Total across the three suites: 649 passed, 0 failed. All final processes exited with code 0.
- git diff --check: passed.
- Visually reviewed the actual rendered shared scene at 1024x1536 and 720x1280, including a 100-tile board.
- Render coverage includes every level at 1024x1536, Level 1 at 720x1280, 1080x1920 and 1080x2400, and Level 6 at 720x1280.
- Real mouse events in the rendered scene reach Answer, Roll Dice and Back. Rapid double clicks trigger only one roll. The on-board face and numeric result match movement. Back opens the real Level Selection scene.
- Test progress uses isolated save paths or mock progress. The real player's historyroll_progress.json SHA-256 remained 7493D1B3ABDBF9A8A779E9D7357E7D94AA4CE9BD523818A374DB58F346D384CC.

Captures are saved to user://gameplay_level_1_1024x1536_ready.png, user://gameplay_level_1_720x1280_ready.png and corresponding gameplay_level_* files. Popup, long-question, happy/sad reaction and on-board die captures are also generated.

An initial rendered test run completed 479 checks but crashed during engine teardown. The test now stops procedural audio and drains pending answer timers before quitting; the final expanded run completed 487 checks and exited normally. No script, missing-resource or rendering errors were reported by the final gameplay suites. The AudioManager still reports its existing built-in music fallback for missing .ogg tracks; audio behavior was not changed.

Physical Android performance, device safe areas and touch input remain unverified.

To re-run:
- Godot --headless --path . --script res://tests/question_first_redesign_test.gd
- Godot --headless --path . --script res://tests/phase6_levels_test.gd
- Godot --path . --script res://tests/gameplay_redesign_layout_test.gd --audio-driver Dummy

Manual check: F5 -> Start Game -> select an available level -> PLAY. Answer the question, let the popup close, press Roll Dice, check movement against the displayed die, then use Back. Higher levels automatically use the same skin. No Inspector setup is required.

## Artwork provenance and prompts

The built-in image_gen tool generated the three PNGs; no CLI/API fallback was used. The selected outputs were copied into this project folder and retain their original alpha where applicable. The reference and existing artwork served as style inputs. SVGs extend the project's native UI graphics; back.svg reuses the parchment Level Selection arrow, and the HUD/die icons reuse the existing gameplay icon shapes with brown outlines.

### background.png

Use case: precise-object-edit. Asset type: portrait full-bleed background scenery plate for existing Godot mobile game HistoryRoll. Image 1 is the USER'S uploaded wooden/green board reference and is the main composition target. Image 2 is an existing forest background style reference. Image 3 (snake head) is NOT part of this edit. Recreate ONLY the scenery of image 1, naturally extending the landscape behind ALL removed game interface. Portrait ratio 9:16. Crisp coherent pixel-art, stepped edges and restrained warm green/teal/ochre/cream palette. Overhanging leafy tree canopies in upper corners; muted teal sky and cream pixel clouds; layered blue-green mountains, tropical Philippine forest and rice terraces; old ivy stone ruin at right edge. Bottom left a softly glowing amber lantern standing on two books atop a stone block; bottom right two modest nipa huts and rocks, lower corners green foliage. Center is calm green landscape for a large live board. Keep these scenery props near the EDGES and bottom. Remove ALL UI: no board, tiles, snakes, ladders, numbers, letters, banner, logo, arrows, button, status strip, dice, icons or text. Opaque background. Match image 1's warm pixel aesthetic and detailed natural scenery; no gradients that look like vector art, no blur, no watermark. Deliver only scenery, no frame.

### snake_green.png

Use case: stylized-concept. Asset type: transparent PNG sprite, ONLY a friendly green snake head for a pixel-art Snakes and Ladders mobile game. One head plus a SHORT neck at bottom center, facing right in three-quarter view. Cute child-friendly cheerful expression, two glossy brown eyes, tiny pink cheeks, yellow-cream muzzle and short forked red tongue extending to right. Leaf-green head with a few warm gold round spots; dark chocolate-brown 2-3 pixel outline, hard stepped pixel edges and limited flat pixel color shading, retro 16-bit style. Similar in scale and feel to polished pixel-art RPG UI mascots, not smooth vector cartoon. Head fills nearly all canvas, centered and entirely visible. Neck exits bottom center so live code-drawn body can join it. Absolutely NO full snake body, no floor, no square backing, no frame, no text, no other objects. Real transparent alpha outside the head.

### roll_base.png

Use case: stylized-concept. Asset type: a SINGLE blank horizontal wooden button base for a warm pixel-art mobile game, transparent outside silhouette, width to height 3.5:1. Octagonal rectangle shape, small clipped corners, polished rich reddish chestnut wood interior, subtle horizontal timber grain, thick cream and warm gold beveled outer border, dark chocolate outline, tiny pixel offset shadow beneath. Match warm 16-bit RPG parchment-and-wood game UI. Crisp stepped pixel edges, handmade outlined retro pixel art, not photorealistic, not smooth vector. Interior is dark warm brown and spacious. ENTIRE button fully visible with narrow transparent padding. Absolutely no text, letters, icons, dice, arrows, sparkles, leaves, ropes, nails, scenery or symbols. Blank button base ONLY; all text and icons will be live game controls.

# HOORAY and OH NO score popups

Implemented on 26 November 2026. The green HOORAY/chibi popup was implemented
first; the user then requested a matching sad-face popup for incorrect answers.

## Files and behavior

- `success_frame.png`: 1536x1024 transparent PNG, generated with the built-in
  image_gen tool from the user's gameplay reference. It contains the empty
  green radial plate, gold border, crown, red pennants and scroll corners.
  Hero art, lettering and points are not baked into this asset.
- `success_frame.png.import`: Godot texture import settings.
- `incorrect_frame.png` and its import settings: matching 1536x1024 transparent
  plum/burgundy variant, edited with the built-in image_gen tool from the green
  frame. Crown, gold trim, red pennants and scroll-corner composition are retained.
- `res://hero_reaction_skin.gd`: reusable presentation helper. Reuses the
  existing ReactionPopup, ReactionContent, FaceCenter, FaceFrame, ReactionFace,
  ReactionTitle and ReactionScore nodes, without creating or reparenting nodes.
- `res://gameplay_placeholder.gd`: applies the matching correct/incorrect skins,
  restores the question for the next turn, and keeps feedback timers tied to
  their own reaction so rapid turns cannot dismiss a newer popup.
- `res://tests/hero_reaction_skin_test.gd`: rendering, functionality and timing
  regression tests.

The full asset is scaled proportionally. The existing per-hero happy face sits
inside a gold-and-cream portrait frame; the repository's Titan One font supplies
bold cream/gold text with dark outlines. Reward text uses the actual configurable
points. Wrong answers use the matching muted plum frame, the existing per-hero
sad face, OH NO! caption and configured penalty text. The score floor and
penalty rules are unchanged. Correct answers return to the original green frame.

The existing entrance/fade flow remains, with a gentle popup bounce and
portrait tilt. The question artwork is hidden while happy or sad feedback is
shown, and restored for the next question. No scoring values, dice rules, board
layout, save schema, Main Menu, Settings or navigation destinations changed.
No .tscn files or node hierarchy changed. No Editor setup is needed.

## Verification actually executed

Godot 4.7.1, desktop Compatibility renderer; Dummy audio driver.

| Suite | Passed | Failed |
| --- | ---: | ---: |
| Matching happy/sad popups, all hero faces and portrait layouts | 531 | 0 |
| Existing question-first gameplay | 115 | 0 |
| Existing question-popup transitions and dice input | 12 | 0 |
| Existing per-level answer-review regression | 223 | 0 |
| **Total** | **881** | **0** |

The dedicated suite rendered all six heroes at 720x1280 and 1024x1536,
plus Level 1 at 1080x2400. It checked text/portrait bounds, native artwork
proportions, identical node hierarchy and board/control positions, duplicate
answer rejection, an actual Roll Dice mouse click, next-question restoration,
matching sad-answer styling, configurable points/penalties, zero-score behavior
and stale feedback timers during both happy-to-happy and happy-to-sad turns.

Actual Godot captures were visually inspected, including:
- `user://hooray_level_1_720x1280.png`
- `user://hooray_level_1_1024x1536.png`
- `user://oh_no_level_1_720x1280.png`
- `user://oh_no_level_1_1024x1536.png`
- `user://oh_no_level_3_720x1280.png`

The real player progress and Settings files retained their original SHA-256
hashes. Final tests had no script errors. The existing question-popup test
still reports one ObjectDB instance at shutdown. Editor import reports the
pre-existing external-editor configuration error. Physical Android/device
testing was not performed; re-export an APK to include the new asset/scripts.

Manual check: stop the previous game, press F5, start any available level and
answer correctly. Check the happy hero, HOORAY text and actual points. Wait for
the popup to close, then roll. Verify the next question appears. Answer wrongly
to see the matching plum frame, sad face, OH NO! and penalty. After rolling,
answer correctly to verify it returns to green HOORAY.

Run the focused suite:
```text
Godot --path . --script res://tests/hero_reaction_skin_test.gd --audio-driver Dummy
```

## Asset generation provenance

Mode: built-in image_gen, transparent background enabled; input: the user's
uploaded gameplay reference. Output copied into this project without editing
the existing scenery or hero faces. PNG corner alpha was verified as zero.

Success-frame prompt used:

```text
Use case: background-extraction / precise-object-edit.
Edit target: the most recent uploaded HistoryRoll gameplay reference. Extract and recreate ONLY its central celebratory green chibi score popup as a reusable 2D Godot game UI background asset.
Keep the same warm hand-painted cartoon game-art style, glossy beveled golden trim, dark warm-brown outline, emerald-green rounded rectangular panel, soft yellow-green radial rays inside the green panel, small golden crown centered along the top edge, and two small red hanging victory pennants with simple gold laurel emblems beside its upper sides. Modest golden scroll curls at lower corners, matching the reference.
Composition: a single complete centered landscape popup plate, roughly 3:2 aspect ratio, with generous clean green content space. Keep the decorations contained within the asset. Main green content rectangle approximately x=14%-86%, y=16%-90%; crown above; pennants outside the inner green content. Flat front-facing view.
Remove ALL foreground content from the green plate: no hero, no human face, no portrait or portrait frame, no words, no letters, no score, no numbers. Godot will place the existing animated hero face, HOORAY title and score on top at runtime. Keep the radial background subtle enough for cream/yellow lettering.
Output a real transparent PNG cutout: transparent OUTSIDE the popup and decorations; opaque green INSIDE the panel. No white backdrop and no fake checkerboard.
Do not include the gameplay screen, board, dice, controls, Battle/Reward tabs, scenery, plants or flowers. Only one standalone empty green victory popup frame. No watermark.
```

Incorrect-frame prompt used:

```text
Use case: precise-object-edit.
Edit target: the supplied existing HistoryRoll success popup frame PNG.
Create its matching incorrect-answer popup variant by changing ONLY the central green panel fill and its radial rays to a soft muted burgundy/plum palette. Use a warm cranberry/plum interior with restrained lighter rose radial rays, comfortably readable behind cream and yellow game text. It should feel gentle and encouraging for schoolchildren, not alarming or neon.
Preserve the original 1536x1024 landscape composition and 3:2 proportions: the same glossy golden frame, small crown at the top center, red hanging pennants at both sides, gold laurel symbols, bottom red rail, golden scroll curls, highlights, outlines and positions. Do not crop, reposition or enlarge the decorations. This variant will be drawn at the exact same UI size as the original.
Keep the center completely empty. No faces, people, portrait frame, words, text, numbers or icons inside the panel. The existing Godot UI will add each hero's sad face, the caption OH NO! and the actual penalty dynamically.
Preserve real transparency outside the popup/decorations, including the original transparent corners. Keep the panel interior opaque. No scenery, no background rectangle, no fake checkerboard, no watermark.
```

# Shared level-completion card

Implemented from the user's supplied Great Job reference on 20 November 2026.

## Behavior

The existing ResultsPanel in gameplay_placeholder.tscn now displays the same completion card for every level, including replays. Great Job, Level N Completed, the three score captions, score values, and Continue are live controls. The PNG contains only the star, frame, ribbons, trophy decorations, and blank green button artwork.

The shared card keeps its image proportions, fits portrait viewports, adapts its typography, supports resizing while open, dims the board, and enters with a short fade/scale Tween. Existing native ReturnButton signals remain connected to gameplay. Continue still returns to Level Selection through the existing controller and ProgressManager. No new scene, Autoload, input action, gameplay rule, or save schema was added.

Invalid or misconfigured gameplay still presents an error and a working Back action, without showing false congratulations. The existing statistics ResultsLabel remains populated for compatibility and is hidden during successful completion.

## Score fields

- Your Score: final gameplay score minus the already-recorded bonus increase.
- Bonus Score: existing bonus_score_increase from this run.
- Total Score: the actual final gameplay score passed to ProgressManager.

For example, a final score of 35 containing 25 earned bonus points displays 10 / 25 / 35. The card never adds or awards another bonus. The current catalog's bonus amount remains unchanged at zero; it was not replaced with the reference image's example numbers.

Your Score is an accounting subtotal after deductions. If deductions consumed previously earned bonus points, that subtotal can be negative while the final total still follows the game's existing nonnegative-score rule. Values use thousands separators and scale down to fit their frames.

Completion is guarded against repeated processing. Continue disables itself after use, and duplicate clicks cannot repeat navigation or rewards. Existing completion, level unlock, character reward, best-score, and replay rules remain owned by ProgressManager.

## Files

Created:

- res://level_completion_card.gd and its UID: reusable presentation, responsive positioning, formatted values, entrance animation, and error display.
- res://assets/gameplay_ui/level_completion/card.png and its import descriptor: selected transparent artwork.
- res://tests/level_completion_test.gd and its UID: all-level completion, rendering, input, score, replay, and persistence coverage.
- This README, including the generation prompt.

Modified:

- res://gameplay_placeholder.gd: present the shared card, preserve score saving and routing, reject repeated completion, and retain fatal-error behavior.
- res://gameplay_placeholder.tscn: restyle the existing ResultsPanel and add live labels/artwork. Existing ResultsMargin, ResultsContent, ResultsLabel, and ReturnButton names/paths are retained. ResultsContent is now a Control for artwork-relative positioning.
- res://tests/question_first_redesign_test.gd: update the Continue-caption expectation and clean up fast-test feedback/audio before engine shutdown.

## Verification actually performed

Godot 4.7.1 desktop, Compatibility renderer, Dummy audio driver:

| Suite | Passed | Failed | Final exit |
| --- | ---: | ---: | ---: |
| level_completion_test.gd | 532 | 0 | 0 |
| question_first_redesign_test.gd | 115 | 0 | 0 |
| gameplay_redesign_layout_test.gd | 425 | 0 | 0 |
| Total checks | 1,072 | 0 | |

Completion coverage includes all six levels at 1024x1536 and 720x1280, plus Level 1 at 1080x2400. Final actual renders were visually inspected for Level 1 at 720x1280, Level 6 at 1024x1536, and the large-score case.

Tests reach each catalog's actual finish using an exact roll through the existing explicit debug dice interface. Only fixtures place the token one tile before the finish and accelerate the animations; normal gameplay randomness and timings are unchanged.

Verified: actual level number, actual score fields, zero/large/bonus/penalty breakdowns, fitted text, portrait bounds, open-popup resizing, exact-roll completion, saved statistics, single completion processing, native pointer Continue, duplicate-click rejection, all-six-level saved progression, replay without duplicate hero rewards, save reload, and invalid-level recovery. The existing gameplay suite also verifies real Answer, Roll Dice, and Back pointer input.

Some initial accelerated test runs passed their assertions but terminated abnormally during engine cleanup. The completion and question-first fixtures now explicitly stop procedural music and allow the existing answer-feedback timers to finish before quitting. Both final suites exited normally without the earlier leak warning. The unchanged gameplay layout suite still reports its existing one-instance shutdown warning. No new script or missing-resource errors remain in the final runs. Import-only editor checks report this machine's existing external-editor launch warning.

The actual user settings and progress files retained their pre-test SHA-256 hashes:

- historyroll_settings.cfg: 27A5E3EDB4F0918F4713B9A2E16709CBA02FD6030E50457B85C632D2581AA45D
- historyroll_progress.json: 7493D1B3ABDBF9A8A779E9D7357E7D94AA4CE9BD523818A374DB58F346D384CC

Progression tests use user://historyroll_completion_card_test.json and delete that fixture afterwards. They never reset or replace the real player's progress. git diff --check passed.

Physical Android, device safe areas, and audible sound were not tested for this change.

## Run and manually verify

1. F5 -> Start Game -> select an available level -> PLAY.
2. Answer questions and roll normally until reaching that level's exact finish.
3. Confirm the matching Level N Completed title, actual score fields, and green Continue button.
4. Press Continue; Level Selection should open with the existing unlocked progress.
5. Replay a completed level to see the card again without duplicate one-time rewards.

No Inspector setup or manual signal connection is required.

Run automated checks with Godot --path . --script res://tests/level_completion_test.gd --audio-driver Dummy. The question-first suite can also run headless.

Captures are saved to user://completion_level_N_WIDTHxHEIGHT.png and user://completion_large_score_720x1280.png.

## Artwork provenance and final prompt

Built-in imagegen tool, transparent_background=true, using the user's completion-card reference. No CLI/API fallback. The selected PNG was copied into this project folder with its alpha intact. Text remains live and uses the existing Bree Serif font with a FontVariation for simulated bold.

Use case: precise-object-edit. Asset type: transparent portrait LEVEL COMPLETION CARD background for the existing Godot mobile game HistoryRoll. Input image: the user's latest uploaded Great Job / Level Completed score card is the exact shape, color, composition and style reference. Recreate that entire ornate standalone card on true transparent alpha, canvas aspect ratio 10:11. Preserve its large golden five-point star at top center; curved deep red upper header with thick shiny gold border; cream level-title ribbon with red tails below it; warm cream parchment body in a gold frame with rounded curled corners; THREE vertically stacked cream score boxes, each with a red/gold rounded header tab, small golden trophy at the left side of the number area, and red ribbon tails at the sides; and the large glossy bright GREEN rounded Continue button with thick cream/gold rim overlapping the bottom edge. Match the polished warm friendly illustrated game UI exactly: dark brown outlines, red/gold/cream palette, rich bevels and subtle shaded highlights. CRITICAL: REMOVE EVERY WORD, LETTER AND NUMBER. The upper red header must be blank for live 'Great Job!' text. The cream level ribbon must be blank for a live level number. All three red header tabs must be blank for live score labels. All three cream number fields must be empty except for the small trophy at LEFT. The green bottom button must be completely blank. Do not write Great Job, Level 1, Your Score, Bonus Score, Total Score, 3,000,000, or Continue anywhere. Maintain generous clear interior space in each text area. Keep the complete star, frame, ribbon tails and green button visible with 1-2% transparent padding around the entire silhouette. No square background, no scenery, no characters, no watermark. Real transparent pixels outside the artwork.

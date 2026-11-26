# Per-level answer review

Implemented for all six HistoryRoll levels on 26 November 2026.

## Player flow

After completing a board, the existing completion card shows **Correct** and
**Incorrect** answer totals alongside the existing score breakdown.

- **Continue** opens the first incorrect-answer review, when there are mistakes.
- Each page shows the question, the player's chosen answer, the validated correct
  answer, totals and the current page number.
- **Next** opens the next mistake. The final **Continue** uses the existing
  destination: Level Selection, or the eligible certificate after Level 6.
- A perfect run continues directly, without an empty review page.

Reviewing never awards points, changes a recorded answer, repeats completion
rewards or changes the level-unlock rules. Gameplay controls remain disabled.
Each separately accepted attempt counts once. If a question comes around again
and is answered incorrectly again, both mistakes remain in the review.

## Implementation and existing systems

The gameplay counters already existed, but accepted answer details were discarded.
The completion-card presentation also hid the older statistics label.

- `quiz_session.gd` snapshots each accepted answer before the next question,
  rejects invalid/duplicate submissions as before, exposes a defensive history
  copy and clears history when configured for a new run.
- New `answer_review.gd` builds JSON-safe totals and mistake snapshots from that
  history and validates restored review data.
- `gameplay_placeholder.gd` passes the history into the existing completion/save
  flow and lets Continue visit the review before the existing navigation.
- `level_completion_card.gd` reuses ResultsLabel, the existing title labels,
  card artwork and Continue button. A parchment inset keeps review text readable
  over the existing score rows. Wrapped text fits its intended box before Godot
  computes the Label's minimum height.
- `progress_manager.gd` stores the most recent completed attempt per level and
  provides `get_level_answer_review(level_id)`, returning a defensive copy.
- `tests/answer_review_test.gd` reuses the existing completion-test fixtures.
  `tests/level_completion_test.gd` now checks the visible answer totals.

No .tscn, node hierarchy, gameplay artwork, question-bank content, scoring values,
dice rules or export settings changed. No Godot Editor node setup is required.

## Offline saving and compatibility

An optional `level_answer_reviews` dictionary was added to the existing version-3
save. Keys are level IDs as strings; each entry contains:

- `level_id`
- `correct_answers`
- `incorrect_answers`
- `mistakes`: question ID/text, chosen/correct indices and answer text snapshots.

The existing `last_level_stats` also receives the accepted answer history.
A completed replay replaces that level's latest review. Reviews for other levels,
best scores, unlocked levels, player name and one-time rewards remain intact.

Old saves without the optional field still load. Earlier wrong answers cannot be
reconstructed because the original game did not save them; review begins with
newly completed attempts. Invalid review entries are ignored independently of
ordinary progression. No save-version migration or player reset is required.

Progress is saved at board completion, before reading the review. Closing the
application during review keeps the completed-attempt data, but does not resume
the current review page on restart. An unfinished attempt follows the existing
restart behavior. No separate past-review menu was added.

## Verification actually executed

Godot 4.7.1, desktop Compatibility renderer; automated fixtures used isolated
user:// test files and the existing debug-only dice controls/board setup to
exercise real answer, movement, completion and navigation callbacks.

| Suite | Passed | Failed |
| --- | ---: | ---: |
| Answer history, review flow, per-level persistence, replay and layouts | 223 | 0 |
| Existing completion cards, scores and final navigation | 532 | 0 |
| Existing question-first gameplay and legacy migration | 115 | 0 |
| Player names, save compatibility and certificate access | 135 | 0 |
| Sequential progression integration | 7 | 0 |
| **Total** | **1012** | **0** |

The review suite covered all six levels, all-correct/all-wrong attempts,
duplicate submissions, repeated-question mistakes, restart loading, legacy
version-3 saves, corrupt review records and replay isolation. It also checked
**all 437 validated question/wrong-choice combinations at each of 720x1280
and 1024x1536** (874 text-layout cases).

Actual rendered totals and reviews were visually inspected, including long text:
`user://answer_totals_720x1280.png`,
`user://answer_review_1024x1536.png`,
`user://answer_review_level_4_720x1280.png` and
`user://answer_review_longest_720x1280.png`.

The actual player progress and Settings files retained their original SHA-256
hashes throughout testing. Final test runs had no script errors. The identity
suite's intentional failed-write/corrupt-save fixtures emit expected warnings;
its existing ObjectDB shutdown warning remains. Headless Editor import also
reports the pre-existing external-text-editor configuration error.

Physical Android/device testing was not performed. Re-export an APK to include
the updated scripts.

## Manual check

1. Stop the old running game and press F5. Start an available level.
2. Answer some questions correctly and incorrectly; complete the board using its
   exact-roll finish rule.
3. Check Correct/Incorrect totals on the completion card, then press Continue.
4. Confirm each review shows the actual question, your choice and correct answer.
   Use Next, then Continue after the last correction.
5. Confirm the existing Level Selection/certificate destination opens.
   A completed all-correct run should continue without any mistake pages.

Run the focused review suite:

```text
Godot --path . --script res://tests/answer_review_test.gd --audio-driver Dummy
```

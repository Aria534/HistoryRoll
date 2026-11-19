# Responsive Main Menu assets

The two PNGs were separated from the user's approved 2026-11-19 reference using
the built-in imagegen tool. They are edited reference assets, not original source
layers or a claim of exact pixel-for-pixel extraction. Previous menu artwork is
preserved in the parent folder.

- `tropical_background_v1.png` (1086 x 1448): scenery with logo, menu buttons,
  and arrow removed. The lower landmarks are preserved.
- `historyroll_scroll_v1.png` (2172 x 724): independent parchment logo with alpha.
- `navy_button.svg`: shared code-authored navy pixel plaque; real Godot Labels
  render the four menu captions using the existing licensed Pixelify Sans font.
- `selection_arrow.svg`: code-authored gold pixel selection arrow.

Both SVGs reproduce simple UI shapes from the approved reference. Labels remain
editable text and are not baked into the background. Pixelify Sans is a close
project-available pixel font, not an identified exact match to the reference.

## Layout

The project keeps its existing 1024 x 1536 base resolution so existing screens
retain their coordinate system. Canvas Items with Expand fills taller phones.
The Main Menu computes logo/button layout against a 720 x 1280 design area and
uses Android display safe-area insets. Scenery fits the width, remains anchored
to the bottom, and extends the topmost sky row above it on tall screens. This
preserves the source aspect ratio, edge landmarks, and full screen coverage.

Main Menu timing and navigation remain in `res://main_menu_tscn.gd`. The original
StartButton, HeroCardsButton, SettingsButton, and QuitButton names are retained.
The old decorative branches remain hidden. Returning to this scene requests the
existing AudioManager track and respects saved Music and SFX preferences.

## Image edit prompts

Background: Remove only the HISTORYROLL parchment logo, all four navy button
plaques including text/shadows, and the selection arrow from the approved image.
Fill those areas with the matching blue sky. Preserve the clouds, bahay kubo,
Philippine flag, palm, lake, mountain, well, grass/earth platform, composition,
palette, and crisp pixel-art style. No additional objects or UI.

Logo: Isolate only the HISTORYROLL parchment scroll on a genuinely transparent
background. Preserve its cream curled banner, gold pixel lettering, dark red
extrusion, black outlines, proportions, and exact HISTORYROLL wording. No other
elements; use a small transparent margin.

## Verification

Run `res://tests/main_menu_redesign_test.gd` with the normal GL Compatibility
renderer to render 720 x 1280, 1080 x 1920, 1080 x 2340, 1080 x 2400, and the
legacy 1024 x 1536 canvas. Captures are saved to `user://main_menu_WxH.png`.
The test exercises layout, GUI input hit testing, all four navigation callbacks,
press/release, music reuse, and live resizing. Run the existing
`res://tests/main_menu_foliage_test.gd` entry point for the updated stationary
scenery and saved audio preference checks.

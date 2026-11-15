# HistoryRoll Story Assets

`story_data.gd` currently uses the existing historical background and hero chibis as explicit development placeholders. No generated final illustrations or audio are included.

For each hero, use this replaceable structure:

```text
assets/story/<hero_id>/
  scene_01_background.png
  scene_01_midground.png
  scene_01_character.png
  scene_01_foreground.png
  scene_01_effects.png
  voice/scene_01.ogg
  sfx/scene_01.ogg
  music/story_theme.ogg
```

Repeat `scene_01` through `scene_06`. Then set the corresponding `background_path`, `midground_path`, `character_path`, `foreground_path`, `effects_path`, `voice_path`, `sfx_path`, and `music_path` values in `story_data.gd`.

- Backgrounds should use the game's portrait-safe composition and avoid placing important details behind the subtitle panel.
- Character images should have transparent backgrounds.
- Midground, foreground, and effects files must be transparent PNGs aligned to their matching background so the player can animate them independently.
- Voice files use the `Master` bus so narration remains audible when Music or SFX is disabled.
- Music uses the `Music` bus; scene effects use the `SFX` bus.
- Keep Android assets compressed through Godot's import settings and avoid loading artwork for heroes other than the selected story.

# HistoryRoll background music

Place Godot-compatible Ogg Vorbis files in this folder using these exact names:

- `main_menu.ogg` — Main Menu and related menu screens
- `level_select.ogg` — Level Selection
- `gameplay.ogg` — gameplay boards
- `victory.ogg` — short Level Complete cue (it may also loop safely)

Optional hero-specific Story Mode tracks may also be stored here and referenced
from the corresponding story data as `res://assets/audio/music/<name>.ogg`.

The global `AudioManager` enables looping at runtime, so the imported files do
not need scene-local `AudioStreamPlayer` nodes.

# HistoryRoll background music

Place Godot-compatible Ogg Vorbis files in this folder using these exact names:

| Track | Screens |
| --- | --- |
| `main_menu.ogg` | Loading, Main Menu, Settings, Hero Cards, and Hero Story ending / coming-soon screens |
| `level_select.ogg` | Level Selection and its How to Play overlay |
| `gameplay.ogg` | All gameplay boards |
| `victory.ogg` | Level Complete results, Character Unlock, and level-unlock confirmation |

Loading requests the Main Menu track immediately. The existing AudioManager
continues that same stream into Main Menu without restarting it. The nine-second
loading interval is unchanged. Settings and Hero Cards How to Play overlays keep
their parent screen's music.

Story Mode keeps its existing hero-specific / built-in soundtrack. Optional
Story Mode files can be referenced from the corresponding story data as
`res://assets/audio/music/<name>.ogg`. Hero Story movies suspend global music
before playback; their ending and coming-soon screens restore menu music.
The final movie files are not installed in the current project.

The existing `AudioManager` Autoload owns one global music player, enables
looping, and handles scene fades. Music OFF is loaded from
`user://historyroll_settings.cfg` before startup playback and remains OFF across
these screens. SFX uses its separate bus and setting. No additional Autoloads,
scene-local music players, or scene changes are needed for this integration.

There are currently no `.ogg` tracks in this folder. The existing lightweight
built-in instrumental for each role provides offline background music until a
listed file is installed. A matching `.ogg` replaces it on the next run without
script or scene changes.

## Verification (2026-11-23)

Executed with Godot 4.7.1 and the Dummy audio mixer:

- Scene music coverage: 132 passed, 0 failed.
- Existing AudioManager: 25 passed, 0 failed.
- Existing Hero Story video player: 59 passed, 0 failed.
- Existing Settings design: 303 passed, 0 failed.
- Existing Splash Screen: 218 passed, 0 failed.

Total: **737 passed, 0 failed**. The scene suite uses isolated progress/settings
files and checks both Music ON and OFF, soundtrack roles, single-player ownership,
loading-to-menu continuity, Story Replay, and unchanged SFX state. A Music-bus
capture during loading contained 8,192 frames with a nonzero peak of 0.0415;
this confirms generated audio reaches the mixer. The separate splash suite
measured the normal loading transition at 9.224 seconds including fades.

The real player save and settings files retained their original SHA-256 hashes.
Some existing suites still report ObjectDB/resource cleanup warnings on exit.
The Editor import completes but reports its existing external-text-editor
configuration errors. No script or parse errors were reported. Speaker listening,
physical Android playback, and audio from the absent final movie files were not
tested.

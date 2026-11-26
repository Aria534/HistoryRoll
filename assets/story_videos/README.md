# HistoryRoll hero story videos

## Installed Lapu-Lapu story

- Source: [Lapu-Lapu Short Story Tagalog Version](https://www.youtube.com/watch?v=sErCMnK40Rg)
- Creator: Great Day Channel
- Requested by the user on 25 November 2026.
- Runtime file: `res://assets/story_videos/lapulapu_story.ogv`
- Source credits and media details: `lapulapu_story.source.json`
- Duration: 138.433333 seconds (about 2 minutes 18 seconds).
- Encoding: Ogg Theora, 960x540, 30 fps; Vorbis audio, stereo, 44.1 kHz.
- Size: 48,441,004 bytes.
- The original video's picture and audio were re-encoded for Godot playback.
  Its composition was kept; no portrait crop or stretching was applied.

## Installed Andres Bonifacio story

- Source: [Andres Bonifacio - Short Story Tagalog](https://www.youtube.com/watch?v=Biys0BdyO5g)
- Creator: Great Day Channel
- Requested by the user on 26 November 2026.
- Runtime file: `res://assets/story_videos/bonifacio_story.ogv`
- Source credits and media details: `bonifacio_story.source.json`
- Duration: 147.666667 seconds (about 2 minutes 28 seconds).
- Encoding: Ogg Theora, 960x540, 30 fps; Vorbis audio, stereo, 44.1 kHz.
- Size: 42,714,898 bytes.
- The source picture and audio were re-encoded for offline Godot playback.
  The full landscape composition is preserved, without portrait cropping or stretching.
- The existing Level 2 video mapping already uses this filename. No runtime
  scripts, scenes, gameplay rules or level-unlock logic needed modification.

The existing Hero Cards WATCH STORY actions select the corresponding local movie
for Lapu-Lapu or Andres Bonifacio.
The game does not open YouTube, stream a URL, or require internet to play it.
Video/audio streams were downloaded and converted using temporary portable tools;
the downloader, encoder, original downloads and temporary network metadata are
outside the project and are not runtime dependencies.

## Shared player

The existing `hero_story_video_player.gd` and scene are reused. The script
fits the existing `VideoAspect` container to the decoded frame's native ratio.
A landscape movie appears fully within the portrait application with black space
above and below. The application orientation, node hierarchy and visual scene
resources were not changed.

Pause/Resume, Skip, Replay, Play Level, Back, progress display, ending information,
and watched-state saving keep the existing flow. Starting the movie stops global
background music; the ending and Back restore menu music. Movie audio uses the
existing SFX bus, so Settings > Sound Effects controls its sound.

The existing Android export preset uses `export_filter="all_resources"`; no export
configuration or APK was changed for this integration. The new .ogv is a Godot
video resource. A previously built APK must be exported again to receive it.

## Other hero movies

Place final Godot-compatible Ogg Theora videos in this folder using these names:

- `rizal_story.ogv`
- `antonio_luna_story.ogv`
- `melchora_aquino_story.ogv`
- `mabini_story.ogv`

These four final movies are not installed yet. Their safe "Story Video Coming Soon"
states remain available; opening a missing movie does not mark it watched.
Each installed movie keeps its own native aspect ratio.

## Verification executed on 25 November 2026

Godot 4.7.1, desktop Compatibility renderer and Dummy audio mixer:

| Suite | Passed | Failed |
| --- | ---: | ---: |
| Hero Story video player, including full natural movie playback | 74 | 0 |
| Scene music ON/OFF and transitions | 154 | 0 |
| Question-first gameplay regression | 115 | 0 |
| Total | 343 | 0 |

- The actual local Theora movie loaded, decoded and advanced in Godot.
- Audio captured from the movie's SFX bus: 57,344 frames, peak 0.3927.
  This verifies a non-silent decoded signal; it was not a speaker listening test.
- Pause froze the real playback position; Resume, Skip, Replay, Play Level and
  Back routes retained their behavior.
- The complete movie played until its natural finished signal, with the ending
  reached after 140.931 seconds of test time. Watched status was saved to an
  isolated test file; this did not unlock gameplay.
- Actual video frames were rendered and inspected at 1024x1536 and 720x1280.
  Captures: `user://hero_story_playing_1024x1536.png` and
  `user://hero_story_playing_720x1280.png`.
- FFmpeg decoded the entire converted video/audio without errors.
- Real player progress and settings kept their original SHA-256 hashes.
- Existing ObjectDB shutdown warnings remain; no script/parse errors occurred
  in the final runs. Physical Android playback was not tested.
- The pre-existing Editor change in `assets/player_identity/identity_theme.tres`
  was left untouched.

Run the reusable tests, including natural playback:

```text
Godot --path . --script res://tests/hero_story_video_player_test.gd --audio-driver Dummy -- --full-playback
```

For a manual check, stop the previous running game, press F5, open Hero Cards,
choose Lapu-Lapu and press WATCH STORY. Enable Sound Effects in Settings to hear
the original movie audio.

## Bonifacio verification executed on 26 November 2026

Godot 4.7.1, desktop Compatibility renderer and Dummy audio mixer:

| Suite | Passed | Failed |
| --- | ---: | ---: |
| Hero Story video player, both installed movies and full Bonifacio playback | 118 | 0 |
| Scene music ON/OFF and transitions | 154 | 0 |
| Total | 272 | 0 |

- The complete Bonifacio movie reached its native finished signal after
  151.142 seconds of test time (media duration: 147.666667 seconds).
- Actual movie audio reached the SFX bus: 61,440 captured frames, peak 0.6542.
  This verifies decoded audio, rather than physical speaker output.
- Both installed movies passed automatic playback, Pause/Resume, Skip, Replay,
  Back, watched-state persistence and existing Play Level access checks.
- Bonifacio's story played with Level 2 locked; watching it did not unlock
  gameplay. Tests used an isolated progress file.
- Rendered Bonifacio frames were visually inspected at 1024x1536 and 720x1280:
  `user://hero_story_2_playing_1024x1536.png` and
  `user://hero_story_2_playing_720x1280.png`.
  The full landscape frame remains centered without stretching or cropping.
- FFmpeg decoded the entire new video and audio without errors.
- Real progress and Settings files retained their original SHA-256 hashes.
- No script errors occurred in the final test runs. The existing scene-music
  suite still reports two ObjectDB instances at shutdown. The headless Editor
  import reports its pre-existing external-editor configuration error.
- Regression tests now cover both installed movies, an explicit missing-file
  fixture and optional full Bonifacio playback. Full-playback checks wait for
  decoder initialization before querying native stream duration.
- No runtime GDScript, scene layout, export preset or APK changed.
  Physical Android playback was not tested.

Run the Bonifacio full-playback check:

```text
Godot --path . --script res://tests/hero_story_video_player_test.gd --audio-driver Dummy -- --full-bonifacio
```

For a manual check, stop the old running game, press F5, open Hero Cards, choose
Andres Bonifacio and press WATCH STORY. Keep Sound Effects ON for movie audio.
Re-export the Android APK to include the new local movie.

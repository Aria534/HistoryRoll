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

## Installed Jose Rizal story

- Source: [Jose Rizal Short Story - Tagalog Version](https://www.youtube.com/watch?v=jChjPmuEATw)
- Creator: Great Day Channel
- Requested by the user on 26 November 2026.
- Runtime file: `res://assets/story_videos/rizal_story.ogv`
- Source credits and media details: `rizal_story.source.json`
- Duration: 149.633333 seconds (about 2 minutes 30 seconds).
- Encoding: Ogg Theora, 960x540, 30 fps; Vorbis audio, stereo, 44.1 kHz.
- Size: 38,128,410 bytes.
- The source picture and original audio were re-encoded for offline Godot playback.
  The complete landscape composition is preserved without cropping or stretching.
- The existing Level 3 video mapping already uses this filename. No runtime
  scripts, scenes, gameplay or progression rules needed modification.

The existing Hero Cards WATCH STORY actions select the corresponding local movie
for Lapu-Lapu, Andres Bonifacio, Jose Rizal or Antonio Luna.
The game does not open YouTube, stream a URL, or require internet to play it.
For the first three linked channel videos, streams were downloaded and converted using temporary tools;
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

- `melchora_aquino_story.ogv`
- `mabini_story.ogv`

These two final movies are not installed yet. Their safe "Story Video Coming Soon"
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

## Rizal verification executed on 26 November 2026

Godot 4.7.1, desktop Compatibility renderer and Dummy audio mixer:

| Suite | Passed | Failed |
| --- | ---: | ---: |
| Hero Story video player, all three installed movies and full Rizal playback | 164 | 0 |
| Scene music ON/OFF and transitions | 154 | 0 |
| Total | 318 | 0 |

- The complete Rizal movie reached its native finished signal after 152.791
  seconds of test time (media duration: 149.633333 seconds).
- Actual Rizal audio reached the SFX bus: 61,440 captured frames, peak 0.5267.
  This verifies a non-silent decoded signal, rather than physical speaker output.
- Lapu-Lapu, Bonifacio and Rizal passed automatic playback, Pause/Resume,
  Skip, Replay, Back, watched-state persistence and Play Level access checks.
- Rizal's story played while Level 3 stayed locked. Watching the story did not
  unlock gameplay. All progress writes used an isolated test file.
- Actual Rizal video frames were rendered and visually inspected at 1024x1536
  and 720x1280, preserving the complete landscape picture without stretching:
  `user://hero_story_3_playing_1024x1536.png` and
  `user://hero_story_3_playing_720x1280.png`.
- FFmpeg decoded the entire new video and audio without errors.
- Real player progress and Settings retained their original SHA-256 hashes.
- No script errors occurred in the final test runs. Shutdown still reported
  ObjectDB warnings (one instance in video tests, two in scene-music tests).
  Headless Editor import also reported the existing external-editor setting error.
- Only the new movie, UID, source credits, regression tests and this guide changed.
  No runtime script, scene, export preset or APK was changed.
  Physical Android playback was not tested.

Run the Rizal full-playback check:

```text
Godot --path . --script res://tests/hero_story_video_player_test.gd --audio-driver Dummy -- --full-rizal
```

For a manual check, stop the previous running game, press F5, open Hero Cards,
choose Jose Rizal and press WATCH STORY. Enable Sound Effects for movie audio.
Re-export the Android APK to include the new offline video.

## Installed Antonio Luna short — 26 November 2026

- Title: **Antonio Luna — Maikling Kuwento ng Isang Heneral**.
- Master for direct review: `res://assets/story_videos/antonio_luna_story.mp4`.
- Native Godot runtime: `res://assets/story_videos/antonio_luna_story.ogv`.
- Exactly six scenes, **88.5 seconds**, **1280x720**, **24 fps / 2,124 frames**.
- Original realistic AI-generated illustrations, gentle pan/zoom and contained fades.
  This is an illustrated narrated short; it does not animate character limbs or lips.
- Original-script **synthetic Tagalog narration**, with 17 audio-timed Filipino
  subtitle cues burned into both formats. No YouTube footage, third-party film
  narration, music or streaming service is used by this Luna short.
- Archival likeness guide only: [Antonio luna small.jpg](https://commons.wikimedia.org/wiki/File:Antonio_luna_small.jpg),
  Public Domain Mark 1.0. The photograph is not included as footage.
- Historical sources, asset provenance, codec details and SHA-256 hashes:
  `antonio_luna_story.source.json`. Research links are not playback dependencies.
- Content package: `docs/story_videos/antonio_luna/` contains the final script,
  storyboard, measured scene JSON, SRT and exact image-generation prompts.
- Local production assets: `assets/story/antonio_luna/tagalog_short/` contains six
  source plates, 17 used narration clips and their manifest. Existing English Luna
  production assets are preserved. Unused new audition takes remain in the local
  temporary production directory, outside the shipped project.
- Offline rebuild: `tools/render_antonio_luna_story.ps1 -FFmpegPath <ffmpeg.exe>`.
  The renderer uses local art, narration and the project's licensed Roboto font.
  Generated intermediate scene clips and audio mixes go to the Windows temp folder.

### Integration and review

The missing `antonio_luna_story.ogv` was why Level 4 previously showed no actual
movie. Its existing `VIDEO_PATHS[4]` mapping was already correct. No gameplay,
progression, Settings, `.tscn`, or runtime navigation script needed changes.

1. Stop the old running game and press **F5**.
2. Open **Hero Cards**, find **Antonio Luna**, then press **WATCH STORY**.
3. Keep **Settings > Sound Effects ON** for the existing movie audio bus.
4. Pause/Resume, Skip, Replay and Back remain available.

The movie is reviewable even while Level 4 gameplay is locked. Watching or
replaying it does not bypass level unlocking. The full landscape frame is
letterboxed inside the existing portrait player. Re-export an Android APK to
include the new local OGV; an older APK will not contain this video.

### Verification actually executed

| Check | Passed | Failed |
| --- | ---: | ---: |
| Godot movie suite, installed levels 1–4 and full Luna playback | 210 | 0 |
| Six-scene content, measured source audio and subtitle validation | 242 | 0 |

- Both MP4 and OGV decoded fully through FFmpeg with `-xerror` and no decode errors.
- Native Godot playback reached the actual finished signal after **88.894 seconds**
  of test time (media duration **88.500 seconds**), then showed the normal ending.
- Luna movie SFX capture: **61,440 frames**, **peak 0.5762**. Global background music
  did not overlap the movie. This verifies the decoded signal, not physical speakers.
- Whole OGV audio measured **−16.9 LUFS**, **−1.3 dBFS true peak**, without clipping.
- All six encoded scene samples were visually inspected, including respectful
  death-scene treatment and the concluding message. Actual native movie captures
  were also inspected at **720x1280** and **1024x1536**:
  `user://hero_story_4_playing_720x1280.png` and
  `user://hero_story_4_playing_1024x1536.png`.
- Tests exercised automatic playback, actual decoded frame advancement, native
  audio, Pause/Resume, Skip, Replay, Back, watched-save reload, locked-level access,
  safe missing-file behavior and natural completion using an isolated test save.
- Real progress and Settings SHA-256 hashes matched their pre-test values.
- No playback script/parse errors occurred. One ObjectDB instance warning remains
  at test shutdown. Headless Editor import exits successfully but reports the
  existing external-text-editor configuration errors.
- Physical Android playback and a speaker listening test were **not** performed.

Run the optional complete Luna playback test:

```text
Godot --path . --script res://tests/hero_story_video_player_test.gd --audio-driver Dummy -- --full-luna
```
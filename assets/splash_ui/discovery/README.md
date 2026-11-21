# Discovery loading intro

Applied to the existing splash screen on 21 November 2026, following the user's supplied blue-sky HistoryRoll loading-screen reference.

## Files and integration

Modified:

- res://splash_screen.tscn: retains SplashScreen, Background, Presentation, Logo, Tagline, Subject, LoadingLabel, and FadeOverlay; adds the explorer art, cream/red banner plates, and yellow loading controls. The existing GlowBottom node is hidden.
- res://splash_screen.gd: retains the existing fade controls, minimum skip delay, skip_splash entry point, scene_change_handler, and Main Menu destination. Adds responsive layout, threaded Main Menu loading, and a nine-second minimum intro.
- res://tests/splash_screen_test.gd: extends the existing startup suite to cover the new design, actual loading, skip guards, and real Main Menu startup.

Created in this folder:

- background.png: opaque sky, tropical trees, mountains, Philippine flag, fortified gate, gardens, and stone path.
- logo.png: transparent HistoryRoll sign with book, globe, scroll, quill, and golden rays.
- explorers.png: transparent boy/girl explorer duo.
- subject_banner.svg, loading_banner.svg, bar_track.svg, bar_fill.svg: native UI graphics, including diagonal gold progress stripes.
- Corresponding Godot .import descriptors and this README.

The PNGs were generated with the built-in imagegen tool, then copied into this project. No CLI/API fallback was used. Original source PNG alpha is retained. Logo and explorer padding is removed through static AtlasTexture regions in the scene, measured from the generated images; no runtime image scanning or PNG pixel editing is required.

The Main Menu, Settings, gameplay, completion card, ProgressManager, AudioManager, project startup setting, and save schemas were not changed.

## Loading and navigation

The project still starts at res://splash_screen.tscn and ends the intro at res://main_menu_tscn.tscn.

ResourceLoader loads the actual existing Main Menu PackedScene in the background. Default timing is 0.45 seconds fade-in, 8.1 seconds hold, and 0.45 seconds fade-out: nine seconds in total. minimum_intro_duration is 9.0 seconds. The yellow bar represents overall startup progress, bounded by both elapsed presentation time and actual resource loading. It fills over 8.55 seconds before the final 0.45-second fade, and cannot reach 100 until the PackedScene is ready. Slow resource loading can extend startup beyond nine seconds; navigation never uses an unavailable scene.

Touch, left mouse, and non-repeat keyboard input still respect minimum_skip_delay, but cannot shorten the nine-second minimum intro. Early requests wait for both the minimum presentation time and the required scene resource. Repeated input cannot trigger duplicate transitions. The preloaded PackedScene is used for the actual scene change.

Logo, captions, characters, loading frame, and loading caption adapt independently to portrait screens, preserving artwork proportions and readable text. Background scenery fills the viewport. Android safe-area bounds are supported, but physical-device rendering remains unverified.

No Inspector setup or manual signal connection is required.

## Verification actually performed

Godot 4.7.1 desktop, Compatibility renderer, Dummy audio driver:

| Check | Passed | Failed | Exit code |
| --- | ---: | ---: | ---: |
| tests/splash_screen_test.gd | 236 | 0 | 0 |
| tests/main_menu_redesign_test.gd | 370 | 0 | 0 |
| Total assertions | 606 | 0 | |

- Portrait renders: 1024x1536, 720x1280, 1086x1448, 1080x1920, 1080x2340, and 1080x2400.
- Visually inspected actual Godot renders at 1086x1448 and 720x1280.
- Verified logo/character proportions, caption bounds, spacing, stripe/border visibility, bounded monotonic resource progress, automatic transition, early skip waiting for loading, minimum skip delay, touch/mouse/keyboard branches, and repeated-input protection.
- The splash suite also navigates to the real Main Menu and confirms its four controls and preserved global Music preference. Its default-duration case verifies gradual progress, early input protection, and exactly one transition after the nine-second interval. The final timed run measured 9.528 seconds, including frame/rendering overhead, and exited with code 0.
- Before the nine-second timing adjustment, launched the normal configured project using --quit-after 240; it reached Main Menu and exited with code 0. The updated suite separately tests the default nine-second configuration and real Main Menu routing.
- Main Menu regression covers existing navigation, animations, Settings, and saved audio preferences.
- The real user settings and progress SHA-256 hashes matched their pre-change values.
- git diff --check passed.

Remaining warnings: final runs still log ObjectDB cleanup warnings. The final nine-second intro suite reported three instances; the normal startup reported two RefCounted instances and the existing procedural AudioStreamGeneratorPlayback instance. Their underlying cause has not been established here. The existing Main Menu suite reports its procedural-audio cleanup warning. Final runs exited normally with no script or missing-resource errors. The import-only editor check also logs this machine's existing external-text-editor launch error.

Physical Android input, device performance, device safe areas, and audible audio were not tested.

Captures are saved to user://splash_discovery_WIDTHxHEIGHT.png. Tests use the existing scene-change seam for isolated cases and a real scene change for the startup case; they do not reset player saves.

## Manual check

1. Press F5 to run the project from its configured startup scene.
2. Confirm the illustrated logo, captions, two explorers, gate/flag scenery, yellow striped bar, and red loading caption.
3. Wait nine seconds, including both fades; the existing Main Menu should open. Very slow resource loading can extend this interval.
4. Run again and tap or press a key during loading; it must still wait for the nine-second minimum and open Main Menu once.
5. Confirm Start Game, Hero Cards, Settings, and Quit retain their existing actions.

The splash exports control fade_in_duration, hold_duration, fade_out_duration, minimum_skip_delay, and minimum_intro_duration. No Inspector changes are needed for the requested nine-second timing.

Run the intro tests with Godot --path . --script res://tests/splash_screen_test.gd --audio-driver Dummy.

## Final image-generation prompts

### background.png

Use case: precise-object-edit. Asset type: opaque portrait scenery background plate for the existing HistoryRoll loading intro, mobile portrait. Input image: the user's newest uploaded blue-sky HistoryRoll loading screen is the exact style and scenery reference. Recreate ONLY its tropical Philippine environment, naturally extending the parts previously hidden behind the removed interface: bright cheerful blue sky with small cream-white clouds; leafy green tree branches framing the upper corners and side edges; layered blue-green mountains behind an old pale warm-stone fortified entrance/gate at lower-middle right; a single Philippine flag flying above that gate; lush bushes with a few small white flowers; low stone walls near the lower sides; a warm irregular stone-paved path filling the foreground bottom. Same polished friendly hand-drawn cartoon-game illustration, clear dark-brown outlines and rich blue/green/gold colors. Portrait aspect ratio 3:4. Keep the UPPER HALF calm blue sky, because a separate logo and two live captions will be placed there. Keep the lower-left foreground/path open for two separate explorer characters. REMOVE the whole HistoryRoll title/sign, globe/book/quill crest, ALL text, captions and text banners, both explorer characters, the loading bar and the loading caption button. No letters, no numbers, no characters or people, no interface, no logo, no watermark. Fully opaque edge-to-edge background scenery only.

### logo.png

Use case: background-extraction. Asset type: transparent HistoryRoll loading-intro logo/sign for the existing mobile game. Input images: Image 1 is the user's uploaded loading screen and is the exact logo reference; Image 2 is the separately prepared sky/gate background and must NOT be included. Isolate/recreate ONLY the logo artwork in the upper part of Image 1: large red-brown wooden/parchment sign bordered with shiny gold, rounded rolled ends, clearly readable cream lettering 'HistoryRoll' in the same friendly bold serif, the open cream book above the left, blue/green globe in a gold stand at center with short golden rays above, small rolled parchment above right, and large white quill angled up toward the top right. Match the proportions, dark-brown outlines, polished friendly cartoon-game shading and warm gold/red/cream palette exactly. Entire logo and crest visible, tightly framed with minimal transparent padding, horizontal shape approximately 2:1. Text must be EXACTLY 'HistoryRoll' with those capitals and no space. Do not include the tagline, subject caption, characters, scenery, loading bar, buttons, extra writing, rectangle or watermark. Actual transparent alpha outside the logo silhouette.

### explorers.png

Use case: background-extraction. Asset type: transparent explorer character duo for the HistoryRoll loading intro. Input images: Image 1 is the user's original loading-screen reference and is the exact character/pose/style guide; Image 2 is a background scenery plate; Image 3 is the separate HistoryRoll logo. Extract/recreate ONLY the two full-body explorer children from Image 1 as a single compact duo on real transparent alpha: boy on LEFT with cream/tan wide-brim explorer hat, brown hair, cheerful open-mouth smile, white shirt, red neckerchief, brown shorts, brown shoes and shoulder satchel; his raised hand has one finger pointing up beside his cheek, as in the reference. Girl on RIGHT with long brown hair, a small white-yellow flower beside her temple, friendly smile, white puff-sleeve blouse, red skirt with cream trim, brown shoes, holding a brown/gold history book with a small head silhouette on its cover. Keep both characters' complete hats, hair, hands, feet, and book fully inside the canvas. Preserve their relative heights and spacing. Same rounded chibi proportions, dark-brown outlines, polished colorful hand-drawn cartoon-game shading and warm friendly faces as Image 1. Tightly crop the duo silhouette with minimal transparent padding, portrait-ish aspect about 4:5. No scenery, floor, cast floor shadow, wall, logo, loading bar, text, rectangle, extra characters, or watermark. Genuine transparency outside the characters.

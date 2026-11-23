# Hero Cards — heritage village reference design

Implemented on 22 November 2026 for the user's supplied FILIPINO HERO reference.

## Integration

- `hero_cards.tscn` retains its existing nodes and navigation structure. Its Background now uses `background.png`; the unused shade is hidden.
- `hero_cards.gd` draws the book/sun/red-and-gold crest, wooden frame, parchment cards and red Back plate using the existing Controls and native Buttons.
- All text is live, sourced from the existing LevelCatalog/HeroDatabase. The six heroes, historical facts and references were not rewritten.
- Names and the title use the existing Bree Serif font; biography text uses the existing Roboto font. Watch Story uses the existing Titan One font and selection arrow SVG.
- Full-body portraits reuse `assets/gameplay_chibis/*_chibi.png`. Cached AtlasTextures omit transparent padding only; no head-to-toe artwork is removed and the original images remain unchanged.
- At 1024×1536 the first three cards fit in the scroll area. Narrower portrait sizes keep readable text and scroll to the remaining heroes.
- Story films remain available for all six heroes. Selecting a gameplay hero still requires ProgressManager to report that hero unlocked. Watched-story indicators and the selected-hero strip remain functional.
- Story destination remains `res://hero_story_video_player.tscn`; Back remains `res://main_menu_tscn.tscn`.
- No Autoload, gameplay, progression, save schema, main menu or Settings changes.

## Assets

| File | Purpose | Transparency |
| --- | --- | --- |
| background.png | Philippine village, flag, lantern, books, scrolls and cannon scenery | Opaque |
| title.png | Blank book/sun/ribbon crest and gold laurels | Alpha |
| frame.png | Blank wooden backing and gold rim | Alpha |
| card.png | Blank cream parchment card and gold rim | Alpha |
| back.png | Blank red/gold Back plate with laurels | Alpha |

Files are installed in `res://assets/hero_cards_ui/heritage_village/`. Godot-generated `.png.import` files accompany them. Text, hero portraits and interactions are separate from the generated artwork.

## Verification executed

Godot 4.7.1 stable, Windows desktop:

| Suite | Result |
| --- | --- |
| `tests/hero_cards_design_test.gd` | 453 passed, 0 failed; exit 0 |
| `tests/question_first_redesign_test.gd` | 115 passed, 0 failed; exit 0 |

The design suite loads the actual Hero Cards scene into rendered SubViewports at 1024×1536, 720×1280, 1080×1920 and 1080×2400. It checks all six cards, visible text bounds, preservation of full-body portrait pixels, initial scroll position, access to the sixth hero, pointer input on Watch Story, every hero's story route, Back, locked-hero selection restrictions, unlocked-hero selection and watched-story status. The regression suite also exercises the existing gameplay/progression and Hero Cards-to-story route.

Initial and lower-card captures were saved to Godot's local `user://` directory:
`hero_cards_<width>x<height>.png` and
`hero_cards_<width>x<height>_last_heroes.png`.
The rendered 1024×1536, 720×1280 and lower-card 1024×1536 captures were visually reviewed.

Real player saves were not reset. Settings and progression SHA-256 hashes matched their pre-task values after testing:
- `historyroll_settings.cfg`: `27A5E3EDB4F0918F4713B9A2E16709CBA02FD6030E50457B85C632D2581AA45D`
- `historyroll_progress.json`: `7493D1B3ABDBF9A8A779E9D7357E7D94AA4CE9BD523818A374DB58F346D384CC`

An earlier verbose rendering run reported one existing procedural AudioStreamGeneratorPlayback shutdown warning. The final design and regression runs completed without script errors. Physical Android/device testing has not been performed. This is a visual recreation using the existing portraits and live typography, not an exact pixel-for-pixel copy of the reference.

## Manual check in Godot

1. Open the existing project and let the five PNG assets import.
2. Run the game and open Hero Cards.
3. Confirm the first hero appears initially, the cream cards contain readable facts, and the title says FILIPINO HERO.
4. Scroll down to Antonio Luna, Melchora Aquino and Apolinario Mabini.
5. Click Watch Story for any hero; confirm the appropriate existing story player opens.
6. Return and check that watched status and any legitimately selected hero are retained.
7. Use Back to return to Main Menu. Repeat at a narrow portrait size.

## Generation record and final prompts

Provider: built-in image generation tool, invoked under the imagegen skill.
Input: the latest user-supplied FILIPINO HERO screenshot in the conversation, used as the sole reference image for each generation (`num_last_images_to_include: 1`).
Output: five separately generated PNGs copied into the asset paths above; original generated pixel data and transparency retained. Blank artwork was requested so live game data would not be baked into the UI.
The title, frame, card and Back generations used `transparent_background: true`; scenery used `false`.

### background.png

Use case: precise-object-edit. Asset type: opaque portrait scenery plate for the existing HistoryRoll Hero Cards screen. Image 1 is the user's newest FILIPINO HERO reference and is the exact visual/composition reference. Recreate ONLY its cheerful Philippine village scenery, naturally extending the environment behind ALL removed interface. Bright blue sky with soft white clouds, green leafy tree canopy at upper left, tropical mountain silhouettes, nipa hut structures at the side edges, bamboo fence at right with a tall Philippine flag, warm dirt/stone village path through the center. Bottom left a glowing brass lantern and two small closed books on crates, two cream rolled parchments tied with red ribbon in front; bottom right an old wooden-wheeled cannon and a few crates. Keep all props near the sides and bottom, center calm and open for a separate tall hero-card panel. Match the reference's polished friendly illustrated educational-game look, chunky dark-brown outlines, vibrant warm greens/blues and gold/ochre accents. Portrait 2:3. Remove ALL title/crest/book logo, laurel UI decorations, wood interface panel, hero portraits, cards, banners, labels, buttons and lettering. No characters, no people, no writing, no game UI, no watermark. Environmental leaves and flowers remain as in the reference. Fully opaque edge-to-edge scenery.

### title.png

Use case: precise-object-edit. Asset type: one transparent blank title crest for HistoryRoll Hero Cards. Image 1 is the user's newest FILIPINO HERO reference and is the precise title style/shape reference. Recreate ONLY the upper crest: open cream book with brown page lines at top center, a bold golden Philippine sun with straight rays behind the book, flowing red-and-blue ribbon ends behind a wide dark-red/burgundy curved name plaque, thick polished gold bevel trim, dark-brown outline, a small gold diamond at the bottom center, and two GOLDEN LAUREL sprigs framing the plaque on left and right as shown. Keep the main red lettering area COMPLETELY BLANK for the existing live FILIPINO HERO Godot Label. Wide centered crest about 3.3:1 overall, entire book, sun rays, ribbon and laurel tips fully visible with minimal transparent padding. Same warm polished storybook mobile-game illustration, crisp chunky outline, softly shaded cream/red/gold. No text, letters, names, numbers, status bar, background scenery, portraits, buttons, extra objects or watermark. Actual transparent alpha outside the crest. One crest only.

### frame.png

Use case: precise-object-edit. Asset type: a single blank portrait wooden backing panel for HistoryRoll Hero Cards. Image 1 is the user's newest reference and is the exact material/color/frame guide. Recreate ONLY the large reddish-brown wooden UI backing board that surrounds the cards: tall portrait rectangular board with gently rounded corners, thick bright gold-and-cream beveled rim, thin dark-brown outline/drop shadow and a calm deep warm chestnut interior with subtle vertical/horizontal wood grain. It should be completely EMPTY throughout so separate live title, selected-hero strip, scrollable cards and Back button can be rendered on top. Ratio about 3:4. Entire board fully visible, tightly framed with narrow transparent padding. Match Image 1's warm polished illustrated mobile game style, soft gold highlights, chunky dark outline. No title crest, book, sun, laurels, leaves, flowers, portraits, card divisions, banners, text, icons, buttons or scenery. True transparent alpha outside the outer board silhouette. One empty board only.

### card.png

Use case: precise-object-edit. Asset type: one blank hero biography card panel for the existing HistoryRoll game. Image 1 is the user's newest hero-screen reference and is the exact card texture/border guide. Recreate ONLY a single wide cream parchment biography-card panel: softly rounded rectangular silhouette, thick polished golden outer rim, thin cream inner highlight, dark-brown outer outline and a compact bottom shadow; spacious pale warm cream center with only very subtle paper shading. Ratio approximately 2.9:1. The ENTIRE interior must stay empty because an existing full-body hero portrait, live name/theme/facts and a green story indicator will be placed on top. Entire panel visible with very narrow transparent margin. Same friendly polished illustrated mobile game aesthetic as Image 1, warm gold/cream palette and crisp chunky outlines. No portrait compartment, no header bars, text, names, numbers, hero characters, story buttons, icons, leaves, flowers, decorative flourishes or background scenery. Actual transparent alpha outside the card. One card only.

### back.png

Use case: precise-object-edit. Asset type: a single transparent blank Back-button plate for HistoryRoll Hero Cards. Image 1 is the user's latest FILIPINO HERO reference and is the exact Back-button style reference. Recreate ONLY its bottom Back button: rich dark-red/burgundy rounded capsule, subtle bright red top gloss, thick double gold and cream beveled rim, dark chocolate outline, small bottom shadow, and two symmetrical short GOLDEN LAUREL sprigs on the left and right sides as shown. Leave the entire red center COMPLETELY BLANK; the existing native Godot Button will render a left arrow and BACK in live cream lettering. Width to height about 4:1 including laurels. Entire plate and both sprigs fully visible with very narrow transparent padding. Match Image 1's polished friendly cartoon mobile-game illustration, warm shiny gold highlights and chunky brown outlines. No text, letters, arrow, numbers, icons, scenery, other controls or watermark. True transparent alpha outside the silhouette. One button plate only.

## Leaf-free title and Back update - 23 November 2026

- Added `title_leaf_free.png` and `back_leaf_free.png`, with Godot import metadata, in this folder. The original PNGs remain available.
- `hero_cards.gd` now uses the leaf-free title and Back plate. The title keeps the book, sun, ribbons, red plaque and gold trim; its FILIPINO HERO text remains live.
- The existing Back button stays centered below the scroll area. Its minimum size is 340x96 for compact viewports and 440x104 otherwise, with lower-frame spacing and reduced text padding to fit the leaf-free capsule.
- Hero data, portraits, six story routes, selection restrictions, saved progress and scene hierarchy are preserved. No Inspector changes are needed.

Verification executed: Godot 4.7.1 imported both assets successfully and `tests/hero_cards_design_test.gd` passed 453 assertions with 0 failures (exit 0). The suite rendered 1024x1536, 720x1280, 1080x1920 and 1080x2400, tested all six Watch Story routes, selection restrictions, watched status, scrolling and Back navigation. The 1024x1536 first-card capture and 720x1280 lower-card capture were visually reviewed. Real settings/progress hashes remained unchanged. The test log reports one pre-existing ObjectDB shutdown warning; the import log reports the existing external text editor configuration warning. No script errors or physical Android tests.

Provider: built-in image generation, under the imagegen skill, using each existing local PNG as its edit target. Both calls requested transparent backgrounds; selected outputs were copied intact into this project. This section supersedes the earlier notes describing title/Back laurels.

### title_leaf_free.png final prompt

Use case: precise-object-edit. Asset type: transparent title crest PNG for an existing Godot Hero Cards screen. Image 1 is the existing local title.png and is the edit target. Remove ONLY the two golden laurel/leaf sprigs from the left and right sides. Preserve the same open cream book, straight golden Philippine sun rays, red-and-blue ribbon tails, rich dark-red curved blank plaque, thick gold bevel, brown outline, central gold diamond, shading and overall wide composition. Reconstruct clean gold plaque edges where the laurels were attached. Keep the red plaque entirely blank: no text or symbols. No leaves, laurels, foliage or flowers anywhere. Preserve the original 3:1 canvas proportions and relative positioning of the book, sun, ribbons and plaque so it can replace the original asset without changing the screen layout. Keep the entire crest and rays visible with a small transparent safety margin. Real transparent alpha outside the artwork. One crest only, no scenery, no watermark.

### back_leaf_free.png final prompt

Use case: precise-object-edit. Asset type: transparent red-and-gold Back button plate for an existing Godot mobile game. Image 1 is the existing Back plate and is the EDIT TARGET. Remove BOTH golden leaf/laurel sprigs completely, left and right. Preserve the original rich burgundy red rounded capsule, subtle bright red upper gloss, thick double gold and cream beveled border, dark chocolate outline and compact bottom shadow. Keep the red center COMPLETELY BLANK because the existing Godot Button renders the arrow and BACK text. Deliver only the leaf-free capsule, tightly framed with a very small even transparent margin, wide horizontal composition approximately 4:1. No leaves, no laurels, no plants, no flowers anywhere. No text, no arrow, no letters, no icons, no scenery, no extra decorations, no watermark. Real transparent alpha outside the complete undamaged button. Same polished warm illustrated style and colors; do not invent a different button shape.

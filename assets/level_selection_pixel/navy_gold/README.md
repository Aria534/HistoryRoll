# Navy/gold Level Selection reference assets

The PNGs in this folder were separated from the user's approved Level Selection
reference with the built-in imagegen tool. They are edited reference assets,
not a claim of exact pixel-for-pixel extraction. Previous artwork is preserved.

- `background_v1.png`: scenery only, with all baked-in controls removed.
- `title_v1.png` and `play_v1.png`: separate transparent title and PLAY artwork.
- `level1_v1.png` through `level6_v1.png`: one navy/gold hero row per level.
  The printed padlocks were removed so the existing silver padlock stays dynamic.
- `back_icon.svg` and `icon_base.svg`: code-authored navy icon shapes matching
  the reference. The Help symbol is a real Label over the icon base.

Native AtlasTexture regions trim transparent margins without changing the source
PNGs. The existing LevelSelectionRow Button class owns each row, keeps its level
ID/title metadata and changes the lock based on ProgressManager. Old text and
portrait nodes remain available but are hidden to avoid duplicate content.

The scene uses nearest filtering, width-fitted scenery anchored to the bottom,
and an extended sky strip on tall phones. Rows remain separate scene instances
and can be adjusted in the 2D Editor. Levels are not permanently hardcoded locked;
fresh players have Level 1 available, while returning players keep their saves.

## Image edit prompts

### background

Use case: precise-object-edit. Asset type: portrait Godot Level Selection background. Input image 1 is the user's latest approved HistoryRoll CHOOSE YOUR LEVEL reference. Preserve its exact navy blue, gold, black outline, red text extrusion, crisp pixel-art style. Separate the requested element from that image rather than redesigning. No stars, subtitles, modern effects or extra objects.  Remove the complete top title banner, back and help icons, all six hero rows INCLUDING their portraits and padlocks, and the bottom PLAY button. Fill removed areas with the underlying blue sky/white pixel clouds and green landscape matching the image. Preserve the mountain at right, palm trees, stone belfry on right, terraced green field, stone ruins and rocks, and grass/earth platform along the bottom exactly in their original places. No UI or text anywhere. Keep the original portrait 1086 by 1448 composition and colors.

### title

Use case: background-extraction. Asset type: transparent UI title banner. Input image 1 is the user's latest approved HistoryRoll CHOOSE YOUR LEVEL reference. Preserve its exact navy blue, gold, black outline, red text extrusion, crisp pixel-art style. Separate the requested element from that image rather than redesigning. No stars, subtitles, modern effects or extra objects.  Isolate ONLY the long navy octagonal banner with its gold beveled frame and CHOOSE YOUR LEVEL gold pixel lettering/red extrusion at the top. Exact text: CHOOSE YOUR LEVEL. No sky or other elements. Tight transparent horizontal canvas. Preserve proportions and entire border without clipping.

### play

Use case: background-extraction. Asset type: transparent Godot PLAY button. Input image 1 is the user's latest approved HistoryRoll CHOOSE YOUR LEVEL reference. Preserve its exact navy blue, gold, black outline, red text extrusion, crisp pixel-art style. Separate the requested element from that image rather than redesigning. No stars, subtitles, modern effects or extra objects.  Isolate ONLY the bottom navy blue octagonal PLAY button with gold beveled border, gold right-pointing triangle and exact gold/red-extruded word PLAY. Keep the reference design and proportions. No scenery, no separate external shadows/background, no other UI. Tight transparent canvas around the whole intact button.

### level1

Use case: background-extraction. Asset type: one transparent horizontal Godot level row texture. Input image 1 is the user's latest approved HistoryRoll CHOOSE YOUR LEVEL reference. Preserve its exact navy blue, gold, black outline, red text extrusion, crisp pixel-art style. Separate the requested element from that image rather than redesigning. No stars, subtitles, modern effects or extra objects.  Isolate ONLY the row labeled "LEVEL 1 - LAPU-LAPU" with the red-headband Lapu-Lapu warrior in the first row. Keep its illustrated face in the complete left octagonal gold portrait frame, the long navy plaque, thin cream/gold border, and gold block/pixel text with red extrusion. Exact text: LEVEL 1 - LAPU-LAPU. REMOVE THE SILVER PADLOCK completely, replacing it with clean matching navy plaque; reserve blank space on the far right for a dynamic padlock supplied separately by Godot. Do not change the hero illustration or invent a different face. No background scenery and no other rows. Make the full row tightly framed with a genuinely transparent background, matching the reference's very wide approximately 5.8:1 row proportions. Keep portrait and plaque aligned as in reference, no additional text or ornament.

### level2

Use case: background-extraction. Asset type: one transparent horizontal Godot level row texture. Input image 1 is the user's latest approved HistoryRoll CHOOSE YOUR LEVEL reference. Preserve its exact navy blue, gold, black outline, red text extrusion, crisp pixel-art style. Separate the requested element from that image rather than redesigning. No stars, subtitles, modern effects or extra objects.  Isolate ONLY the row labeled "LEVEL 2 - ANDRES BONIFACIO" with Andres Bonifacio with white shirt and red neckerchief in the second row. Keep its illustrated face in the complete left octagonal gold portrait frame, the long navy plaque, thin cream/gold border, and gold block/pixel text with red extrusion. Exact text: LEVEL 2 - ANDRES BONIFACIO. REMOVE THE SILVER PADLOCK completely, replacing it with clean matching navy plaque; reserve blank space on the far right for a dynamic padlock supplied separately by Godot. Do not change the hero illustration or invent a different face. No background scenery and no other rows. Make the full row tightly framed with a genuinely transparent background, matching the reference's very wide approximately 5.8:1 row proportions. Keep portrait and plaque aligned as in reference, no additional text or ornament.

### level3

Use case: background-extraction. Asset type: one transparent horizontal Godot level row texture. Input image 1 is the user's latest approved HistoryRoll CHOOSE YOUR LEVEL reference. Preserve its exact navy blue, gold, black outline, red text extrusion, crisp pixel-art style. Separate the requested element from that image rather than redesigning. No stars, subtitles, modern effects or extra objects.  Isolate ONLY the row labeled "LEVEL 3 - JOSE RIZAL" with Jose Rizal in a dark suit in the third row. Keep its illustrated face in the complete left octagonal gold portrait frame, the long navy plaque, thin cream/gold border, and gold block/pixel text with red extrusion. Exact text: LEVEL 3 - JOSE RIZAL. REMOVE THE SILVER PADLOCK completely, replacing it with clean matching navy plaque; reserve blank space on the far right for a dynamic padlock supplied separately by Godot. Do not change the hero illustration or invent a different face. No background scenery and no other rows. Make the full row tightly framed with a genuinely transparent background, matching the reference's very wide approximately 5.8:1 row proportions. Keep portrait and plaque aligned as in reference, no additional text or ornament.

### level4

Use case: background-extraction. Asset type: one transparent horizontal Godot level row texture. Input image 1 is the user's latest approved HistoryRoll CHOOSE YOUR LEVEL reference. Preserve its exact navy blue, gold, black outline, red text extrusion, crisp pixel-art style. Separate the requested element from that image rather than redesigning. No stars, subtitles, modern effects or extra objects.  Isolate ONLY the row labeled "LEVEL 4 - ANTONIO LUNA" with General Antonio Luna with white military cap and blue/gold uniform in the fourth row. Keep its illustrated face in the complete left octagonal gold portrait frame, the long navy plaque, thin cream/gold border, and gold block/pixel text with red extrusion. Exact text: LEVEL 4 - ANTONIO LUNA. REMOVE THE SILVER PADLOCK completely, replacing it with clean matching navy plaque; reserve blank space on the far right for a dynamic padlock supplied separately by Godot. Do not change the hero illustration or invent a different face. No background scenery and no other rows. Make the full row tightly framed with a genuinely transparent background, matching the reference's very wide approximately 5.8:1 row proportions. Keep portrait and plaque aligned as in reference, no additional text or ornament.

### level5

Use case: background-extraction. Asset type: one transparent horizontal Godot level row texture. Input image 1 is the user's latest approved HistoryRoll CHOOSE YOUR LEVEL reference. Preserve its exact navy blue, gold, black outline, red text extrusion, crisp pixel-art style. Separate the requested element from that image rather than redesigning. No stars, subtitles, modern effects or extra objects.  Isolate ONLY the row labeled "LEVEL 5 - MELCHORA AQUINO" with the elderly gray-haired Melchora Aquino in the fifth row. Keep its illustrated face in the complete left octagonal gold portrait frame, the long navy plaque, thin cream/gold border, and gold block/pixel text with red extrusion. Exact text: LEVEL 5 - MELCHORA AQUINO. REMOVE THE SILVER PADLOCK completely, replacing it with clean matching navy plaque; reserve blank space on the far right for a dynamic padlock supplied separately by Godot. Do not change the hero illustration or invent a different face. No background scenery and no other rows. Make the full row tightly framed with a genuinely transparent background, matching the reference's very wide approximately 5.8:1 row proportions. Keep portrait and plaque aligned as in reference, no additional text or ornament.

### level6

Use case: background-extraction. Asset type: one transparent horizontal Godot level row texture. Input image 1 is the user's latest approved HistoryRoll CHOOSE YOUR LEVEL reference. Preserve its exact navy blue, gold, black outline, red text extrusion, crisp pixel-art style. Separate the requested element from that image rather than redesigning. No stars, subtitles, modern effects or extra objects.  Isolate ONLY the row labeled "LEVEL 6 - APOLINARIO MABINI" with Apolinario Mabini in a black suit in the sixth row. Keep its illustrated face in the complete left octagonal gold portrait frame, the long navy plaque, thin cream/gold border, and gold block/pixel text with red extrusion. Exact text: LEVEL 6 - APOLINARIO MABINI. REMOVE THE SILVER PADLOCK completely, replacing it with clean matching navy plaque; reserve blank space on the far right for a dynamic padlock supplied separately by Godot. Do not change the hero illustration or invent a different face. No background scenery and no other rows. Make the full row tightly framed with a genuinely transparent background, matching the reference's very wide approximately 5.8:1 row proportions. Keep portrait and plaque aligned as in reference, no additional text or ornament.

## Verification

Run `res://tests/level_selection_layout_test.gd` with GL Compatibility for the
reference 1086x1448, legacy 1024x1536, and 720x1280, 1080x1920, 1080x2340,
1080x2400 portrait captures. Run `res://tests/level_selection_test.gd` for fresh
progress, locked access, automatic unlocks and saved progress persistence.

All tests use separate temporary test saves under user://. The actual player
progress file is neither reset nor replaced.

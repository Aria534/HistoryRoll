extends RefCounted

const SPECIAL_TILE_TYPES: PackedStringArray = ["bonus", "shield"]


static func get_tile_count(config: Dictionary) -> int:
	return int(config.get("columns", 0)) * int(config.get("rows", 0))


static func validate_config(config: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var columns := int(config.get("columns", 0))
	var rows := int(config.get("rows", 0))
	var tile_count := columns * rows
	if columns < 2:
		errors.append("Board columns must be at least 2.")
	if rows < 2:
		errors.append("Board rows must be at least 2.")
	if tile_count < 4:
		errors.append("Board must contain at least 4 tiles.")

	var snakes: Dictionary = config.get("snakes", {})
	var ladders: Dictionary = config.get("ladders", {})
	var question_tiles: Variant = config.get("question_tiles", [])
	var seen_question_tiles: Dictionary = {}
	_validate_connections(snakes, tile_count, false, errors)
	_validate_connections(ladders, tile_count, true, errors)
	for start: Variant in snakes:
		if _mapping_has(ladders, int(start)):
			errors.append("Tile %d cannot start both a snake and a ladder." % int(start))
	if not question_tiles is Array:
		errors.append("Question tiles must be an array.")
	else:
		for raw_tile: Variant in question_tiles:
			if not raw_tile is int and not raw_tile is float:
				errors.append("Every question tile must be a number.")
				continue
			var question_tile := int(raw_tile)
			if question_tile <= 1 or question_tile >= tile_count:
				errors.append("Question tile %d must be between tiles 2 and %d." % [question_tile, tile_count - 1])
			elif seen_question_tiles.has(question_tile):
				errors.append("Question tile %d is duplicated." % question_tile)
			elif _mapping_has(snakes, question_tile) or _mapping_has(ladders, question_tile):
				errors.append("Question tile %d cannot also start a snake or ladder." % question_tile)
			else:
				seen_question_tiles[question_tile] = true
	_validate_special_tiles(config, tile_count, snakes, ladders, seen_question_tiles, errors)
	return errors


static func calculate_normal_destination(
	current_position: int,
	dice_result: int,
	tile_count: int,
	exact_finish: bool
) -> int:
	if dice_result < 1 or dice_result > 6 or tile_count < 1:
		return current_position
	var proposed := current_position + dice_result
	if proposed > tile_count:
		return current_position if exact_finish else tile_count
	return proposed


static func get_tile_effect(config: Dictionary, tile: int) -> Dictionary:
	var ladders: Dictionary = config.get("ladders", {})
	if _mapping_has(ladders, tile):
		return {"type": "ladder", "from": tile, "to": _mapping_get(ladders, tile)}
	var snakes: Dictionary = config.get("snakes", {})
	if _mapping_has(snakes, tile):
		return {"type": "snake", "from": tile, "to": _mapping_get(snakes, tile)}
	return {}


static func is_question_tile(config: Dictionary, tile: int) -> bool:
	var question_tiles: Variant = config.get("question_tiles", [])
	if not question_tiles is Array:
		return false
	for raw_tile: Variant in question_tiles:
		if int(raw_tile) == tile:
			return true
	return false


static func get_special_tile_type(config: Dictionary, tile: int) -> String:
	var special_tiles: Variant = config.get("special_tiles", {})
	if not special_tiles is Dictionary:
		return ""
	for tile_type: String in SPECIAL_TILE_TYPES:
		var positions: Variant = special_tiles.get(tile_type, [])
		if positions is Array:
			for raw_tile: Variant in positions:
				if int(raw_tile) == tile:
					return tile_type
	return ""


# Tile priority is positional movement, then special tile, then regular question.
# Configuration validation prevents conflicting primary effects on one tile.
static func get_primary_tile_effect(config: Dictionary, tile: int) -> Dictionary:
	var movement_effect := get_tile_effect(config, tile)
	if not movement_effect.is_empty():
		return movement_effect
	var special_type := get_special_tile_type(config, tile)
	if not special_type.is_empty():
		return {"type": special_type, "from": tile, "to": tile}
	if is_question_tile(config, tile):
		return {"type": "question", "from": tile, "to": tile}
	return {"type": "normal", "from": tile, "to": tile}


static func tile_to_visual_cell(tile: int, columns: int, rows: int) -> Vector2i:
	if tile < 1 or tile > columns * rows:
		return Vector2i(-1, -1)
	var board_row := (tile - 1) / columns
	var offset := (tile - 1) % columns
	var visual_column := offset if board_row % 2 == 0 else columns - 1 - offset
	var visual_row := rows - 1 - board_row
	return Vector2i(visual_column, visual_row)


static func _validate_connections(
	connections: Dictionary,
	tile_count: int,
	is_ladder: bool,
	errors: PackedStringArray
) -> void:
	for raw_start: Variant in connections:
		var start := int(raw_start)
		var destination := int(connections[raw_start])
		if start < 1 or start > tile_count or destination < 1 or destination > tile_count:
			errors.append("Connection %d -> %d is outside the board." % [start, destination])
		elif is_ladder and destination <= start:
			errors.append("Ladder %d -> %d must move upward." % [start, destination])
		elif not is_ladder and destination >= start:
			errors.append("Snake %d -> %d must move downward." % [start, destination])


static func _validate_special_tiles(
	config: Dictionary,
	tile_count: int,
	snakes: Dictionary,
	ladders: Dictionary,
	question_tiles: Dictionary,
	errors: PackedStringArray
) -> void:
	var special_tiles: Variant = config.get("special_tiles", {})
	if not special_tiles is Dictionary:
		errors.append("Special tiles must be a dictionary.")
		return

	for raw_type: Variant in special_tiles:
		if not SPECIAL_TILE_TYPES.has(str(raw_type)):
			errors.append("Unknown special tile type: %s." % str(raw_type))

	var occupied_tiles: Dictionary = {}
	for tile_type: String in SPECIAL_TILE_TYPES:
		var positions: Variant = special_tiles.get(tile_type, [])
		if not positions is Array:
			errors.append("Special tile category '%s' must be an array." % tile_type)
			continue
		var category_tiles: Dictionary = {}
		for raw_tile: Variant in positions:
			if not raw_tile is int and not raw_tile is float:
				errors.append("Every %s tile must be a number." % tile_type)
				continue
			var tile := int(raw_tile)
			if tile <= 1 or tile >= tile_count:
				errors.append("Special tile %d must be between tiles 2 and %d." % [tile, tile_count - 1])
			elif category_tiles.has(tile):
				errors.append("Special tile %d is duplicated in '%s'." % [tile, tile_type])
			elif occupied_tiles.has(tile):
				errors.append("Special tile %d conflicts between '%s' and '%s'." % [tile, occupied_tiles[tile], tile_type])
			elif question_tiles.has(tile):
				errors.append("Special tile %d conflicts with a Question Mark tile." % tile)
			elif _mapping_has(snakes, tile) or _mapping_has(ladders, tile):
				errors.append("Special tile %d conflicts with a snake or ladder start." % tile)
			else:
				category_tiles[tile] = true
				occupied_tiles[tile] = tile_type


static func _mapping_has(mapping: Dictionary, tile: int) -> bool:
	return mapping.has(tile) or mapping.has(str(tile))


static func _mapping_get(mapping: Dictionary, tile: int) -> int:
	if mapping.has(tile):
		return int(mapping[tile])
	return int(mapping.get(str(tile), tile))

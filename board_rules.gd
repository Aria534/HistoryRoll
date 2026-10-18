extends RefCounted


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
	_validate_connections(snakes, tile_count, false, errors)
	_validate_connections(ladders, tile_count, true, errors)
	for start: Variant in snakes:
		if _mapping_has(ladders, int(start)):
			errors.append("Tile %d cannot start both a snake and a ladder." % int(start))
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


static func _mapping_has(mapping: Dictionary, tile: int) -> bool:
	return mapping.has(tile) or mapping.has(str(tile))


static func _mapping_get(mapping: Dictionary, tile: int) -> int:
	if mapping.has(tile):
		return int(mapping[tile])
	return int(mapping.get(str(tile), tile))

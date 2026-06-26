class_name BoardGenerator
extends RefCounted

func generate_board(words: Array[WordEntry], width: int, height: int) -> Dictionary:
	var grid: Array = _create_empty_grid(width, height)
	var placed: Array[Dictionary] = []
	if words.is_empty():
		return {"grid": grid, "placed_words": placed}

	var first: WordEntry = words[0]
	var start_x: int = int((width - first.length) / 2)
	var start_y: int = int(height / 2)
	var start: Vector2i = Vector2i(start_x, start_y)
	if _can_place_word(grid, first, start, Vector2i(1, 0), width, height):
		_place_word(grid, first, start, Vector2i(1, 0), 0)
		placed.append({
			"id": 0,
			"entry": first,
			"start": start,
			"dir": Vector2i(1, 0),
			"length": first.length,
		})

	var next_id: int = placed.size()
	for i in range(1, words.size()):
		var entry: WordEntry = words[i]
		var placement: Variant = _find_best_available_placement(grid, placed, entry, width, height)
		if placement == null:
			continue
		var dir: Vector2i = placement["dir"]
		var start_pos: Vector2i = placement["start"]
		_place_word(grid, entry, start_pos, dir, next_id)
		placed.append({
			"id": next_id,
			"entry": entry,
			"start": start_pos,
			"dir": dir,
			"length": entry.length,
		})
		next_id += 1

	return _remove_isolated_words(grid, placed, width, height)

func _find_best_available_placement(grid: Array, placed: Array[Dictionary], entry: WordEntry, width: int, height: int) -> Variant:
	var placement: Variant = _find_placement(grid, placed, entry, width, height, 1)
	if placement != null:
		return placement

	placement = _find_fallback_placement(grid, entry, width, height, false, 1)
	return placement

func _remove_isolated_words(_grid: Array, placed: Array[Dictionary], width: int, height: int) -> Dictionary:
	var connected: Array[Dictionary] = []
	for word_data in placed:
		if _word_has_intersection(_grid, word_data):
			connected.append(word_data)
	if connected.size() == placed.size():
		return {"grid": _grid, "placed_words": placed}

	var rebuilt_grid: Array = _create_empty_grid(width, height)
	var rebuilt_words: Array[Dictionary] = []
	var next_id: int = 0
	for word_data in connected:
		var entry: WordEntry = word_data["entry"]
		var start: Vector2i = Vector2i(word_data["start"])
		var dir: Vector2i = Vector2i(word_data["dir"])
		_place_word(rebuilt_grid, entry, start, dir, next_id)
		rebuilt_words.append({
			"id": next_id,
			"entry": entry,
			"start": start,
			"dir": dir,
			"length": entry.length,
		})
		next_id += 1
	return {"grid": rebuilt_grid, "placed_words": rebuilt_words}

func _word_has_intersection(grid: Array, word_data: Dictionary) -> bool:
	var start: Vector2i = Vector2i(word_data["start"])
	var dir: Vector2i = Vector2i(word_data["dir"])
	var length: int = int(word_data["length"])
	for i in range(length):
		var pos: Vector2i = start + dir * i
		var cell: Variant = grid[pos.y][pos.x]
		if cell != null and cell.get("word_ids", []).size() > 1:
			return true
	return false

func _create_empty_grid(width: int, height: int) -> Array:
	var grid: Array = []
	for y in range(height):
		var row: Array = []
		row.resize(width)
		for x in range(width):
			row[x] = null
		grid.append(row)
	return grid

func _find_placement(grid: Array, placed: Array[Dictionary], entry: WordEntry, width: int, height: int, min_intersections: int) -> Variant:
	var best: Dictionary = {}
	var best_score: float = -999999.0
	var best_distance: float = 0.0
	var center: Vector2 = Vector2(width * 0.5, height * 0.5)
	var base_bounds: Dictionary = _get_bounds(placed)
	var base_area: int = _bounds_area(base_bounds)
	for placed_word in placed:
		var existing: WordEntry = placed_word["entry"]
		var existing_dir: Vector2i = placed_word["dir"]
		var new_dir: Vector2i = Vector2i(existing_dir.y, existing_dir.x)
		for i in range(entry.length):
			for j in range(existing.length):
				if entry.letters[i] != existing.letters[j]:
					continue
				var intersect: Vector2i = Vector2i(placed_word["start"]) + existing_dir * j
				var start_pos: Vector2i = intersect - new_dir * i
				if _can_place_word(grid, entry, start_pos, new_dir, width, height):
					var intersections: int = _count_intersections(grid, entry, start_pos, new_dir)
					if intersections < min_intersections:
						continue
					var distance: float = _distance_to_center(start_pos, entry.length, new_dir, center)
					var new_bounds: Dictionary = _bounds_after_placement(base_bounds, start_pos, new_dir, entry.length)
					var area_penalty: float = float(_bounds_area(new_bounds) - base_area)
					var score: float = float(intersections * 10) - area_penalty * 0.35 - distance
					if score > best_score or (score == best_score and distance < best_distance):
						best_score = score
						best_distance = distance
						best = {"start": start_pos, "dir": new_dir}
	if best_score > -99999.0:
		return best
	return null

func _can_place_word(grid: Array, entry: WordEntry, start: Vector2i, dir: Vector2i, width: int, height: int) -> bool:
	for i in range(entry.length):
		var x: int = start.x + dir.x * i
		var y: int = start.y + dir.y * i
		if x < 0 or y < 0 or x >= width or y >= height:
			return false
		var cell: Variant = grid[y][x]
		if cell != null and cell["original_char"] != entry.letters[i]:
			return false
		if cell == null:
			if dir.x != 0:
				if _cell_exists(grid, x, y - 1, width, height) or _cell_exists(grid, x, y + 1, width, height):
					return false
			else:
				if _cell_exists(grid, x - 1, y, width, height) or _cell_exists(grid, x + 1, y, width, height):
					return false

	var before: Vector2i = start - dir
	var after: Vector2i = start + dir * entry.length
	if _cell_exists(grid, before.x, before.y, width, height):
		return false
	if _cell_exists(grid, after.x, after.y, width, height):
		return false
	return true

func _find_fallback_placement(grid: Array, entry: WordEntry, width: int, height: int, allow_adjacent: bool, min_intersections: int) -> Variant:
	var best: Dictionary = {}
	var best_score: float = -99999.0
	var center: Vector2 = Vector2(width * 0.5, height * 0.5)
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1)]
	var base_bounds: Dictionary = _get_bounds_from_grid(grid, width, height)
	var base_area: int = _bounds_area(base_bounds)
	for dir in dirs:
		var max_x: int = width - 1
		var max_y: int = height - 1
		if dir.x != 0:
			max_x = width - entry.length
		if dir.y != 0:
			max_y = height - entry.length
		for y in range(max_y + 1):
			for x in range(max_x + 1):
				var start: Vector2i = Vector2i(x, y)
				if not _can_place_word_fallback(grid, entry, start, dir, width, height, allow_adjacent):
					continue
				var intersections: int = _count_intersections(grid, entry, start, dir)
				if intersections < min_intersections:
					continue
				var distance: float = _distance_to_center(start, entry.length, dir, center)
				var new_bounds: Dictionary = _bounds_after_placement(base_bounds, start, dir, entry.length)
				var area_penalty: float = float(_bounds_area(new_bounds) - base_area)
				var score: float = float(intersections * 10) - area_penalty * 0.35 - distance
				if score > best_score:
					best_score = score
					best = {"start": start, "dir": dir}
	if best_score < -9000.0:
		return null
	return best

func _can_place_word_fallback(grid: Array, entry: WordEntry, start: Vector2i, dir: Vector2i, width: int, height: int, allow_adjacent: bool) -> bool:
	if allow_adjacent:
		for i in range(entry.length):
			var x: int = start.x + dir.x * i
			var y: int = start.y + dir.y * i
			if x < 0 or y < 0 or x >= width or y >= height:
				return false
			var cell: Variant = grid[y][x]
			if cell != null and cell["original_char"] != entry.letters[i]:
				return false
		return true
	return _can_place_word(grid, entry, start, dir, width, height)

func _cell_exists(grid: Array, x: int, y: int, width: int, height: int) -> bool:
	if x < 0 or y < 0 or x >= width or y >= height:
		return false
	return grid[y][x] != null

func _count_intersections(grid: Array, entry: WordEntry, start: Vector2i, dir: Vector2i) -> int:
	var count: int = 0
	for i in range(entry.length):
		var x: int = start.x + dir.x * i
		var y: int = start.y + dir.y * i
		if grid[y][x] != null:
			count += 1
	return count

func _distance_to_center(start: Vector2i, length: int, dir: Vector2i, center: Vector2) -> float:
	var mid: Vector2 = Vector2(start) + Vector2(dir) * float(length - 1) * 0.5
	return mid.distance_to(center)

func _get_bounds(placed: Array[Dictionary]) -> Dictionary:
	if placed.is_empty():
		return {"min_x": 0, "max_x": -1, "min_y": 0, "max_y": -1}
	var min_x: int = 99999
	var max_x: int = -99999
	var min_y: int = 99999
	var max_y: int = -99999
	for word_data in placed:
		var start: Vector2i = Vector2i(word_data["start"])
		var dir: Vector2i = Vector2i(word_data["dir"])
		var length: int = int(word_data["length"])
		var end: Vector2i = start + dir * (length - 1)
		min_x = mini(mini(min_x, start.x), end.x)
		max_x = maxi(maxi(max_x, start.x), end.x)
		min_y = mini(mini(min_y, start.y), end.y)
		max_y = maxi(maxi(max_y, start.y), end.y)
	return {"min_x": min_x, "max_x": max_x, "min_y": min_y, "max_y": max_y}

func _get_bounds_from_grid(grid: Array, width: int, height: int) -> Dictionary:
	var min_x: int = 99999
	var max_x: int = -99999
	var min_y: int = 99999
	var max_y: int = -99999
	var found: bool = false
	for y in range(height):
		for x in range(width):
			if grid[y][x] == null:
				continue
			found = true
			min_x = mini(min_x, x)
			max_x = maxi(max_x, x)
			min_y = mini(min_y, y)
			max_y = maxi(max_y, y)
	if not found:
		return {"min_x": 0, "max_x": -1, "min_y": 0, "max_y": -1}
	return {"min_x": min_x, "max_x": max_x, "min_y": min_y, "max_y": max_y}

func _bounds_after_placement(bounds: Dictionary, start: Vector2i, dir: Vector2i, length: int) -> Dictionary:
	var min_x: int = int(bounds.get("min_x", 0))
	var max_x: int = int(bounds.get("max_x", -1))
	var min_y: int = int(bounds.get("min_y", 0))
	var max_y: int = int(bounds.get("max_y", -1))
	var end: Vector2i = start + dir * (length - 1)
	if max_x < min_x:
		min_x = start.x
		max_x = start.x
		min_y = start.y
		max_y = start.y
	min_x = mini(mini(min_x, start.x), end.x)
	max_x = maxi(maxi(max_x, start.x), end.x)
	min_y = mini(mini(min_y, start.y), end.y)
	max_y = maxi(maxi(max_y, start.y), end.y)
	return {"min_x": min_x, "max_x": max_x, "min_y": min_y, "max_y": max_y}

func _bounds_area(bounds: Dictionary) -> int:
	var min_x: int = int(bounds.get("min_x", 0))
	var max_x: int = int(bounds.get("max_x", -1))
	var min_y: int = int(bounds.get("min_y", 0))
	var max_y: int = int(bounds.get("max_y", -1))
	if max_x < min_x or max_y < min_y:
		return 0
	return (max_x - min_x + 1) * (max_y - min_y + 1)

func _place_word(grid: Array, entry: WordEntry, start: Vector2i, dir: Vector2i, word_id: int) -> void:
	var pos: Vector2i = start
	for i in range(entry.length):
		var letter: String = entry.letters[i]
		if grid[pos.y][pos.x] == null:
			var info: Dictionary = DiacriticHelper.char_to_info(letter)
			grid[pos.y][pos.x] = {
				"original_char": letter,
				"base_char": info["base"],
				"variant": info["variant"],
				"tone": info["tone"],
				"input_char": "",
				"is_filled": false,
				"is_correct": false,
				"word_ids": [word_id],
			}
		else:
			var cell: Variant = grid[pos.y][pos.x]
			if not cell["word_ids"].has(word_id):
				cell["word_ids"].append(word_id)
		pos += dir

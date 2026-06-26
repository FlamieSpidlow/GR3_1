class_name GameState
extends RefCounted

var grid: Array = []
var placed_words: Array[Dictionary] = []
var width: int = 0
var height: int = 0
var guess_attempts: int = 0
var guess_correct: int = 0
var elapsed_seconds: int = 0
var start_time_msec: int = 0
var guess_history: Array[Dictionary] = []
var score: int = 0
var word_times: Dictionary = {}
var hinted_letters: Dictionary = {}
var hint_letters_used: int = 0
var hint_words_used: int = 0
var current_streak: int = 0
var best_streak: int = 0
var missions: Array[Dictionary] = []
var stars_awarded: bool = false
var active_word_id: int = -1
var active_word_started_msec: int = 0
var level_id: String = ""
var level_title: String = ""
var level_difficulty: String = ""

const MAX_HISTORY := 200

func set_board(board: Dictionary) -> void:
	grid = board["grid"]
	placed_words = board["placed_words"]
	height = grid.size()
	width = 0
	if height > 0:
		width = grid[0].size()
	for word_data in placed_words:
		word_data["completed"] = false
	_reset_stats()

func set_level_info(new_id: String, new_title: String, new_difficulty: String) -> void:
	level_id = new_id
	level_title = new_title
	level_difficulty = new_difficulty

func _reset_stats() -> void:
	guess_attempts = 0
	guess_correct = 0
	elapsed_seconds = 0
	start_time_msec = Time.get_ticks_msec()
	guess_history = []
	score = 0
	word_times = {}
	hinted_letters = {}
	hint_letters_used = 0
	hint_words_used = 0
	current_streak = 0
	best_streak = 0
	missions = _generate_missions()
	stars_awarded = false
	active_word_id = -1
	active_word_started_msec = 0

func get_tile(pos: Vector2i) -> Variant:
	if pos.y < 0 or pos.y >= height:
		return null
	if pos.x < 0 or pos.x >= width:
		return null
	return grid[pos.y][pos.x]

func set_input_at(pos: Vector2i, char: String) -> bool:
	var cell: Variant = get_tile(pos)
	if cell == null:
		return false
	cell["input_char"] = char
	cell["is_filled"] = char != ""
	cell["is_correct"] = cell["is_filled"] and char == cell["original_char"]
	return true

func clear_input_at(pos: Vector2i) -> void:
	var cell: Variant = get_tile(pos)
	if cell == null:
		return
	cell["input_char"] = ""
	cell["is_filled"] = false
	cell["is_correct"] = false

func update_cell_correctness() -> void:
	for y in range(height):
		for x in range(width):
			var cell: Variant = grid[y][x]
			if cell == null:
				continue
			var input_char: String = String(cell["input_char"])
			cell["is_correct"] = input_char != "" and input_char == cell["original_char"]

func check_word(word_id: int) -> bool:
	var word_data: Variant = _get_word_by_id(word_id)
	if word_data == null:
		return false
	var pos: Vector2i = word_data["start"]
	var dir: Vector2i = word_data["dir"]
	var ok: bool = true
	for i in range(word_data["length"]):
		var cell: Variant = grid[pos.y][pos.x]
		if cell == null:
			ok = false
			break
		var input_char: String = String(cell["input_char"])
		if input_char == "" or input_char != cell["original_char"]:
			ok = false
			break
		pos += dir
	word_data["completed"] = ok
	return ok

func check_all_words() -> bool:
	update_cell_correctness()
	var all_ok: bool = true
	for word_data in placed_words:
		var ok: bool = check_word(word_data["id"])
		if not ok:
			all_ok = false
	return all_ok

func is_complete() -> bool:
	if placed_words.is_empty():
		return false
	for word_data in placed_words:
		if not word_data.get("completed", false):
			return false
	return true

func count_completed() -> int:
	var count: int = 0
	for word_data in placed_words:
		if word_data.get("completed", false):
			count += 1
	return count

func get_first_filled_pos() -> Vector2i:
	for y in range(height):
		for x in range(width):
			if grid[y][x] != null:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

func get_word_data(word_id: int) -> Variant:
	return _get_word_by_id(word_id)

func record_guess(word_id: int, guess: String, is_correct: bool, earned_score: int = 0) -> void:
	guess_attempts += 1
	if is_correct:
		guess_correct += 1
		current_streak += 1
		best_streak = maxi(best_streak, current_streak)
	else:
		current_streak = 0
	var word_data: Variant = _get_word_by_id(word_id)
	var target_word: String = ""
	if word_data != null:
		var entry: WordEntry = word_data["entry"]
		target_word = entry.word
	guess_history.append({
		"time": get_elapsed_seconds(),
		"word": target_word,
		"guess": guess,
		"correct": is_correct,
		"score": earned_score,
	})
	while guess_history.size() > MAX_HISTORY:
		guess_history.remove_at(0)

func select_word_timer(word_id: int) -> void:
	if active_word_id == word_id:
		return
	pause_active_word_timer()
	var word_data: Variant = _get_word_by_id(word_id)
	if word_data == null or bool(word_data.get("completed", false)):
		active_word_id = -1
		active_word_started_msec = 0
		return
	active_word_id = word_id
	active_word_started_msec = Time.get_ticks_msec()

func pause_active_word_timer() -> void:
	if active_word_id < 0 or active_word_started_msec <= 0:
		return
	var elapsed: int = int((Time.get_ticks_msec() - active_word_started_msec) / 1000)
	if elapsed < 0:
		elapsed = 0
	word_times[str(active_word_id)] = int(word_times.get(str(active_word_id), 0)) + elapsed
	active_word_id = -1
	active_word_started_msec = 0

func pause_clock() -> void:
	if start_time_msec > 0:
		var elapsed: int = int((Time.get_ticks_msec() - start_time_msec) / 1000)
		if elapsed > 0:
			elapsed_seconds += elapsed
		start_time_msec = 0
	pause_active_word_timer()

func resume_clock() -> void:
	if start_time_msec <= 0:
		start_time_msec = Time.get_ticks_msec()

func get_word_elapsed_seconds(word_id: int) -> int:
	var total: int = int(word_times.get(str(word_id), 0))
	if word_id == active_word_id and active_word_started_msec > 0:
		var elapsed: int = int((Time.get_ticks_msec() - active_word_started_msec) / 1000)
		if elapsed > 0:
			total += elapsed
	return total

func award_score_for_word(word_id: int) -> int:
	var word_data: Variant = _get_word_by_id(word_id)
	if word_data == null:
		return 0
	var entry: WordEntry = word_data["entry"]
	var elapsed: int = get_word_elapsed_seconds(word_id)
	var length_points: int = entry.length * 100
	var speed_bonus: int = maxi(0, 300 - elapsed * 10)
	var raw_score: int = length_points + speed_bonus
	var self_solved_letters: int = maxi(entry.length - get_hinted_letter_count(word_id), 0)
	var earned: int = int(round(float(raw_score) * float(self_solved_letters) / float(maxi(entry.length, 1))))
	score += earned
	return earned

func mark_hinted_letter(word_id: int) -> void:
	var word_data: Variant = _get_word_by_id(word_id)
	if word_data == null:
		return
	var entry: WordEntry = word_data["entry"]
	var current: int = get_hinted_letter_count(word_id)
	hinted_letters[str(word_id)] = mini(current + 1, entry.length)
	hint_letters_used += 1

func mark_hinted_word(word_id: int) -> void:
	var word_data: Variant = _get_word_by_id(word_id)
	if word_data == null:
		return
	var entry: WordEntry = word_data["entry"]
	hinted_letters[str(word_id)] = entry.length
	hint_words_used += 1

func get_hinted_letter_count(word_id: int) -> int:
	return int(hinted_letters.get(str(word_id), 0))

func get_total_hints_used() -> int:
	return hint_letters_used + hint_words_used

func get_mission_star_count() -> int:
	var count: int = 0
	for mission in missions:
		if is_mission_complete(mission):
			count += 1
	return count

func is_mission_complete(mission: Dictionary) -> bool:
	var mission_type: String = String(mission.get("type", ""))
	if mission_type == "complete":
		return is_complete()
	if mission_type == "score":
		return is_complete() and score >= int(mission.get("target", 0))
	if mission_type == "hint_limit":
		return is_complete() and get_total_hints_used() <= int(mission.get("target", 0))
	if mission_type == "streak":
		return is_complete() and best_streak >= int(mission.get("target", 0))
	if mission_type == "time_limit":
		return is_complete() and get_elapsed_seconds() <= int(mission.get("target", 0))
	if mission_type == "no_word_hint":
		return is_complete() and hint_words_used == 0
	if mission_type == "accuracy":
		if not is_complete() or guess_attempts <= 0:
			return false
		var percent: int = int(round(float(guess_correct) / float(guess_attempts) * 100.0))
		return percent >= int(mission.get("target", 0))
	return false

func get_mission_progress_text(mission: Dictionary) -> String:
	var mission_type: String = String(mission.get("type", ""))
	if mission_type == "complete":
		return "%d/%d từ" % [count_completed(), placed_words.size()]
	if mission_type == "score":
		return "%d/%d điểm" % [score, int(mission.get("target", 0))]
	if mission_type == "hint_limit":
		return "%d/%d gợi ý" % [get_total_hints_used(), int(mission.get("target", 0))]
	if mission_type == "streak":
		return "%d/%d liên tiếp" % [best_streak, int(mission.get("target", 0))]
	if mission_type == "time_limit":
		return "%s/%s" % [_format_seconds(get_elapsed_seconds()), _format_seconds(int(mission.get("target", 0)))]
	if mission_type == "no_word_hint":
		return "%d lần lộ cả từ" % hint_words_used
	if mission_type == "accuracy":
		var percent: int = 0
		if guess_attempts > 0:
			percent = int(round(float(guess_correct) / float(guess_attempts) * 100.0))
		return "%d%%/%d%%" % [percent, int(mission.get("target", 0))]
	return ""

func _generate_missions() -> Array[Dictionary]:
	var generated: Array[Dictionary] = []
	generated.append({"type": "complete", "text": "Hoàn thành màn"})
	var score_target: int = _get_score_mission_target()
	generated.append({"type": "score", "target": score_target, "text": "Đạt %d điểm" % score_target})
	generated.append(_generate_bonus_mission())
	return generated

func _generate_bonus_mission() -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var options: Array[Dictionary] = []
	var word_count: int = maxi(placed_words.size(), 1)
	var hint_limit: int = maxi(1, int(ceil(float(word_count) * 0.25)))
	var streak_target: int = mini(word_count, maxi(2, int(ceil(float(word_count) * 0.4))))
	var time_target: int = _get_time_mission_target()
	options.append({"type": "hint_limit", "target": hint_limit, "text": "Dùng tối đa %d gợi ý" % hint_limit})
	options.append({"type": "streak", "target": streak_target, "text": "Đoán đúng %d từ liên tiếp" % streak_target})
	options.append({"type": "time_limit", "target": time_target, "text": "Hoàn thành trong %s" % _format_seconds(time_target)})
	options.append({"type": "no_word_hint", "text": "Không dùng Lộ cả từ"})
	options.append({"type": "accuracy", "target": 80, "text": "Đoán đúng ít nhất 80%"})
	return options[rng.randi_range(0, options.size() - 1)]

func _get_score_mission_target() -> int:
	var theoretical_score: int = 0
	for word_data in placed_words:
		var entry: WordEntry = word_data["entry"]
		theoretical_score += entry.length * 100 + 300
	return int(round(float(theoretical_score) * 0.65))

func _get_time_mission_target() -> int:
	var total_letters: int = 0
	for word_data in placed_words:
		total_letters += int(word_data["length"])
	var seconds: int = placed_words.size() * 18 + total_letters * 2
	return maxi(90, seconds)

func _format_seconds(seconds: int) -> String:
	var minutes: int = int(seconds / 60)
	var remain: int = int(seconds % 60)
	return "%02d:%02d" % [minutes, remain]

func get_elapsed_seconds() -> int:
	if start_time_msec <= 0:
		return elapsed_seconds
	var delta: int = int((Time.get_ticks_msec() - start_time_msec) / 1000)
	if delta < 0:
		delta = 0
	return elapsed_seconds + delta

func reveal_word(word_id: int) -> bool:
	var word_data: Variant = _get_word_by_id(word_id)
	if word_data == null:
		return false
	var pos: Vector2i = word_data["start"]
	var dir: Vector2i = word_data["dir"]
	for i in range(word_data["length"]):
		var cell: Variant = grid[pos.y][pos.x]
		if cell != null:
			cell["input_char"] = cell["original_char"]
			cell["is_filled"] = true
			cell["is_correct"] = true
		pos += dir
	word_data["completed"] = true
	check_all_words()
	return true

func reveal_first_letter(word_id: int) -> bool:
	var word_data: Variant = _get_word_by_id(word_id)
	if word_data == null:
		return false
	var pos: Vector2i = word_data["start"]
	var cell: Variant = grid[pos.y][pos.x]
	if cell == null:
		return false
	cell["input_char"] = cell["original_char"]
	cell["is_filled"] = true
	cell["is_correct"] = true
	check_word(word_id)
	return true

func reveal_one_letter(word_id: int) -> bool:
	var word_data: Variant = _get_word_by_id(word_id)
	if word_data == null:
		return false
	var pos: Vector2i = word_data["start"]
	var dir: Vector2i = word_data["dir"]
	for i in range(word_data["length"]):
		var cell: Variant = grid[pos.y][pos.x]
		if cell != null and String(cell.get("input_char", "")) != cell["original_char"]:
			cell["input_char"] = cell["original_char"]
			cell["is_filled"] = true
			cell["is_correct"] = true
			check_word(word_id)
			return true
		pos += dir
	return false

func _get_word_by_id(word_id: int) -> Variant:
	for word_data in placed_words:
		if word_data["id"] == word_id:
			return word_data
	return null

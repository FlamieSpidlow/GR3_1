class_name SaveManager
extends RefCounted

const RECORD_PATH := "user://records.json"
const STARTING_STARS := 3
const DEFAULT_PROFILE_ID := "player"
const DEFAULT_PROFILE_NAME := "Người chơi"

static func load_best_score() -> int:
	return int(_load_current_progress().get("best_score", 0))

static func save_best_score(score: int) -> bool:
	var data: Dictionary = load_records()
	var records: Dictionary = _get_current_progress(data)
	records["best_score"] = score
	_set_current_progress(data, records)
	return save_records(data)

static func load_total_stars() -> int:
	return int(_load_current_progress().get("total_stars", STARTING_STARS))

static func add_stars(amount: int) -> bool:
	if amount <= 0:
		return true
	var data: Dictionary = load_records()
	var records: Dictionary = _get_current_progress(data)
	records["total_stars"] = int(records.get("total_stars", STARTING_STARS)) + amount
	records["earned_stars"] = int(records.get("earned_stars", 0)) + amount
	_set_current_progress(data, records)
	return save_records(data)

static func spend_stars(amount: int) -> bool:
	if amount <= 0:
		return true
	var data: Dictionary = load_records()
	var records: Dictionary = _get_current_progress(data)
	var current: int = int(records.get("total_stars", STARTING_STARS))
	if current < amount:
		return false
	records["total_stars"] = current - amount
	records["spent_stars"] = int(records.get("spent_stars", 0)) + amount
	_set_current_progress(data, records)
	return save_records(data)

static func add_played_game() -> bool:
	var data: Dictionary = load_records()
	var records: Dictionary = _get_current_progress(data)
	records["games_played"] = int(records.get("games_played", 0)) + 1
	_set_current_progress(data, records)
	return save_records(data)

static func get_level_progress(level_id: String) -> Dictionary:
	var levels: Dictionary = _get_levels_record(_load_current_progress())
	var raw_progress: Variant = levels.get(level_id, {})
	if typeof(raw_progress) != TYPE_DICTIONARY:
		return {}
	return raw_progress

static func record_level_completion(level_id: String, stars: int, score: int, elapsed_seconds: int) -> bool:
	if level_id == "":
		return false
	var data: Dictionary = load_records()
	var records: Dictionary = _get_current_progress(data)
	var levels: Dictionary = _get_levels_record(records)
	var current: Dictionary = {}
	var raw_current: Variant = levels.get(level_id, {})
	if typeof(raw_current) == TYPE_DICTIONARY:
		current = raw_current
	current["completed"] = true
	current["stars"] = maxi(int(current.get("stars", 0)), stars)
	current["best_score"] = maxi(int(current.get("best_score", 0)), score)
	var best_time: int = int(current.get("best_time", 0))
	if best_time <= 0 or elapsed_seconds < best_time:
		current["best_time"] = elapsed_seconds
	levels[level_id] = current
	records["levels"] = levels
	_set_current_progress(data, records)
	return save_records(data)

static func get_profiles() -> Array[Dictionary]:
	var data: Dictionary = load_records()
	var profiles: Dictionary = _get_profiles(data)
	var result: Array[Dictionary] = []
	for profile_id in profiles.keys():
		var raw_profile: Variant = profiles[profile_id]
		if typeof(raw_profile) != TYPE_DICTIONARY:
			continue
		var profile: Dictionary = raw_profile
		result.append({
			"id": String(profile_id),
			"name": String(profile.get("name", DEFAULT_PROFILE_NAME)),
			"current": String(profile_id) == String(data.get("current_profile_id", DEFAULT_PROFILE_ID)),
		})
	return result

static func get_current_profile_id() -> String:
	return String(load_records().get("current_profile_id", DEFAULT_PROFILE_ID))

static func select_profile(profile_id: String) -> bool:
	var data: Dictionary = load_records()
	if not _get_profiles(data).has(profile_id):
		return false
	data["current_profile_id"] = profile_id
	return save_records(data)

static func create_profile(display_name: String) -> String:
	var clean_name: String = display_name.strip_edges()
	if clean_name == "":
		return ""
	var data: Dictionary = load_records()
	var profiles: Dictionary = _get_profiles(data)
	var profile_id: String = _make_profile_id(clean_name, profiles)
	profiles[profile_id] = {
		"name": clean_name,
		"records": _default_progress_records(),
	}
	data["profiles"] = profiles
	data["current_profile_id"] = profile_id
	if save_records(data):
		return profile_id
	return ""

static func delete_profile(profile_id: String) -> bool:
	var data: Dictionary = load_records()
	var profiles: Dictionary = _get_profiles(data)
	if profiles.size() <= 1 or not profiles.has(profile_id):
		return false
	profiles.erase(profile_id)
	data["profiles"] = profiles
	if String(data.get("current_profile_id", DEFAULT_PROFILE_ID)) == profile_id:
		data["current_profile_id"] = String(profiles.keys()[0])
	return save_records(data)

static func load_records() -> Dictionary:
	if not FileAccess.file_exists(RECORD_PATH):
		return _default_root_records()
	var file: FileAccess = FileAccess.open(RECORD_PATH, FileAccess.READ)
	if file == null:
		return _default_root_records()
	var data: Variant = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return _default_root_records()
	return _normalize_root_records(data)

static func save_records(data: Dictionary) -> bool:
	data = _normalize_root_records(data)
	data["initialized"] = true
	var file: FileAccess = FileAccess.open(RECORD_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write records file")
		return false
	file.store_string(JSON.stringify(data))
	return true

static func _default_root_records() -> Dictionary:
	return {
		"initialized": true,
		"current_profile_id": DEFAULT_PROFILE_ID,
		"profiles": {
			DEFAULT_PROFILE_ID: {
				"name": DEFAULT_PROFILE_NAME,
				"records": _default_progress_records(),
			},
		},
	}

static func _default_progress_records() -> Dictionary:
	return {
		"initialized": true,
		"best_score": 0,
		"total_stars": STARTING_STARS,
		"earned_stars": 0,
		"spent_stars": 0,
		"games_played": 0,
		"levels": {},
	}

static func _get_levels_record(data: Dictionary) -> Dictionary:
	var raw_levels: Variant = data.get("levels", {})
	if typeof(raw_levels) == TYPE_DICTIONARY:
		return raw_levels
	return {}

static func _load_current_progress() -> Dictionary:
	return _get_current_progress(load_records())

static func _get_current_progress(data: Dictionary) -> Dictionary:
	var profile_id: String = String(data.get("current_profile_id", DEFAULT_PROFILE_ID))
	var profiles: Dictionary = _get_profiles(data)
	var raw_profile: Variant = profiles.get(profile_id, {})
	if typeof(raw_profile) != TYPE_DICTIONARY:
		return _default_progress_records()
	var profile: Dictionary = raw_profile
	var raw_records: Variant = profile.get("records", {})
	if typeof(raw_records) != TYPE_DICTIONARY:
		return _default_progress_records()
	return _normalize_progress_records(raw_records)

static func _set_current_progress(data: Dictionary, records: Dictionary) -> void:
	var profile_id: String = String(data.get("current_profile_id", DEFAULT_PROFILE_ID))
	var profiles: Dictionary = _get_profiles(data)
	var profile: Dictionary = {}
	var raw_profile: Variant = profiles.get(profile_id, {})
	if typeof(raw_profile) == TYPE_DICTIONARY:
		profile = raw_profile
	profile["name"] = String(profile.get("name", DEFAULT_PROFILE_NAME))
	profile["records"] = _normalize_progress_records(records)
	profiles[profile_id] = profile
	data["profiles"] = profiles

static func _normalize_root_records(data: Dictionary) -> Dictionary:
	if typeof(data.get("profiles", {})) != TYPE_DICTIONARY:
		return _migrate_legacy_records(data)
	var profiles: Dictionary = _get_profiles(data)
	if profiles.is_empty():
		return _default_root_records()
	for profile_id in profiles.keys():
		var raw_profile: Variant = profiles[profile_id]
		if typeof(raw_profile) != TYPE_DICTIONARY:
			profiles.erase(profile_id)
			continue
		var profile: Dictionary = raw_profile
		profile["name"] = String(profile.get("name", DEFAULT_PROFILE_NAME)).strip_edges()
		if String(profile["name"]) == "":
			profile["name"] = DEFAULT_PROFILE_NAME
		var raw_records: Variant = profile.get("records", {})
		if typeof(raw_records) == TYPE_DICTIONARY:
			profile["records"] = _normalize_progress_records(raw_records)
		else:
			profile["records"] = _default_progress_records()
		profiles[profile_id] = profile
	if profiles.is_empty():
		return _default_root_records()
	var current_id: String = String(data.get("current_profile_id", ""))
	if not profiles.has(current_id):
		current_id = String(profiles.keys()[0])
	return {
		"initialized": true,
		"current_profile_id": current_id,
		"profiles": profiles,
	}

static func _migrate_legacy_records(data: Dictionary) -> Dictionary:
	return {
		"initialized": true,
		"current_profile_id": DEFAULT_PROFILE_ID,
		"profiles": {
			DEFAULT_PROFILE_ID: {
				"name": DEFAULT_PROFILE_NAME,
				"records": _normalize_progress_records(data),
			},
		},
	}

static func _normalize_progress_records(data: Dictionary) -> Dictionary:
	var records: Dictionary = _default_progress_records()
	records["best_score"] = int(data.get("best_score", 0))
	records["total_stars"] = maxi(int(data.get("total_stars", STARTING_STARS)), 0)
	records["earned_stars"] = maxi(int(data.get("earned_stars", 0)), 0)
	records["spent_stars"] = maxi(int(data.get("spent_stars", 0)), 0)
	records["games_played"] = maxi(int(data.get("games_played", 0)), 0)
	records["levels"] = _get_levels_record(data)
	return records

static func _get_profiles(data: Dictionary) -> Dictionary:
	var raw_profiles: Variant = data.get("profiles", {})
	if typeof(raw_profiles) == TYPE_DICTIONARY:
		return raw_profiles
	return {}

static func _make_profile_id(_display_name: String, profiles: Dictionary) -> String:
	var suffix: int = profiles.size() + 1
	var unique_id: String = "player_%d" % suffix
	while profiles.has(unique_id):
		suffix += 1
		unique_id = "player_%d" % suffix
	return unique_id

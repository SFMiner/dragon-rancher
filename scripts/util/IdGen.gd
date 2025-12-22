# IdGen.gd
# ID and name generation utility
# Part of Dragon Ranch - Session 3 Dragon Entities & Lifecycle
#
# Generates unique IDs for dragons, eggs, and other entities
# Provides random name selection from name database

extends Node

## Path to dragon names JSON
const DRAGON_NAMES_PATH: String = "res://data/config/names_dragons.json"

## Counter for generating unique IDs
var _id_counter: int = 0

## List of dragon names loaded from JSON
var _dragon_names: Array[String] = []

## Recently used names (to avoid duplicates in same session)
var _used_names: Dictionary = {}

## Whether names have been loaded
var _names_loaded: bool = false


func _ready() -> void:
	load_dragon_names()


## Load dragon names from JSON file
func load_dragon_names() -> bool:
	if _names_loaded:
		return true

	if not FileAccess.file_exists(DRAGON_NAMES_PATH):
		push_warning("[IdGen] Dragon names file not found: %s" % DRAGON_NAMES_PATH)
		# Use fallback names
		_dragon_names = _get_fallback_names()
		_names_loaded = true
		return false

	var file: FileAccess = FileAccess.open(DRAGON_NAMES_PATH, FileAccess.READ)
	if file == null:
		push_error("[IdGen] Failed to open dragon names file")
		_dragon_names = _get_fallback_names()
		_names_loaded = true
		return false

	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_text)

	if parse_result != OK:
		push_error("[IdGen] Failed to parse names JSON: %s" % json.get_error_message())
		_dragon_names = _get_fallback_names()
		_names_loaded = true
		return false

	var data = json.data
	if data is Dictionary and data.has("names"):
		var names: Array = data["names"]
		for dragon_name in names:
			if dragon_name is String:
				_dragon_names.append(dragon_name)
	elif data is Array:
		# Support direct array format
		for dragon_name in data:
			if dragon_name is String:
				_dragon_names.append(dragon_name)

	if _dragon_names.is_empty():
		push_warning("[IdGen] No names loaded, using fallback")
		_dragon_names = _get_fallback_names()

	_names_loaded = true
	print("[IdGen] Loaded %d dragon names" % _dragon_names.size())
	return true


## Generate a unique dragon ID
## Format: "dragon_<timestamp>_<counter>"
func generate_dragon_id() -> String:
	_id_counter += 1
	var timestamp: int = int(Time.get_unix_time_from_system())
	return "dragon_%d_%d" % [timestamp, _id_counter]


## Generate a unique egg ID
## Format: "egg_<timestamp>_<counter>"
func generate_egg_id() -> String:
	_id_counter += 1
	var timestamp: int = int(Time.get_unix_time_from_system())
	return "egg_%d_%d" % [timestamp, _id_counter]


## Generate a unique facility ID
## Format: "facility_<timestamp>_<counter>"
func generate_facility_id() -> String:
	_id_counter += 1
	var timestamp: int = int(Time.get_unix_time_from_system())
	return "facility_%d_%d" % [timestamp, _id_counter]


## Generate a unique order ID
## Format: "order_<timestamp>_<counter>"
func generate_order_id() -> String:
	_id_counter += 1
	var timestamp: int = int(Time.get_unix_time_from_system())
	return "order_%d_%d" % [timestamp, _id_counter]


## Get a random dragon name
## Tries to avoid recently used names if possible
func generate_random_name() -> String:
	if _dragon_names.is_empty():
		return "Dragon_%d" % _id_counter

	# Try to find unused name (up to 10 attempts)
	var candidate: String = ""
	for i in range(10):
		candidate = RNGService.choice(_dragon_names)
		if not _used_names.has(candidate):
			_used_names[candidate] = true
			return candidate

	# If all names used or can't find unused, just pick random
	candidate = RNGService.choice(_dragon_names)
	return candidate


## Get a random name with prefix (for themed naming)
## Example: get_random_name_with_prefix("Fire") -> "Ember", "Blaze", etc.
func get_random_name_with_theme(_theme: String) -> String:
	# For now, just return random name
	# Future: implement themed name filtering
	return generate_random_name()


## Clear recently used names (call when starting new game)
func clear_used_names() -> void:
	_used_names.clear()


## Get total number of available names
func get_name_count() -> int:
	return _dragon_names.size()


## Check if a specific name exists in the database
func has_name(dragon_name: String) -> bool:
	return dragon_name in _dragon_names


## Add a custom name to the pool (for mods/user content)
func add_custom_name(dragon_name: String) -> void:
	if dragon_name.is_empty() or dragon_name in _dragon_names:
		return
	_dragon_names.append(dragon_name)


## Get fallback names if JSON fails to load
func _get_fallback_names() -> Array[String]:
	return [
		"Ember", "Blaze", "Ash", "Cinder", "Smoke",
		"Flame", "Spark", "Scorch", "Char", "Soot",
		"Skyfire", "Cloudwing", "Stormscale", "Thunderclaw", "Windwhisper",
		"Ruby", "Onyx", "Pearl", "Jade", "Topaz",
		"Shadow", "Eclipse", "Midnight", "Twilight", "Dawn",
		"Fang", "Talon", "Spike", "Claw", "Scale",
		"Nova", "Comet", "Star", "Luna", "Sol",
		"Drake", "Wyrm", "Wyvern", "Serpent", "Draco",
		"Crimson", "Azure", "Verdant", "Golden", "Silver",
		"Thunder", "Lightning", "Storm", "Tempest", "Gale"
	]


## Reload names from file (for development/modding)
func reload_names() -> bool:
	_names_loaded = false
	_dragon_names.clear()
	return load_dragon_names()


## Serialization for save system
func to_dict() -> Dictionary:
	return {
		"id_counter": _id_counter,
		"used_names": _used_names.duplicate()
	}


## Deserialization for load system
func from_dict(data: Dictionary) -> void:
	_id_counter = data.get("id_counter", 0)
	_used_names = data.get("used_names", {}).duplicate()

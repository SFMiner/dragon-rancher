# SaveSystem.gd
# Save/load system with versioning and validation
# Part of Dragon Ranch - Session 5 Save System

extends Node

## Save file version
const SAVE_VERSION: int = 1

## Save file paths
const SAVE_PATH: String = "user://savegame_v1.json"
const BACKUP_PATH: String = "user://savegame_v1.bak.json"

## Signals
signal save_complete(success: bool)
signal load_complete(success: bool)

## Autosave timer
var _autosave_timer: Timer = null
var _autosave_enabled: bool = false


# === SERIALIZATION ===

func _serialize_dragon(dragon: DragonData) -> Dictionary:
	if dragon == null:
		return {}
	return dragon.to_dict()


func _deserialize_dragon(data: Dictionary) -> DragonData:
	var dragon := DragonData.new()
	dragon.from_dict(data)
	if not dragon.is_valid():
		push_error("[SaveSystem] Invalid dragon data")
		return null
	return dragon


func _serialize_egg(egg: EggData) -> Dictionary:
	if egg == null:
		return {}
	return egg.to_dict()


func _deserialize_egg(data: Dictionary) -> EggData:
	var egg := EggData.new()
	egg.from_dict(data)
	if not egg.is_valid():
		push_error("[SaveSystem] Invalid egg data")
		return null
	return egg


# === SAVE GAME ===

func save_game() -> bool:
	print("[SaveSystem] Saving game...")

	# Gather all state
	var save_data: Dictionary = {
		"save_version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"current_season": RanchState.current_season,
		"money": RanchState.money,
		"reputation": RanchState.reputation,
		"food_supply": RanchState.food_supply,
		"dragons": {},
		"eggs": {},
		"facilities": RanchState.facilities.duplicate(true),
		"active_orders": RanchState.active_orders.duplicate(true),
		"rng_seed": RNGService.get_seed()
	}

	# Serialize dragons
	for dragon_id in RanchState.dragons.keys():
		save_data["dragons"][dragon_id] = _serialize_dragon(RanchState.dragons[dragon_id])

	# Serialize eggs
	for egg_id in RanchState.eggs.keys():
		save_data["eggs"][egg_id] = _serialize_egg(RanchState.eggs[egg_id])

	# Convert to JSON
	var json_string: String = JSON.stringify(save_data, "\t")

	# Backup existing save
	if FileAccess.file_exists(SAVE_PATH):
		var backup_result: Error = DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
		if backup_result != OK:
			push_warning("[SaveSystem] Failed to create backup: %d" % backup_result)

	# Write to file
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveSystem] Failed to open save file for writing")
		save_complete.emit(false)
		return false

	file.store_string(json_string)
	file.close()

	# Verify write succeeded
	if not FileAccess.file_exists(SAVE_PATH):
		push_error("[SaveSystem] Save file not created")
		save_complete.emit(false)
		return false

	print("[SaveSystem] Game saved successfully to %s" % SAVE_PATH)
	save_complete.emit(true)
	return true


# === LOAD GAME ===

func load_game() -> bool:
	print("[SaveSystem] Loading game...")

	# Check if save exists
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveSystem] No save file found")
		load_complete.emit(false)
		return false

	# Read file
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("[SaveSystem] Failed to open save file")
		return _try_load_backup()

	var json_string: String = file.get_as_text()
	file.close()

	# Parse JSON
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(json_string)

	if parse_result != OK:
		push_error("[SaveSystem] Failed to parse save file: %s" % json.get_error_message())
		return _try_load_backup()

	var save_data: Dictionary = json.data

	# Validate version
	if not save_data.has("save_version"):
		push_error("[SaveSystem] Save file missing version")
		return _try_load_backup()

	var file_version: int = save_data["save_version"]
	if file_version != SAVE_VERSION:
		print("[SaveSystem] Save version mismatch: %d (expected %d)" % [file_version, SAVE_VERSION])
		save_data = _migrate_save(save_data, file_version, SAVE_VERSION)
		if save_data.is_empty():
			return _try_load_backup()

	# Load into RanchState
	if not RanchState.load_state(save_data):
		push_error("[SaveSystem] Failed to load state")
		return _try_load_backup()

	print("[SaveSystem] Game loaded successfully")
	load_complete.emit(true)
	return true


func _try_load_backup() -> bool:
	print("[SaveSystem] Attempting to load backup...")

	if not FileAccess.file_exists(BACKUP_PATH):
		push_error("[SaveSystem] No backup file found")
		load_complete.emit(false)
		return false

	var file: FileAccess = FileAccess.open(BACKUP_PATH, FileAccess.READ)
	if file == null:
		push_error("[SaveSystem] Failed to open backup file")
		load_complete.emit(false)
		return false

	var json_string: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(json_string) != OK:
		push_error("[SaveSystem] Backup file also corrupted")
		load_complete.emit(false)
		return false

	var save_data: Dictionary = json.data

	if RanchState.load_state(save_data):
		print("[SaveSystem] Loaded from backup successfully")
		load_complete.emit(true)
		return true

	load_complete.emit(false)
	return false


# === MIGRATION ===

func _migrate_save(data: Dictionary, from_version: int, to_version: int) -> Dictionary:
	print("[SaveSystem] Migrating save from version %d to %d" % [from_version, to_version])

	# For now, just validate basic structure
	if not _validate_save_structure(data):
		push_error("[SaveSystem] Save structure validation failed")
		return {}

	# Future: Add migration paths for specific versions
	# if from_version == 1 and to_version == 2:
	#     data = _migrate_v1_to_v2(data)

	return data


func _validate_save_structure(data: Dictionary) -> bool:
	# Check required keys
	var required_keys: Array[String] = ["current_season", "money", "dragons", "eggs"]

	for key in required_keys:
		if not data.has(key):
			push_warning("[SaveSystem] Missing required key: %s" % key)
			return false

	# Validate dragons
	if not data["dragons"] is Dictionary:
		push_warning("[SaveSystem] Dragons data is not a dictionary")
		return false

	# Validate eggs
	if not data["eggs"] is Dictionary:
		push_warning("[SaveSystem] Eggs data is not a dictionary")
		return false

	return true


# === AUTOSAVE ===

func enable_autosave(interval_seconds: float = 300.0) -> void:
	if _autosave_timer == null:
		_autosave_timer = Timer.new()
		_autosave_timer.timeout.connect(_on_autosave_timer_timeout)
		add_child(_autosave_timer)

	_autosave_timer.wait_time = interval_seconds
	_autosave_timer.start()
	_autosave_enabled = true

	print("[SaveSystem] Autosave enabled (every %.0f seconds)" % interval_seconds)


func disable_autosave() -> void:
	if _autosave_timer:
		_autosave_timer.stop()

	_autosave_enabled = false
	print("[SaveSystem] Autosave disabled")


func _on_autosave_timer_timeout() -> void:
	if _autosave_enabled:
		print("[SaveSystem] Autosaving...")
		save_game()


# === MANUAL TRIGGERS ===

## Trigger save at key moments
func trigger_autosave_if_enabled() -> void:
	if _autosave_enabled:
		save_game()


# === UTILITY ===

func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		var result: Error = DirAccess.remove_absolute(SAVE_PATH)
		if result == OK:
			print("[SaveSystem] Save file deleted")
			return true
		else:
			push_error("[SaveSystem] Failed to delete save: %d" % result)
			return false
	return true

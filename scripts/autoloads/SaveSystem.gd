# SaveSystem.gd
# Save/load system with multiple slots, versioning, and validation
# Part of Dragon Ranch - Session 14 Save/Load System

extends Node

## Current save format version
const SAVE_VERSION: String = "1.0"

## Save directory
const SAVE_DIR: String = "user://saves/"

## Auto-save slot (special slot)
const AUTOSAVE_SLOT: int = -1

## Signals
signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_failed(slot: int, error: String)
signal load_failed(slot: int, error: String)

## Auto-save settings
var autosave_enabled: bool = true
var autosave_interval_seasons: int = 5
var _seasons_since_autosave: int = 0


func _ready() -> void:
	# Ensure save directory exists
	_ensure_save_directory()

	# Connect to RanchState for auto-save triggers
	if RanchState:
		RanchState.season_changed.connect(_on_season_changed)
		RanchState.order_completed.connect(_on_order_completed)

	print("[SaveSystem] Initialized - Save directory: ", SAVE_DIR)


## Ensure save directory exists
func _ensure_save_directory() -> void:
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		var err = dir.make_dir("saves")
		if err != OK:
			push_error("[SaveSystem] Failed to create saves directory: " + str(err))


## Get save file path for a slot
func _get_save_path(slot: int) -> String:
	if slot == AUTOSAVE_SLOT:
		return SAVE_DIR + "autosave.json"
	else:
		return SAVE_DIR + "save_%d.json" % slot


## Get backup path for a slot
func _get_backup_path(slot: int) -> String:
	return _get_save_path(slot) + ".bak"


## Save game to specific slot
func save_game(slot: int = 0) -> bool:
	print("[SaveSystem] Saving game to slot %d..." % slot)

	# Create SaveData from current game state
	var save_data = SaveData.new()
	save_data.version = SAVE_VERSION
	save_data.timestamp = Time.get_unix_time_from_system()

	# Gather state from RanchState
	if RanchState and RanchState.has_method("save_state"):
		var ranch_state_data = RanchState.save_state()

		save_data.season = ranch_state_data.get("season", 1)
		save_data.money = ranch_state_data.get("money", 500)
		save_data.food = ranch_state_data.get("food", 100)
		save_data.reputation = ranch_state_data.get("reputation", 0)
		save_data.dragons = ranch_state_data.get("dragons", [])
		save_data.eggs = ranch_state_data.get("eggs", [])
		save_data.facilities = ranch_state_data.get("facilities", [])
		save_data.active_orders = ranch_state_data.get("active_orders", [])
		save_data.completed_orders = ranch_state_data.get("completed_orders", [])
		save_data.unlocked_traits = ranch_state_data.get("unlocked_traits", [])
	else:
		push_error("[SaveSystem] RanchState.save_state() not available")
		save_failed.emit(slot, "RanchState not ready")
		return false

	# Get tutorial state
	if TutorialService and TutorialService.has_method("save_state"):
		save_data.tutorial_state = TutorialService.save_state()

	# Get RNG state
	if RNGService and RNGService.has_method("get_seed"):
		save_data.rng_state = RNGService.get_seed()

	# Convert to JSON
	var json_string = JSON.stringify(save_data.to_dict(), "\t")

	# Backup existing save
	var save_path = _get_save_path(slot)
	if FileAccess.file_exists(save_path):
		var backup_path = _get_backup_path(slot)
		DirAccess.copy_absolute(save_path, backup_path)

	# Write to file
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		var err_msg = "Failed to open file for writing: " + save_path
		push_error("[SaveSystem] " + err_msg)
		save_failed.emit(slot, err_msg)
		return false

	file.store_string(json_string)
	file.close()

	# Verify write
	if not FileAccess.file_exists(save_path):
		var err_msg = "Save file not created after write"
		push_error("[SaveSystem] " + err_msg)
		save_failed.emit(slot, err_msg)
		return false

	print("[SaveSystem] Game saved successfully to slot %d" % slot)
	save_completed.emit(slot)
	return true


## Load game from specific slot
func load_game(slot: int = 0) -> bool:
	print("[SaveSystem] Loading game from slot %d..." % slot)

	var save_path = _get_save_path(slot)

	# Check if save exists
	if not FileAccess.file_exists(save_path):
		var err_msg = "Save file not found: " + save_path
		print("[SaveSystem] " + err_msg)
		load_failed.emit(slot, err_msg)
		return false

	# Read file
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		var err_msg = "Failed to open save file"
		push_error("[SaveSystem] " + err_msg)
		# Try backup
		return _try_load_backup(slot)

	var json_string = file.get_as_text()
	file.close()

	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		var err_msg = "Failed to parse JSON: " + json.get_error_message()
		push_error("[SaveSystem] " + err_msg)
		# Try backup
		return _try_load_backup(slot)

	var data = json.data
	if not data is Dictionary:
		var err_msg = "JSON root is not a dictionary"
		push_error("[SaveSystem] " + err_msg)
		return _try_load_backup(slot)

	# Create SaveData from dictionary
	var save_data = SaveData.from_dict(data)

	# Check version
	if save_data.version != SAVE_VERSION:
		print("[SaveSystem] Version mismatch: %s (expected %s)" % [save_data.version, SAVE_VERSION])
		# Attempt migration
		save_data = _migrate_save_data(save_data)
		if save_data == null:
			return _try_load_backup(slot)

	# Load into RanchState
	if RanchState and RanchState.has_method("load_state"):
		var ranch_state_data = {
			"season": save_data.season,
			"money": save_data.money,
			"food": save_data.food,
			"reputation": save_data.reputation,
			"dragons": save_data.dragons,
			"eggs": save_data.eggs,
			"facilities": save_data.facilities,
			"active_orders": save_data.active_orders,
			"completed_orders": save_data.completed_orders,
			"unlocked_traits": save_data.unlocked_traits
		}

		if not RanchState.load_state(ranch_state_data):
			var err_msg = "RanchState.load_state() failed"
			push_error("[SaveSystem] " + err_msg)
			load_failed.emit(slot, err_msg)
			return false
	else:
		var err_msg = "RanchState.load_state() not available"
		push_error("[SaveSystem] " + err_msg)
		load_failed.emit(slot, err_msg)
		return false

	# Load tutorial state
	if TutorialService and TutorialService.has_method("load_state"):
		TutorialService.load_state(save_data.tutorial_state)

	# Load RNG state
	if RNGService and RNGService.has_method("set_seed"):
		RNGService.set_seed(save_data.rng_state)

	print("[SaveSystem] Game loaded successfully from slot %d" % slot)
	load_completed.emit(slot)
	_seasons_since_autosave = 0
	return true


## Try to load from backup
func _try_load_backup(slot: int) -> bool:
	print("[SaveSystem] Attempting to load backup for slot %d..." % slot)

	var backup_path = _get_backup_path(slot)

	if not FileAccess.file_exists(backup_path):
		var err_msg = "No backup file found"
		push_error("[SaveSystem] " + err_msg)
		load_failed.emit(slot, err_msg)
		return false

	# Copy backup to main save and try again
	var save_path = _get_save_path(slot)
	DirAccess.copy_absolute(backup_path, save_path)

	var err_msg = "Loaded from backup"
	print("[SaveSystem] " + err_msg)
	return load_game(slot)


## Delete save file
func delete_save(slot: int) -> bool:
	var save_path = _get_save_path(slot)

	if not FileAccess.file_exists(save_path):
		return true  # Already deleted

	var result = DirAccess.remove_absolute(save_path)
	if result == OK:
		# Also delete backup
		var backup_path = _get_backup_path(slot)
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_path)

		print("[SaveSystem] Deleted save slot %d" % slot)
		return true
	else:
		push_error("[SaveSystem] Failed to delete save slot %d: %d" % [slot, result])
		return false


## Check if save exists
func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_get_save_path(slot))


## Get save info for display
func get_save_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {"exists": false, "slot": slot}

	var save_path = _get_save_path(slot)
	var file = FileAccess.open(save_path, FileAccess.READ)

	if file == null:
		return {"exists": false, "slot": slot, "error": "Failed to open"}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {"exists": false, "slot": slot, "error": "Corrupted"}

	var data = json.data
	if not data is Dictionary:
		return {"exists": false, "slot": slot, "error": "Invalid format"}

	var save_data = SaveData.from_dict(data)
	var info = save_data.get_summary()
	info["exists"] = true
	info["slot"] = slot

	return info


## List all saves
func list_saves() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []

	# Check slots 0-9
	for slot in range(10):
		saves.append(get_save_info(slot))

	# Check autosave
	if has_save(AUTOSAVE_SLOT):
		saves.append(get_save_info(AUTOSAVE_SLOT))

	return saves


## Migrate save data between versions
func _migrate_save_data(save_data: SaveData) -> SaveData:
	print("[SaveSystem] Migrating save data from version %s to %s" % [save_data.version, SAVE_VERSION])

	# Future: Add version-specific migrations here
	# For now, just update version and hope for the best
	save_data.version = SAVE_VERSION

	return save_data


## Auto-save on season change
func _on_season_changed(_season: int) -> void:
	if not autosave_enabled:
		return

	_seasons_since_autosave += 1

	if _seasons_since_autosave >= autosave_interval_seasons:
		print("[SaveSystem] Auto-saving...")
		save_game(AUTOSAVE_SLOT)
		_seasons_since_autosave = 0


## Auto-save on order completion
func _on_order_completed(_order_id: String, _payment: int) -> void:
	if autosave_enabled:
		print("[SaveSystem] Auto-saving after order completion...")
		save_game(AUTOSAVE_SLOT)

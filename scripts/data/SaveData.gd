## Save data structure
## Contains all game state that needs to be persisted
class_name SaveData
extends Resource

## Save format version (for migration)
@export var version: String = "1.0"

## Save timestamp (Unix time)
@export var timestamp: int = 0

## Game state
@export var season: int = 1
@export var money: int = 500
@export var food: int = 100
@export var reputation: int = 0

## Entity collections (serialized as dictionaries)
@export var dragons: Array[Dictionary] = []
@export var eggs: Array[Dictionary] = []
@export var facilities: Array[Dictionary] = []

## Orders
@export var active_orders: Array[Dictionary] = []
@export var completed_orders: Array[Dictionary] = []

## Tutorial state
@export var tutorial_state: Dictionary = {}

## RNG state for reproducibility
@export var rng_state: int = 0

## Unlocked features
@export var unlocked_traits: Array[String] = []


## Serialize to dictionary for JSON export
func to_dict() -> Dictionary:
	return {
		"version": version,
		"timestamp": timestamp,
		"season": season,
		"money": money,
		"food": food,
		"reputation": reputation,
		"dragons": dragons,
		"eggs": eggs,
		"facilities": facilities,
		"active_orders": active_orders,
		"completed_orders": completed_orders,
		"tutorial_state": tutorial_state,
		"rng_state": rng_state,
		"unlocked_traits": unlocked_traits
	}


## Create from dictionary (for JSON import)
static func from_dict(data: Dictionary) -> SaveData:
	var save_data = SaveData.new()

	save_data.version = data.get("version", "1.0")
	save_data.timestamp = data.get("timestamp", 0)
	save_data.season = data.get("season", 1)
	save_data.money = data.get("money", 500)
	save_data.food = data.get("food", 100)
	save_data.reputation = data.get("reputation", 0)

	# Entity collections - handle missing or invalid data
	save_data.dragons = _safe_get_array(data, "dragons")
	save_data.eggs = _safe_get_array(data, "eggs")
	save_data.facilities = _safe_get_array(data, "facilities")
	save_data.active_orders = _safe_get_array(data, "active_orders")
	save_data.completed_orders = _safe_get_array(data, "completed_orders")

	save_data.tutorial_state = data.get("tutorial_state", {})
	save_data.rng_state = data.get("rng_state", 0)

	# Unlocked traits
	var traits_data = data.get("unlocked_traits", [])
	if traits_data is Array:
		for gene_trait in traits_data:
			if gene_trait is String:
				save_data.unlocked_traits.append(gene_trait)

	return save_data


## Safely get array from dictionary, handling missing/invalid data
static func _safe_get_array(data: Dictionary, key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	if not data.has(key):
		return result

	var value = data[key]
	if not value is Array:
		push_warning("SaveData: Expected array for key '" + key + "', got " + str(typeof(value)))
		return result

	# Convert to Array[Dictionary]
	for item in value:
		if item is Dictionary:
			result.append(item)
		else:
			push_warning("SaveData: Skipping non-dictionary item in " + key)

	return result


## Get formatted timestamp string
func get_formatted_timestamp() -> String:
	var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
	return "%04d-%02d-%02d %02d:%02d" % [
		datetime.year,
		datetime.month,
		datetime.day,
		datetime.hour,
		datetime.minute
	]


## Get summary info for save slot display
func get_summary() -> Dictionary:
	return {
		"version": version,
		"timestamp": timestamp,
		"formatted_time": get_formatted_timestamp(),
		"season": season,
		"money": money,
		"dragon_count": dragons.size(),
		"egg_count": eggs.size(),
		"reputation": reputation
	}

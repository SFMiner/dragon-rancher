# facility_data.gd
# Resource class for facility data storage and serialization
# Part of Dragon Ranch - Session 1 Architecture
#
# INTERFACE LOCKED - See docs/API_Reference.md

extends Resource
class_name FacilityData

## Facility type constants
const TYPE_STABLE: String = "stable"
const TYPE_PASTURE: String = "pasture"
const TYPE_BREEDING_PEN: String = "breeding_pen"
const TYPE_NURSERY: String = "nursery"
const TYPE_GENETICS_LAB: String = "genetics_lab"
const TYPE_LUXURY_HABITAT: String = "luxury_habitat"
const TYPE_TRAINING_GROUNDS: String = "training_grounds"
const TYPE_MEDICAL_BAY: String = "medical_bay"
const TYPE_FOOD_SILO: String = "food_silo"

## Unique identifier for this facility instance
@export var id: String = ""

## Facility type (see constants above)
@export var type: String = ""

## Display name (can be customized by player)
@export var name: String = ""

## Number of dragon slots this facility provides
@export var capacity: int = 0

## Bonuses provided by this facility
## Keys: "happiness", "growth_speed", "health_regen", "training_speed", etc.
## Values: float multipliers or flat bonuses
@export var bonuses: Dictionary = {}

## Purchase cost (for reference, actual cost from config)
@export var cost: int = 0

## Minimum reputation level to build
@export var reputation_required: int = 0

## Season when facility was built
@export var built_season: int = 0

## Position on ranch grid (for visual placement)
@export var grid_position: Vector2i = Vector2i.ZERO

## Whether this facility is operational
@export var is_active: bool = true


# === SERIALIZATION ===

func to_dict() -> Dictionary:
	"""Serialize facility data to JSON-compatible dictionary."""
	return {
		"id": id,
		"type": type,
		"name": name,
		"capacity": capacity,
		"bonuses": bonuses.duplicate(true),
		"cost": cost,
		"reputation_required": reputation_required,
		"built_season": built_season,
		"grid_position": {"x": grid_position.x, "y": grid_position.y},
		"is_active": is_active
	}


func from_dict(data: Dictionary) -> void:
	"""Deserialize facility data from dictionary."""
	id = data.get("id", "")
	type = data.get("type", "")
	name = data.get("name", "")
	capacity = data.get("capacity", 0)
	bonuses = data.get("bonuses", {}).duplicate(true)
	cost = data.get("cost", 0)
	reputation_required = data.get("reputation_required", 0)
	built_season = data.get("built_season", 0)
	
	var pos_data: Dictionary = data.get("grid_position", {})
	grid_position = Vector2i(pos_data.get("x", 0), pos_data.get("y", 0))
	
	is_active = data.get("is_active", true)


# === VALIDATION ===

func is_valid() -> bool:
	"""Validate that all required fields are present and correct."""
	if id.is_empty():
		push_warning("FacilityData.is_valid: id is empty")
		return false
	
	var valid_types := [
		TYPE_STABLE, TYPE_PASTURE, TYPE_BREEDING_PEN, TYPE_NURSERY,
		TYPE_GENETICS_LAB, TYPE_LUXURY_HABITAT, TYPE_TRAINING_GROUNDS,
		TYPE_MEDICAL_BAY, TYPE_FOOD_SILO
	]
	
	if type not in valid_types:
		push_warning("FacilityData.is_valid: invalid type '%s'" % type)
		return false
	
	if capacity < 0:
		push_warning("FacilityData.is_valid: capacity cannot be negative")
		return false
	
	return true


# === HELPER METHODS ===

func get_bonus(bonus_type: String) -> float:
	"""Get a specific bonus value, defaulting to 0.0."""
	return bonuses.get(bonus_type, 0.0)


func has_bonus(bonus_type: String) -> bool:
	"""Check if this facility provides a specific bonus."""
	return bonuses.has(bonus_type) and bonuses[bonus_type] != 0.0


func get_type_display() -> String:
	"""Get human-readable facility type name."""
	match type:
		TYPE_STABLE:
			return "Stable"
		TYPE_PASTURE:
			return "Pasture"
		TYPE_BREEDING_PEN:
			return "Breeding Pen"
		TYPE_NURSERY:
			return "Nursery"
		TYPE_GENETICS_LAB:
			return "Genetics Lab"
		TYPE_LUXURY_HABITAT:
			return "Luxury Habitat"
		TYPE_TRAINING_GROUNDS:
			return "Training Grounds"
		TYPE_MEDICAL_BAY:
			return "Medical Bay"
		TYPE_FOOD_SILO:
			return "Food Silo"
		_:
			return "Unknown"


func get_description() -> String:
	"""Get facility description for UI."""
	match type:
		TYPE_STABLE:
			return "Basic housing for %d dragons." % capacity
		TYPE_PASTURE:
			return "Outdoor space for %d dragons." % capacity
		TYPE_BREEDING_PEN:
			return "Required for breeding. Holds 1 breeding pair."
		TYPE_NURSERY:
			return "Houses %d hatchlings with faster growth." % capacity
		TYPE_GENETICS_LAB:
			return "Reveals hidden genotypes. Unlocks Punnett square."
		TYPE_LUXURY_HABITAT:
			return "Premium housing with +%.0f%% happiness bonus." % (get_bonus("happiness") * 100)
		TYPE_TRAINING_GROUNDS:
			return "Train dragons for contests and battles."
		TYPE_MEDICAL_BAY:
			return "Heals sick dragons faster."
		TYPE_FOOD_SILO:
			return "Stores bulk food at reduced cost."
		_:
			return "Unknown facility type."


func provides_breeding() -> bool:
	"""Check if this facility enables breeding."""
	return type == TYPE_BREEDING_PEN


func provides_genotype_reveal() -> bool:
	"""Check if this facility reveals hidden genotypes."""
	return type == TYPE_GENETICS_LAB


func duplicate_data() -> FacilityData:
	"""Create a deep copy of this facility data."""
	var copy := FacilityData.new()
	copy.from_dict(to_dict())
	return copy

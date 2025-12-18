# order_data.gd
# Resource class for customer order data storage and serialization
# Part of Dragon Ranch - Session 1 Architecture
#
# INTERFACE LOCKED - See docs/API_Reference.md

extends Resource
class_name OrderData

## Order type constants
const TYPE_SIMPLE: String = "simple"           # Single trait requirement
const TYPE_COMPLEX: String = "complex"         # Multiple trait requirements
const TYPE_EXACT: String = "exact_genotype"    # Specific genotype required
const TYPE_RENTAL: String = "rental"           # Dragon returns after period
const TYPE_BREEDING: String = "breeding"       # Use customer's dragon for breeding

## Unique identifier for this order
@export var id: String = ""

## Order type (see constants above)
@export var type: String = TYPE_SIMPLE

## Human-readable description of what customer wants
@export var description: String = ""

## Required traits dictionary: trait_key -> requirement_pattern
## Patterns:
##   "F_" = at least one dominant allele (F)
##   "FF" = exact homozygous genotype
##   "fire" = phenotype name match
@export var required_traits: Dictionary = {}

## Base payment amount (before multipliers)
@export var payment: int = 100

## Seasons until order expires (countdown from acceptance)
@export var deadline_seasons: int = 3

## Minimum reputation level to see this order
@export var reputation_required: int = 0

## Season when order was accepted (0 = not yet accepted)
@export var accepted_season: int = 0

## Season when order was created (for display)
@export var created_season: int = 0

## Whether this order is urgent (higher pay, shorter deadline)
@export var is_urgent: bool = false

## Customer name for flavor (optional)
@export var customer_name: String = ""


# === SERIALIZATION ===

func to_dict() -> Dictionary:
	"""Serialize order data to JSON-compatible dictionary."""
	return {
		"id": id,
		"type": type,
		"description": description,
		"required_traits": required_traits.duplicate(true),
		"payment": payment,
		"deadline_seasons": deadline_seasons,
		"reputation_required": reputation_required,
		"accepted_season": accepted_season,
		"created_season": created_season,
		"is_urgent": is_urgent,
		"customer_name": customer_name
	}


func from_dict(data: Dictionary) -> void:
	"""Deserialize order data from dictionary."""
	id = data.get("id", "")
	type = data.get("type", TYPE_SIMPLE)
	description = data.get("description", "")
	required_traits = data.get("required_traits", {}).duplicate(true)
	payment = data.get("payment", 100)
	deadline_seasons = data.get("deadline_seasons", 3)
	reputation_required = data.get("reputation_required", 0)
	accepted_season = data.get("accepted_season", 0)
	created_season = data.get("created_season", 0)
	is_urgent = data.get("is_urgent", false)
	customer_name = data.get("customer_name", "")


# === VALIDATION ===

func is_valid() -> bool:
	"""Validate that all required fields are present and correct."""
	if id.is_empty():
		push_warning("OrderData.is_valid: id is empty")
		return false
	
	if type not in [TYPE_SIMPLE, TYPE_COMPLEX, TYPE_EXACT, TYPE_RENTAL, TYPE_BREEDING]:
		push_warning("OrderData.is_valid: invalid type '%s'" % type)
		return false
	
	if description.is_empty():
		push_warning("OrderData.is_valid: description is empty")
		return false
	
	if required_traits.is_empty():
		push_warning("OrderData.is_valid: required_traits is empty")
		return false
	
	if payment <= 0:
		push_warning("OrderData.is_valid: payment must be positive")
		return false
	
	if deadline_seasons <= 0:
		push_warning("OrderData.is_valid: deadline_seasons must be positive")
		return false
	
	return true


# === HELPER METHODS ===

func is_accepted() -> bool:
	"""Check if this order has been accepted."""
	return accepted_season > 0


func is_expired(current_season: int) -> bool:
	"""Check if this order has expired based on current season."""
	if not is_accepted():
		return false
	return current_season >= (accepted_season + deadline_seasons)


func get_seasons_remaining(current_season: int) -> int:
	"""Get number of seasons remaining until deadline."""
	if not is_accepted():
		return deadline_seasons
	return max(0, (accepted_season + deadline_seasons) - current_season)


func get_deadline_season() -> int:
	"""Get the season when this order expires."""
	if not is_accepted():
		return 0
	return accepted_season + deadline_seasons


func get_requirement_display() -> String:
	"""Get human-readable requirement string for UI."""
	var parts: Array[String] = []
	for trait_key in required_traits.keys():
		var req: String = required_traits[trait_key]
		parts.append("%s: %s" % [trait_key.capitalize(), req])
	return ", ".join(parts)


func get_type_display() -> String:
	"""Get human-readable order type."""
	match type:
		TYPE_SIMPLE:
			return "Simple Order"
		TYPE_COMPLEX:
			return "Complex Order"
		TYPE_EXACT:
			return "Exact Genotype"
		TYPE_RENTAL:
			return "Rental Contract"
		TYPE_BREEDING:
			return "Breeding Contract"
		_:
			return "Unknown"


func duplicate_data() -> OrderData:
	"""Create a deep copy of this order data."""
	var copy := OrderData.new()
	copy.from_dict(to_dict())
	return copy

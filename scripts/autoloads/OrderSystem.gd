# OrderSystem.gd
# Order generation and management
# Part of Dragon Ranch - Session 6 Order System

extends Node

## Path to order templates
const ORDER_TEMPLATES_PATH: String = "res://data/config/order_templates.json"
const RENTAL_TEMPLATES_PATH: String = "res://data/config/rental_templates.json"

## Loaded templates
var _templates: Array = []
var _rental_templates: Array = []

## Whether templates are loaded
var _loaded: bool = false
var _rentals_loaded: bool = false

## Signals
signal orders_generated(orders: Array)


func _ready() -> void:
	load_templates()
	load_rental_templates()


## Load order templates from JSON
func load_templates() -> bool:
	if _loaded:
		return true

	if not FileAccess.file_exists(ORDER_TEMPLATES_PATH):
		push_error("[OrderSystem] Templates file not found: %s" % ORDER_TEMPLATES_PATH)
		return false

	var file: FileAccess = FileAccess.open(ORDER_TEMPLATES_PATH, FileAccess.READ)
	if file == null:
		push_error("[OrderSystem] Failed to open templates file")
		return false

	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(json_text) != OK:
		push_error("[OrderSystem] Failed to parse templates JSON")
		return false

	var data: Dictionary = json.data
	_templates = data.get("templates", [])

	_loaded = true
	print("[OrderSystem] Loaded %d order templates" % _templates.size())
	return true


## Load rental templates from JSON
func load_rental_templates() -> bool:
	if _rentals_loaded:
		return true

	if not FileAccess.file_exists(RENTAL_TEMPLATES_PATH):
		push_error("[OrderSystem] Rental templates file not found: %s" % RENTAL_TEMPLATES_PATH)
		return false

	var file: FileAccess = FileAccess.open(RENTAL_TEMPLATES_PATH, FileAccess.READ)
	if file == null:
		push_error("[OrderSystem] Failed to open rental templates file")
		return false

	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(json_text) != OK:
		push_error("[OrderSystem] Failed to parse rental templates JSON")
		return false

	var data: Dictionary = json.data
	_rental_templates = data.get("templates", [])

	_rentals_loaded = true
	print("[OrderSystem] Loaded %d rental templates" % _rental_templates.size())
	return true


## Generate orders based on reputation level
func generate_orders(reputation_level: int) -> Array:
	if not _loaded:
		push_error("[OrderSystem] Templates not loaded")
		return []

	# Determine number of orders (3-5)
	var order_count: int = RNGService.randi_range(3, 5)

	# Filter templates by reputation
	var available_templates: Array = []
	for template in _templates:
		if template.get("reputation_required", 0) <= reputation_level:
			available_templates.append(template)

	if available_templates.is_empty():
		push_warning("[OrderSystem] No templates available for reputation %d" % reputation_level)
		return []

	# Generate orders
	var orders: Array = []
	for i in range(order_count):
		var template: Dictionary = RNGService.choice(available_templates)
		var order: OrderData = _create_order_from_template(template)
		orders.append(order)

	# Ensure variety: 60% simple, 30% complex, 10% special
	# For now, just random selection is fine

	orders_generated.emit(orders)
	return orders


## Generate rental contracts based on reputation level
func generate_rentals(reputation_level: int) -> Array:
	if not _rentals_loaded:
		push_error("[OrderSystem] Rental templates not loaded")
		return []

	# Determine number of rentals (2-4)
	var rental_count: int = RNGService.randi_range(2, 4)

	# Filter templates by reputation
	var available_templates: Array = []
	for template in _rental_templates:
		if template.get("reputation_required", 0) <= reputation_level:
			available_templates.append(template)

	if available_templates.is_empty():
		push_warning("[OrderSystem] No rental templates available for reputation %d" % reputation_level)
		return []

	# Generate rentals
	var rentals: Array = []
	for i in range(rental_count):
		var template: Dictionary = RNGService.choice(available_templates)
		var rental: OrderData = _create_rental_from_template(template)
		rentals.append(rental)

	return rentals


## Create an order from a template
func _create_order_from_template(template: Dictionary) -> OrderData:
	var order := OrderData.new()

	order.id = IdGen.generate_order_id()
	order.type = template.get("type", "simple")
	order.description = template.get("description", "Dragon needed")
	order.required_traits = template.get("required_traits", {}).duplicate(true)

	# Randomize payment within range
	var payment_min: int = template.get("payment_min", 100)
	var payment_max: int = template.get("payment_max", 150)
	order.payment = RNGService.randi_range(payment_min, payment_max)

	# Randomize deadline
	var deadline_min: int = template.get("deadline_min", 2)
	var deadline_max: int = template.get("deadline_max", 5)
	order.deadline_seasons = RNGService.randi_range(deadline_min, deadline_max)

	order.reputation_required = template.get("reputation_required", 0)
	order.created_season = RanchState.current_season
	order.is_urgent = template.get("id", "").contains("urgent")

	return order


## Create a rental contract from a template
func _create_rental_from_template(template: Dictionary) -> OrderData:
	var rental := OrderData.new()

	rental.id = IdGen.generate_order_id()
	rental.type = OrderData.TYPE_RENTAL
	rental.description = template.get("description", "Dragon job needed")
	rental.required_traits = template.get("required_traits", {}).duplicate(true)

	# Randomize base payment within range (purchase price basis)
	var payment_min: int = template.get("payment_min", 100)
	var payment_max: int = template.get("payment_max", 150)
	rental.payment = RNGService.randi_range(payment_min, payment_max)

	# Rental duration (1-4 seasons)
	var duration_min: int = template.get("duration_min", 1)
	var duration_max: int = template.get("duration_max", 4)
	rental.deadline_seasons = RNGService.randi_range(duration_min, duration_max)

	rental.reputation_required = template.get("reputation_required", 0)
	rental.created_season = RanchState.current_season
	return rental

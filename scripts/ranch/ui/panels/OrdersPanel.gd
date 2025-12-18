# OrdersPanel.gd
# Order board UI controller
# Part of Dragon Ranch - Session 10 UI Logic & Interactivity

extends PanelContainer

@onready var order_list_container = $VBoxContainer/ScrollContainer/OrderListContainer

## Currently selected order for fulfillment
var selected_order: OrderData = null


func _ready():
	# Connect to RanchState signals if they exist
	if RanchState.has_signal("order_completed"):
		RanchState.order_completed.connect(_on_order_completed)

	# Display active orders
	refresh_display()

	# Initially hide
	hide()


## Open the panel
func open_panel() -> void:
	refresh_display()
	show()


## Close the panel
func close_panel() -> void:
	hide()


## Refresh the order display
func refresh_display() -> void:
	_display_orders(RanchState.active_orders)


## Display list of orders
func _display_orders(orders: Array) -> void:
	# Clear existing UI
	for child in order_list_container.get_children():
		child.queue_free()

	if orders.is_empty():
		var no_orders_label := Label.new()
		no_orders_label.text = "No active orders available"
		order_list_container.add_child(no_orders_label)
		return

	# Create UI for each order
	for order in orders:
		if not order is OrderData:
			continue

		# Order container
		var order_box := VBoxContainer.new()
		order_box.add_theme_constant_override("separation", 4)

		# Order description
		var desc_label := Label.new()
		desc_label.text = order.description
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		order_box.add_child(desc_label)

		# Requirements
		var req_label := Label.new()
		req_label.text = "Requirements: " + _format_requirements(order)
		req_label.add_theme_font_size_override("font_size", 12)
		order_box.add_child(req_label)

		# Payment and deadline
		var info_label := Label.new()
		info_label.text = "Payment: $%d | Deadline: %d seasons" % [order.payment, order.deadline_seasons - (RanchState.current_season - order.accepted_season)]
		info_label.add_theme_font_size_override("font_size", 12)
		order_box.add_child(info_label)

		# Buttons
		var button_box := HBoxContainer.new()

		var details_button := Button.new()
		details_button.text = "View Details"
		details_button.pressed.connect(_on_view_details_pressed.bind(order))
		button_box.add_child(details_button)

		var fulfill_button := Button.new()
		fulfill_button.text = "Fulfill Order"
		fulfill_button.pressed.connect(_on_fulfill_order_pressed.bind(order))
		button_box.add_child(fulfill_button)

		order_box.add_child(button_box)

		# Separator
		var separator := HSeparator.new()

		order_list_container.add_child(order_box)
		order_list_container.add_child(separator)


## Format order requirements for display
func _format_requirements(order: OrderData) -> String:
	var parts: Array[String] = []

	for trait_key in order.required_traits.keys():
		var requirement: String = order.required_traits[trait_key]
		parts.append("%s: %s" % [trait_key.capitalize(), requirement])

	return ", ".join(parts) if parts.size() > 0 else "Any dragon"


## View details button pressed
func _on_view_details_pressed(order: OrderData) -> void:
	selected_order = order

	# Show detailed order requirements and matching dragons
	var matching_dragons: Array[DragonData] = _get_matching_dragons(order)

	var message: String = "Order: %s\n\n" % order.description
	message += "Requirements:\n"
	for trait_key in order.required_traits.keys():
		message += "  %s: %s\n" % [trait_key.capitalize(), order.required_traits[trait_key]]
	message += "\nPayment: $%d\n" % order.payment
	message += "\nMatching Dragons: %d\n" % matching_dragons.size()

	if matching_dragons.size() > 0:
		message += "\nDragons that match:\n"
		for dragon in matching_dragons:
			message += "  - %s (Age: %d, %s)\n" % [dragon.name, dragon.age, dragon.life_stage]

	_show_notification(message)


## Fulfill order button pressed
func _on_fulfill_order_pressed(order: OrderData) -> void:
	selected_order = order

	# Get matching dragons
	var matching_dragons: Array[DragonData] = _get_matching_dragons(order)

	if matching_dragons.is_empty():
		_show_notification("No dragons match this order!")
		return

	# For now, auto-select first matching dragon
	# TODO: Show dragon selection dialog
	var dragon: DragonData = matching_dragons[0]

	# Attempt to fulfill
	var success: bool = RanchState.fulfill_order(order.id, dragon.id)

	if success:
		var payment: int = Pricing.calculate_order_payment(order, dragon, RanchState.reputation)
		_show_notification("Order fulfilled! Earned $%d" % payment)
		refresh_display()
	else:
		_show_notification("Failed to fulfill order!")


## Get dragons that match order requirements
func _get_matching_dragons(order: OrderData) -> Array[DragonData]:
	var matching: Array[DragonData] = []

	for dragon in RanchState.dragons.values():
		if OrderMatching.does_dragon_match(dragon, order):
			matching.append(dragon)

	return matching


## Refresh orders button pressed
func _on_refresh_button_pressed() -> void:
	var refresh_cost: int = 50

	if not RanchState.spend_money(refresh_cost):
		_show_notification("Not enough money! Refresh costs $%d" % refresh_cost)
		return

	# Generate new orders
	var new_orders: Array = OrderSystem.generate_orders(RanchState.reputation)

	# Replace active orders
	RanchState.active_orders = new_orders

	refresh_display()
	_show_notification("Orders refreshed!")


## Order completed callback
func _on_order_completed(order_id: String, payment: int) -> void:
	refresh_display()


## Show notification message
func _show_notification(message: String) -> void:
	var notifications_panel = get_tree().root.find_child("NotificationsPanel", true, false)
	if notifications_panel and notifications_panel.has_method("show_notification"):
		notifications_panel.show_notification(message)
	else:
		print("[OrdersPanel] Notification: " + message)

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


func _on_close_button_pressed() -> void:
	close_panel()


## Open the panel
func open_panel() -> void:
	refresh_display()
	show()
	AudioManager.play_sfx("ui_confirm.ogg")


## Close the panel
func close_panel() -> void:
	hide()
	
## View details button pressed
func _on_view_details_pressed(order: OrderData) -> void:
	AudioManager.play_sfx("ui_click.ogg")
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
	AudioManager.play_sfx("ui_click.ogg")
	selected_order = order

	# Get matching dragons
	var matching_dragons: Array[DragonData] = _get_matching_dragons(order)

	if matching_dragons.is_empty():
		_show_notification("No dragons match this order!", true)
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
		_show_notification("Failed to fulfill order!", true)
		
## Refresh orders button pressed
func _on_refresh_button_pressed() -> void:
	AudioManager.play_sfx("ui_click.ogg")
	var refresh_cost: int = 50

	if not RanchState.spend_money(refresh_cost):
		_show_notification("Not enough money! Refresh costs $%d" % refresh_cost, true)
		return

	# Generate new orders
	var new_orders: Array = OrderSystem.generate_orders(RanchState.reputation)

	# Replace active orders
	RanchState.active_orders = new_orders

	refresh_display()
	_show_notification("Orders refreshed!")


## Order completed callback
func _on_order_completed(_order_id: String, _payment: int) -> void:
	refresh_display()


## Refresh the display of orders
func refresh_display() -> void:
	# Clear existing order cards
	for child in order_list_container.get_children():
		child.queue_free()

	# Check if OrderSystem is available
	if not OrderSystem:
		push_warning("[OrdersPanel] OrderSystem not found")
		return

	# Get active orders from RanchState
	var active_orders: Array = RanchState.active_orders

	if active_orders.is_empty():
		var no_orders_label := Label.new()
		no_orders_label.text = "No orders available. Generate new orders!"
		order_list_container.add_child(no_orders_label)
		return

	# Display each order
	for order in active_orders:
		if not order is OrderData:
			continue

		# Create order card
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 5)

		# Title
		var title_label := Label.new()
		title_label.text = order.description
		title_label.add_theme_font_size_override("font_size", 14)
		card.add_child(title_label)

		# Payment
		var payment_label := Label.new()
		payment_label.text = "Payment: $" + str(order.payment)
		card.add_child(payment_label)

		# Buttons
		var button_container := HBoxContainer.new()
		button_container.add_theme_constant_override("separation", 10)

		var view_button := Button.new()
		view_button.text = "View Details"
		view_button.pressed.connect(_on_view_details_pressed.bind(order))
		button_container.add_child(view_button)

		var fulfill_button := Button.new()
		fulfill_button.text = "Fulfill Order"
		fulfill_button.pressed.connect(_on_fulfill_order_pressed.bind(order))
		button_container.add_child(fulfill_button)

		card.add_child(button_container)

		# Separator
		var separator := HSeparator.new()
		card.add_child(separator)

		order_list_container.add_child(card)

	print("[OrdersPanel] Displayed %d orders" % active_orders.size())


## Get dragons that match an order's requirements
func _get_matching_dragons(order: OrderData) -> Array[DragonData]:
	var matching_dragons: Array[DragonData] = []

	# Get all adult dragons
	var adult_dragons: Array[DragonData] = RanchState.get_adult_dragons()

	# Check each dragon
	for dragon in adult_dragons:
		if _dragon_matches_order(dragon, order):
			matching_dragons.append(dragon)

	return matching_dragons


## Check if a dragon matches an order's requirements
func _dragon_matches_order(dragon: DragonData, order: OrderData) -> bool:
	# Reuse shared order-matching logic (handles genotype, allele wildcards, phenotype names)
	return OrderMatching.does_dragon_match(dragon, order)


## Show notification message
func _show_notification(message: String, is_error: bool = false) -> void:
	if is_error:
		AudioManager.play_sfx("ui_error.ogg")
	var notifications_panel = get_tree().root.find_child("NotificationsPanel", true, false)
	if notifications_panel and notifications_panel.has_method("show_notification"):
		notifications_panel.show_notification(message)
	else:
		print("[OrdersPanel] Notification: " + message)

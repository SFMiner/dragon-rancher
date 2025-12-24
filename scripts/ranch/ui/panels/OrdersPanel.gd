# OrdersPanel.gd
# Order board UI controller
# Part of Dragon Ranch - Session 10 UI Logic & Interactivity

extends PanelContainer

@onready var tab_container = $VBoxContainer/TabContainer
@onready var order_list_container = $VBoxContainer/TabContainer/OrdersTab/ScrollContainer/OrderListContainer
@onready var job_list_container = $VBoxContainer/TabContainer/JobsTab/ScrollContainer/JobListContainer

## Currently selected order for fulfillment
var selected_order: OrderData = null
var preferred_dragon_id: String = ""


func _ready():
	# Connect to RanchState signals if they exist
	if RanchState.has_signal("order_completed"):
		RanchState.order_completed.connect(_on_order_completed)
	if RanchState.has_signal("rental_started"):
		RanchState.rental_started.connect(_on_rental_changed)
	if RanchState.has_signal("rental_completed"):
		RanchState.rental_completed.connect(_on_rental_changed)

	# Display active orders
	refresh_display()

	# Initially hide
	hide()


func _on_close_button_pressed() -> void:
	close_panel()


## Open the panel
func open_panel() -> void:
	preferred_dragon_id = ""
	refresh_display()
	tab_container.current_tab = 0
	show()
	AudioManager.play_sfx("ui_confirm.ogg")


func open_panel_with_dragon(dragon: DragonData) -> void:
	if dragon == null:
		open_panel()
		return
	preferred_dragon_id = dragon.id
	refresh_display()
	tab_container.current_tab = 0
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


## View details button pressed (jobs)
func _on_view_job_details_pressed(rental: OrderData) -> void:
	AudioManager.play_sfx("ui_click.ogg")
	selected_order = rental

	var matching_dragons: Array[DragonData] = _get_matching_dragons(rental)

	var message: String = "Job: %s\n\n" % rental.description
	message += "Requirements:\n"
	for trait_key in rental.required_traits.keys():
		message += "  %s: %s\n" % [trait_key.capitalize(), rental.required_traits[trait_key]]
	message += "\nContract: %d season(s)\n" % rental.deadline_seasons
	message += "Estimated payment per season: $%d\n" % Pricing.calculate_rental_payment_from_base(rental.payment)
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

	var dragon: DragonData = null
	if not preferred_dragon_id.is_empty():
		dragon = RanchState.get_dragon(preferred_dragon_id)
		if dragon == null:
			_show_notification("Selected dragon not found.", true)
			return
		if RanchState.is_dragon_rented(dragon.id):
			_show_notification("Selected dragon is currently on a job.", true)
			return
		if not _dragon_matches_order(dragon, order):
			_show_notification("Selected dragon does not match this order.", true)
			return
	else:
		# Get matching dragons
		var matching_dragons: Array[DragonData] = _get_matching_dragons(order)

		if matching_dragons.is_empty():
			_show_notification("No dragons match this order!", true)
			return

		# For now, auto-select first matching dragon
		# TODO: Show dragon selection dialog
		dragon = matching_dragons[0]

	# Attempt to fulfill
	var success: bool = RanchState.fulfill_order(order.id, dragon.id)

	if success:
		var payment: int = Pricing.calculate_order_payment(order, dragon, RanchState.reputation)
		_show_notification("Order fulfilled! Earned $%d" % payment)
		refresh_display()
	else:
		_show_notification("Failed to fulfill order!", true)


## Start job button pressed
func _on_start_job_pressed(rental: OrderData) -> void:
	AudioManager.play_sfx("ui_click.ogg")
	selected_order = rental

	var dragon: DragonData = null
	if not preferred_dragon_id.is_empty():
		dragon = RanchState.get_dragon(preferred_dragon_id)
		if dragon == null:
			_show_notification("Selected dragon not found.", true)
			return
		if RanchState.is_dragon_rented(dragon.id):
			_show_notification("Selected dragon is already on a job.", true)
			return
		if not _dragon_matches_order(dragon, rental):
			_show_notification("Selected dragon does not match this job.", true)
			return
	else:
		var matching_dragons: Array[DragonData] = _get_matching_dragons(rental)
		if matching_dragons.is_empty():
			_show_notification("No dragons match this job!", true)
			return
		dragon = matching_dragons[0]

	var success: bool = RanchState.start_rental(rental.id, dragon.id)
	if success:
		_show_notification("Job started! %s is out on contract." % dragon.name)
		refresh_jobs_display()
	else:
		_show_notification("Failed to start job!", true)

## Refresh orders button pressed
func _on_refresh_orders_button_pressed() -> void:
	AudioManager.play_sfx("ui_click.ogg")
	var refresh_cost: int = 50

	if not RanchState.spend_money(refresh_cost):
		_show_notification("Not enough money! Refresh costs $%d" % refresh_cost, true)
		return

	# Generate new orders
	var new_orders: Array = OrderSystem.generate_orders(RanchState.reputation)

	# Replace active orders safely to satisfy typed array
	RanchState.replace_active_orders(new_orders)

	refresh_orders_display()
	_show_notification("Orders refreshed!")

## Refresh jobs button pressed
func _on_refresh_jobs_button_pressed() -> void:
	AudioManager.play_sfx("ui_click.ogg")
	var refresh_cost: int = 50

	if not RanchState.spend_money(refresh_cost):
		_show_notification("Not enough money! Refresh costs $%d" % refresh_cost, true)
		return

	# Generate new rentals
	var new_rentals: Array = OrderSystem.generate_rentals(RanchState.reputation)

	# Replace available rentals safely to satisfy typed array
	RanchState.replace_available_rentals(new_rentals)

	refresh_jobs_display()
	_show_notification("Jobs refreshed!")


## Order completed callback
func _on_order_completed(_order_id: String, _payment: int) -> void:
	refresh_display()


func _on_rental_changed(_rental_id: String, _dragon_id: String) -> void:
	refresh_jobs_display()


## Refresh the display of orders
func refresh_display() -> void:
	refresh_orders_display()
	refresh_jobs_display()


## Refresh the display of orders
func refresh_orders_display() -> void:
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


## Refresh the display of jobs
func refresh_jobs_display() -> void:
	# Clear existing job cards
	for child in job_list_container.get_children():
		child.queue_free()

	# Check if OrderSystem is available
	if not OrderSystem:
		push_warning("[OrdersPanel] OrderSystem not found")
		return

	var any_jobs: bool = false

	# Display active rentals
	if not RanchState.active_rentals.is_empty():
		var active_label := Label.new()
		active_label.text = "Active Jobs"
		active_label.add_theme_font_size_override("font_size", 14)
		job_list_container.add_child(active_label)

		for rental in RanchState.active_rentals:
			if not rental is OrderData:
				continue
			any_jobs = true
			_add_job_card(rental, true)

		var separator := HSeparator.new()
		job_list_container.add_child(separator)

	# Display available rentals
	var available_rentals: Array = RanchState.available_rentals
	if available_rentals.is_empty():
		if not any_jobs:
			var no_jobs_label := Label.new()
			no_jobs_label.text = "No jobs available. Generate new jobs!"
			job_list_container.add_child(no_jobs_label)
		return

	var available_label := Label.new()
	available_label.text = "Available Jobs"
	available_label.add_theme_font_size_override("font_size", 14)
	job_list_container.add_child(available_label)

	for rental in available_rentals:
		if not rental is OrderData:
			continue
		_add_job_card(rental, false)


func _add_job_card(rental: OrderData, is_active: bool) -> void:
	var card := VBoxContainer.new()
	card.add_theme_constant_override("separation", 5)

	var title_label := Label.new()
	title_label.text = rental.description
	title_label.add_theme_font_size_override("font_size", 14)
	card.add_child(title_label)

	var duration_label := Label.new()
	duration_label.text = "Contract: %d season(s)" % rental.deadline_seasons
	card.add_child(duration_label)

	var payment_text: String = ""
	if is_active:
		payment_text = "Payment per season: $" + str(rental.payment_per_season)
	else:
		var estimated: int = Pricing.calculate_rental_payment_from_base(rental.payment)
		payment_text = "Estimated payment per season: $" + str(estimated)
	var payment_label := Label.new()
	payment_label.text = payment_text
	card.add_child(payment_label)

	if is_active:
		var remaining := _get_rental_seasons_remaining(rental)
		var status_label := Label.new()
		status_label.text = "Remaining seasons: %d" % remaining
		card.add_child(status_label)
	else:
		var button_container := HBoxContainer.new()
		button_container.add_theme_constant_override("separation", 10)

		var view_button := Button.new()
		view_button.text = "View Details"
		view_button.pressed.connect(_on_view_job_details_pressed.bind(rental))
		button_container.add_child(view_button)

		var start_button := Button.new()
		start_button.text = "Start Job"
		start_button.pressed.connect(_on_start_job_pressed.bind(rental))
		button_container.add_child(start_button)

		card.add_child(button_container)

	var separator := HSeparator.new()
	card.add_child(separator)

	job_list_container.add_child(card)


func _get_rental_seasons_remaining(rental: OrderData) -> int:
	var start_season: int = rental.accepted_season + 1
	var end_season: int = rental.accepted_season + rental.deadline_seasons

	if RanchState.current_season < start_season:
		return max(0, end_season - start_season + 1)

	return max(0, end_season - RanchState.current_season + 1)


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

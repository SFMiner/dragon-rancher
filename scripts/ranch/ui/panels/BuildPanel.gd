# BuildPanel.gd
# Facility building UI controller
# Part of Dragon Ranch - Session 10 UI Logic & Interactivity

extends PanelContainer

## Node references
@onready var facility_list_container: VBoxContainer = $VBoxContainer/ScrollContainer/FacilityListContainer

## Facility definitions (loaded from JSON)
var facility_defs: Array = []


func _ready() -> void:
	# Load facility definitions
	_load_facility_definitions()

	# Display facilities
	_display_facilities()

	# Connect to RanchState signals
	if RanchState.has_signal("facility_built"):
		RanchState.facility_built.connect(_on_facility_built)
	if RanchState.has_signal("money_changed"):
		RanchState.money_changed.connect(_on_money_changed)

	# Initially hide
	hide()


## Load facility definitions from JSON
func _load_facility_definitions() -> void:
	var file_path: String = "res://data/config/facility_defs.json"

	if not FileAccess.file_exists(file_path):
		push_error("[BuildPanel] Facility definitions file not found: " + file_path)
		return

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[BuildPanel] Failed to open facility definitions file")
		return

	var json_string: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)

	if error != OK:
		push_error("[BuildPanel] Failed to parse facility definitions JSON: " + json.get_error_message())
		return

	var data: Dictionary = json.data
	facility_defs = data.get("facilities", [])

	print("[BuildPanel] Loaded %d facility definitions" % facility_defs.size())


## Open the panel
func open_panel() -> void:
	_display_facilities()
	show()


## Close the panel
func close_panel() -> void:
	hide()


## Display facility list
func _display_facilities() -> void:
	# Clear existing UI
	for child in facility_list_container.get_children():
		child.queue_free()

	if facility_defs.is_empty():
		var error_label := Label.new()
		error_label.text = "No facilities available"
		facility_list_container.add_child(error_label)
		return

	# Create UI for each facility
	for facility_def in facility_defs:
		var facility_box := VBoxContainer.new()
		facility_box.add_theme_constant_override("separation", 4)

		# Facility name
		var name_label := Label.new()
		name_label.text = facility_def.get("name", "Unknown Facility")
		name_label.add_theme_font_size_override("font_size", 16)
		facility_box.add_child(name_label)

		# Description
		var desc_label := Label.new()
		desc_label.text = facility_def.get("description", "")
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_font_size_override("font_size", 12)
		facility_box.add_child(desc_label)

		# Stats
		var stats_label := Label.new()
		var stats_text: String = ""

		if facility_def.get("capacity", 0) > 0:
			stats_text += "Capacity: +%d dragons | " % facility_def["capacity"]

		stats_text += "Cost: $%d" % facility_def.get("cost", 0)

		var reputation_required: int = facility_def.get("reputation_required", 0)
		if reputation_required > 0:
			stats_text += " | Reputation: Level %d" % reputation_required

		stats_label.text = stats_text
		stats_label.add_theme_font_size_override("font_size", 12)
		facility_box.add_child(stats_label)

		# Bonuses
		var bonuses: Dictionary = facility_def.get("bonuses", {})
		if not bonuses.is_empty():
			var bonus_label := Label.new()
			var bonus_text: String = "Bonuses: "
			var bonus_parts: Array[String] = []

			for bonus_type in bonuses.keys():
				var bonus_value = bonuses[bonus_type]
				bonus_parts.append("%s: %s" % [bonus_type.capitalize(), str(bonus_value)])

			bonus_label.text = bonus_text + ", ".join(bonus_parts)
			bonus_label.add_theme_font_size_override("font_size", 12)
			bonus_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
			facility_box.add_child(bonus_label)

		# Build button
		var build_button := Button.new()
		build_button.text = "Build"

		var facility_type: String = facility_def.get("type", "")
		build_button.pressed.connect(_on_build_pressed.bind(facility_type))

		# Check if can afford and has reputation
		var cost: int = facility_def.get("cost", 0)
		var can_afford: bool = RanchState.money >= cost
		var has_reputation: bool = RanchState.reputation >= reputation_required

		if not can_afford:
			build_button.disabled = true
			build_button.text = "Build (Not enough money)"
		elif not has_reputation:
			build_button.disabled = true
			build_button.text = "Build (Reputation too low)"
		else:
			build_button.disabled = false

		facility_box.add_child(build_button)

		# Separator
		var separator := HSeparator.new()

		facility_list_container.add_child(facility_box)
		facility_list_container.add_child(separator)


## Build button pressed
func _on_build_pressed(facility_type: String) -> void:
	var success: bool = RanchState.build_facility(facility_type)

	if success:
		_show_notification("Facility built successfully!")
		_display_facilities()  # Refresh display
	else:
		_show_notification("Failed to build facility. Check if you have enough money.")


## Facility built callback
func _on_facility_built(facility_id: String) -> void:
	# Refresh display to update button states
	_display_facilities()


## Money changed callback
func _on_money_changed(new_amount: int) -> void:
	# Refresh display to update button states
	_display_facilities()


## Show notification message
func _show_notification(message: String) -> void:
	var notifications_panel = get_tree().root.find_child("NotificationsPanel", true, false)
	if notifications_panel and notifications_panel.has_method("show_notification"):
		notifications_panel.show_notification(message)
	else:
		print("[BuildPanel] Notification: " + message)

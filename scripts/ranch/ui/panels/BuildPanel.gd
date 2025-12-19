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
	AudioManager.play_sfx("ui_confirm.ogg")


## Close the panel
func close_panel() -> void:
	hide()
	
## Build button pressed
func _on_build_pressed(facility_type: String) -> void:
	AudioManager.play_sfx("ui_click.ogg")
	var success: bool = RanchState.build_facility(facility_type)

	if success:
		_show_notification("Facility built successfully!")
		_display_facilities()  # Refresh display
	else:
		_show_notification("Failed to build facility. Check if you have enough money.", true)


## Facility built callback
func _on_facility_built(_facility_id: String) -> void:
	# Refresh display to update button states
	_display_facilities()


## Money changed callback
func _on_money_changed(_new_amount: int) -> void:
	# Refresh display to update button states
	_display_facilities()


## Display facilities list
func _display_facilities() -> void:
	# Clear existing facility buttons
	for child in facility_list_container.get_children():
		child.queue_free()

	# Display each facility definition
	for facility_def in facility_defs:
		if not facility_def is Dictionary:
			continue

		var facility_type: String = facility_def.get("type", "unknown")
		var facility_name: String = facility_def.get("name", "Unknown")
		var facility_cost: int = facility_def.get("cost", 0)
		var facility_desc: String = facility_def.get("description", "")

		# Create facility card
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 5)

		# Title label
		var title_label := Label.new()
		title_label.text = facility_name + " - $" + str(facility_cost)
		title_label.add_theme_font_size_override("font_size", 16)
		card.add_child(title_label)

		# Description label
		var desc_label := Label.new()
		desc_label.text = facility_desc
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc_label.custom_minimum_size = Vector2(300, 0)
		card.add_child(desc_label)

		# Build button
		var build_button := Button.new()
		build_button.text = "Build"
		build_button.disabled = RanchState.money < facility_cost
		build_button.pressed.connect(_on_build_pressed.bind(facility_type))
		card.add_child(build_button)

		# Separator
		var separator := HSeparator.new()
		card.add_child(separator)

		facility_list_container.add_child(card)

	print("[BuildPanel] Displayed %d facilities" % facility_defs.size())


## Show notification message
func _show_notification(message: String, is_error: bool = false) -> void:
	if is_error:
		AudioManager.play_sfx("ui_error.ogg")
	var notifications_panel = get_tree().root.find_child("NotificationsPanel", true, false)
	if notifications_panel and notifications_panel.has_method("show_notification"):
		notifications_panel.show_notification(message)
	else:
		print("[BuildPanel] Notification: " + message)


func _on_close_button_pressed() -> void:
	close_panel()

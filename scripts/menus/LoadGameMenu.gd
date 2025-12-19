# LoadGameMenu.gd
# UI for loading and managing save files
# Part of Dragon Ranch - Session 14 Save/Load System

extends Control

## Signals
signal back_pressed()
signal game_loaded(slot: int)

## Node references
@onready var save_slots_container = $MarginContainer/VBoxContainer/ScrollContainer/SaveSlotsContainer
@onready var back_button = $MarginContainer/VBoxContainer/BottomButtons/BackButton
@onready var confirm_dialog = $ConfirmDialog

## Current slot pending deletion
var _pending_delete_slot: int = -999


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	confirm_dialog.confirmed.connect(_on_delete_confirmed)

	# Refresh save list
	refresh_save_list()


## Refresh the list of save slots
func refresh_save_list() -> void:
	# Clear existing slots
	for child in save_slots_container.get_children():
		child.queue_free()

	# Get all saves (slots 0-9 + autosave)
	var saves = SaveSystem.list_saves()

	# Add autosave first if it exists
	for save_info in saves:
		if save_info.get("slot") == SaveSystem.AUTOSAVE_SLOT and save_info.get("exists", false):
			_create_save_slot_card(save_info)
			break

	# Add regular save slots
	for slot in range(10):
		var save_info = SaveSystem.get_save_info(slot)
		_create_save_slot_card(save_info)


## Create a save slot card UI element
func _create_save_slot_card(save_info: Dictionary) -> void:
	var slot: int = save_info.get("slot", 0)
	var exists: bool = save_info.get("exists", false)

	# Create card container
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 80)
	save_slots_container.add_child(card)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	card.add_child(hbox)

	# Left side: Save info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	if exists:
		# Slot name
		var slot_label = Label.new()
		if slot == SaveSystem.AUTOSAVE_SLOT:
			slot_label.text = "Auto-Save"
		else:
			slot_label.text = "Save Slot %d" % slot
		slot_label.add_theme_font_size_override("font_size", 18)
		info_vbox.add_child(slot_label)

		# Save details
		var details_label = Label.new()
		var season = save_info.get("season", 1)
		var money = save_info.get("money", 0)
		var dragon_count = save_info.get("dragon_count", 0)
		var formatted_time = save_info.get("formatted_time", "Unknown")

		details_label.text = "Season %d | %d coins | %d dragons | %s" % [
			season, money, dragon_count, formatted_time
		]
		details_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		info_vbox.add_child(details_label)

		# Version info (if different)
		var version = save_info.get("version", "")
		if version != SaveSystem.SAVE_VERSION:
			var version_label = Label.new()
			version_label.text = "Version: %s (migration may be required)" % version
			version_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
			info_vbox.add_child(version_label)
	else:
		# Empty slot
		var empty_label = Label.new()
		if slot == SaveSystem.AUTOSAVE_SLOT:
			empty_label.text = "Auto-Save (Empty)"
		else:
			empty_label.text = "Save Slot %d (Empty)" % slot
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		info_vbox.add_child(empty_label)

	# Right side: Action buttons
	var button_vbox = VBoxContainer.new()
	button_vbox.add_theme_constant_override("separation", 5)
	hbox.add_child(button_vbox)

	if exists:
		# Load button
		var load_button = Button.new()
		load_button.text = "Load"
		load_button.custom_minimum_size = Vector2(100, 0)
		load_button.pressed.connect(_on_load_pressed.bind(slot))
		button_vbox.add_child(load_button)

		# Delete button (not for auto-save)
		if slot != SaveSystem.AUTOSAVE_SLOT:
			var delete_button = Button.new()
			delete_button.text = "Delete"
			delete_button.custom_minimum_size = Vector2(100, 0)
			delete_button.pressed.connect(_on_delete_pressed.bind(slot))
			button_vbox.add_child(delete_button)
	else:
		# Disabled load button for empty slots
		var load_button = Button.new()
		load_button.text = "Empty"
		load_button.custom_minimum_size = Vector2(100, 0)
		load_button.disabled = true
		button_vbox.add_child(load_button)


## Handle load button pressed
func _on_load_pressed(slot: int) -> void:
	print("[LoadGameMenu] Loading game from slot %d..." % slot)

	# Attempt to load
	if SaveSystem.load_game(slot):
		print("[LoadGameMenu] Game loaded successfully")
		game_loaded.emit(slot)
		# Switch to ranch scene with fade transition
		SceneManager.change_scene("res://scenes/ranch/Ranch.tscn")
	else:
		# Show error popup
		_show_error_dialog("Failed to load save file. The file may be corrupted.")
		# Refresh list in case backup was used
		refresh_save_list()


## Handle delete button pressed
func _on_delete_pressed(slot: int) -> void:
	_pending_delete_slot = slot

	# Show confirmation dialog
	confirm_dialog.dialog_text = "Are you sure you want to delete Save Slot %d? This action cannot be undone." % slot
	confirm_dialog.popup_centered()


## Handle delete confirmation
func _on_delete_confirmed() -> void:
	if _pending_delete_slot >= 0:
		print("[LoadGameMenu] Deleting slot %d" % _pending_delete_slot)
		SaveSystem.delete_save(_pending_delete_slot)
		_pending_delete_slot = -999
		refresh_save_list()


## Handle back button pressed
func _on_back_pressed() -> void:
	back_pressed.emit()


## Show error dialog
func _show_error_dialog(message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Error"
	add_child(dialog)
	dialog.popup_centered()

	# Auto-free after closing
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)

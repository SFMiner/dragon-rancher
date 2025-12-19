# MainMenu.gd
# Main menu with New Game, Continue, Load Game, Settings, Quit
# Part of Dragon Ranch - Session 14 Save/Load System

extends Control

## Node references
@onready var new_game_button = $CenterContainer/VBoxContainer/ButtonContainer/NewGameButton
@onready var continue_button = $CenterContainer/VBoxContainer/ButtonContainer/ContinueButton
@onready var load_game_button = $CenterContainer/VBoxContainer/ButtonContainer/LoadGameButton
@onready var settings_button = $CenterContainer/VBoxContainer/ButtonContainer/SettingsButton
@onready var quit_button = $CenterContainer/VBoxContainer/ButtonContainer/QuitButton
@onready var load_game_menu = $LoadGameMenu
@onready var confirm_dialog = $ConfirmDialog
@onready var main_menu_container = $CenterContainer


func _ready() -> void:
	# Connect button signals
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Connect load game menu signals
	load_game_menu.back_pressed.connect(_on_load_menu_back_pressed)
	load_game_menu.game_loaded.connect(_on_game_loaded)

	# Connect confirm dialog
	confirm_dialog.confirmed.connect(_on_new_game_confirmed)

	# Check if autosave exists
	_update_continue_button()


## Update continue button availability
func _update_continue_button() -> void:
	var has_autosave = SaveSystem.has_save(SaveSystem.AUTOSAVE_SLOT)
	continue_button.disabled = not has_autosave

	if has_autosave:
		var save_info = SaveSystem.get_save_info(SaveSystem.AUTOSAVE_SLOT)
		var season = save_info.get("season", 1)
		continue_button.text = "Continue (Season %d)" % season
	else:
		continue_button.text = "Continue"


## Handle New Game button
func _on_new_game_pressed() -> void:
	# Check if autosave exists
	if SaveSystem.has_save(SaveSystem.AUTOSAVE_SLOT):
		# Warn that it will be overwritten
		confirm_dialog.popup_centered()
	else:
		# No autosave, start immediately
		_start_new_game()


## Handle New Game confirmation
func _on_new_game_confirmed() -> void:
	_start_new_game()


## Start a new game
func _start_new_game() -> void:
	print("[MainMenu] Starting new game...")

	# Reset RanchState to new game state
	if RanchState and RanchState.has_method("start_new_game"):
		RanchState.start_new_game()
	else:
		# Fallback: clear state manually
		RanchState.current_season = 1
		RanchState.money = 500
		RanchState.food_supply = 100
		RanchState.reputation = 0
		RanchState.dragons.clear()
		RanchState.eggs.clear()
		RanchState.facilities.clear()
		RanchState.active_orders.clear()
		RanchState.completed_orders.clear()
		RanchState.unlocked_traits.clear()

	# Reset tutorial
	if TutorialService:
		TutorialService.reset_tutorial()

	# Load ranch scene with fade transition
	SceneManager.change_scene("res://scenes/ranch/Ranch.tscn")


## Handle Continue button
func _on_continue_pressed() -> void:
	print("[MainMenu] Continuing from autosave...")

	# Load autosave
	if SaveSystem.load_game(SaveSystem.AUTOSAVE_SLOT):
		SceneManager.change_scene("res://scenes/ranch/Ranch.tscn")
	else:
		_show_error("Failed to load autosave. Please try loading from a save slot instead.")
		_update_continue_button()


## Handle Load Game button
func _on_load_game_pressed() -> void:
	print("[MainMenu] Opening load game menu...")
	main_menu_container.visible = false
	load_game_menu.visible = true
	load_game_menu.refresh_save_list()


## Handle back from load menu
func _on_load_menu_back_pressed() -> void:
	load_game_menu.visible = false
	main_menu_container.visible = true
	_update_continue_button()


## Handle game loaded from load menu
func _on_game_loaded(slot: int) -> void:
	print("[MainMenu] Game loaded from slot %d" % slot)
	# Scene transition handled by LoadGameMenu


## Handle Settings button
func _on_settings_pressed() -> void:
	print("[MainMenu] Settings not yet implemented")
	_show_info("Settings menu coming soon!")


## Handle Quit button
func _on_quit_pressed() -> void:
	print("[MainMenu] Quitting game...")
	get_tree().quit()


## Show error dialog
func _show_error(message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Error"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)


## Show info dialog
func _show_info(message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Info"
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)

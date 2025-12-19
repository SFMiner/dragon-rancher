# PausePanel.gd
# Pause menu panel with Resume, Settings, and Save & Quit options
# Part of Dragon Ranch - Session 19 Main Menu & Game Flow

extends PanelContainer

## Signals
signal resumed()

## Node references
@onready var settings_panel = get_node_or_null("/root/Ranch/UILayer/SettingsPanel")


func _ready() -> void:
	# Initially hidden
	hide()


## Open the pause panel and pause the game
func open_panel() -> void:
	show()
	# Pause the game tree (but not UI)
	get_tree().paused = true
	print("[PausePanel] Game paused")


## Close the pause panel and resume the game
func close_panel() -> void:
	hide()
	# Resume the game tree
	get_tree().paused = false
	resumed.emit()
	print("[PausePanel] Game resumed")


## Handle Resume button
func _on_resume_button_pressed() -> void:
	AudioManager.play_sfx("ui_click.ogg")
	close_panel()


## Handle Settings button
func _on_settings_button_pressed() -> void:
	AudioManager.play_sfx("ui_click.ogg")
	if settings_panel and settings_panel.has_method("open_panel"):
		settings_panel.open_panel()


## Handle Save and Quit button
func _on_save_and_quit_button_pressed() -> void:
	AudioManager.play_sfx("ui_click.ogg")

	print("[PausePanel] Saving game and returning to main menu...")

	# Save the game to autosave slot
	if SaveSystem.save_game(SaveSystem.AUTOSAVE_SLOT):
		print("[PausePanel] Game saved successfully")
	else:
		push_warning("[PausePanel] Failed to save game")

	# Resume the game tree before changing scene
	get_tree().paused = false

	# Return to main menu with fade transition
	SceneManager.change_scene("res://scenes/menus/MainMenu.tscn")


## Handle ESC key to toggle pause
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC key
		if visible:
			close_panel()
		else:
			open_panel()
		# Consume the event
		get_viewport().set_input_as_handled()

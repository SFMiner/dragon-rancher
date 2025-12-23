extends Control

@onready var money_label = $CanvasLayer/TopBar/HBoxContainer/MoneyLabel
@onready var food_label = $CanvasLayer/TopBar/HBoxContainer/FoodLabel
@onready var season_label = $CanvasLayer/TopBar/HBoxContainer/SeasonLabel
@onready var reputation_label = $CanvasLayer/TopBar/HBoxContainer2/ReputationLabel

## Top bar buttons
@onready var menu_button = get_node_or_null("CanvasLayer/TopBar/HBoxContainer2/MarginContainer/MenuButton")
@onready var settings_button = get_node_or_null("CanvasLayer/TopBar/HBoxContainer2/MarginContainer2/SettingsButton")

## Bottom bar buttons
@onready var orders_button = $CanvasLayer/BottomBar/OrdersButton
@onready var breeding_button = $CanvasLayer/BottomBar/BreedingButton
@onready var build_button = $CanvasLayer/BottomBar/BuildButton
@onready var shop_button = get_node_or_null("CanvasLayer/BottomBar/ShopButton")
@onready var dragons_button = get_node_or_null("CanvasLayer/BottomBar/DragonsButton")
@onready var advance_season_button = $CanvasLayer/BottomBar/AdvanceSeasonButton

## Panel references
@onready var orders_panel = get_node_or_null("/root/Ranch/UILayer/OrdersPanel")
@onready var breeding_panel = get_node_or_null("/root/Ranch/UILayer/BreedingPanel")
@onready var build_panel = get_node_or_null("/root/Ranch/UILayer/BuildPanel")
@onready var shop_panel = get_node_or_null("/root/Ranch/UILayer/ShopPanel")
@onready var dragon_list_panel = get_node_or_null("/root/Ranch/UILayer/DragonListPanel")
@onready var dragon_details_panel = get_node_or_null("/root/Ranch/UILayer/DragonDetailsPanel")
@onready var settings_panel = get_node_or_null("/root/Ranch/UILayer/SettingsPanel")
@onready var pause_panel = get_node_or_null("/root/Ranch/UILayer/PausePanel")

func _ready():
	# Connect RanchState signals
	RanchState.money_changed.connect(_on_money_changed)
	RanchState.food_changed.connect(_on_food_changed)
	RanchState.season_changed.connect(_on_season_changed)
	RanchState.reputation_increased.connect(_on_reputation_changed)

	# Connect button signals (only if not already connected in editor)
	if menu_button and not menu_button.pressed.is_connected(_on_menu_button_pressed):
		menu_button.pressed.connect(_on_menu_button_pressed)
	if settings_button and not settings_button.pressed.is_connected(_on_settings_button_pressed):
		settings_button.pressed.connect(_on_settings_button_pressed)
	if orders_button and not orders_button.pressed.is_connected(_on_orders_button_pressed):
		orders_button.pressed.connect(_on_orders_button_pressed)
	if breeding_button and not breeding_button.pressed.is_connected(_on_breeding_button_pressed):
		breeding_button.pressed.connect(_on_breeding_button_pressed)
	if build_button and not build_button.pressed.is_connected(_on_build_button_pressed):
		build_button.pressed.connect(_on_build_button_pressed)
	if shop_button and not shop_button.pressed.is_connected(_on_shop_button_pressed):
		shop_button.pressed.connect(_on_shop_button_pressed)
	if dragons_button and not dragons_button.pressed.is_connected(_on_dragons_button_pressed):
		dragons_button.pressed.connect(_on_dragons_button_pressed)
	if advance_season_button and not advance_season_button.pressed.is_connected(_on_advance_season_button_pressed):
		advance_season_button.pressed.connect(_on_advance_season_button_pressed)

	# Initialize display
	_on_money_changed(RanchState.money)
	_on_food_changed(RanchState.food_supply)
	_on_season_changed(RanchState.current_season)
	_on_reputation_changed(RanchState.reputation)

	# Register tutorial anchors
	_register_tutorial_anchors()

	print("[HUD] Ready complete - buttons available:")
	print("  - orders_button: ", orders_button)
	print("  - breeding_button: ", breeding_button)
	print("  - build_button: ", build_button)
	print("  - shop_button: ", shop_button)
	print("  - dragons_button: ", dragons_button)
	print("  - advance_season_button: ", advance_season_button)
	if orders_button:
		print("  - orders_button disabled: ", orders_button.disabled)
	if breeding_button:
		print("  - breeding_button disabled: ", breeding_button.disabled)

func _on_money_changed(new_money):
	money_label.text = "$" + str(new_money)

func _on_food_changed(new_food):
	food_label.text = str(new_food) + " (" + str(RanchState.get_food_needs()) + ")"

func _on_season_changed(new_season):
	season_label.text = str(new_season)

func _on_reputation_changed(new_reputation):
	reputation_label.text = str(new_reputation)

func _on_menu_button_pressed():
	print("[HUD] Menu button pressed!")
	AudioManager.play_sfx("ui_click.ogg")
	# Open pause menu
	if pause_panel and pause_panel.has_method("open_panel"):
		pause_panel.open_panel()

func _on_settings_button_pressed():
	print("[HUD] Settings button pressed!")
	AudioManager.play_sfx("ui_click.ogg")
	if settings_panel:
		settings_panel.open_panel()

## Orders button pressed
func _on_orders_button_pressed():
	print("[HUD] Orders button pressed!")
	AudioManager.play_sfx("ui_click.ogg")
	if orders_panel and orders_panel.has_method("open_panel"):
		_close_other_panels(orders_panel)
		orders_panel.open_panel()
		# Emit tutorial event
		if TutorialService:
			TutorialService.process_event("panel_opened", {"panel": "orders"})

## Breeding button pressed
func _on_breeding_button_pressed():
	print("[HUD] Breeding button pressed!")
	AudioManager.play_sfx("ui_click.ogg")
	if breeding_panel and breeding_panel.has_method("open_panel"):
		_close_other_panels(breeding_panel)
		breeding_panel.open_panel()
		# Emit tutorial event
		if TutorialService:
			TutorialService.process_event("panel_opened", {"panel": "breeding"})

## Build button pressed
func _on_build_button_pressed():
	print("[HUD] Build button pressed!")
	AudioManager.play_sfx("ui_click.ogg")
	if build_panel and build_panel.has_method("open_panel"):
		_close_other_panels(build_panel)
		build_panel.open_panel()
		# Emit tutorial event
		if TutorialService:
			TutorialService.process_event("panel_opened", {"panel": "build"})

## Shop button pressed
func _on_shop_button_pressed():
	print("[HUD] Shop button pressed!")
	AudioManager.play_sfx("ui_click.ogg")
	if shop_panel and shop_panel.has_method("open_panel"):
		_close_other_panels(shop_panel)
		shop_panel.open_panel()
		if TutorialService:
			TutorialService.process_event("panel_opened", {"panel": "shop"})

## Dragons button pressed
func _on_dragons_button_pressed():
	print("[HUD] Dragons button pressed!")
	AudioManager.play_sfx("ui_click.ogg")
	if dragon_list_panel and dragon_list_panel.has_method("open_panel"):
		_close_other_panels(dragon_list_panel)
		dragon_list_panel.open_panel()
		if TutorialService:
			TutorialService.process_event("panel_opened", {"panel": "dragon_list"})

## Advance season button pressed
func _on_advance_season_button_pressed():
	print("[HUD] Advance Season button pressed!")
	AudioManager.play_sfx("ui_click.ogg")
	RanchState.advance_season()
	# Emit tutorial event
	if TutorialService:
		TutorialService.process_event("season_advanced", {})

## Register UI elements as tutorial anchors
func _register_tutorial_anchors():
	# Get the TutorialOverlay from the scene tree
	var tutorial_overlay = get_tree().root.find_child("TutorialOverlay", true, false)
	if not tutorial_overlay or not tutorial_overlay.has_method("register_anchor"):
		print("[HUD] TutorialOverlay not found, skipping anchor registration")
		return

	# Register buttons as anchors
	tutorial_overlay.register_anchor("orders_button", orders_button)
	tutorial_overlay.register_anchor("breeding_button", breeding_button)
	tutorial_overlay.register_anchor("build_button", build_button)
	if shop_button:
		tutorial_overlay.register_anchor("shop_button", shop_button)

	# Register panels if they exist
	if dragon_details_panel:
		tutorial_overlay.register_anchor("dragon_details", dragon_details_panel)
	if dragon_list_panel:
		tutorial_overlay.register_anchor("dragon_list", dragon_list_panel)

	print("[HUD] Tutorial anchors registered")


## Close other main panels when opening one to avoid overlap
func _close_other_panels(active_panel: Node):
	var panels = [orders_panel, breeding_panel, build_panel, shop_panel, dragon_list_panel]
	for panel in panels:
		if panel and panel != active_panel:
			if panel.has_method("close_panel"):
				panel.close_panel()
			else:
				panel.hide()


func _on_test_button_1_pressed() -> void:
	print("Test 1 works")


func _on_test_button_2_pressed() -> void:
	print("Test 2 works")

# ShopPanel.gd
# Simple shop UI for buying consumables
# Part of Dragon Ranch - Session UI Panels

extends PanelContainer

const FOOD_PACKS := [
	{"amount": 10, "cost": 10, "label": "Food Pack (10)"},
	{"amount": 50, "cost": 45, "label": "Food Crate (50)"},
	{"amount": 100, "cost": 80, "label": "Food Barrel (100)"}
]

@onready var buy_small_button: Button = $VBoxContainer/ScrollContainer/ItemListContainer/FoodRowSmall/BuyButton
@onready var buy_medium_button: Button = $VBoxContainer/ScrollContainer/ItemListContainer/FoodRowMedium/BuyButton
@onready var buy_large_button: Button = $VBoxContainer/ScrollContainer/ItemListContainer/FoodRowLarge/BuyButton
@onready var close_button: Button = $CloseButton


func _ready() -> void:
	buy_small_button.pressed.connect(_on_buy_small_pressed)
	buy_medium_button.pressed.connect(_on_buy_medium_pressed)
	buy_large_button.pressed.connect(_on_buy_large_pressed)
	hide()


func open_panel() -> void:
	show()
	AudioManager.play_sfx("ui_confirm.ogg")


func close_panel() -> void:
	hide()
	AudioManager.play_sfx("ui_click.ogg")


func _on_buy_small_pressed() -> void:
	_buy_food(FOOD_PACKS[0])


func _on_buy_medium_pressed() -> void:
	_buy_food(FOOD_PACKS[1])


func _on_buy_large_pressed() -> void:
	_buy_food(FOOD_PACKS[2])


func _buy_food(pack: Dictionary) -> void:
	var amount: int = pack.get("amount", 0)
	var cost: int = pack.get("cost", 0)
	if amount <= 0 or cost <= 0:
		push_warning("[ShopPanel] Invalid food pack data")
		return

	if not RanchState.spend_money(cost):
		_show_notification("Not enough money! Need $%d." % cost, true)
		return

	RanchState.add_food(amount)
	_show_notification("Purchased %d food for $%d." % [amount, cost])


func _show_notification(message: String, is_error: bool = false) -> void:
	if is_error:
		AudioManager.play_sfx("ui_error.ogg")
	var notifications_panel = get_tree().root.find_child("NotificationsPanel", true, false)
	if notifications_panel and notifications_panel.has_method("show_notification"):
		notifications_panel.show_notification(message)
	else:
		print("[ShopPanel] Notification: " + message)


func _on_close_button_pressed() -> void:
	close_panel()

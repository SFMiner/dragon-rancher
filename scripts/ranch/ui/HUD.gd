extends Control

@onready var money_label = $CanvasLayer/TopBar/HBoxContainer/MoneyLabel
@onready var food_label = $CanvasLayer/TopBar/HBoxContainer/FoodLabel
@onready var season_label = $CanvasLayer/TopBar/HBoxContainer/SeasonLabel
@onready var reputation_label = $CanvasLayer/TopBar/HBoxContainer2/ReputationLabel

func _ready():
	RanchState.money_changed.connect(_on_money_changed)
	RanchState.food_changed.connect(_on_food_changed)
	RanchState.season_changed.connect(_on_season_changed)
	RanchState.reputation_increased.connect(_on_reputation_changed)

	_on_money_changed(RanchState.money)
	_on_food_changed(RanchState.food)
	_on_season_changed(RanchState.season)
	_on_reputation_changed(RanchState.reputation)

func _on_money_changed(new_money):
	money_label.text = "Money: $" + str(new_money)

func _on_food_changed(new_food):
	food_label.text = "Food: " + str(new_food)

func _on_season_changed(new_season):
	season_label.text = "Season: " + str(new_season)

func _on_reputation_changed(new_reputation):
	reputation_label.text = "Reputation: " + str(new_reputation)

func _on_menu_button_pressed():
	pass # Stub

func _on_settings_button_pressed():
	pass # Stub

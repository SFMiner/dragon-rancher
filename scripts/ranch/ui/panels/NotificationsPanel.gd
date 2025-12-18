extends Control

@onready var vbox_container = $CanvasLayer/VBoxContainer

func _ready():
	RanchState.order_completed.connect(_on_order_completed)
	RanchState.dragon_added.connect(_on_dragon_added)
	RanchState.reputation_increased.connect(_on_reputation_increased)

func show_notification(text: String, type: String = "info"):
	var notification_label = Label.new()
	notification_label.text = text
	
	match type:
		"success":
			notification_label.modulate = Color.GREEN
		"error":
			notification_label.modulate = Color.RED
		"info":
			notification_label.modulate = Color.WHITE

	vbox_container.add_child(notification_label)

	var tween = create_tween()
	tween.tween_property(notification_label, "modulate:a", 0, 3.0).from(1.0)
	tween.tween_callback(notification_label.queue_free)

func _on_order_completed(order_id, price):
	show_notification("Order completed! +$" + str(price), "success")

func _on_dragon_added(dragon_id):
	show_notification("Dragon hatched!", "info")

func _on_reputation_increased(amount):
	show_notification("Reputation increased by " + str(amount) + "!", "success")

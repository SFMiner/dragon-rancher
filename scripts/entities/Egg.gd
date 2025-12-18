# Egg.gd
# Egg entity controller
# Part of Dragon Ranch - Session 3 Dragon Entities & Lifecycle
#
# Attached to Egg.tscn
# Displays egg visual and incubation progress

class_name Egg
extends Node2D

## Egg ready to hatch signal
signal egg_ready_to_hatch(egg: Egg)

## Reference to egg data
var egg_data: EggData = null

## Node references (set in _ready)
@onready var sprite: Sprite2D = $Sprite2D
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	# Connect to season changes if RanchState exists
	# For now, we'll manually call update when needed
	pass


## Setup egg with data
func setup(data: EggData) -> void:
	egg_data = data

	if egg_data == null:
		push_error("[Egg] setup: null egg data")
		return

	# Update visuals
	update_visuals()

	# Update progress bar
	update_timer_display()


## Update visual representation
func update_visuals() -> void:
	if egg_data == null:
		return

	# Try to load egg sprite
	var sprite_path: String = "res://assets/sprites/eggs/egg.png"
	if ResourceLoader.exists(sprite_path):
		var texture: Texture2D = load(sprite_path)
		if sprite and texture:
			sprite.texture = texture
	else:
		# Use placeholder colored circle
		_create_placeholder_sprite()


## Create placeholder sprite for egg
func _create_placeholder_sprite() -> void:
	if not sprite:
		return

	var placeholder_size: int = 48
	var color: Color = _get_egg_color()

	# Create oval/egg shaped image
	var image := Image.create(placeholder_size, placeholder_size, false, Image.FORMAT_RGBA8)

	# Draw egg shape (simplified oval)
	for y in range(placeholder_size):
		for x in range(placeholder_size):
			var center_x: float = placeholder_size / 2.0
			var center_y: float = placeholder_size / 2.0
			var rx: float = placeholder_size / 2.0
			var ry: float = placeholder_size / 1.6  # Slightly taller

			var dx: float = (x - center_x) / rx
			var dy: float = (y - center_y) / ry

			if dx * dx + dy * dy <= 1.0:
				# Inside egg shape
				var is_border: bool = dx * dx + dy * dy > 0.8
				if is_border:
					image.set_pixel(x, y, Color.BLACK)
				else:
					image.set_pixel(x, y, color)

	var texture := ImageTexture.create_from_image(image)
	sprite.texture = texture


## Get egg color based on genotype (hint at what's inside)
func _get_egg_color() -> Color:
	if egg_data == null or egg_data.genotype.is_empty():
		return Color(0.95, 0.95, 0.9)  # Off-white default

	# Hint at fire trait through shell color
	if egg_data.genotype.has("fire"):
		var alleles: Array = egg_data.genotype["fire"]
		var has_fire: bool = "F" in alleles

		if has_fire:
			# Reddish tint
			return Color(0.95, 0.85, 0.8)
		else:
			# Grayish tint
			return Color(0.85, 0.85, 0.85)

	return Color(0.95, 0.95, 0.9)


## Update incubation timer display
func update_timer_display() -> void:
	if egg_data == null or progress_bar == null:
		return

	# Update progress bar
	var progress: float = egg_data.get_incubation_progress()
	progress_bar.value = progress * 100.0

	# Check if ready to hatch
	if egg_data.is_ready_to_hatch():
		_trigger_hatch_ready()


## Called when egg is ready to hatch
func _trigger_hatch_ready() -> void:
	# Play crack animation if available
	if animation_player and animation_player.has_animation("crack"):
		animation_player.play("crack")

	# Emit signal
	egg_ready_to_hatch.emit(self)

	print("[Egg] Ready to hatch! ID: %s" % egg_data.id if egg_data else "Unknown")


## Play hatching animation
func play_hatch_animation() -> void:
	if animation_player and animation_player.has_animation("hatch"):
		animation_player.play("hatch")
	else:
		# Simple fallback: just hide the egg
		queue_free()


## Called when season changes (decrement incubation timer)
func on_season_changed() -> void:
	if egg_data == null:
		return

	egg_data.decrement_incubation()
	update_timer_display()


## Get incubation progress (0.0 to 1.0)
func get_incubation_progress() -> float:
	if egg_data:
		return egg_data.get_incubation_progress()
	return 0.0


## Get seasons remaining
func get_seasons_remaining() -> int:
	if egg_data:
		return egg_data.incubation_seasons_remaining
	return 0

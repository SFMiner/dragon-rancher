# Dragon.gd
# Dragon entity controller
# Part of Dragon Ranch - Session 3 Dragon Entities & Lifecycle
#
# Attached to Dragon.tscn
# Handles visual representation, wandering behavior, and user interaction

extends Node2D

## Dragon clicked signal (emitted when player clicks this dragon)
signal dragon_clicked(dragon: Node2D, dragon_id: String)

## Reference to dragon data
var dragon_data: DragonData = null

## Target position for wandering
var target_position: Vector2 = Vector2.ZERO

## Movement speed (pixels per second)
@export var base_wander_speed: float = 50.0

## Current movement speed (modified by life stage)
var wander_speed: float = 50.0

## How often to pick new wander target (seconds)
@export var wander_interval: float = 3.0

## Timer for wandering
var _wander_timer: float = 0.0

## Whether this dragon is currently wandering
var _is_wandering: bool = true

## Node references (set in _ready)
@onready var sprite: Polygon2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var name_label: Label = $NameLabel
@onready var click_area: Area2D = $ClickArea


func _ready() -> void:
	# Connect click area signal
	if click_area:
		click_area.input_event.connect(_on_click_area_input_event)

	# Start idle animation if available
	if animation_player and animation_player.has_animation("idle"):
		animation_player.play("idle")
	refresh_from_data()

	# Update visuals when season advances (age may change in RanchState)
	if Engine.has_singleton("RanchState") or typeof(RanchState) != TYPE_NIL:
		RanchState.season_changed.connect(_on_season_changed)

## Setup dragon with data
func setup(data: DragonData) -> void:
	dragon_data = data

	if dragon_data == null:
		push_error("[Dragon] setup: null dragon data")
		return

	# Update visuals based on phenotype
	update_visuals()

	# Set name label
	# Update movement speed based on life stage and metabolism
	var speed_multiplier: float = Lifecycle.get_stage_speed_multiplier(dragon_data.life_stage)

	# Apply metabolism speed multiplier if present
	if dragon_data.phenotype.has("metabolism"):
		var metabolism_pheno: Dictionary = dragon_data.phenotype["metabolism"]
		var metabolism_speed: float = metabolism_pheno.get("speed_multiplier", 1.0)
		speed_multiplier *= metabolism_speed

	wander_speed = base_wander_speed * speed_multiplier

	# Pick initial wander target
	_pick_new_wander_target()
	if name_label:
		name_label.text = dragon_data.name



## Update visual representation based on phenotype
func update_visuals() -> void:
	if dragon_data == null:
		return

	# Get scale based on life stage and age progression
	var stage_scale: float = _compute_age_stage_scale()

	# Get scale based on size phenotype
	var size_scale: float = 1.0
	if dragon_data.phenotype.has("size"):
		var size_pheno: Dictionary = dragon_data.phenotype["size"]
		size_scale = size_pheno.get("scale_factor", 1.0)

	# Combine both scales
	var final_scale: float = stage_scale * size_scale
	scale = Vector2(final_scale, final_scale)

	# Try to load sprite based on phenotype
	#var sprite_path: String = _build_sprite_path()
	#if ResourceLoader.exists(sprite_path):
	#	var texture: Texture2D = load(sprite_path)
	#	if sprite and texture:
	#		sprite.texture = texture
	#else:
		# Use colored placeholder based on phenotype
	#	_create_placeholder_sprite()

	# Apply color modulation if color trait present
	_apply_color_modulation()


## Build sprite path from phenotype
## Example: "res://assets/sprites/dragons/dragon_red_fire_vestigial_heavy.png"
func _build_sprite_path() -> String:
	if dragon_data == null or dragon_data.phenotype.is_empty():
		return ""

	var parts: Array[String] = ["dragon"]

	# Add phenotype suffixes in order: color, fire, wings, armor
	for trait_key in ["color", "fire", "wings", "armor"]:
		if dragon_data.phenotype.has(trait_key):
			var pheno_data: Dictionary = dragon_data.phenotype[trait_key]
			if pheno_data.has("sprite_suffix"):
				parts.append(pheno_data["sprite_suffix"])

	var filename: String = "_".join(parts) + ".png"
	return "res://assets/sprites/dragons/" + filename


## Create placeholder colored sprite when actual sprite is missing
func _create_placeholder_sprite() -> void:
	if not sprite:
		return

	# Create a colored square based on dominant phenotype
	var placeholder_size: int = 64
	var color: Color = _get_dominant_phenotype_color()

	# Create image
	var image := Image.create(placeholder_size, placeholder_size, false, Image.FORMAT_RGBA8)
	image.fill(color)

	# Add border
	var border_color: Color = Color.BLACK
	for x in range(placeholder_size):
		image.set_pixel(x, 0, border_color)
		image.set_pixel(x, placeholder_size - 1, border_color)
	for y in range(placeholder_size):
		image.set_pixel(0, y, border_color)
		image.set_pixel(placeholder_size - 1, y, border_color)

	# Create texture
	var texture := ImageTexture.create_from_image(image)
	sprite.texture = texture


## Get dominant phenotype color for placeholder
func _get_dominant_phenotype_color() -> Color:
	if dragon_data == null or dragon_data.phenotype.is_empty():
		return Color.GRAY

	# Prioritize color trait if present
	if dragon_data.phenotype.has("color"):
		var color_pheno: Dictionary = dragon_data.phenotype["color"]
		if color_pheno.has("color"):
			var color_value = color_pheno["color"]
			if color_value is Color:
				return color_value
			elif color_value is String:
				return Color.from_string(color_value, Color.GRAY)

	# Try to get color from fire trait (most visible)
	for trait_key in ["fire", "wings", "armor"]:
		if dragon_data.phenotype.has(trait_key):
			var pheno_data: Dictionary = dragon_data.phenotype[trait_key]
			if pheno_data.has("color"):
				var color_value = pheno_data["color"]
				if color_value is Color:
					return color_value
				elif color_value is String:
					return Color.from_string(color_value, Color.GRAY)

	return Color.GRAY


## Apply color modulation to sprite based on color trait
func _apply_color_modulation() -> void:
	if not sprite or dragon_data == null:
		return

	# Check if color trait is present
	if not dragon_data.phenotype.has("color"):
		# No color trait, use default white (no modulation)
		sprite.modulate = Color.WHITE
		return

	var color_pheno: Dictionary = dragon_data.phenotype["color"]
	if not color_pheno.has("color"):
		sprite.modulate = Color.WHITE
		return

	# Get color value
	var color_value = color_pheno["color"]
	var modulate_color: Color = Color.WHITE

	if color_value is Color:
		modulate_color = color_value
	elif color_value is String:
		modulate_color = Color.from_string(color_value, Color.WHITE)

	# Apply color modulation to sprite
	sprite.modulate = modulate_color


## Process wandering behavior
func _process(delta: float) -> void:
	if not _is_wandering or dragon_data == null:
		return

	# Update wander timer
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_pick_new_wander_target()
		_wander_timer = wander_interval

	# Move towards target
	var direction: Vector2 = (target_position - position).normalized()
	var distance: float = position.distance_to(target_position)

	if distance > 5.0:  # Don't move if very close
		position += direction * wander_speed * delta

		# Flip sprite based on movement direction
		if sprite and direction.x != 0:
#			sprite.flip_h = direction.x < 0
			pass

## Pick a new random wander target near current position
func _pick_new_wander_target() -> void:
	# Wander within a radius around spawn point
	var wander_radius: float = 200.0
	var angle: float = randf() * TAU
	var distance: float = randf() * wander_radius

	target_position = Vector2(
		cos(angle) * distance,
		sin(angle) * distance
	)


## Handle click detection
func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			dragon_clicked.emit(self, dragon_data.id if dragon_data else "")
			# P0 PERFORMANCE: Only allocate debug string in debug builds
			if OS.is_debug_build():
				print("[Dragon] Clicked: %s" % (dragon_data.name if dragon_data else "Unknown"))


## Enable/disable wandering
func set_wandering(enabled: bool) -> void:
	_is_wandering = enabled


## Get dragon's current life stage
func get_life_stage() -> String:
	if dragon_data:
		return dragon_data.life_stage
	return ""


## Get dragon's health percentage
func get_health_percentage() -> float:
	if dragon_data:
		return dragon_data.health / 100.0
	return 0.0


## Update dragon data (called when dragon ages, etc.)
func refresh_from_data() -> void:
	if dragon_data:
		update_visuals()

		# Update speed based on new life stage and metabolism
		var speed_multiplier: float = Lifecycle.get_stage_speed_multiplier(dragon_data.life_stage)

		# Apply metabolism speed multiplier if present
		if dragon_data.phenotype.has("metabolism"):
			var metabolism_pheno: Dictionary = dragon_data.phenotype["metabolism"]
			var metabolism_speed: float = metabolism_pheno.get("speed_multiplier", 1.0)
			speed_multiplier *= metabolism_speed

		wander_speed = base_wander_speed * speed_multiplier

		# Update name label
		if name_label:
			name_label.text = dragon_data.name


## Called when RanchState advances season (dragon ages elsewhere)
func _on_season_changed(_new_season: int) -> void:
	if dragon_data:
		refresh_from_data()


## Compute a smooth scale multiplier based on age progression inside the current life stage
func _compute_age_stage_scale() -> float:
	if dragon_data == null:
		return 1.0

	var age: int = dragon_data.age
	var stage: String = dragon_data.life_stage

	match stage:
		Lifecycle.STAGE_HATCHLING:
			var start_age: int = 0
			var end_age: int = Lifecycle.HATCHLING_MAX_AGE
			var start_scale: float = Lifecycle.get_stage_scale(Lifecycle.STAGE_HATCHLING)
			var end_scale: float = Lifecycle.get_stage_scale(Lifecycle.STAGE_JUVENILE)
			var span: int = max(1, end_age - start_age)
			var t: float = clamp(float(age - start_age) / float(span), 0.0, 1.0)
			return lerp(start_scale, end_scale, t)

		Lifecycle.STAGE_JUVENILE:
			var start_age = Lifecycle.HATCHLING_MAX_AGE + 1
			var end_age = Lifecycle.JUVENILE_MAX_AGE
			var start_scale = Lifecycle.get_stage_scale(Lifecycle.STAGE_JUVENILE)
			var end_scale = Lifecycle.get_stage_scale(Lifecycle.STAGE_ADULT)
			var span2: int = max(1, end_age - start_age)
			var t2: float = clamp(float(age - start_age) / float(span2), 0.0, 1.0)
			return lerp(start_scale, end_scale, t2)
		Lifecycle.STAGE_ADULT, Lifecycle.STAGE_ELDER:
			return Lifecycle.get_stage_scale(stage)
		_:
			return Lifecycle.get_stage_scale(stage)

# Ranch.gd
# Main ranch scene controller
# Part of Dragon Ranch - Session 11 Ranch World Scene

extends Node2D

## Node references
@onready var dragons_layer: Node2D = $DragonsLayer
@onready var eggs_layer: Node2D = $EggsLayer
@onready var facilities_layer: Node2D = $FacilitiesLayer

## Track spawned entities
var dragon_nodes: Dictionary = {}  # dragon_id -> Dragon node
var egg_nodes: Dictionary = {}  # egg_id -> Egg node
var facility_nodes: Dictionary = {}  # facility_id -> Facility node

## Ranch bounds
const RANCH_WIDTH: float = 2000.0
const RANCH_HEIGHT: float = 1500.0


func _ready() -> void:
	# Play background music
	AudioManager.play_music("ranch_theme.ogg")

	# Connect to RanchState signals
	RanchState.dragon_added.connect(_on_dragon_added)
	RanchState.dragon_removed.connect(_on_dragon_removed)
	RanchState.egg_created.connect(_on_egg_created)
	RanchState.egg_hatched.connect(_on_egg_hatched)
	RanchState.facility_built.connect(_on_facility_built)

	# Spawn existing entities
	_spawn_existing_entities()

	# Connect TutorialService to RanchState
	if TutorialService:
		TutorialService.connect_to_ranch_state()

		# Start tutorial for new game (this should be conditional based on save state)
		# For now, always start tutorial
		# TODO: Check if this is a new game or loaded game
		if RanchState.is_new_game():
			TutorialService.start_tutorial()


## Spawn all existing entities from RanchState
func _spawn_existing_entities() -> void:
	# Spawn all dragons
	for dragon_id in RanchState.dragons.keys():
		_spawn_dragon(dragon_id)

	# Spawn all eggs
	for egg_id in RanchState.eggs.keys():
		_spawn_egg(egg_id)

	# Spawn all facilities
	for facility_id in RanchState.facilities.keys():
		_spawn_facility(facility_id)


## Dragon added to RanchState
func _on_dragon_added(dragon_id: String) -> void:
	_spawn_dragon(dragon_id)


## Dragon removed from RanchState
func _on_dragon_removed(dragon_id: String) -> void:
	if dragon_nodes.has(dragon_id):
		var dragon_node = dragon_nodes[dragon_id]

		# Play exit animation if available
		# TODO: Add fade-out animation

		# Remove from scene
		dragon_node.queue_free()
		dragon_nodes.erase(dragon_id)

		print("[Ranch] Removed dragon from scene: " + dragon_id)


## Egg created in RanchState
func _on_egg_created(egg_id: String) -> void:
	_spawn_egg(egg_id)


## Egg hatched in RanchState
func _on_egg_hatched(egg_id: String, dragon_id: String) -> void:
	# Remove egg node
	if egg_nodes.has(egg_id):
		var egg_node = egg_nodes[egg_id]

		# Play hatch animation if available
		if egg_node.has_method("play_hatch_animation"):
			egg_node.play_hatch_animation()

		egg_node.queue_free()
		egg_nodes.erase(egg_id)

		print("[Ranch] Egg hatched: " + egg_id)

	# Dragon will be spawned via dragon_added signal


## Facility built in RanchState
func _on_facility_built(facility_id: String) -> void:
	_spawn_facility(facility_id)


## Spawn a dragon in the world
func _spawn_dragon(dragon_id: String) -> void:
	if dragon_nodes.has(dragon_id):
		return  # Already spawned

	var dragon_data: DragonData = RanchState.get_dragon(dragon_id)
	if dragon_data == null:
		push_warning("[Ranch] Cannot spawn dragon: data not found for " + dragon_id)
		return

	# Load Dragon scene
	var dragon_scene_path: String = "res://scenes/entities/dragon/Dragon.tscn"
	if not ResourceLoader.exists(dragon_scene_path):
		push_error("[Ranch] Dragon scene not found: " + dragon_scene_path)
		return

	var dragon_scene: PackedScene = load(dragon_scene_path)
	var dragon_node = dragon_scene.instantiate()

	# Setup dragon with data
	if dragon_node.has_method("setup"):
		dragon_node.setup(dragon_data)

	# Position dragon
	dragon_node.position = get_spawn_position()

	# Connect dragon_clicked signal if available
	if dragon_node.has_signal("dragon_clicked"):
		dragon_node.dragon_clicked.connect(_on_dragon_clicked.bind(dragon_id))

	# Add to scene
	dragons_layer.add_child(dragon_node)
	dragon_nodes[dragon_id] = dragon_node

	print("[Ranch] Spawned dragon: " + dragon_data.name + " at " + str(dragon_node.position))


## Spawn an egg in the world
func _spawn_egg(egg_id: String) -> void:
	if egg_nodes.has(egg_id):
		return  # Already spawned

	var egg_data: EggData = RanchState.eggs.get(egg_id)
	if egg_data == null:
		push_warning("[Ranch] Cannot spawn egg: data not found for " + egg_id)
		return

	# Load Egg scene
	var egg_scene_path: String = "res://scenes/entities/egg/Egg.tscn"
	if not ResourceLoader.exists(egg_scene_path):
		push_error("[Ranch] Egg scene not found: " + egg_scene_path)
		return

	var egg_scene: PackedScene = load(egg_scene_path)
	var egg_node = egg_scene.instantiate()

	# Setup egg with data
	if egg_node.has_method("setup"):
		egg_node.setup(egg_data)

	# Position egg
	egg_node.position = get_spawn_position()

	# Connect signals if available
	if egg_node.has_signal("egg_ready_to_hatch"):
		egg_node.egg_ready_to_hatch.connect(_on_egg_ready_to_hatch.bind(egg_id))

	# Add to scene
	eggs_layer.add_child(egg_node)
	egg_nodes[egg_id] = egg_node

	print("[Ranch] Spawned egg: " + egg_id + " at " + str(egg_node.position))


## Spawn a facility in the world
func _spawn_facility(facility_id: String) -> void:
	if facility_nodes.has(facility_id):
		return  # Already spawned

	var facility_data = RanchState.facilities.get(facility_id)
	if facility_data == null:
		push_warning("[Ranch] Cannot spawn facility: data not found for " + facility_id)
		return

	# Create placeholder facility visual
	var facility_node := Node2D.new()
	facility_node.name = "Facility_" + facility_id

	# Create simple visual representation
	var sprite := Sprite2D.new()

	# Create placeholder texture
	var placeholder_size: int = 128
	var image := Image.create(placeholder_size, placeholder_size, false, Image.FORMAT_RGBA8)

	# Color based on facility type
	var color: Color = _get_facility_color(facility_data.type)

	# Draw simple square
	for y in range(placeholder_size):
		for x in range(placeholder_size):
			if x < 4 or y < 4 or x >= placeholder_size - 4 or y >= placeholder_size - 4:
				image.set_pixel(x, y, Color.BLACK)
			else:
				image.set_pixel(x, y, color)

	var texture := ImageTexture.create_from_image(image)
	sprite.texture = texture

	facility_node.add_child(sprite)

	# Add label
	var label := Label.new()
	label.text = facility_data.type.capitalize()
	label.position = Vector2(-50, 70)
	facility_node.add_child(label)

	# Position facility in grid
	var facility_index: int = facility_nodes.size()
	facility_node.position = _get_facility_grid_position(facility_index)

	# Add to scene
	facilities_layer.add_child(facility_node)
	facility_nodes[facility_id] = facility_node

	print("[Ranch] Spawned facility: " + facility_data.type + " at " + str(facility_node.position))


## Get spawn position for entities
func get_spawn_position() -> Vector2:
	# Random position within ranch bounds
	var x: float = randf_range(-RANCH_WIDTH / 2, RANCH_WIDTH / 2)
	var y: float = randf_range(-RANCH_HEIGHT / 2, RANCH_HEIGHT / 2)

	return Vector2(x, y)


## Get grid position for facilities
func _get_facility_grid_position(index: int) -> Vector2:
	var grid_size: int = 200
	var columns: int = 5

	var row: int = index / columns
	var col: int = index % columns

	var x: float = -RANCH_WIDTH / 2 + 200 + col * grid_size
	var y: float = -RANCH_HEIGHT / 2 + 200 + row * grid_size

	return Vector2(x, y)


## Get color for facility type
func _get_facility_color(facility_type: String) -> Color:
	match facility_type:
		"stable":
			return Color(0.6, 0.4, 0.2)  # Brown
		"pasture":
			return Color(0.4, 0.7, 0.3)  # Green
		"breeding_pen":
			return Color(0.7, 0.5, 0.3)  # Tan
		"nursery":
			return Color(0.8, 0.6, 0.8)  # Pink
		"genetics_lab":
			return Color(0.5, 0.5, 0.8)  # Blue
		"luxury_habitat":
			return Color(0.9, 0.8, 0.4)  # Gold
		_:
			return Color.GRAY


## Dragon clicked callback
func _on_dragon_clicked(dragon_id: String) -> void:
	var dragon_data: DragonData = RanchState.get_dragon(dragon_id)
	if dragon_data == null:
		return

	# Open dragon details panel
	var details_panel = get_node_or_null("UILayer/DragonDetailsPanel")
	if details_panel and details_panel.has_method("show_dragon"):
		details_panel.show_dragon(dragon_data)


## Egg ready to hatch callback
func _on_egg_ready_to_hatch(egg: Egg, egg_id: String) -> void:
	print("[Ranch] Egg ready to hatch: " + egg_id)
	# Hatching is handled by RanchState during advance_season

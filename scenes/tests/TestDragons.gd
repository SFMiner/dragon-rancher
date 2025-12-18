# TestDragons.gd
# Test scene for dragons and eggs
# Part of Dragon Ranch - Session 3 Testing
#
# Demonstrates dragon lifecycle, egg hatching, and entity visualization

extends Node2D

## Dragon scene to instantiate
const DRAGON_SCENE := preload("res://scenes/entities/dragon/Dragon.tscn")

## Egg scene to instantiate
const EGG_SCENE := preload("res://scenes/entities/egg/Egg.tscn")

## Container for spawned entities
@onready var entities_container: Node2D = $EntitiesContainer

## UI labels
@onready var info_label: Label = $UI/InfoLabel
@onready var instructions_label: Label = $UI/InstructionsLabel

## Test dragons created
var test_dragons: Array = []

## Test eggs created
var test_eggs: Array = []


func _ready() -> void:
	# Set seed for reproducible results
	RNGService.set_seed(42)

	# Display instructions
	if instructions_label:
		instructions_label.text = """Session 3 Test Scene - Dragons & Eggs

Press [1] - Spawn random adult dragon
Press [2] - Spawn random hatchling
Press [3] - Spawn random egg
Press [4] - Age all dragons by 1 season
Press [5] - Hatch all ready eggs
Press [Space] - Toggle dragon info display
"""

	# Spawn some initial test dragons
	_spawn_test_dragons()

	# Spawn some test eggs
	_spawn_test_eggs()

	# Update info display
	_update_info_display()


func _process(_delta: float) -> void:
	# Handle input
	if Input.is_action_just_pressed("ui_select"):  # Space
		_update_info_display()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key_event := event as InputEventKey

		match key_event.keycode:
			KEY_1:
				_spawn_random_adult()
			KEY_2:
				_spawn_random_hatchling()
			KEY_3:
				_spawn_random_egg()
			KEY_4:
				_age_all_dragons()
			KEY_5:
				_hatch_ready_eggs()


## Spawn initial test dragons for demonstration
func _spawn_test_dragons() -> void:
	# Create dragons at different life stages
	var stages: Array[String] = ["hatchling", "juvenile", "adult"]
	var x_offset: float = 100.0

	for i in range(stages.size()):
		var dragon_data := _create_test_dragon(stages[i])
		var dragon_node = _spawn_dragon(dragon_data, Vector2(x_offset * (i + 1), 200))
		test_dragons.append(dragon_node)


## Spawn initial test eggs
func _spawn_test_eggs() -> void:
	for i in range(2):
		var egg_data := _create_test_egg(i)
		var egg_node = _spawn_egg(egg_data, Vector2(500 + i * 80, 300))
		test_eggs.append(egg_node)


## Create test dragon data
func _create_test_dragon(life_stage: String) -> DragonData:
	var dragon := DragonData.new()
	dragon.id = IdGen.generate_dragon_id()
	dragon.name = IdGen.generate_random_name()
	dragon.sex = "male" if randf() > 0.5 else "female"

	# Generate random genotype
	dragon.genotype = TraitDB.get_random_genotype(0)

	# Calculate phenotype
	dragon.phenotype = GeneticsEngine.calculate_phenotype(dragon.genotype)

	# Set life stage and appropriate age
	dragon.life_stage = life_stage
	match life_stage:
		"hatchling":
			dragon.age = 0
		"juvenile":
			dragon.age = 2
		"adult":
			dragon.age = 8
		"elder":
			dragon.age = 20

	dragon.health = 100.0
	dragon.happiness = 80.0

	return dragon


## Create test egg data
func _create_test_egg(incubation_remaining: int) -> EggData:
	var egg := EggData.new()
	egg.id = IdGen.generate_egg_id()

	# Generate random genotype
	egg.genotype = TraitDB.get_random_genotype(0)

	egg.parent_a_id = "test_parent_a"
	egg.parent_b_id = "test_parent_b"
	egg.incubation_seasons_remaining = incubation_remaining
	egg.created_season = 1

	return egg


## Spawn a dragon entity
func _spawn_dragon(dragon_data: DragonData, pos: Vector2) -> Node2D:
	var dragon_node = DRAGON_SCENE.instantiate()
	entities_container.add_child(dragon_node)
	dragon_node.position = pos
	dragon_node.setup(dragon_data)
	dragon_node.dragon_clicked.connect(_on_dragon_clicked)
	return dragon_node


## Spawn an egg entity
func _spawn_egg(egg_data: EggData, pos: Vector2) -> Node2D:
	var egg_node = EGG_SCENE.instantiate()
	entities_container.add_child(egg_node)
	egg_node.position = pos
	egg_node.setup(egg_data)
	egg_node.egg_ready_to_hatch.connect(_on_egg_ready_to_hatch)
	return egg_node


## Spawn random adult dragon
func _spawn_random_adult() -> void:
	var dragon_data := _create_test_dragon("adult")
	var spawn_pos := Vector2(randf_range(100, 700), randf_range(100, 500))
	var dragon_node = _spawn_dragon(dragon_data, spawn_pos)
	test_dragons.append(dragon_node)
	_update_info_display()
	print("Spawned adult: %s" % dragon_data.name)


## Spawn random hatchling
func _spawn_random_hatchling() -> void:
	var dragon_data := _create_test_dragon("hatchling")
	var spawn_pos := Vector2(randf_range(100, 700), randf_range(100, 500))
	var dragon_node = _spawn_dragon(dragon_data, spawn_pos)
	test_dragons.append(dragon_node)
	_update_info_display()
	print("Spawned hatchling: %s" % dragon_data.name)


## Spawn random egg
func _spawn_random_egg() -> void:
	var egg_data := _create_test_egg(2)
	var spawn_pos := Vector2(randf_range(100, 700), randf_range(100, 500))
	var egg_node = _spawn_egg(egg_data, spawn_pos)
	test_eggs.append(egg_node)
	_update_info_display()
	print("Spawned egg: %s" % egg_data.id)


## Age all dragons by one season
func _age_all_dragons() -> void:
	for dragon_node in test_dragons:
		if dragon_node and dragon_node.dragon_data:
			var data: DragonData = dragon_node.dragon_data
			var old_stage: String = data.life_stage

			# Advance age using Lifecycle
			Lifecycle.advance_age(data)

			# Refresh visuals
			dragon_node.refresh_from_data()

			if old_stage != data.life_stage:
				print("%s aged: %s -> %s (age %d)" % [data.name, old_stage, data.life_stage, data.age])
			else:
				print("%s aged to %d (%s)" % [data.name, data.age, data.life_stage])

	_update_info_display()


## Hatch all ready eggs
func _hatch_ready_eggs() -> void:
	var hatched_count: int = 0

	for egg_node in test_eggs:
		if egg_node and egg_node.egg_data:
			if egg_node.egg_data.is_ready_to_hatch():
				_hatch_egg(egg_node)
				hatched_count += 1

	if hatched_count > 0:
		print("Hatched %d eggs" % hatched_count)
	else:
		print("No eggs ready to hatch")

	_update_info_display()


## Hatch a specific egg
func _hatch_egg(egg_node: Node2D) -> void:
	if not egg_node or not egg_node.egg_data:
		return

	print("Hatching egg: %s" % egg_node.egg_data.id)

	# Create hatchling from egg
	var hatchling := DragonData.new()
	hatchling.id = IdGen.generate_dragon_id()
	hatchling.name = IdGen.generate_random_name()
	hatchling.sex = "male" if randf() > 0.5 else "female"
	hatchling.genotype = egg_node.egg_data.genotype.duplicate(true)
	hatchling.phenotype = GeneticsEngine.calculate_phenotype(hatchling.genotype)
	hatchling.life_stage = "hatchling"
	hatchling.age = 0
	hatchling.parent_a_id = egg_node.egg_data.parent_a_id
	hatchling.parent_b_id = egg_node.egg_data.parent_b_id
	hatchling.health = 100.0
	hatchling.happiness = 100.0

	# Spawn dragon at egg position
	var dragon_node = _spawn_dragon(hatchling, egg_node.position)
	test_dragons.append(dragon_node)

	# Remove egg
	test_eggs.erase(egg_node)
	egg_node.queue_free()

	print("Hatched: %s" % hatchling.name)


## Update info display
func _update_info_display() -> void:
	if not info_label:
		return

	var info_lines: Array[String] = []
	info_lines.append("=== Dragon Ranch - Session 3 Test ===")
	info_lines.append("")
	info_lines.append("Dragons: %d" % test_dragons.size())
	info_lines.append("Eggs: %d" % test_eggs.size())
	info_lines.append("")

	# Count dragons by stage
	var stage_counts: Dictionary = {}
	for dragon_node in test_dragons:
		if dragon_node and dragon_node.dragon_data:
			var stage: String = dragon_node.dragon_data.life_stage
			stage_counts[stage] = stage_counts.get(stage, 0) + 1

	info_lines.append("By Stage:")
	for stage in ["hatchling", "juvenile", "adult", "elder"]:
		if stage_counts.has(stage):
			info_lines.append("  %s: %d" % [stage.capitalize(), stage_counts[stage]])

	info_label.text = "\n".join(info_lines)


## Handle dragon clicked
func _on_dragon_clicked(dragon_node: Node2D) -> void:
	if not dragon_node or not dragon_node.dragon_data:
		return

	var data: DragonData = dragon_node.dragon_data
	var info: Dictionary = Lifecycle.get_lifecycle_info(data)

	print("\n=== Dragon Info ===")
	print("Name: %s" % data.name)
	print("ID: %s" % data.id)
	print("Sex: %s" % data.sex)
	print("Age: %d seasons" % data.age)
	print("Life Stage: %s" % info["stage_display_name"])
	print("Genotype: %s" % GeneticsResolvers.format_genotype_display(data.genotype))
	print("Can Breed: %s" % ("Yes" if info["can_breed"] else "No"))
	print("Max Lifespan: %d seasons" % info["max_lifespan"])
	print("Age Progress: %.1f%%" % (info["age_percentage"] * 100.0))
	print("==================\n")


## Handle egg ready to hatch
func _on_egg_ready_to_hatch(egg_node: Node2D) -> void:
	print("Egg ready to hatch: %s" % (egg_node.egg_data.id if egg_node.egg_data else "Unknown"))

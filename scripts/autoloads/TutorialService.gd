## Tutorial service autoload
## Integrates tutorial system with game state
## Listens for game events and manages tutorial progression
extends Node

## Emitted when the tutorial advances to a new step
signal step_changed(step: TutorialStep)

## Emitted when the tutorial is completed
signal tutorial_completed()

## Emitted when the tutorial is skipped
signal tutorial_skipped()

## Internal tutorial logic module
var _tutorial_logic: TutorialLogic = null

## Path to tutorial steps JSON
const TUTORIAL_JSON_PATH = "res://data/config/tutorial_steps.json"


func _ready() -> void:
	# Initialize tutorial logic
	_tutorial_logic = TutorialLogic.new()

	# Load tutorial steps
	if not _tutorial_logic.load_tutorial_steps(TUTORIAL_JSON_PATH):
		push_error("Failed to load tutorial steps!")
		return

	# Connect to tutorial logic signals
	_tutorial_logic.step_advanced.connect(_on_step_advanced)

	print("TutorialService initialized")


## Start the tutorial
func start_tutorial() -> void:
	if _tutorial_logic == null:
		push_error("TutorialLogic not initialized!")
		return

	_tutorial_logic.start_tutorial()

	# Emit signal for first step
	var first_step = _tutorial_logic.get_current_step()
	if first_step:
		step_changed.emit(first_step)


## Skip/disable the tutorial
func skip_tutorial() -> void:
	if _tutorial_logic == null:
		return

	_tutorial_logic.skip_tutorial()
	tutorial_skipped.emit()


## Reset tutorial to beginning (for new games)
func reset_tutorial() -> void:
	if _tutorial_logic == null:
		return

	_tutorial_logic.reset()
	print("[TutorialService] Tutorial reset for new game")


## Check if tutorial is active
func is_tutorial_active() -> bool:
	if _tutorial_logic == null:
		return false
	return _tutorial_logic.is_active()


## Check if tutorial is completed
func is_tutorial_completed() -> bool:
	if _tutorial_logic == null:
		return false
	return _tutorial_logic.is_completed()


## Get the current tutorial step (null if not active)
func get_current_step() -> TutorialStep:
	if _tutorial_logic == null:
		return null
	return _tutorial_logic.get_current_step()


## Process a tutorial event
## This is the main entry point for game systems to notify tutorial progression
func process_event(event_type: String, payload: Dictionary = {}) -> void:
	if _tutorial_logic == null:
		return

	if not _tutorial_logic.is_active():
		return

	# Process the event
	var advanced = _tutorial_logic.process_event(event_type, payload)

	# If tutorial didn't advance, ignore
	if not advanced:
		return

	# Check if tutorial is now complete
	if _tutorial_logic.is_completed():
		tutorial_completed.emit()
		return

	# Emit new step
	var new_step = _tutorial_logic.get_current_step()
	if new_step:
		step_changed.emit(new_step)


## Get tutorial progress percentage (0-100)
func get_progress_percentage() -> float:
	if _tutorial_logic == null:
		return 0.0
	return _tutorial_logic.get_progress_percentage()


## Check if a specific step has been completed
func is_step_completed(step_id: String) -> bool:
	if _tutorial_logic == null:
		return false
	return _tutorial_logic.is_step_completed(step_id)


## Serialize tutorial state for saving
func save_state() -> Dictionary:
	if _tutorial_logic == null:
		return {}
	return _tutorial_logic.to_dict()


## Restore tutorial state from save data
func load_state(data: Dictionary) -> void:
	if _tutorial_logic == null:
		return

	_tutorial_logic.from_dict(data)

	# If tutorial is active, emit current step
	if _tutorial_logic.is_active():
		var current_step = _tutorial_logic.get_current_step()
		if current_step:
			step_changed.emit(current_step)


## Internal handler for when tutorial advances
func _on_step_advanced(old_step_id: String, new_step_id: String) -> void:
	print("TutorialService: Step advanced from ", old_step_id, " to ", new_step_id)


## Connect to RanchState signals (call this after RanchState is ready)
func connect_to_ranch_state() -> void:
	if not has_node("/root/RanchState"):
		push_warning("RanchState not found, cannot connect tutorial signals")
		return

	var ranch_state = get_node("/root/RanchState")

	# Connect to relevant signals
	if ranch_state.has_signal("dragon_added"):
		ranch_state.dragon_added.connect(_on_dragon_added)

	if ranch_state.has_signal("egg_created"):
		ranch_state.egg_created.connect(_on_egg_created)

	if ranch_state.has_signal("order_completed"):
		ranch_state.order_completed.connect(_on_order_completed)

	if ranch_state.has_signal("season_changed"):
		ranch_state.season_changed.connect(_on_season_changed)

	if ranch_state.has_signal("facility_built"):
		ranch_state.facility_built.connect(_on_facility_built)

	print("TutorialService connected to RanchState signals")


## Signal handlers for RanchState events

func _on_dragon_added(dragon_id: String) -> void:
	process_event("dragon_spawned", {"dragon_id": dragon_id})

	# Check if dragon matured to adult
	var dragon_data: DragonData = RanchState.get_dragon(dragon_id)
	if dragon_data and dragon_data.life_stage == "adult":
		process_event("dragon_matured", {"dragon_id": dragon_id})


func _on_egg_created(egg_id: String) -> void:
	process_event("egg_created", {"egg_id": egg_id})


func _on_order_completed(order_id: String, payment: int) -> void:
	process_event("order_completed", {"order_id": order_id, "payment": payment})


func _on_season_changed(season: int) -> void:
	process_event("season_advanced", {"season": season})


func _on_facility_built(facility_id: String) -> void:
	process_event("facility_built", {"facility_id": facility_id})

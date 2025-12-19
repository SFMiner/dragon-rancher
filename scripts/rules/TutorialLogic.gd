## Tutorial state machine
## Manages tutorial progression through steps based on events
## This is a module class, not an autoload
class_name TutorialLogic
extends RefCounted

## Signal emitted when advancing to a new step
signal step_advanced(old_step_id: String, new_step_id: String)

## All tutorial steps in order
var tutorial_steps: Array[TutorialStep] = []

## Whether the tutorial is currently active
var tutorial_enabled: bool = false

## Current step index (-1 = not started, >= steps.size() = completed)
var current_step_index: int = -1

## Dictionary of completed step IDs
var completed_steps: Dictionary = {}


## Load tutorial steps from JSON file
func load_tutorial_steps(json_path: String) -> bool:
	if not FileAccess.file_exists(json_path):
		push_error("Tutorial JSON file not found: " + json_path)
		return false

	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open tutorial JSON file: " + json_path)
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_text)

	if parse_result != OK:
		push_error("Failed to parse tutorial JSON: " + json.get_error_message())
		return false

	var data = json.data
	if not data is Dictionary or not data.has("steps"):
		push_error("Invalid tutorial JSON structure - missing 'steps' array")
		return false

	tutorial_steps.clear()
	for step_data in data["steps"]:
		if step_data is Dictionary:
			var from_step = TutorialStep.new()
			from_step.from_dict(step_data)
			tutorial_steps.append(from_step)

	print("Loaded ", tutorial_steps.size(), " tutorial steps")
	return true


## Start the tutorial from the beginning
func start_tutorial() -> void:
	tutorial_enabled = true
	current_step_index = 0
	completed_steps.clear()
	print("Tutorial started at step 0: ", get_current_step().id if get_current_step() else "none")


## Skip/disable the tutorial
func skip_tutorial() -> void:
	tutorial_enabled = false
	print("Tutorial skipped")


## Reset tutorial to beginning
func reset() -> void:
	tutorial_enabled = false
	current_step_index = -1
	completed_steps.clear()
	print("Tutorial reset")


## Get the current tutorial step (null if not in tutorial)
func get_current_step() -> TutorialStep:
	if not tutorial_enabled:
		return null

	if current_step_index < 0 or current_step_index >= tutorial_steps.size():
		return null

	return tutorial_steps[current_step_index]


## Check if tutorial is currently active
func is_active() -> bool:
	return tutorial_enabled and get_current_step() != null


## Check if tutorial is completed
func is_completed() -> bool:
	return current_step_index >= tutorial_steps.size()


## Process an event and advance tutorial if conditions match
## Returns true if the tutorial advanced to a new step
func process_event(event_type: String, payload: Dictionary) -> bool:
	if not is_active():
		return false

	var current_step = get_current_step()
	if current_step == null:
		return false

	# Check if event matches advance condition
	if not current_step.matches_advance_condition(event_type, payload):
		return false

	# Mark current step as completed
	completed_steps[current_step.id] = true

	# Advance to next step
	var old_step_id = current_step.id
	current_step_index += 1

	var new_step = get_current_step()
	var new_step_id = new_step.id if new_step else ""

	# Check if tutorial is now complete
	if current_step_index >= tutorial_steps.size():
		tutorial_enabled = false
		print("Tutorial completed!")

	step_advanced.emit(old_step_id, new_step_id)
	print("Tutorial advanced: ", old_step_id, " -> ", new_step_id)

	return true


## Get step by ID (useful for testing/debugging)
func get_step_by_id(step_id: String) -> TutorialStep:
	for step in tutorial_steps:
		if step.id == step_id:
			return step
	return null


## Check if a specific step has been completed
func is_step_completed(step_id: String) -> bool:
	return completed_steps.has(step_id)


## Get progress percentage (0-100)
func get_progress_percentage() -> float:
	if tutorial_steps.is_empty():
		return 0.0

	return (float(completed_steps.size()) / float(tutorial_steps.size())) * 100.0


## Serialize state for saving
func to_dict() -> Dictionary:
	return {
		"tutorial_enabled": tutorial_enabled,
		"current_step_index": current_step_index,
		"completed_steps": completed_steps
	}


## Restore state from save data
func from_dict(data: Dictionary) -> void:
	tutorial_enabled = data.get("tutorial_enabled", false)
	current_step_index = data.get("current_step_index", -1)
	completed_steps = data.get("completed_steps", {})

	print("Tutorial state loaded: enabled=", tutorial_enabled, ", step_index=", current_step_index)

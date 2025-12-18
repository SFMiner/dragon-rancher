## Tutorial step data structure
## Represents a single step in the tutorial sequence
class_name TutorialStep
extends Resource

## Unique identifier for this tutorial step
@export var id: String = ""

## Display title for this step
@export var title: String = ""

## Main instructional text shown to the player
@export_multiline var body: String = ""

## UI element id to highlight (if any)
@export var anchor: String = ""

## How to display the highlight
## Valid values: "anchor" (highlight element), "screen_center" (center card), "none" (no highlight)
@export_enum("anchor", "screen_center", "none") var highlight_mode: String = "screen_center"

## Condition that must be met to advance to next step
## Format: {"event_type": "string", "payload": {key: value, ...}}
## Example: {"event_type": "panel_opened", "payload": {"panel": "breeding"}}
@export var advance_condition: Dictionary = {}

## Actions to execute when entering this step
## Array of action dictionaries
## Example: [{"action": "highlight_ui", "target": "breeding_button"}]
@export var on_enter_actions: Array[Dictionary] = []

## Actions to execute when exiting this step
## Array of action dictionaries
## Example: [{"action": "unhighlight_ui", "target": "breeding_button"}]
@export var on_exit_actions: Array[Dictionary] = []

## Check if an event matches this step's advance condition
func matches_advance_condition(event_type: String, payload: Dictionary) -> bool:
	if advance_condition.is_empty():
		return false

	# Check if event type matches
	if not advance_condition.has("event_type"):
		return false

	if advance_condition["event_type"] != event_type:
		return false

	# If no payload requirements, event type match is enough
	if not advance_condition.has("payload"):
		return true

	var required_payload = advance_condition["payload"]

	# Check if all required payload keys match
	for key in required_payload.keys():
		if not payload.has(key):
			return false
		if payload[key] != required_payload[key]:
			return false

	return true


## Serialize to dictionary for saving
func to_dict() -> Dictionary:
	return {
		"id": id,
		"title": title,
		"body": body,
		"anchor": anchor,
		"highlight_mode": highlight_mode,
		"advance_condition": advance_condition,
		"on_enter_actions": on_enter_actions,
		"on_exit_actions": on_exit_actions
	}


## Create from dictionary (for loading from JSON)
static func from_dict(data: Dictionary) -> TutorialStep:
	var step = TutorialStep.new()
	step.id = data.get("id", "")
	step.title = data.get("title", "")
	step.body = data.get("body", "")
	step.anchor = data.get("anchor", "")
	step.highlight_mode = data.get("highlight_mode", "screen_center")
	step.advance_condition = data.get("advance_condition", {})
	step.on_enter_actions.clear()
	step.on_enter_actions.clear()

	# Convert on_enter_actions Array to Array[Dictionary]
	if data.has("on_enter_actions"):
		for action in data["on_enter_actions"]:
			if action is Dictionary:
				step.on_enter_actions.append(action)

	# Convert on_exit_actions Array to Array[Dictionary]
	if data.has("on_exit_actions"):
		for action in data["on_exit_actions"]:
			if action is Dictionary:
				step.on_exit_actions.append(action)

	return step

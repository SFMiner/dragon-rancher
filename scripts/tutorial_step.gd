# tutorial_step.gd
# Resource class for tutorial step data
# Defines a single step in the onboarding tutorial
# Part of Dragon Ranch - Session 1 Architecture
#
# INTERFACE LOCKED - See docs/API_Reference.md

extends Resource
class_name TutorialStep

## Highlight mode constants
const HIGHLIGHT_ANCHOR: String = "anchor"         # Highlight specific UI element
const HIGHLIGHT_CENTER: String = "screen_center"  # Show in center of screen
const HIGHLIGHT_NONE: String = "none"             # No highlight

## Unique identifier for this step (e.g., "tut_01_welcome")
@export var id: String = ""

## Step title for display
@export var title: String = ""

## Step body text (instructions)
@export var body: String = ""

## UI anchor id to highlight (e.g., "breeding_button", "orders_panel")
@export var anchor: String = ""

## How to display highlight
@export var highlight_mode: String = HIGHLIGHT_ANCHOR

## Condition that must be met to advance to next step
## {
##   "type": "event_type",
##   "payload": {...}  // Optional additional conditions
## }
## Types: "dragon_selected", "panel_opened", "egg_created", 
##        "season_advanced", "order_completed", "user_clicked_next"
@export var advance_condition: Dictionary = {}

## Actions to perform when entering this step
## Array of {"action": "action_type", "params": {...}}
## Actions: "open_panel", "set_time_speed", "highlight_dragon", etc.
@export var on_enter_actions: Array[Dictionary] = []

## Actions to perform when exiting this step
@export var on_exit_actions: Array[Dictionary] = []

## Order index for sequencing (lower = earlier)
@export var order_index: int = 0

## Whether this step can be skipped
@export var skippable: bool = true

## Whether to show a "Next" button (vs auto-advance)
@export var show_next_button: bool = false


# === SERIALIZATION ===

func to_dict() -> Dictionary:
	"""Serialize tutorial step to JSON-compatible dictionary."""
	return {
		"id": id,
		"title": title,
		"body": body,
		"anchor": anchor,
		"highlight_mode": highlight_mode,
		"advance_condition": advance_condition.duplicate(true),
		"on_enter_actions": on_enter_actions.duplicate(true),
		"on_exit_actions": on_exit_actions.duplicate(true),
		"order_index": order_index,
		"skippable": skippable,
		"show_next_button": show_next_button
	}


func from_dict(data: Dictionary) -> void:
	"""Deserialize tutorial step from dictionary."""
	id = data.get("id", "")
	title = data.get("title", "")
	body = data.get("body", "")
	anchor = data.get("anchor", "")
	highlight_mode = data.get("highlight_mode", HIGHLIGHT_ANCHOR)
	advance_condition = data.get("advance_condition", {}).duplicate(true)
	on_enter_actions = Array(data.get("on_enter_actions", []), TYPE_DICTIONARY, "", null)
	on_exit_actions = Array(data.get("on_exit_actions", []), TYPE_DICTIONARY, "", null)
	order_index = data.get("order_index", 0)
	skippable = data.get("skippable", true)
	show_next_button = data.get("show_next_button", false)


# === VALIDATION ===

func is_valid() -> bool:
	"""Validate that tutorial step is complete and correct."""
	if id.is_empty():
		push_warning("TutorialStep.is_valid: id is empty")
		return false
	
	if title.is_empty():
		push_warning("TutorialStep.is_valid: title is empty")
		return false
	
	if body.is_empty():
		push_warning("TutorialStep.is_valid: body is empty")
		return false
	
	if highlight_mode not in [HIGHLIGHT_ANCHOR, HIGHLIGHT_CENTER, HIGHLIGHT_NONE]:
		push_warning("TutorialStep.is_valid: invalid highlight_mode '%s'" % highlight_mode)
		return false
	
	if highlight_mode == HIGHLIGHT_ANCHOR and anchor.is_empty():
		push_warning("TutorialStep.is_valid: anchor mode requires anchor id")
		return false
	
	if advance_condition.is_empty():
		push_warning("TutorialStep.is_valid: advance_condition is empty")
		return false
	
	if not advance_condition.has("type"):
		push_warning("TutorialStep.is_valid: advance_condition needs 'type' key")
		return false
	
	return true


# === HELPER METHODS ===

func get_advance_type() -> String:
	"""Get the event type needed to advance this step."""
	return advance_condition.get("type", "")


func check_advance_condition(event_type: String, payload: Dictionary = {}) -> bool:
	"""Check if an event matches the advance condition."""
	var required_type: String = advance_condition.get("type", "")
	
	if event_type != required_type:
		return false
	
	# Check additional payload conditions if specified
	var required_payload: Dictionary = advance_condition.get("payload", {})
	for key in required_payload.keys():
		if not payload.has(key):
			return false
		if payload[key] != required_payload[key]:
			return false
	
	return true


func requires_user_click() -> bool:
	"""Check if this step requires user to click Next button."""
	return show_next_button or advance_condition.get("type", "") == "user_clicked_next"


func has_enter_actions() -> bool:
	"""Check if this step has on-enter actions."""
	return on_enter_actions.size() > 0


func has_exit_actions() -> bool:
	"""Check if this step has on-exit actions."""
	return on_exit_actions.size() > 0


func duplicate_data() -> TutorialStep:
	"""Create a deep copy of this tutorial step."""
	var copy := TutorialStep.new()
	copy.from_dict(to_dict())
	return copy

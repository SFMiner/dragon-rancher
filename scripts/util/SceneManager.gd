# SceneManager.gd
# Autoload singleton for managing scene transitions with fade effects
# Part of Dragon Ranch - Session 19 Main Menu & Game Flow

extends Node

## Signals
signal transition_started()
signal transition_finished()

## Transition state
var _is_transitioning: bool = false
var _transition_overlay: ColorRect = null
var _tween: Tween = null

## Transition settings
const FADE_DURATION: float = 0.3
const FADE_COLOR: Color = Color.BLACK


func _ready() -> void:
	# Create transition overlay
	_create_transition_overlay()


## Create the fullscreen fade overlay
func _create_transition_overlay() -> void:
	# Create CanvasLayer to render on top of everything
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "TransitionLayer"
	canvas_layer.layer = 100  # Render on top
	add_child(canvas_layer)

	# Create ColorRect for fade effect
	_transition_overlay = ColorRect.new()
	_transition_overlay.name = "FadeOverlay"
	_transition_overlay.color = FADE_COLOR
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Make it fullscreen
	_transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_overlay.anchor_left = 0
	_transition_overlay.anchor_top = 0
	_transition_overlay.anchor_right = 1
	_transition_overlay.anchor_bottom = 1
	_transition_overlay.offset_left = 0
	_transition_overlay.offset_top = 0
	_transition_overlay.offset_right = 0
	_transition_overlay.offset_bottom = 0

	# Start invisible
	_transition_overlay.modulate.a = 0.0

	canvas_layer.add_child(_transition_overlay)


## Change scene with fade transition
func change_scene(scene_path: String) -> void:
	if _is_transitioning:
		push_warning("[SceneManager] Transition already in progress, ignoring request")
		return

	_is_transitioning = true
	transition_started.emit()

	# Fade out
	await _fade_out()

	# Change scene
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("[SceneManager] Failed to change scene to: %s (error %d)" % [scene_path, error])
		_is_transitioning = false
		await _fade_in()
		return

	# Wait one frame for new scene to load
	await get_tree().process_frame

	# Fade in
	await _fade_in()

	_is_transitioning = false
	transition_finished.emit()


## Fade to black
func _fade_out() -> void:
	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(_transition_overlay, "modulate:a", 1.0, FADE_DURATION)
	await _tween.finished


## Fade from black
func _fade_in() -> void:
	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(_transition_overlay, "modulate:a", 0.0, FADE_DURATION)
	await _tween.finished


## Check if currently transitioning
func is_transitioning() -> bool:
	return _is_transitioning

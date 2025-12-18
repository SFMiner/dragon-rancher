# RanchCamera.gd
# Camera controls for ranch scene
# Part of Dragon Ranch - Session 11 Ranch World Scene

extends Camera2D

## Camera settings
const MIN_ZOOM: float = 0.5
const MAX_ZOOM: float = 2.0
const ZOOM_SPEED: float = 0.1
const PAN_SPEED: float = 1.0

## Camera bounds
const BOUND_LEFT: float = -2000.0
const BOUND_RIGHT: float = 2000.0
const BOUND_TOP: float = -1500.0
const BOUND_BOTTOM: float = 1500.0

## Drag state
var is_dragging: bool = false
var drag_start_position: Vector2 = Vector2.ZERO
var camera_start_position: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Set initial zoom
	zoom = Vector2.ONE


func _input(event: InputEvent) -> void:
	# Handle mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_out()

		# Handle drag start
		elif event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_start_drag(event.position)
			else:
				_end_drag()

	# Handle mouse motion (dragging)
	elif event is InputEventMouseMotion:
		if is_dragging:
			_update_drag(event.position)


## Start camera drag
func _start_drag(mouse_position: Vector2) -> void:
	is_dragging = true
	drag_start_position = mouse_position
	camera_start_position = position


## Update camera drag
func _update_drag(mouse_position: Vector2) -> void:
	if not is_dragging:
		return

	# Calculate drag delta
	var delta: Vector2 = (drag_start_position - mouse_position) / zoom

	# Apply to camera position
	position = camera_start_position + delta

	# Clamp to bounds
	_apply_bounds()


## End camera drag
func _end_drag() -> void:
	is_dragging = false


## Zoom in
func _zoom_in() -> void:
	var new_zoom: float = zoom.x + ZOOM_SPEED
	new_zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(new_zoom, new_zoom)


## Zoom out
func _zoom_out() -> void:
	var new_zoom: float = zoom.x - ZOOM_SPEED
	new_zoom = clampf(new_zoom, MIN_ZOOM, MAX_ZOOM)
	zoom = Vector2(new_zoom, new_zoom)


## Apply camera bounds
func _apply_bounds() -> void:
	position.x = clampf(position.x, BOUND_LEFT, BOUND_RIGHT)
	position.y = clampf(position.y, BOUND_TOP, BOUND_BOTTOM)


## Handle keyboard input
func _process(delta: float) -> void:
	# Keyboard panning (optional)
	var move_vector := Vector2.ZERO

	if Input.is_action_pressed("ui_left"):
		move_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		move_vector.x += 1
	if Input.is_action_pressed("ui_up"):
		move_vector.y -= 1
	if Input.is_action_pressed("ui_down"):
		move_vector.y += 1

	if move_vector.length() > 0:
		position += move_vector.normalized() * PAN_SPEED * 300.0 * delta / zoom.x
		_apply_bounds()

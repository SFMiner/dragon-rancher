## Tutorial overlay controller
## Displays tutorial steps and highlights UI elements
extends CanvasLayer

## Reference to UI elements
@onready var backdrop: ColorRect = $Backdrop
@onready var step_card: PanelContainer = $StepCard
@onready var title_label: Label = $StepCard/VBoxContainer/TitleLabel
@onready var body_label: Label = $StepCard/VBoxContainer/BodyLabel
@onready var next_button: Button = $StepCard/VBoxContainer/ButtonContainer/NextButton
@onready var skip_button: Button = $StepCard/VBoxContainer/ButtonContainer/SkipButton
@onready var highlight_overlay: Control = $HighlightOverlay

## Current step being displayed
var current_step: TutorialStep = null

## Registry of UI anchors for highlighting
## Format: {"anchor_id": Control node}
var anchor_registry: Dictionary = {}


func _ready() -> void:
	# Start hidden
	hide()

	# Make sure backdrop doesn't block input when hidden
	if backdrop:
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Connect button signals
	next_button.pressed.connect(_on_next_pressed)
	skip_button.pressed.connect(_on_skip_pressed)

	# Connect to TutorialService
	if TutorialService:
		TutorialService.step_changed.connect(_on_step_changed)
		TutorialService.tutorial_completed.connect(_on_tutorial_completed)
		TutorialService.tutorial_skipped.connect(_on_tutorial_skipped)

	print("TutorialOverlay ready")


## Register a UI element for highlighting
func register_anchor(anchor_id: String, node: Control) -> void:
	if not node:
		push_warning("Cannot register null anchor: ", anchor_id)
		return

	anchor_registry[anchor_id] = node
	print("Registered tutorial anchor: ", anchor_id)


## Unregister a UI element
func unregister_anchor(anchor_id: String) -> void:
	anchor_registry.erase(anchor_id)


## Clear all registered anchors
func clear_anchors() -> void:
	anchor_registry.clear()


## Handle step change from TutorialService
func _on_step_changed(step: TutorialStep) -> void:
	if not step:
		hide()
		if backdrop:
			backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return

	current_step = step
	_display_step(step)
	# Enable backdrop to block input during tutorial
	if backdrop:
		backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	show()


## Display a tutorial step
func _display_step(step: TutorialStep) -> void:
	# Update text
	title_label.text = step.title
	body_label.text = step.body

	# Position card based on highlight mode and anchor
	_position_card(step)

	# Handle highlighting
	_apply_highlight(step)

	# Update button state
	# Note: For now, Next button is always enabled
	# Could be disabled until advance condition is met in future
	next_button.disabled = false


## Position the tutorial card based on step configuration
func _position_card(step: TutorialStep) -> void:
	if step.highlight_mode == "anchor" and step.anchor != "":
		var anchor_node = anchor_registry.get(step.anchor)
		if anchor_node:
			# Position card near the anchored element
			_position_card_near_anchor(anchor_node)
		else:
			# Anchor not found, center instead
			push_warning("Tutorial anchor not found: ", step.anchor)
			_position_card_center()
	else:
		# Center the card
		_position_card_center()


## Position card in center of screen
func _position_card_center() -> void:
	step_card.anchor_left = 0.5
	step_card.anchor_top = 0.5
	step_card.anchor_right = 0.5
	step_card.anchor_bottom = 0.5
	step_card.offset_left = -250.0
	step_card.offset_top = -150.0
	step_card.offset_right = 250.0
	step_card.offset_bottom = 150.0


## Position card near an anchored UI element
func _position_card_near_anchor(anchor_node: Control) -> void:
	# Get anchor global position
	var anchor_rect = anchor_node.get_global_rect()

	# Calculate card position (below and to the right of anchor)
	var card_width = 500.0
	var card_height = 300.0

	# Try to position below the anchor
	var card_x = anchor_rect.position.x
	var card_y = anchor_rect.end.y + 20.0  # 20px gap

	# Get viewport size for boundary checking
	var viewport_size = get_viewport().get_visible_rect().size

	# Keep card on screen
	if card_x + card_width > viewport_size.x:
		card_x = viewport_size.x - card_width - 20

	if card_y + card_height > viewport_size.y:
		# Position above instead
		card_y = anchor_rect.position.y - card_height - 20.0

	# Set card position (using offsets instead of anchors for absolute positioning)
	step_card.anchor_left = 0.0
	step_card.anchor_top = 0.0
	step_card.anchor_right = 0.0
	step_card.anchor_bottom = 0.0
	step_card.offset_left = card_x
	step_card.offset_top = card_y
	step_card.offset_right = card_x + card_width
	step_card.offset_bottom = card_y + card_height


## Apply highlighting based on step configuration
func _apply_highlight(step: TutorialStep) -> void:
	# Clear previous highlights
	highlight_overlay.queue_redraw()

	if step.highlight_mode == "anchor" and step.anchor != "":
		var anchor_node = anchor_registry.get(step.anchor)
		if anchor_node:
			_highlight_element(anchor_node)
		else:
			# No highlight if anchor not found
			backdrop.color = Color(0, 0, 0, 0.5)
	elif step.highlight_mode == "none":
		# No backdrop dimming
		backdrop.color = Color(0, 0, 0, 0.3)
	else:
		# Default: screen_center with dimmed backdrop
		backdrop.color = Color(0, 0, 0, 0.5)


## Highlight a specific UI element
func _highlight_element(node: Control) -> void:
	# Make backdrop darker
	backdrop.color = Color(0, 0, 0, 0.7)

	# Draw highlight rect around the element
	# We'll use queue_redraw and _draw to do this
	highlight_overlay.set_meta("highlight_rect", node.get_global_rect())
	highlight_overlay.queue_redraw()


## Draw highlight rectangle (called by Godot when queue_redraw is called)
func _draw() -> void:
	if highlight_overlay.has_meta("highlight_rect"):
		var rect = highlight_overlay.get_meta("highlight_rect")
		var expanded_rect = rect.grow(5.0)  # Add 5px margin

		# Draw a bright outline around the highlighted element
		highlight_overlay.draw_rect(expanded_rect, Color(1, 1, 0, 0.8), false, 3.0)


## Handle Next button press
func _on_next_pressed() -> void:
	# Emit event to TutorialService
	if TutorialService:
		TutorialService.process_event("next_clicked", {})


## Handle Skip button press
func _on_skip_pressed() -> void:
	if TutorialService:
		TutorialService.skip_tutorial()


## Handle tutorial completion
func _on_tutorial_completed() -> void:
	print("Tutorial completed!")
	if backdrop:
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


## Handle tutorial skipped
func _on_tutorial_skipped() -> void:
	print("Tutorial skipped!")
	if backdrop:
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


## Connect the _draw function to highlight_overlay
func _process(_delta: float) -> void:
	# Redraw highlight if needed
	if highlight_overlay.has_meta("highlight_rect"):
		# Keep redrawing to maintain highlight
		pass

# DragonDetailsPanel.gd
# Dragon details display UI controller
# Part of Dragon Ranch - Session 10 UI Logic & Interactivity

extends PanelContainer

## Currently displayed dragon
var current_dragon: DragonData = null

## Node references
@onready var dragon_name_label: Label = $VBoxContainer/DragonNameLabel
@onready var sprite_preview: TextureRect = $VBoxContainer/TextureRect
@onready var genotype_label: Label = $VBoxContainer/GenotypeLabel
@onready var phenotype_label: Label = $VBoxContainer/PhenotypeLabel
@onready var age_label: Label = $VBoxContainer/AgeLabel
@onready var life_stage_label: Label = $VBoxContainer/LifeStageLabel
@onready var health_bar: ProgressBar = $VBoxContainer/HealthProgressBar
@onready var happiness_bar: ProgressBar = $VBoxContainer/HappinessProgressBar
@onready var select_button: Button = $VBoxContainer/HBoxContainer/SelectButton
@onready var sell_button: Button = $VBoxContainer/HBoxContainer/SellButton
@onready var close_button: Button = $VBoxContainer/HBoxContainer/CloseButton


func _ready() -> void:
	# Connect button signals
	select_button.pressed.connect(_on_select_for_breeding_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	close_button.pressed.connect(close_panel)

	# Initially hide the panel
	hide()


## Show dragon details
func show_dragon(dragon: DragonData) -> void:
	if dragon == null:
		push_warning("[DragonDetailsPanel] Attempted to show null dragon")
		return

	current_dragon = dragon
	_update_display()
	show()


## Close the panel
func close_panel() -> void:
	current_dragon = null
	hide()


## Update all labels and displays
func _update_display() -> void:
	if current_dragon == null:
		return

	# Update name
	dragon_name_label.text = current_dragon.name

	# Update genotype
	genotype_label.text = "Genotype: " + _format_genotype(current_dragon.genotype)

	# Update phenotype
	phenotype_label.text = "Phenotype: " + _format_phenotype(current_dragon.phenotype)

	# Update age and life stage
	age_label.text = "Age: %d seasons (%s)" % [current_dragon.age, current_dragon.life_stage.capitalize()]
	life_stage_label.text = "Life Stage: " + current_dragon.life_stage.capitalize()

	# Update progress bars
	health_bar.value = current_dragon.health
	happiness_bar.value = current_dragon.happiness

	# Update sprite preview
	_update_sprite_preview()

	# Enable/disable buttons based on state
	_update_button_states()


## Update sprite preview
func _update_sprite_preview() -> void:
	if current_dragon == null or sprite_preview == null:
		return

	# Try to create a simple visual representation
	var placeholder_size: int = 128
	var image := Image.create(placeholder_size, placeholder_size, false, Image.FORMAT_RGBA8)

	# Get dragon color based on traits
	var color: Color = _get_dragon_color()

	# Draw simple square for now (TODO: better dragon sprites)
	for y in range(placeholder_size):
		for x in range(placeholder_size):
			var center_x: float = placeholder_size / 2.0
			var center_y: float = placeholder_size / 2.0
			var radius: float = placeholder_size / 2.5

			var dx: float = x - center_x
			var dy: float = y - center_y

			if dx * dx + dy * dy <= radius * radius:
				image.set_pixel(x, y, color)

	var texture := ImageTexture.create_from_image(image)
	sprite_preview.texture = texture


## Get dragon color based on phenotype
func _get_dragon_color() -> Color:
	if current_dragon == null or current_dragon.phenotype.is_empty():
		return Color.GRAY

	# Color based on fire trait
	if current_dragon.phenotype.has("fire"):
		if current_dragon.phenotype["fire"] == "fire":
			return Color(0.9, 0.3, 0.2)  # Red for fire
		else:
			return Color(0.6, 0.6, 0.6)  # Gray for no fire

	return Color.GRAY


## Format genotype for display
func _format_genotype(genotype: Dictionary) -> String:
	var parts: Array[String] = []

	for trait_key in genotype.keys():
		var alleles: Array = genotype[trait_key]
		if alleles.size() >= 2:
			parts.append("%s%s" % [alleles[0], alleles[1]])

	return ", ".join(parts) if parts.size() > 0 else "No traits"


## Format phenotype for display
func _format_phenotype(phenotype: Dictionary) -> String:
	var parts: Array[String] = []

	for trait_key in phenotype.keys():
		var value: String = phenotype[trait_key]
		parts.append(value.capitalize())

	return ", ".join(parts) if parts.size() > 0 else "No traits"


## Update button states based on dragon state
func _update_button_states() -> void:
	if current_dragon == null:
		return

	# Can only breed adults
	var can_breed: bool = Lifecycle.can_breed(current_dragon)
	select_button.disabled = not can_breed

	# Can always sell (but maybe add confirmation)
	sell_button.disabled = false


## Select for breeding button pressed
func _on_select_for_breeding_pressed() -> void:
	if current_dragon == null:
		return

	# Find BreedingPanel and open it with this dragon pre-selected
	var breeding_panel = get_tree().root.find_child("BreedingPanel", true, false)
	if breeding_panel and breeding_panel.has_method("open_panel"):
		breeding_panel.open_panel()

		# Pre-select this dragon as parent A
		if breeding_panel.has_method("set_parent_a"):
			breeding_panel.set_parent_a(current_dragon)
		else:
			# Fallback: set property directly
			breeding_panel.selected_parent_a = current_dragon
			if breeding_panel.has_method("_update_ui"):
				breeding_panel._update_ui()
			if breeding_panel.has_method("_update_predictions"):
				breeding_panel._update_predictions()

	close_panel()


## Sell button pressed
func _on_sell_pressed() -> void:
	if current_dragon == null:
		return

	# Find OrdersPanel and open it in "fulfill" mode with this dragon
	var orders_panel = get_tree().root.find_child("OrdersPanel", true, false)
	if orders_panel and orders_panel.has_method("open_panel"):
		# TODO: Pass dragon to fulfill mode
		orders_panel.open_panel()

	close_panel()

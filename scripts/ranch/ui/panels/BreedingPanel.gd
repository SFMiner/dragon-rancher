# BreedingPanel.gd
# Breeding workflow UI controller
# Part of Dragon Ranch - Session 10 UI Logic & Interactivity

extends PanelContainer

## Selected parents
var selected_parent_a: DragonData = null
var selected_parent_b: DragonData = null

## Node references
@onready var parent_a_button: Button = $VBoxContainer/HBoxContainer/ParentA_Button
@onready var parent_a_label: Label = $VBoxContainer/HBoxContainer/ParentA_Label
@onready var parent_b_button: Button = $VBoxContainer/HBoxContainer/ParentB_Button
@onready var parent_b_label: Label = $VBoxContainer/HBoxContainer/ParentB_Label
@onready var prediction_results: VBoxContainer = $VBoxContainer/PredictionResults
@onready var breed_button: Button = $VBoxContainer/BreedButton


func _ready() -> void:
	# Connect button signals
	parent_a_button.pressed.connect(_on_select_parent_a_pressed)
	parent_b_button.pressed.connect(_on_select_parent_b_pressed)
	breed_button.pressed.connect(_on_breed_pressed)

	# Initially hide the panel
	hide()


## Open the breeding panel
func open_panel() -> void:
	# Reset selections
	selected_parent_a = null
	selected_parent_b = null
	_update_ui()
	show()
	AudioManager.play_sfx("ui_confirm.ogg")


## Close the breeding panel
func close_panel() -> void:
	hide()


## Select parent A button pressed
func _on_select_parent_a_pressed() -> void:
	AudioManager.play_sfx("ui_click.ogg")
	var adult_dragons: Array[DragonData] = RanchState.get_adult_dragons()

	if adult_dragons.is_empty():
		_show_notification("No adult dragons available for breeding!", true)
		return

	# TODO: Show dragon selection dialog
	# For now, select first adult dragon
	if adult_dragons.size() > 0:
		selected_parent_a = adult_dragons[0]
		_update_ui()
		_update_predictions()


## Select parent B button pressed
func _on_select_parent_b_pressed() -> void:
	AudioManager.play_sfx("ui_click.ogg")
	var adult_dragons: Array[DragonData] = RanchState.get_adult_dragons()

	if adult_dragons.is_empty():
		_show_notification("No adult dragons available for breeding!", true)
		return

	# TODO: Show dragon selection dialog
	# For now, select second adult dragon if available
	if adult_dragons.size() > 1:
		selected_parent_b = adult_dragons[1]
		_update_ui()
		_update_predictions()


## Update UI based on current selections
func _update_ui() -> void:
	# Update parent A display
	if selected_parent_a:
		parent_a_button.text = selected_parent_a.name
		parent_a_label.text = _format_genotype(selected_parent_a.genotype)
	else:
		parent_a_button.text = "Select Parent A"
		parent_a_label.text = "Parent A genotype"

	# Update parent B display
	if selected_parent_b:
		parent_b_button.text = selected_parent_b.name
		parent_b_label.text = _format_genotype(selected_parent_b.genotype)
	else:
		parent_b_button.text = "Select Parent B"
		parent_b_label.text = "Parent B genotype"

	# Enable/disable breed button
	breed_button.disabled = not (selected_parent_a and selected_parent_b)

	# Emit tutorial event if both parents selected
	if selected_parent_a and selected_parent_b and TutorialService:
		TutorialService.process_event("both_parents_selected", {})


## Update offspring predictions
func _update_predictions() -> void:
	# Clear existing predictions
	for child in prediction_results.get_children():
		child.queue_free()

	# If both parents selected, show predictions
	if selected_parent_a and selected_parent_b:
		# Check if breeding is allowed
		var can_breed: Dictionary = GeneticsEngine.can_breed(selected_parent_a, selected_parent_b)

		if not can_breed["success"]:
			var error_label := Label.new()
			error_label.text = "Cannot breed: " + can_breed["reason"]
			error_label.add_theme_color_override("font_color", Color.RED)
			prediction_results.add_child(error_label)
			breed_button.disabled = true
			return

		# Generate predictions for each trait
		var predictions: Dictionary = _calculate_predictions()

		for trait_key in predictions.keys():
			var trait_predictions: Dictionary = predictions[trait_key]

			var trait_label := Label.new()
			trait_label.text = trait_key.capitalize() + ":"
			trait_label.add_theme_font_size_override("font_size", 14)
			prediction_results.add_child(trait_label)

			for phenotype in trait_predictions.keys():
				var probability: float = trait_predictions[phenotype]
				var prob_label := Label.new()
				prob_label.text = "  %d%% %s" % [int(probability * 100), phenotype]
				prob_label.add_theme_font_size_override("font_size", 12)
				prediction_results.add_child(prob_label)


## Calculate breeding predictions
func _calculate_predictions() -> Dictionary:
	if not selected_parent_a or not selected_parent_b:
		return {}

	var predictions: Dictionary = {}

	# Get all trait keys
	var trait_keys: Array = selected_parent_a.genotype.keys()

	for trait_key in trait_keys:
		# Generate Punnett square for this trait
		var outcomes: Array = GeneticsEngine.generate_punnett_square(
			selected_parent_a,
			selected_parent_b,
			trait_key
		)
		
		var punnett: Dictionary = {"outcomes": outcomes}

		# Count phenotypes
		var phenotype_counts: Dictionary = {}
		var total_outcomes: int = 0

		for genotype in punnett.get("outcomes", []):
			total_outcomes += 1

			# Calculate phenotype for this genotype
			var test_genotype: Dictionary = {trait_key: genotype}
			var phenotype_dict: Dictionary = GeneticsEngine.calculate_phenotype(test_genotype)
			var phenotype: String = phenotype_dict.get(trait_key, "unknown")

			if not phenotype_counts.has(phenotype):
				phenotype_counts[phenotype] = 0
			phenotype_counts[phenotype] += 1

		# Convert counts to probabilities
		var trait_predictions: Dictionary = {}
		for phenotype in phenotype_counts.keys():
			var count: int = phenotype_counts[phenotype]
			trait_predictions[phenotype] = float(count) / float(total_outcomes)

		predictions[trait_key] = trait_predictions

	return predictions


## Format genotype for display
func _format_genotype(genotype: Dictionary) -> String:
	var parts: Array[String] = []

	for trait_key in genotype.keys():
		var alleles: Array = genotype[trait_key]
		if alleles.size() >= 2:
			parts.append("%s: %s%s" % [trait_key.capitalize(), alleles[0], alleles[1]])

	return ", ".join(parts) if parts.size() > 0 else "No traits"


## Breed button pressed
func _on_breed_pressed() -> void:
	AudioManager.play_sfx("ui_click.ogg")
	if not selected_parent_a or not selected_parent_b:
		return

	# Check if Breeding Pen facility exists
	var has_breeding_pen: bool = false
	for facility in RanchState.facilities.values():
		if facility.type == "breeding_pen":
			has_breeding_pen = true
			break

	if not has_breeding_pen:
		_show_notification("You need a Breeding Pen to breed dragons!", true)
		return

	# Create egg
	var egg_id: String = RanchState.create_egg(selected_parent_a.id, selected_parent_b.id)

	if egg_id.is_empty():
		_show_notification("Breeding failed! Check if dragons are eligible.", true)
		return

	# Success!
	_show_notification("Breeding successful! Egg will hatch in %d seasons." % RanchState.eggs[egg_id].incubation_seasons_remaining)

	# Close panel
	close_panel()


## Show notification message
func _show_notification(message: String, is_error: bool = false) -> void:
	if is_error:
		AudioManager.play_sfx("ui_error.ogg")
	# Find NotificationsPanel if it exists
	var notifications_panel = get_tree().root.find_child("NotificationsPanel", true, false)
	if notifications_panel and notifications_panel.has_method("show_notification"):
		notifications_panel.show_notification(message)
	else:
		print("[BreedingPanel] Notification: " + message)

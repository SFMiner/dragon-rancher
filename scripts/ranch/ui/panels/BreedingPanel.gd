# BreedingPanel.gd
# Breeding workflow UI controller
# Part of Dragon Ranch - Session 10 UI Logic & Interactivity

extends PanelContainer

## Selected parents
var selected_parent_a: DragonData = null
var selected_parent_b: DragonData = null

## P0 PERFORMANCE: Cache Punnett square results to avoid recalculation
var _cached_predictions: Dictionary = {}
var _cached_parent_a_id: String = ""
var _cached_parent_b_id: String = ""

## Node references
@onready var parent_a_button: Button = $VBoxContainer/HBoxContainer/ParentA_Button
@onready var parent_a_label: Label = $VBoxContainer/HBoxContainer/ParentA_Label
@onready var parent_b_button: Button = $VBoxContainer/HBoxContainer/ParentB_Button
@onready var parent_b_label: Label = $VBoxContainer/HBoxContainer/ParentB_Label
@onready var prediction_results: VBoxContainer = $VBoxContainer/PredictionResults
@onready var breed_button: Button = $VBoxContainer/BreedButton
@onready var parent_select_popup: PopupPanel = $ParentSelectPopup
@onready var parent_select_title: Label = $ParentSelectPopup/VBoxContainer/TitleLabel
@onready var parent_select_list: ItemList = $ParentSelectPopup/VBoxContainer/ParentList
@onready var parent_select_confirm: Button = $ParentSelectPopup/VBoxContainer/ButtonRow/SelectButton
@onready var parent_select_cancel: Button = $ParentSelectPopup/VBoxContainer/ButtonRow/CancelButton
@onready var parent_select_container: VBoxContainer = $ParentSelectPopup/VBoxContainer

var _selecting_parent_key: String = ""
var _selectable_dragons: Array[DragonData] = []
var _selectable_disabled: Array[bool] = []


func _ready() -> void:
	# Connect button signals
	parent_a_button.pressed.connect(_on_select_parent_a_pressed)
	parent_b_button.pressed.connect(_on_select_parent_b_pressed)
	breed_button.pressed.connect(_on_breed_pressed)
	parent_select_confirm.pressed.connect(_on_parent_select_confirm_pressed)
	parent_select_cancel.pressed.connect(_on_parent_select_cancel_pressed)
	parent_select_list.item_activated.connect(_on_parent_item_activated)
	parent_select_list.item_selected.connect(_on_parent_item_selected)

	# Keep popup sizing from affecting the panel layout
	var root := get_tree().root
	if parent_select_popup.get_parent() != root:
		parent_select_popup.get_parent().remove_child(parent_select_popup)
		root.add_child(parent_select_popup)

	# Initially hide the panel
	hide()


## Open the breeding panel
func open_panel() -> void:
	# Reset selections
	selected_parent_a = null
	selected_parent_b = null
	# P0 PERFORMANCE: Clear cache when opening panel
	_cached_predictions.clear()
	_cached_parent_a_id = ""
	_cached_parent_b_id = ""
	_update_ui()
	show()
	AudioManager.play_sfx("ui_confirm.ogg")

## Close the breeding panel
func close_panel() -> void:
	hide()


## Select parent A button pressed
func _on_select_parent_a_pressed() -> void:
	AudioManager.play_sfx("ui_click.ogg")
	_open_parent_selection("a")


## Select parent B button pressed
func _on_select_parent_b_pressed() -> void:
	AudioManager.play_sfx("ui_click.ogg")
	_open_parent_selection("b")


func _open_parent_selection(parent_key: String) -> void:
	var adult_dragons: Array[DragonData] = RanchState.get_adult_dragons()
	if adult_dragons.is_empty():
		_show_notification("No adult dragons available for breeding!", true)
		return

	_selecting_parent_key = parent_key
	parent_select_title.text = "Select Parent A" if parent_key == "a" else "Select Parent B"
	_build_parent_select_list(adult_dragons)
	parent_select_confirm.disabled = true
	parent_select_popup.popup_centered()


func _build_parent_select_list(adult_dragons: Array[DragonData]) -> void:
	parent_select_list.clear()
	_selectable_dragons = adult_dragons.duplicate()
	_selectable_dragons.sort_custom(func(a, b): return a.name.to_lower() < b.name.to_lower())
	_selectable_disabled = []

	for dragon in _selectable_dragons:
		var label := "%s  %s" % [dragon.name, _format_genotype_pairs(dragon.genotype)]
		var disabled := false

		if dragon.breedings_this_season >= 2:
			label += " (limit reached)"
			disabled = true

		if _selecting_parent_key == "a" and selected_parent_b and _is_same_dragon(dragon, selected_parent_b):
			label += " (already selected)"
			disabled = true
		elif _selecting_parent_key == "b" and selected_parent_a and _is_same_dragon(dragon, selected_parent_a):
			label += " (already selected)"
			disabled = true

		var index := parent_select_list.add_item(label)
		parent_select_list.set_item_disabled(index, disabled)
		_selectable_disabled.append(disabled)

	_resize_parent_select_popup()


func _is_same_dragon(a: DragonData, b: DragonData) -> bool:
	if a == b:
		return true
	if a == null or b == null:
		return false
	if not a.id.is_empty() and a.id == b.id:
		return true
	return false


func _format_genotype_pairs(genotype: Dictionary) -> String:
	if genotype.is_empty():
		return "--"

	var parts: Array[String] = []
	var trait_keys: Array = _get_ordered_trait_keys(genotype)

	for trait_key in trait_keys:
		var alleles: Array = _get_display_alleles(genotype, trait_key)
		if alleles.size() >= 2:
			var genotype_pair: String = GeneticsResolvers.normalize_genotype(alleles)
			parts.append(genotype_pair)

	return "".join(parts) if parts.size() > 0 else "--"


func _on_parent_item_selected(index: int) -> void:
	if index < 0 or index >= _selectable_disabled.size():
		parent_select_confirm.disabled = true
		return
	parent_select_confirm.disabled = _selectable_disabled[index]


func _on_parent_item_activated(index: int) -> void:
	if index < 0 or index >= _selectable_dragons.size():
		return
	if _selectable_disabled[index]:
		return
	_apply_parent_selection(_selectable_dragons[index])


func _on_parent_select_confirm_pressed() -> void:
	var selected_indices: PackedInt32Array = parent_select_list.get_selected_items()
	if selected_indices.is_empty():
		return
	var index: int = selected_indices[0]
	if index < 0 or index >= _selectable_dragons.size():
		return
	if _selectable_disabled[index]:
		return
	_apply_parent_selection(_selectable_dragons[index])


func _on_parent_select_cancel_pressed() -> void:
	parent_select_popup.hide()


func _apply_parent_selection(dragon: DragonData) -> void:
	if _selecting_parent_key == "a":
		selected_parent_a = dragon
	else:
		selected_parent_b = dragon
	parent_select_popup.hide()
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

	# P0 PERFORMANCE: Check cache first to avoid expensive recalculation
	var parent_a_id: String = selected_parent_a.id
	var parent_b_id: String = selected_parent_b.id

	if _cached_parent_a_id == parent_a_id and _cached_parent_b_id == parent_b_id:
		# Cache hit - return cached result
		return _cached_predictions

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

		for outcome in punnett.get("outcomes", []):
			total_outcomes += 1

			# Use Punnett outcome phenotype data directly to avoid invalid allele warnings
			var phenotype: String = "unknown"
			if outcome is Dictionary:
				var phenotype_data = outcome.get("phenotype_data", null)
				if phenotype_data is Dictionary:
					phenotype = phenotype_data.get("name", "unknown")
				elif outcome.get("phenotype") is String:
					phenotype = outcome.get("phenotype")

			if not phenotype_counts.has(phenotype):
				phenotype_counts[phenotype] = 0
			phenotype_counts[phenotype] += 1

		# Convert counts to probabilities
		var trait_predictions: Dictionary = {}
		for phenotype in phenotype_counts.keys():
			var count: int = phenotype_counts[phenotype]
			trait_predictions[phenotype] = float(count) / float(total_outcomes)

		predictions[trait_key] = trait_predictions

	# P0 PERFORMANCE: Store in cache
	_cached_predictions = predictions
	_cached_parent_a_id = parent_a_id
	_cached_parent_b_id = parent_b_id

	return predictions


## Format genotype for display
func _format_genotype(genotype: Dictionary) -> String:
	var parts: Array[String] = []

	for trait_key in _get_ordered_trait_keys(genotype):
		var alleles: Array = _get_display_alleles(genotype, trait_key)
		if alleles.size() >= 2:
			parts.append("%s: %s%s" % [trait_key.capitalize(), alleles[0], alleles[1]])

	return ", ".join(parts) if parts.size() > 0 else "No traits"


func _get_ordered_trait_keys(genotype: Dictionary) -> Array:
	var ordered: Array = []
	if genotype.has("size_S") or genotype.has("size_s"):
		ordered.append("size_S")
	if genotype.has("size_G") or genotype.has("size_g"):
		ordered.append("size_G")

	var rest: Array = genotype.keys()
	rest.erase("size_S")
	rest.erase("size_G")
	rest.erase("size_s")
	rest.erase("size_g")
	rest.sort()
	ordered.append_array(rest)
	return ordered


func _get_display_alleles(genotype: Dictionary, trait_key: String) -> Array:
	if genotype.has(trait_key):
		return GeneticsResolvers.get_trait_alleles(genotype, trait_key)

	var lower_key: String = trait_key.to_lower()
	if lower_key != trait_key and genotype.has(lower_key):
		return GeneticsResolvers.get_trait_alleles(genotype, lower_key)

	return []


func _resize_parent_select_popup() -> void:
	var max_len: int = 0
	var item_count: int = parent_select_list.get_item_count()
	for i in range(item_count):
		var text := parent_select_list.get_item_text(i)
		max_len = max(max_len, text.length())

	var padding: int = 40
	var approx_char_width: int = 8
	var min_width: int = 220
	var max_width: int = 520
	var desired_width: int = clamp(padding + (max_len * approx_char_width) + 20, min_width, max_width)

	if parent_select_popup.size.x < desired_width:
		parent_select_popup.size = Vector2i(desired_width, parent_select_popup.size.y)
	var inner_width: float = float(desired_width - padding)
	parent_select_container.custom_minimum_size.x = inner_width
	parent_select_list.custom_minimum_size.x = inner_width


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
	var egg_ids: Array[String] = RanchState.create_egg(selected_parent_a.id, selected_parent_b.id)

	if egg_ids.is_empty():
		_show_notification("Breeding failed! Check if dragons are eligible.", true)
		return

	# Success!
	var min_incubation: int = 999
	var max_incubation: int = 0
	for egg_id in egg_ids:
		if RanchState.eggs.has(egg_id):
			var incubation: int = RanchState.eggs[egg_id].incubation_seasons_remaining
			min_incubation = min(min_incubation, incubation)
			max_incubation = max(max_incubation, incubation)

	var incubation_text: String = ""
	if min_incubation == max_incubation:
		incubation_text = "%d seasons" % min_incubation
	else:
		incubation_text = "%d-%d seasons" % [min_incubation, max_incubation]

	_show_notification("Breeding successful! %d eggs will hatch in %s." % [egg_ids.size(), incubation_text])

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


func _on_close_button_pressed() -> void:
	close_panel()

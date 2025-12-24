# DragonListPanel.gd
# Scrollable roster of all dragons with sortable columns
# Part of Dragon Ranch - Session UI Panels

extends PanelContainer

const NAME_SORT_KEY := "name"

@onready var header_container: HBoxContainer = $VBoxContainer/HeaderContainer
@onready var rows_container: VBoxContainer = $VBoxContainer/ScrollContainer/RowsContainer

var sort_key: String = NAME_SORT_KEY
var sort_ascending: bool = true
var trait_keys: Array[String] = []
var trait_display_names: Dictionary = {}


func _ready() -> void:
	_init_traits()
	_rebuild_header_buttons()
	refresh_rows()
	hide()


func open_panel() -> void:
	refresh_rows()
	show()
	AudioManager.play_sfx("ui_confirm.ogg")


func close_panel() -> void:
	hide()
	AudioManager.play_sfx("ui_click.ogg")


func refresh_rows() -> void:
	for child in rows_container.get_children():
		child.queue_free()

	var dragons: Array[DragonData] = RanchState.get_all_dragons()

	if dragons.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No dragons available."
		rows_container.add_child(empty_label)
		return

	dragons.sort_custom(_compare_dragons)

	for dragon in dragons:
		rows_container.add_child(_build_row(dragon))

	_rebuild_header_buttons()


func _init_traits() -> void:
	if not TraitDB:
		push_warning("[DragonListPanel] TraitDB not available; showing no trait columns")
		return

	var t_keys : Array = _order_trait_keys(TraitDB.get_all_trait_keys())
	for key in t_keys:
		trait_keys.append(key) 

	trait_display_names.clear()
	for trait_key in trait_keys:
		var trait_def: TraitDef = TraitDB.get_trait_def(trait_key)
		trait_display_names[trait_key] = trait_def.name if trait_def else trait_key.capitalize()


func _rebuild_header_buttons() -> void:
	for child in header_container.get_children():
		child.queue_free()

	header_container.add_child(_create_header_button("Name", NAME_SORT_KEY, 140))

	for trait_key in trait_keys:
		var display_name: String = trait_display_names.get(trait_key, trait_key.capitalize())
		header_container.add_child(_create_header_button(display_name, trait_key, 120))


func _create_header_button(label_text: String, key: String, min_width: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size.x = float(min_width)

	var indicator: String = ""
	if sort_key == key:
		indicator = " (asc)" if sort_ascending else " (desc)"

	button.text = label_text + indicator
	button.pressed.connect(_on_sort_button_pressed.bind(key))
	return button


func _on_sort_button_pressed(key: String) -> void:
	if sort_key == key:
		sort_ascending = not sort_ascending
	else:
		sort_key = key
		sort_ascending = true

	refresh_rows()


func _compare_dragons(a: DragonData, b: DragonData) -> bool:
	var value_a = _get_sort_value(a, sort_key)
	var value_b = _get_sort_value(b, sort_key)

	if value_a == value_b:
		return a.name.to_lower() < b.name.to_lower()

	return value_a < value_b if sort_ascending else value_a > value_b


func _get_sort_value(dragon: DragonData, key: String):
	match key:
		NAME_SORT_KEY:
			return dragon.name.to_lower()
		_:
			return _get_genotype_string(dragon, key).to_lower()


func _build_row(dragon: DragonData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = dragon.name
	name_label.custom_minimum_size.x = 140
	row.add_child(name_label)

	for trait_key in trait_keys:
		var genotype_label := Label.new()
		genotype_label.text = _get_genotype_string(dragon, trait_key)
		genotype_label.custom_minimum_size.x = 120
		row.add_child(genotype_label)

	return row


func _get_genotype_string(dragon: DragonData, trait_key: String) -> String:
	if dragon == null:
		return "--"

	var alleles: Array = _get_display_alleles(dragon.genotype, trait_key)
	if alleles.size() >= 2:
		return GeneticsResolvers.normalize_genotype(alleles)

	return "--"


func _order_trait_keys(keys: Array) -> Array:
	var ordered: Array = []
	if "size_S" in keys:
		ordered.append("size_S")
	if "size_G" in keys:
		ordered.append("size_G")

	var rest: Array = keys.duplicate()
	rest.erase("size_S")
	rest.erase("size_G")
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


func _on_close_button_pressed() -> void:
	close_panel()

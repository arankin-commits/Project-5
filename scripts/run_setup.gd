extends CanvasLayer

signal closed
signal start_requested(modifiers: Dictionary)

var robot_choice: OptionButton
var route_choice: OptionButton
var route_note: Label
var overclock_checkbox: CheckBox
var reinforcements_checkbox: CheckBox
var fragile_checkbox: CheckBox
var start_button: Button

func _ready() -> void:
	_build_ui()
	visible = false

func open_setup() -> void:
	visible = true

func close_setup() -> void:
	visible = false
	closed.emit()

func selected_modifiers() -> Dictionary:
	return {
		"overclocked_enemies": overclock_checkbox.button_pressed,
		"reinforcements": reinforcements_checkbox.button_pressed,
		"fragile_frame": fragile_checkbox.button_pressed
	}

func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.01, 0.02, 0.82)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 560)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("211c20")
	style.border_color = Color("c8994d")
	style.set_border_width_all(3)
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = "SYNC POD — START A RUN"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("ffd488"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "Close [E]"
	close_button.pressed.connect(close_setup)
	header.add_child(close_button)
	var robot_label := Label.new()
	robot_label.text = "Robot type"
	robot_label.add_theme_font_size_override("font_size", 21)
	content.add_child(robot_label)
	robot_choice = OptionButton.new()
	robot_choice.add_item("Medium | Speed 100% | Health 100% | Damage 100% | Backstab 2x", 0)
	robot_choice.add_item("Light | Speed 125% | Health 60% | Damage 70% | Backstab 6x", 1)
	robot_choice.add_item("Heavy | Speed 70% | Health 150% | Damage 130% | Backstab 2x", 2)
	robot_choice.select(0)
	robot_choice.custom_minimum_size.y = 46
	content.add_child(robot_choice)
	route_choice = OptionButton.new()
	route_choice.add_item("Above ground | Confront the upper brass")
	route_choice.add_item("Below ground | Investigate tech")
	route_choice.select(1)
	route_choice.custom_minimum_size.y = 46
	route_choice.item_selected.connect(_update_route)
	content.add_child(route_choice)
	var modifier_label := Label.new()
	modifier_label.text = "Difficulty modifiers"
	modifier_label.add_theme_font_size_override("font_size", 21)
	content.add_child(modifier_label)
	overclock_checkbox = CheckBox.new()
	overclock_checkbox.text = "Overclocked enemies    +25% enemy speed"
	content.add_child(overclock_checkbox)
	reinforcements_checkbox = CheckBox.new()
	reinforcements_checkbox.text = "Reinforcements    +2 crawlers per chamber"
	content.add_child(reinforcements_checkbox)
	fragile_checkbox = CheckBox.new()
	fragile_checkbox.text = "Fragile frame    -30 maximum hull"
	content.add_child(fragile_checkbox)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(spacer)
	route_note = Label.new()
	route_note.add_theme_font_size_override("font_size",16)
	route_note.add_theme_color_override("font_color", Color("d7b981"))
	content.add_child(route_note)
	start_button = Button.new()
	start_button.text = "START ROGUELIKE RUN"
	start_button.custom_minimum_size.y = 52
	start_button.pressed.connect(_on_start_pressed)
	content.add_child(start_button)
	_update_route(route_choice.selected)

func selected_route() -> String:
	return "above_ground" if route_choice.selected == 0 else "below_ground"

func _update_route(index: int) -> void:
	start_button.disabled = index == 0
	if index == 0:
		route_note.text = "Above-ground route is not yet available."
	else:
		route_note.text = "Investigate tech below ground."

func selected_robot() -> String:
	return ["medium", "light", "heavy"][robot_choice.selected]

func _on_start_pressed() -> void:
	if selected_route() == "above_ground":
		return
	start_requested.emit(selected_modifiers())

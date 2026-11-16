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
	robot_choice.grab_focus()

func close_setup() -> void:
	visible = false
	closed.emit()

func selected_modifiers() -> Dictionary:
	return {
		"overclocked_enemies": overclock_checkbox.button_pressed,
		"reinforcements": reinforcements_checkbox.button_pressed,
		"fragile_frame": fragile_checkbox.button_pressed
	}

const UI = preload("res://scripts/brass_ui.gd")
var canvas: Control
var robot_stats: Label
var route_buttons: Array[Button] = []

func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color("100d0a")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	canvas = Control.new()
	add_child(canvas)
	get_viewport().size_changed.connect(_fit)
	_fit()
	UI.picture(canvas,"res://HUD/Steampunk Sync Pod Interface.png",Rect2(0,0,1280,707))
	UI.button(canvas,"Back [E]",Rect2(48,597,195,65),close_setup)
	# Keep the pod and portrait illustration; all changing values are real controls.
	robot_choice = OptionButton.new()
	for robot in ["MEDIUM", "LIGHT", "HEAVY"]:
		robot_choice.add_item(robot)
	robot_choice.position = Vector2(267,415)
	robot_choice.size = Vector2(260,48)
	robot_choice.add_theme_stylebox_override("normal",UI.style())
	robot_choice.add_theme_font_size_override("font_size",24)
	canvas.add_child(robot_choice)
	robot_choice.item_selected.connect(_robot_changed)
	var stats_panel := Panel.new()
	stats_panel.position = Vector2(264,469)
	stats_panel.size = Vector2(264,150)
	stats_panel.add_theme_stylebox_override("panel",UI.style())
	canvas.add_child(stats_panel)
	robot_stats = UI.label(canvas,"",Rect2(282,479,240,130),18)
	_robot_changed(0)
	UI.button(canvas,"<",Rect2(256,311,40,44),_cycle_robot.bind(-1))
	UI.button(canvas,">",Rect2(500,311,40,44),_cycle_robot.bind(1))
	route_choice = OptionButton.new()
	route_choice.add_item("Above ground")
	route_choice.add_item("Below ground")
	route_choice.select(1)
	route_choice.hide()
	canvas.add_child(route_choice)
	route_choice.item_selected.connect(_update_route)
	for index in 2:
		var b := UI.button(canvas,"ABOVE GROUND / LOCKED" if index == 0 else "BELOW GROUND",Rect2(586,320+index*207,284,42),_select_route.bind(index))
		b.add_theme_font_size_override("font_size",18)
		route_buttons.append(b)
	var modifiers := Panel.new()
	modifiers.position = Vector2(912,177)
	modifiers.size = Vector2(320,375)
	modifiers.add_theme_stylebox_override("panel",UI.style())
	canvas.add_child(modifiers)
	overclock_checkbox = _modifier("Overclocked enemies", "+25% enemy speed", 195)
	reinforcements_checkbox = _modifier("Reinforcements", "+2 crawlers per chamber", 305)
	fragile_checkbox = _modifier("Fragile frame", "-30 maximum hull", 415)
	route_note = UI.label(canvas,"",Rect2(570,579,330,50),16)
	route_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_button = UI.button(canvas,"START RUN",Rect2(923,575,305,86),_on_start_pressed)
	start_button.add_theme_font_size_override("font_size",32)
	_update_route(1)

func _fit() -> void:
	UI.fit(canvas,get_viewport().get_visible_rect().size)

func _modifier(heading: String, detail: String, y: float) -> CheckBox:
	var check := CheckBox.new()
	check.text = heading
	check.position = Vector2(930,y)
	check.size = Vector2(285,52)
	check.add_theme_font_size_override("font_size",21)
	check.add_theme_color_override("font_color",Color("ffdc9f"))
	canvas.add_child(check)
	UI.label(canvas,detail,Rect2(944,y+52,275,30),17)
	return check

func _select_route(index: int) -> void:
	route_choice.select(index)
	_update_route(index)

func _robot_changed(index: int) -> void:
	robot_stats.text = ["Speed         100%\nHull             100%\nPower          100%\nBackstab       2x", "Speed         125%\nHull               60%\nPower            70%\nBackstab       6x", "Speed           70%\nHull             150%\nPower          130%\nBackstab       2x"][index]

func selected_route() -> String:
	return "above_ground" if route_choice.selected == 0 else "below_ground"

func _update_route(index: int) -> void:
	start_button.disabled = index == 0
	for i in route_buttons.size():
		route_buttons[i].add_theme_stylebox_override("normal",UI.style(Color("174345") if i == index else Color("241b14"),Color("73e6e0") if i == index else Color("b67e39")))
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

func _cycle_robot(direction: int) -> void:
	var index := posmod(robot_choice.selected + direction,3)
	robot_choice.select(index)
	_robot_changed(index)

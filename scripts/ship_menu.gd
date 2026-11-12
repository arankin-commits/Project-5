extends CanvasLayer

var menu: Control
var previous_focus: Control

func _ready() -> void:
	name = "ShipMenu"
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var button := Button.new()
	button.text = "Menu [Esc]"
	button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	button.offset_left = -170
	button.offset_top = 18
	button.offset_right = -25
	button.offset_bottom = 58
	button.pressed.connect(open_menu)
	root.add_child(button)
	menu = preload("res://scripts/run_menu.gd").new()
	menu.can_give_up = false
	root.add_child(menu)
	menu.resume_requested.connect(resume)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if menu.visible:
			menu.back()
		else:
			open_menu()
		get_viewport().set_input_as_handled()

func open_menu() -> void:
	if menu.visible:
		return
	previous_focus = get_viewport().gui_get_focus_owner()
	get_tree().paused = true
	menu.show_menu()

func resume() -> void:
	menu.hide()
	get_tree().paused = false
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():
		previous_focus.grab_focus()

func _exit_tree() -> void:
	if is_instance_valid(menu) and menu.visible:
		get_tree().paused = false

extends Control

const UI = preload("res://scripts/brass_ui.gd")
var canvas: Control
var settings_menu: Control
var page := "title"
var status: Label
var delete_modal: Control = null

func _ready() -> void:
	get_tree().paused = false
	get_node("/root/BackgroundMusic").play_ship()
	canvas = Control.new()
	add_child(canvas)
	resized.connect(_fit)
	_fit()
	show_title()
	settings_menu = preload("res://scripts/run_menu.gd").new()
	add_child(settings_menu)
	settings_menu.resume_requested.connect(func(): settings_menu.hide())
	settings_menu.front_end = true

func _fit() -> void:
	UI.fit(canvas, size)

func _clear() -> void:
	delete_modal = null
	for child in canvas.get_children():
		canvas.remove_child(child)
		child.queue_free()

func show_title() -> void:
	_clear()
	page = "title"
	UI.picture(canvas, "res://HUD/Steampunk Skyship Game Menu.png", Rect2(0,0,1280,720))
	# Transparent real controls preserve the reference's illustrated buttons.
	for entry in [["Play", Rect2(106,207,326,102), show_slots], ["Settings", Rect2(113,345,312,85), _settings], ["Quit", Rect2(114,464,308,85), _quit]]:
		var b := UI.button(canvas, "", entry[1], entry[2])
		b.tooltip_text = entry[0]
		b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("hover", UI.style(Color(1,0.7,0.2,0.12),Color("ffd080")))
		if entry[0] == "Play":
			b.grab_focus()
	UI.label(canvas, "FLYING LIBERTY", Rect2(70,54,600,60), 42)
	UI.label(canvas, "A SKYBOUND ROGUELITE", Rect2(74,112,440,30), 18)

func show_slots() -> void:
	_clear()
	page = "slots"
	UI.picture(canvas, "res://HUD/Steampunk Skyship Game Menu.png", Rect2(0,0,1280,720))
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.025,0.025,0.93)
	shade.size = Vector2(1280,720)
	canvas.add_child(shade)
	UI.label(canvas,"SELECT SAVE FILE",Rect2(80,40,900,60),38)
	UI.label(canvas,"Choose your ship's permanent progression. Expeditions begin at the sync pod.",Rect2(80,104,1100,35),19)
	var saves = get_node("/root/SaveSlots")
	for i in range(1,4):
		var y := 160 + (i-1)*148
		UI.picture(canvas,"res://HUD/Steampunk Roguelike Save Selection.png",Rect2(65,y,1150,140),Rect2(52,254+(i-1)*280,1020,265))
		var cover := Panel.new()
		cover.position = Vector2(345,y+37)
		cover.size = Vector2(850,83)
		cover.add_theme_stylebox_override("panel",UI.style())
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(cover)
		var data: Dictionary = saves.info(i)
		var is_empty: bool = saves.is_slot_empty(i)
		var summary := "%d XP   /   %d upgrades   /   %d victories" % [data.xp,maxi(0,data.skills-1),data.victories] if not is_empty else "Empty slot  /  A new adventure awaits"
		UI.label(canvas,summary,Rect2(365,y+58,490,40),19)
		var slot_btn := Button.new()
		slot_btn.position = Vector2(65, y)
		slot_btn.size = Vector2(790, 140)
		slot_btn.flat = true
		slot_btn.focus_mode = Control.FOCUS_NONE
		slot_btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		slot_btn.add_theme_stylebox_override("hover", UI.style(Color(1,0.7,0.2,0.06), Color("ffd080")))
		slot_btn.add_theme_stylebox_override("pressed", UI.style(Color(0.1,0.4,0.4,0.15), Color("65e2df")))
		slot_btn.pressed.connect(_choose.bind(i))
		canvas.add_child(slot_btn)
		if not is_empty:
			var del_btn := UI.button(canvas, "Delete", Rect2(865, y + 51, 105, 55), _confirm_delete.bind(i))
			del_btn.tooltip_text = "Delete save slot %d" % i
			del_btn.add_theme_font_size_override("font_size", 18)
			del_btn.add_theme_color_override("font_color", Color("ffb3a6"))
			del_btn.add_theme_stylebox_override("normal", UI.style(Color("2a1414"), Color("9e4236")))
			del_btn.add_theme_stylebox_override("hover", UI.style(Color("541c1c"), Color("ff7b6b")))
			del_btn.add_theme_stylebox_override("pressed", UI.style(Color("701a1a"), Color("ffa89e")))
		var b := UI.button(canvas,"Continue" if not is_empty else "Create",Rect2(985,y+51,165,55),_choose.bind(i))
		if i == 1:
			b.grab_focus()
	UI.button(canvas,"Back",Rect2(80,640,180,50),show_title)
	status = UI.label(canvas,"Progress saves automatically. Runs restart from the ship.",Rect2(310,649,900,30),18)

func _confirm_delete(slot: int) -> void:
	if is_instance_valid(delete_modal):
		_close_delete_modal()
	
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.01, 0.015, 0.82)
	shade.size = Vector2(1280, 720)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	delete_modal = shade
	canvas.add_child(shade)
	
	var panel := Panel.new()
	panel.position = Vector2(360, 220)
	panel.size = Vector2(560, 280)
	panel.add_theme_stylebox_override("panel", UI.style(Color("1e1713"), Color("ff7b6b")))
	shade.add_child(panel)
	
	var title := UI.label(panel, "DELETE SAVE FILE %d?" % slot, Rect2(0, 25, 560, 38), 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("ff7b6b"))
	
	var desc := UI.label(panel, "This will permanently delete this save file,\nincluding all unlocked skills, XP, and expedition stats.\nThis action cannot be undone.", Rect2(30, 80, 500, 75), 18)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_color_override("font_color", Color("ffe2ad"))
	
	var cancel_btn := UI.button(panel, "Cancel", Rect2(60, 185, 190, 52), _close_delete_modal)
	cancel_btn.grab_focus()
	
	var confirm_btn := UI.button(panel, "Delete File", Rect2(310, 185, 190, 52), func():
		_close_delete_modal()
		_delete_slot(slot)
	)
	confirm_btn.add_theme_font_size_override("font_size", 20)
	confirm_btn.add_theme_color_override("font_color", Color("ffb3a6"))
	confirm_btn.add_theme_stylebox_override("normal", UI.style(Color("3b1414"), Color("c43d33")))
	confirm_btn.add_theme_stylebox_override("hover", UI.style(Color("5e1b1b"), Color("ff6b5e")))
	confirm_btn.add_theme_stylebox_override("pressed", UI.style(Color("7a2020"), Color("ffa89e")))

func _close_delete_modal() -> void:
	if is_instance_valid(delete_modal):
		if delete_modal.get_parent() != null:
			delete_modal.get_parent().remove_child(delete_modal)
		delete_modal.queue_free()
		delete_modal = null

func _delete_slot(slot: int) -> void:
	var saves = get_node("/root/SaveSlots")
	var error: Error = saves.delete_slot(slot)
	if error != OK:
		if status != null:
			status.text = "Failed to delete slot %d: %s" % [slot, error_string(error)]
		return
	show_slots()
	if status != null:
		status.text = "Save file %d has been deleted." % slot

func _choose(slot: int) -> void:
	var saves = get_node("/root/SaveSlots")
	var is_empty: bool = saves.is_slot_empty(slot)
	var error: Error = saves.select_slot(slot)
	if error != OK:
		if status != null:
			status.text = "Could not save file: " + error_string(error)
		return
	if is_empty:
		var config = get_node("/root/RunConfig")
		config.call("start_run", "medium", {})
		get_tree().change_scene_to_file("res://scenes/RoguelikeRun.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/FlyingLibertyMainHall.tscn")

func _settings() -> void:
	settings_menu.show_settings()

func _quit() -> void:
	get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.is_echo() and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE)):
		if is_instance_valid(delete_modal):
			_close_delete_modal()
		elif settings_menu.visible:
			settings_menu.back()
		elif page == "slots":
			show_title()
		get_viewport().set_input_as_handled()
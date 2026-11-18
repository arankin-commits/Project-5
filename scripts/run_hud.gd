extends CanvasLayer

const CardChoiceButtonClass := preload("res://scripts/card_choice_button.gd")

signal reward_selected(id: String)
signal retry_requested
signal return_requested
signal pause_requested
signal quit_requested

var room_label: Label
var room_subtitle: Label
var health_label: Label
var health_bar: ProgressBar
var dash_label: Label
var objective: Label
var progress_labels: Array[Label] = []
var boss_bar: ProgressBar
var boss_title: Label
var boss_box: VBoxContainer
var modal: Control
var card_view: Control
var result_panel: CenterContainer
var skip_button: Button
var modal_title: Label
var modal_description: Label
var modal_actions: HBoxContainer
var footer: Label
var pause_menu: Control
var progression_label: Label
var perfect_dash_indicator: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var top := HBoxContainer.new()
	top.position = Vector2(24,18)
	top.size = Vector2(1232,86)
	top.add_theme_constant_override("separation",24)
	root.add_child(top)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 300
	top.add_child(left)
	health_label = label("MEDIUM / STANDARD CORE",17)
	left.add_child(health_label)
	health_bar = bar(Color("69d9c7"),Vector2(285,14))
	left.add_child(health_bar)
	dash_label = label("DASH READY",13,Color("a6c6c0"))
	left.add_child(dash_label)
	var middle := VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(middle)
	room_label = label("THE BOILER BELOW",25)
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	middle.add_child(room_label)
	room_subtitle = label("",14,Color("d8ad72"))
	room_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	middle.add_child(room_subtitle)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 280
	top.add_child(right)
	var progress := HBoxContainer.new()
	progress.alignment = BoxContainer.ALIGNMENT_END
	progress.add_theme_constant_override("separation",10)
	right.add_child(progress)
	for i in 9:
		var item := label(str(i+1) if i<8 else "B",18)
		progress.add_child(item)
		progress_labels.append(item)
	objective = label("",14,Color("b3d9d0"))
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(objective)
	footer = label("WASD  Move     LMB / J  Strike     RMB / K  Heavy strike     SPACE  Dash     E  Continue     ESC  Pause",14,Color("e1cba9"))
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -34
	footer.offset_bottom = -8
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(footer)
	progression_label = label("", 15, Color("8ee8d0"))
	progression_label.position = Vector2(24,110)
	root.add_child(progression_label)
	perfect_dash_indicator = label("PERFECT DASH", 30, Color("ffce83"))
	perfect_dash_indicator.position = Vector2(440, 175)
	perfect_dash_indicator.size = Vector2(400, 48)
	perfect_dash_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	perfect_dash_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(perfect_dash_indicator)
	perfect_dash_indicator.hide()
	boss_box = VBoxContainer.new()
	boss_box.position = Vector2(330,615)
	boss_box.size = Vector2(620,48)
	root.add_child(boss_box)
	boss_title = label("FURNACE WARDEN",17,Color("ffc486"))
	boss_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_box.add_child(boss_title)
	boss_bar = bar(Color("e06f37"),Vector2(620,12))
	boss_box.add_child(boss_bar)
	boss_box.hide()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	var shade := ColorRect.new()
	shade.color = Color(0.02,0.025,0.03,0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	# 1. Card Selection View (Matches Steampunk Card Selection HUD Reference)
	card_view = Control.new()
	card_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(card_view)
	var header_rect := TextureRect.new()
	header_rect.name = "HeaderBanner"
	if ResourceLoader.exists("res://art/card_hud/header_banner.png"):
		header_rect.texture = load("res://art/card_hud/header_banner.png")
	header_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	header_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_rect.position = Vector2(365, 12)
	header_rect.size = Vector2(550, 84)
	header_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_view.add_child(header_rect)
	modal_actions = HBoxContainer.new()
	modal_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	modal_actions.add_theme_constant_override("separation", 24)
	modal_actions.position = Vector2(100, 108)
	modal_actions.size = Vector2(1080, 495)
	card_view.add_child(modal_actions)
	var footer_rect := TextureRect.new()
	footer_rect.name = "FooterPromptBar"
	if ResourceLoader.exists("res://art/card_hud/footer_bar.png"):
		footer_rect.texture = load("res://art/card_hud/footer_bar.png")
	footer_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	footer_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	footer_rect.position = Vector2(365, 622)
	footer_rect.size = Vector2(550, 64)
	footer_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_view.add_child(footer_rect)
	skip_button = Button.new()
	skip_button.name = "SkipButton"
	skip_button.flat = true
	skip_button.position = Vector2(695, 624)
	skip_button.size = Vector2(210, 58)
	skip_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.pressed.connect(_on_skip_pressed)
	card_view.add_child(skip_button)
	# 2. Result View (For show_result / run end)
	result_panel = CenterContainer.new()
	result_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(result_panel)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1040,340)
	panel.add_theme_stylebox_override("panel",panel_style())
	result_panel.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",20)
	panel.add_child(stack)
	modal_title = label("",30)
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(modal_title)
	modal_description = label("",17,Color("beccca"))
	modal_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(modal_description)
	modal.hide()
	pause_menu = preload("res://scripts/run_menu.gd").new()
	root.add_child(pause_menu)
	pause_menu.resume_requested.connect(func(): pause_requested.emit())
	pause_menu.give_up_requested.connect(func(): return_requested.emit())
	pause_menu.quit_requested.connect(func(): quit_requested.emit())
	var menu_button := Button.new()
	menu_button.text = "Menu [Esc]"
	menu_button.position = Vector2(1110, 108)
	menu_button.size = Vector2(145, 40)
	menu_button.pressed.connect(func(): pause_requested.emit())
	root.add_child(menu_button)
	# The menu overlay must remain above the HUD button.
	root.move_child(pause_menu, -1)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.is_echo() and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE)):
		if pause_menu.visible:
			pause_menu.back()
		elif modal.visible and card_view.visible:
			_on_skip_pressed()
		else:
			pause_requested.emit()
		get_viewport().set_input_as_handled()

func _on_skip_pressed() -> void:
	reward_selected.emit("skip")

func set_room(index: int, data: Dictionary, run_seed: int) -> void:
	room_label.text = str(data["name"]).to_upper()
	var count: int = data.get("room_count",9)
	room_subtitle.text = "%s  /  %02d OF %02d  /  SEED %d" % [data.get("biome","THE BOILER BELOW"),index+1,count,run_seed%100000]
	for i in progress_labels.size():
		progress_labels[i].visible = i < count
		progress_labels[i].modulate = Color("72e8d2") if i < index else (Color("ffce83") if i == index else Color("766757"))
	modal.hide()

func update_stats(health: float, maximum: float, dash: float, special: float) -> void:
	health_label.text = "%s     HULL %d / %d" % [str(get_node("/root/RunConfig").get("robot_type")).to_upper(),ceili(health),ceili(maximum)]
	health_bar.max_value = maximum
	health_bar.value = health
	dash_label.text = ("DASH READY" if dash <= 0 else "DASH %.1fs" % dash) + "    /    " + ("HEAVY READY" if special <= 0 else "HEAVY %.1fs" % special)

func set_boss(boss: Node) -> void:
	boss_box.visible = is_instance_valid(boss) and boss.get("health") > 0
	if boss_box.visible:
		boss_bar.max_value = boss.get("max_health")
		boss_bar.value = boss.get("health")
		boss_title.text = boss.display_name + ("  /  OVERPRESSURE" if boss.get("phase_two") else "")

func _clear_actions() -> void:
	for child in modal_actions.get_children():
		modal_actions.remove_child(child)
		child.queue_free()

func show_rewards(choices: Array) -> void:
	_clear_actions()
	card_view.show()
	result_panel.hide()
	modal_title.text = "PRESSURE RELEASED"
	modal_description.text = "Choose one core or salvage upgrade for this run. Hull repaired by 12."
	for choice in choices:
		var button := CardChoiceButtonClass.new(choice)
		var choice_id := str(choice.get("id", ""))
		button.pressed.connect(func(): reward_selected.emit(choice_id))
		modal_actions.add_child(button)
	modal.show()
	if modal_actions.get_child_count() > 0:
		modal_actions.get_child(0).grab_focus()

func show_result(title: String, description: String) -> void:
	_clear_actions()
	card_view.hide()
	result_panel.show()
	modal_title.text = title
	modal_description.text = description + "\n\nReturning to the ship..."
	modal.show()

func show_pause() -> void:
	pause_menu.show_menu()

func hide_pause() -> void:
	pause_menu.hide()
	if modal.visible and modal_actions.get_child_count() > 0:
		modal_actions.get_child(0).grab_focus()

func update_progression(energy: float, elements: Array, capacity: int, xp: int, items: int, buff: float, damage_buff := 0.0) -> void:
	progression_label.text = "ENERGY %d/100  |  CORES %d/%d: %s\n+%d XP  |  +%d Aether Gears  |  F Grapple  |  Q Core burst" % [int(energy),elements.size(),capacity,", ".join(elements).to_upper() if not elements.is_empty() else "NONE",xp,items]
	if buff > 0:
		progression_label.text += "  |  PERFECT 2x XP %.1fs" % buff
	if damage_buff > 0:
		progression_label.text += "  |  +25%% DAMAGE %.1fs" % damage_buff

func add_button(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(280,65)
	button.pressed.connect(callback)
	modal_actions.add_child(button)

func label(text: String, size: int, color := Color("ffe1b1")) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size",size)
	result.add_theme_color_override("font_color",color)
	result.add_theme_color_override("font_shadow_color",Color.BLACK)
	result.add_theme_constant_override("shadow_offset_x",2)
	result.add_theme_constant_override("shadow_offset_y",2)
	return result

func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("142126")
	style.border_color = Color("9f7845")
	style.set_border_width_all(2)
	style.set_content_margin_all(24)
	style.set_corner_radius_all(5)
	return style

func bar(color: Color, minimum: Vector2) -> ProgressBar:
	var result := ProgressBar.new()
	result.custom_minimum_size = minimum
	result.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("292c2b")
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	result.add_theme_stylebox_override("background",bg)
	result.add_theme_stylebox_override("fill",fill)
	return result

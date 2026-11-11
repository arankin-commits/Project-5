extends CanvasLayer

signal closed

const PROGRESSION_DATA := preload("res://scripts/core_progression.gd")

@onready var progression: Node = get_node("/root/CoreProgression")

var core_status: Label
var tabs: TabContainer
var skill_points_label: Label
var skill_detail: Label
var unlock_button: Button
var core_buttons: Dictionary = {}
var skill_buttons: Dictionary = {}
var selected_skill := "power_routing"

func _ready() -> void:
	_build_ui()
	visible = false

func open_terminal() -> void:
	_refresh()
	visible = true

func close_terminal() -> void:
	visible = false
	closed.emit()

func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.name = "Dimmer"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.01, 0.02, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(840, 540)
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
	title.text = "CORE INTERFACE"
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color("ffd488"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "Close [E]"
	close_button.pressed.connect(close_terminal)
	header.add_child(close_button)
	core_status = Label.new()
	core_status.add_theme_font_size_override("font_size", 18)
	content.add_child(core_status)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(tabs)
	_build_core_tab(tabs)
	_build_skill_tab(tabs)

func _build_core_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "Cores"
	page.add_theme_constant_override("separation", 12)
	tabs.add_child(page)
	var heading := Label.new()
	heading.text = "Choose an unlocked core"
	heading.add_theme_font_size_override("font_size", 21)
	page.add_child(heading)
	for core_id in ["standard", "core_02", "core_03"]:
		var button := Button.new()
		button.name = core_id
		button.custom_minimum_size.y = 58
		button.pressed.connect(_equip_core.bind(core_id))
		page.add_child(button)
		core_buttons[core_id] = button
	var note := Label.new()
	note.text = "1 of 3 core slots unlocked"
	note.add_theme_color_override("font_color", Color("d7b981"))
	page.add_child(note)

func _build_skill_tab(tabs: TabContainer) -> void:
	var page := VBoxContainer.new()
	page.name = "Skill Tree"
	page.add_theme_constant_override("separation", 13)
	tabs.add_child(page)
	skill_points_label = Label.new()
	skill_points_label.add_theme_font_size_override("font_size", 20)
	page.add_child(skill_points_label)
	var root := _skill_button("power_routing")
	page.add_child(root)
	var connector := Label.new()
	connector.text = "                 ↓                 ↓                 ↓"
	connector.add_theme_color_override("font_color", Color("c8994d"))
	page.add_child(connector)
	var branches := HBoxContainer.new()
	branches.add_theme_constant_override("separation", 10)
	page.add_child(branches)
	for skill_id in ["drive_tuning", "capacitor_bank", "armor_lattice"]:
		var button := _skill_button(skill_id)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		branches.add_child(button)
	skill_detail = Label.new()
	skill_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_detail.custom_minimum_size.y = 55
	page.add_child(skill_detail)
	unlock_button = Button.new()
	unlock_button.text = "Unlock selected skill (1 point)"
	unlock_button.pressed.connect(_unlock_selected_skill)
	page.add_child(unlock_button)

func _skill_button(skill_id: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size.y = 62
	button.pressed.connect(_select_skill.bind(skill_id))
	skill_buttons[skill_id] = button
	return button

func _equip_core(core_id: String) -> void:
	progression.call("equip_core", core_id)
	_refresh()

func _select_skill(skill_id: String) -> void:
	selected_skill = skill_id
	_refresh()

func _unlock_selected_skill() -> void:
	progression.call("unlock_skill", selected_skill)
	_refresh()

func _refresh() -> void:
	var equipped_core: String = progression.get("equipped_core")
	var unlocked_cores: Array = progression.get("unlocked_cores")
	var unlocked_skills: Array = progression.get("unlocked_skills")
	core_status.text = "Equipped: %s" % PROGRESSION_DATA.CORE_NAMES[equipped_core]
	for core_id in ["standard", "core_02", "core_03"]:
		var button: Button = core_buttons[core_id]
		var unlocked := unlocked_cores.has(core_id)
		button.disabled = not unlocked
		button.text = "%s     %s" % [PROGRESSION_DATA.CORE_NAMES[core_id], "EQUIPPED" if core_id == equipped_core else ("Select" if unlocked else "LOCKED")]
	skill_points_label.text = "Standard Core • Skill points: %d" % progression.get("skill_points")
	for skill_id in skill_buttons:
		var button: Button = skill_buttons[skill_id]
		button.text = "%s\n%s" % [PROGRESSION_DATA.SKILLS[skill_id]["name"], "UNLOCKED" if unlocked_skills.has(skill_id) else "LOCKED"]
	skill_detail.text = PROGRESSION_DATA.SKILLS[selected_skill]["description"]
	unlock_button.disabled = not progression.call("can_unlock_skill", selected_skill)

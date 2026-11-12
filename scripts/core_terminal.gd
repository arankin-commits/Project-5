extends CanvasLayer

signal closed
const DATA := preload("res://scripts/core_progression.gd")
const ART := preload("res://Steampunk Elemental Skill Tree.png")
const TREE_SCALE := 0.46
@onready var progression: Node = get_node("/root/CoreProgression")
var skill_buttons: Dictionary = {}
var skill_points_label: Label
var skill_detail: Label
var unlock_button: Button
var selected_skill := "root"

func _ready() -> void:
	_build_ui()
	progression.changed.connect(_refresh)
	visible = false

func open_terminal() -> void:
	_refresh()
	visible = true

func close_terminal() -> void:
	visible = false
	closed.emit()

func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.01,0.02,0.025,0.97)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var layout := HBoxContainer.new()
	layout.position = Vector2(28,24)
	layout.size = Vector2(1224,672)
	layout.add_theme_constant_override("separation",32)
	add_child(layout)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(540,672)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var canvas := Control.new()
	canvas.custom_minimum_size = ART.get_size() * TREE_SCALE
	scroll.add_child(canvas)
	var art := TextureRect.new()
	art.texture = ART
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.size = canvas.custom_minimum_size
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(art)
	for id in DATA.SKILLS:
		var skill: Dictionary = DATA.SKILLS[id]
		var button := Button.new()
		var radius: float = skill.radius * TREE_SCALE
		button.position = skill.at * TREE_SCALE - Vector2.ONE * radius
		button.size = Vector2.ONE * radius * 2
		button.tooltip_text = skill.name + "\n" + skill.description
		button.pressed.connect(_select_skill.bind(id))
		canvas.add_child(button)
		skill_buttons[id] = button
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 630
	side.add_theme_constant_override("separation",22)
	layout.add_child(side)
	var title := Label.new()
	title.text = "ELEMENTAL SKILL TREE"
	title.add_theme_font_size_override("font_size",28)
	title.add_theme_color_override("font_color",Color("ffd488"))
	side.add_child(title)
	skill_points_label = Label.new()
	side.add_child(skill_points_label)
	var legend := Label.new()
	legend.text = "TEAL  Unlocked   |   GOLD  Available\nDIM  Locked   |   Select a node to inspect\n\nRegular nodes: XP only\nSpecial nodes: Aether Gears only\n\nEarn XP by defeating enemies and clearing rooms.\nFind an Aether Gear in chamber 4 and from the boss."
	legend.add_theme_font_size_override("font_size",16)
	side.add_child(legend)
	skill_detail = Label.new()
	skill_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skill_detail.custom_minimum_size.y = 175
	skill_detail.add_theme_font_size_override("font_size",20)
	side.add_child(skill_detail)
	unlock_button = Button.new()
	unlock_button.custom_minimum_size.y = 54
	unlock_button.pressed.connect(_unlock_selected_skill)
	side.add_child(unlock_button)
	var close := Button.new()
	close.text = "Close [E]"
	close.custom_minimum_size.y = 44
	close.pressed.connect(close_terminal)
	side.add_child(close)
	_refresh()

func _select_skill(id: String) -> void:
	selected_skill = id
	_refresh()

func _unlock_selected_skill() -> void:
	progression.unlock_skill(selected_skill)
	_refresh()

func _refresh() -> void:
	if skill_points_label == null:
		return
	skill_points_label.text = "%d XP     |     %d Aether Gears     |     %d core slots" % [progression.xp,progression.special_items,progression.core_capacity()]
	for id in skill_buttons:
		var owned: bool = progression.has_skill(id)
		var available: bool = progression.can_unlock_skill(id)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0,0,0,0.05 if owned or available else 0.55)
		style.border_color = Color("6fffe0") if owned else (Color("ffcd6c") if available else Color("71665b"))
		style.set_border_width_all(4 if id == selected_skill else 2)
		style.set_corner_radius_all(100)
		skill_buttons[id].add_theme_stylebox_override("normal",style)
		var hover := style.duplicate()
		hover.bg_color = Color(0.8,0.6,0.2,0.2)
		skill_buttons[id].add_theme_stylebox_override("hover",hover)
		skill_buttons[id].add_theme_stylebox_override("pressed",hover)
	var skill: Dictionary = DATA.SKILLS[selected_skill]
	var cost := "%d Aether Gear(s)" % skill.item if skill.item > 0 else "%d XP" % skill.xp
	var requirement := ""
	if skill.requires != "" and not progression.has_skill(skill.requires):
		requirement = "\nRequires: " + DATA.SKILLS[skill.requires].name
	skill_detail.text = skill.name + "\n\n" + skill.description + "\n\n" + ("SPECIAL | " if skill.item > 0 else "REGULAR | ") + cost + requirement
	unlock_button.text = "Unlocked" if progression.has_skill(selected_skill) else "Unlock | " + cost
	unlock_button.disabled = not progression.can_unlock_skill(selected_skill)

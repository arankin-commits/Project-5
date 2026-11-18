extends Node2D

const PASSAGE := preload("res://scripts/room_passage.gd")
@onready var player: CharacterBody2D = $Player
var prompt: Label
var panel: PanelContainer
var panel_title: Label
var panel_text: Label
var npc_controller: Node

func _ready() -> void:
	CockpitDoor.take_entry_id()
	get_node("/root/BackgroundMusic").play_ship()
	add_child(preload("res://scripts/ship_menu.gd").new())
	_build_collision()
	_build_ui()
	var passage := PASSAGE.new()
	passage.name = "MainHallReturn"
	passage.position = Vector2(820, 245)
	passage.half_extent = Vector2(45, 20)
	passage.target_scene = "res://scenes/FlyingLibertyMainHall.tscn"
	passage.target_entry_id = "from_computer"
	$Passages.add_child(passage)
	player.position = Vector2(1000, 370)
	npc_controller = preload("res://scripts/ship_npcs.gd").new()
	npc_controller.room_id = "computer"
	add_child(npc_controller)
	$Player/Camera2D.make_current()
	$Player/Camera2D.reset_smoothing()
	$Player/Camera2D.force_update_scroll()

func _process(_delta: float) -> void:
	if npc_controller.blocks_room_input():
		return
	prompt.text = ""

func _build_collision() -> void:
	var boundary := PackedVector2Array([Vector2(85,245),Vector2(1555,245),Vector2(1555,730),Vector2(1470,820),Vector2(170,820),Vector2(85,730)])
	for i in boundary.size():
		_add_wall(boundary[i], boundary[(i+1)%boundary.size()])
	for entry in [
		["LeftConsole", Rect2(355,390,235,165)],
		["CenterConsole", Rect2(700,300,240,175)],
		["RightConsole", Rect2(1090,285,240,170)],
		["LeftServer", Rect2(150,525,140,185)],
		["RightServer", Rect2(1120,535,140,175)],
		["Desk", Rect2(715,550,210,130)],
		["Chair", Rect2(775,655,85,105)],
		["SideTable", Rect2(595,575,95,80)],
		["Plant", Rect2(970,565,60,60)]]:
		var rect: Rect2 = entry[1]
		_add_obstacle(entry[0], PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))

func _add_wall(a: Vector2, b: Vector2) -> void:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var segment := SegmentShape2D.new()
	segment.a = a
	segment.b = b
	shape.shape = segment
	body.add_child(shape)
	$Collision.add_child(body)

func _add_obstacle(node_name: String, points: PackedVector2Array) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	var shape := CollisionPolygon2D.new()
	shape.polygon = points
	body.add_child(shape)
	$Collision.add_child(body)

func _build_ui() -> void:
	prompt = Label.new()
	prompt.position = Vector2(450, 625)
	prompt.custom_minimum_size = Vector2(380, 40)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 24)
	prompt.add_theme_color_override("font_color", Color("ffe6b2"))
	$InteractionUI.add_child(prompt)
	panel = PanelContainer.new()
	panel.position = Vector2(380, 510)
	panel.custom_minimum_size = Vector2(520, 105)
	var box := VBoxContainer.new()
	panel.add_child(box)
	panel_title = Label.new()
	panel_title.add_theme_font_size_override("font_size", 25)
	box.add_child(panel_title)
	panel_text = Label.new()
	box.add_child(panel_text)
	$InteractionUI.add_child(panel)
	panel.hide()
	var hint := Label.new()
	hint.text = "COMPUTER ROOM   WASD move   Space run   E interact"
	hint.position = Vector2(20, 18)
	hint.add_theme_color_override("font_color", Color("fff0ce"))
	$InteractionUI.add_child(hint)

func show_message(title: String, message: String) -> void:
	panel_title.text = title
	panel_text.text = message + "\n[E] Close"
	panel.show()

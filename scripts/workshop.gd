extends Node2D

const INTERACTABLE := preload("res://scripts/cockpit_interactable.gd")
const CORE_INTERACTABLE := preload("res://scripts/core_interactable.gd")
const PASSAGE := preload("res://scripts/room_passage.gd")

@onready var player: CharacterBody2D = $Player
@onready var core_terminal: CanvasLayer = $CoreTerminal
var interactables: Array[CockpitInteractable] = []
var prompt: Label
var panel: PanelContainer
var panel_title: Label
var panel_text: Label

var npc_controller: Node

func _ready() -> void:
	get_node("/root/BackgroundMusic").play_ship()
	add_child(preload("res://scripts/ship_menu.gd").new())
	_build_collision()
	_build_interactions()
	_build_passage()
	_build_ui()
	npc_controller = preload("res://scripts/ship_npcs.gd").new()
	npc_controller.room_id = "workshop"
	add_child(npc_controller)
	core_terminal.connect("closed", Callable(self, "_on_core_terminal_closed"))
	player.position = Vector2(1445, 490)
	$Player/Camera2D.make_current()
	$Player/Camera2D.reset_smoothing()
	$Player/Camera2D.force_update_scroll()

func _process(_delta: float) -> void:
	if npc_controller.blocks_room_input():
		return
	if core_terminal.visible:
		prompt.text = ""
		if Input.is_action_just_pressed("interact"):
			core_terminal.call("close_terminal")
		return
	var nearest := _nearest_interaction()
	prompt.text = "[E] %s" % nearest.prompt if nearest != null and not panel.visible else ""
	if Input.is_action_just_pressed("interact"):
		if panel.visible:
			panel.hide()
		elif nearest != null:
			nearest.activate(self)

func _build_interactions() -> void:
	var core := CORE_INTERACTABLE.new() as CoreInteractable
	core.name = "PowerCoreTerminal"
	core.position = Vector2(800, 610)
	core.prompt = "Open Skill Tree"
	core.radius = 100.0
	$Interactions.add_child(core)
	interactables.append(core)
	var station := INTERACTABLE.new() as CockpitInteractable
	station.name = "AutomatonStation"
	station.position = Vector2(1110, 810)
	station.prompt = "Inspect Automaton Station"
	station.message = "The engineering benches are ready for automaton work."
	station.radius = 100.0
	$Interactions.add_child(station)
	interactables.append(station)

func open_core_terminal() -> void:
	player.set("controls_enabled", false)
	core_terminal.call("open_terminal")

func _on_core_terminal_closed() -> void:
	player.set("controls_enabled", true)

func _build_passage() -> void:
	var return_passage := PASSAGE.new()
	return_passage.name = "MainHallReturn"
	return_passage.position = Vector2(1495, 490)
	return_passage.half_extent = Vector2(28, 65)
	return_passage.target_scene = "res://scenes/FlyingLibertyMainHall.tscn"
	return_passage.target_entry_id = "from_workshop"
	$Passages.add_child(return_passage)

func _nearest_interaction() -> CockpitInteractable:
	var nearest: CockpitInteractable
	var distance := INF
	for item in interactables:
		var d := item.global_position.distance_to(player.global_position)
		if d <= item.radius and d < distance:
			nearest = item
			distance = d
	return nearest

func _build_collision() -> void:
	# The provided illustration is flattened; these footprints track visible solid bases.
	var boundary := PackedVector2Array([Vector2(60, 940), Vector2(60, 160), Vector2(140, 30), Vector2(1450, 30), Vector2(1530, 160), Vector2(1530, 940)])
	for i in boundary.size():
		_add_wall(boundary[i], boundary[(i + 1) % boundary.size()])
	_add_obstacle("HeavyAutomatonPlatform", PackedVector2Array([Vector2(210, 320), Vector2(520, 320), Vector2(520, 410), Vector2(210, 410)]))
	_add_obstacle("CenterAutomatonPlatform", PackedVector2Array([Vector2(645, 320), Vector2(930, 320), Vector2(930, 405), Vector2(645, 405)]))
	_add_obstacle("LightAutomatonPlatform", PackedVector2Array([Vector2(1060, 320), Vector2(1270, 320), Vector2(1270, 405), Vector2(1060, 405)]))
	_add_obstacle("PowerCore", PackedVector2Array([Vector2(620, 455), Vector2(975, 455), Vector2(975, 580), Vector2(620, 580)]))
	_add_obstacle("LeftCabinet", PackedVector2Array([Vector2(35, 470), Vector2(275, 470), Vector2(275, 735), Vector2(35, 735)]))
	_add_obstacle("CenterWorkbench", PackedVector2Array([Vector2(520, 645), Vector2(820, 645), Vector2(820, 765), Vector2(520, 765)]))
	_add_obstacle("RightWorkbench", PackedVector2Array([Vector2(950, 635), Vector2(1305, 635), Vector2(1305, 765), Vector2(950, 765)]))
	_add_obstacle("FrontDesk", PackedVector2Array([Vector2(165, 810), Vector2(480, 810), Vector2(480, 965), Vector2(165, 965)]))

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
	hint.text = "ENGINEERING WORKSHOP   WASD move   E interact"
	hint.position = Vector2(20, 18)
	hint.add_theme_color_override("font_color", Color("fff0ce"))
	$InteractionUI.add_child(hint)

func show_message(title: String, message: String) -> void:
	panel_title.text = title
	panel_text.text = message + "\n[E] Close"
	panel.show()

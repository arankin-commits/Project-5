extends Node2D

const DOOR := preload("res://scripts/cockpit_door.gd")
const INTERACTABLE := preload("res://scripts/cockpit_interactable.gd")
const SYNC_POD := preload("res://scripts/sync_pod_interactable.gd")

@onready var player: CharacterBody2D = $Player
@onready var run_setup: CanvasLayer = $RunSetup
var interactables: Array[CockpitInteractable] = []
var prompt: Label
var panel: PanelContainer
var panel_title: Label
var panel_text: Label

func _ready() -> void:
	_build_collision()
	_build_interactions()
	_build_ui()
	run_setup.connect("closed", Callable(self, "_on_setup_closed"))
	run_setup.connect("start_requested", Callable(self, "_on_start_requested"))
	player.position = Vector2(793, 825)
	$Player/Camera2D.make_current()
	$Player/Camera2D.reset_smoothing()
	$Player/Camera2D.force_update_scroll()

func _process(_delta: float) -> void:
	if run_setup.visible:
		prompt.text = ""
		if Input.is_action_just_pressed("interact"):
			run_setup.call("close_setup")
		return
	var nearest := _nearest_interaction()
	prompt.text = "[E] %s" % nearest.prompt if nearest != null and not panel.visible else ""
	if Input.is_action_just_pressed("interact"):
		if panel.visible:
			panel.hide()
		elif nearest != null:
			nearest.activate(self)

func _build_interactions() -> void:
	var exit_door := DOOR.new() as CockpitDoor
	exit_door.name = "MainHallDoor"
	exit_door.position = Vector2(793, 843)
	exit_door.prompt = "Return to Main Hall"
	exit_door.radius = 100.0
	exit_door.target_room_id = "fly_hall"
	exit_door.target_scene = "res://scenes/FlyingLibertyMainHall.tscn"
	exit_door.target_entry_id = "from_sync"
	$Interactions.add_child(exit_door)
	interactables.append(exit_door)
	var pod := SYNC_POD.new() as SyncPodInteractable
	pod.name = "SyncPod"
	pod.position = Vector2(650, 630)
	pod.prompt = "Configure Roguelike Run"
	pod.radius = 95.0
	$Interactions.add_child(pod)
	interactables.append(pod)

func open_run_setup() -> void:
	player.set("controls_enabled", false)
	run_setup.call("open_setup")

func _on_setup_closed() -> void:
	player.set("controls_enabled", true)

func _on_start_requested(modifiers: Dictionary) -> void:
	var run_config: Node = get_node("/root/RunConfig")
	if run_config.call("start_run", "medium", modifiers):
		get_tree().change_scene_to_file("res://scenes/RoguelikeRun.tscn")

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
	# Footprints are calibrated to the painted machine bases and available deck.
	var boundary := PackedVector2Array([Vector2(110, 705), Vector2(110, 225), Vector2(225, 95), Vector2(1360, 95), Vector2(1480, 225), Vector2(1480, 705), Vector2(920, 705), Vector2(920, 960), Vector2(665, 960), Vector2(665, 705)])
	for i in boundary.size():
		_add_wall(boundary[i], boundary[(i + 1) % boundary.size()])
	_add_obstacle("CentralSyncMachine", PackedVector2Array([Vector2(400, 420), Vector2(880, 420), Vector2(880, 580), Vector2(400, 580)]))
	_add_obstacle("LeftEnergyTank", PackedVector2Array([Vector2(245, 375), Vector2(380, 375), Vector2(380, 565), Vector2(245, 565)]))
	_add_obstacle("RightEnergyTank", PackedVector2Array([Vector2(975, 360), Vector2(1095, 360), Vector2(1095, 465), Vector2(975, 465)]))
	_add_obstacle("RightControlDesk", PackedVector2Array([Vector2(1160, 400), Vector2(1460, 400), Vector2(1460, 580), Vector2(1160, 580)]))
	_add_obstacle("LeftCabinets", PackedVector2Array([Vector2(130, 255), Vector2(220, 255), Vector2(220, 525), Vector2(130, 525)]))
	_add_obstacle("LeftCrates", PackedVector2Array([Vector2(125, 555), Vector2(245, 555), Vector2(245, 690), Vector2(125, 690)]))
	_add_obstacle("RightCrates", PackedVector2Array([Vector2(1380, 580), Vector2(1490, 580), Vector2(1490, 700), Vector2(1380, 700)]))

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
	hint.text = "SYNC CHAMBER   WASD move   E interact"
	hint.position = Vector2(20, 18)
	hint.add_theme_color_override("font_color", Color("fff0ce"))
	$InteractionUI.add_child(hint)

func show_message(title: String, message: String) -> void:
	panel_title.text = title
	panel_text.text = message + "\n[E] Close"
	panel.show()

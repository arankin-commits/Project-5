extends Node2D

const DOOR := preload("res://scripts/cockpit_door.gd")

@onready var player: CharacterBody2D = $Player
var doors: Array[CockpitDoor] = []
var prompt: Label
var panel: PanelContainer
var panel_title: Label
var panel_text: Label

func _ready() -> void:
	_build_collision()
	_build_doors()
	_build_ui()
	$Player/Camera2D.make_current()
	$Player/Camera2D.reset_smoothing()
	$Player/Camera2D.force_update_scroll()

func _process(_delta: float) -> void:
	var nearest := _nearest_door()
	prompt.text = "[E] %s" % nearest.prompt if nearest != null and not panel.visible else ""
	if Input.is_action_just_pressed("interact"):
		if panel.visible:
			panel.hide()
		elif nearest != null:
			nearest.activate(self)

func _build_doors() -> void:
	# Left to right in the supplied hall painting: the second top door is the cockpit.
	_add_door("FirstTopDoor", Vector2(521, 282), "Open first door", "unassigned", "", true)
	_add_door("CockpitDoor", Vector2(844, 277), "Enter Cockpit", "fly_cockpit", "res://scenes/FlyingLibertyCockpit.tscn", false)

func _add_door(node_name: String, at: Vector2, label: String, target_id: String, target_path: String, is_locked: bool) -> void:
	var door := DOOR.new() as CockpitDoor
	door.name = node_name
	door.position = at
	door.prompt = label
	door.radius = 86.0
	door.target_room_id = target_id
	door.target_scene = target_path
	door.locked = is_locked
	$Doors.add_child(door)
	doors.append(door)

func _nearest_door() -> CockpitDoor:
	var nearest: CockpitDoor
	var distance := INF
	for door in doors:
		var d := door.global_position.distance_to(player.global_position)
		if d <= door.radius and d < distance:
			nearest = door
			distance = d
	return nearest

func _build_collision() -> void:
	# The hall painting is a single image; collision is fitted to its visible walkable deck.
	var boundary := PackedVector2Array([Vector2(65, 590), Vector2(65, 400), Vector2(330, 400), Vector2(330, 225), Vector2(1545, 225), Vector2(1545, 700), Vector2(940, 700), Vector2(940, 850), Vector2(750, 850), Vector2(750, 700), Vector2(300, 700), Vector2(300, 590)])
	for i in boundary.size():
		_add_wall(boundary[i], boundary[(i + 1) % boundary.size()])
	_add_obstacle("Bookshelves", PackedVector2Array([Vector2(270, 230), Vector2(405, 230), Vector2(405, 355), Vector2(270, 355)]))
	_add_obstacle("Lounge", PackedVector2Array([Vector2(390, 390), Vector2(650, 390), Vector2(670, 610), Vector2(390, 610)]))
	_add_obstacle("DiningLeft", PackedVector2Array([Vector2(1020, 250), Vector2(1180, 250), Vector2(1180, 415), Vector2(1020, 415)]))
	_add_obstacle("DiningRight", PackedVector2Array([Vector2(1240, 250), Vector2(1400, 250), Vector2(1400, 415), Vector2(1240, 415)]))
	_add_obstacle("Galley", PackedVector2Array([Vector2(1080, 450), Vector2(1460, 450), Vector2(1460, 635), Vector2(1080, 635)]))

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
	hint.text = "MAIN HALL   WASD move   E interact"
	hint.position = Vector2(20, 18)
	hint.add_theme_color_override("font_color", Color("fff0ce"))
	$InteractionUI.add_child(hint)

func show_message(title: String, message: String) -> void:
	panel_title.text = title
	panel_text.text = message + "\n[E] Close"
	panel.show()

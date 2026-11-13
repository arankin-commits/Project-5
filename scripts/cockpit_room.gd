extends Node2D

const MANIFEST := "res://Flying_Liberty_Cockpit_v4_Krita_and_Sprites/manifest_v4.json"
const LAYOUT := "res://Flying_Liberty_Cockpit_v4_Krita_and_Sprites/References/ChamberForge_Cockpit.json"
const MAPPING := "res://data/cockpit_mapping.json"
const ART := "res://art/cockpit/"
const INTERACTABLE := preload("res://scripts/cockpit_interactable.gd")
const DOOR := preload("res://scripts/cockpit_door.gd")
const DEBUG_SCRIPT := preload("res://scripts/cockpit_debug.gd")

@onready var player: CharacterBody2D = $PlayerAndNPCs/Player
@onready var actors: Node2D = $PlayerAndNPCs
@onready var collision_root: Node2D = $GameplayCollision
@onready var interactions: Node2D = $Interactions
@onready var debug_overlay: Node2D = $DebugOverlay
@onready var ui: CanvasLayer = $InteractionUI

var layout: Dictionary
var mapping: Dictionary
var interactables: Array[CockpitInteractable] = []
var prompt_label: Label
var panel: PanelContainer
var panel_title: Label
var panel_text: Label

var npc_controller: Node

func _ready() -> void:
	add_child(preload("res://scripts/ship_menu.gd").new())
	layout = _read_json(LAYOUT)
	mapping = _read_json(MAPPING)
	actors.y_sort_enabled = true
	_build_art()
	_build_collisions()
	_build_actors_and_interactions()
	_build_ui()
	npc_controller = preload("res://scripts/ship_npcs.gd").new()
	npc_controller.room_id = "cockpit"
	add_child(npc_controller)
	var spawn := _object("spawn")
	player.position = map_gameplay(Vector2(spawn["x"], spawn["y"]))
	var camera: Camera2D = player.get_node("Camera2D")
	camera.make_current()
	camera.reset_smoothing()
	camera.force_update_scroll()
	debug_overlay.set_script(DEBUG_SCRIPT)
	for object in layout.get("objects", []):
		debug_overlay.markers.append({"position": map_gameplay(Vector2(object["x"], object["y"])), "label": "%s #%s" % [object["kind"], object["id"]]})
	for child in collision_root.get_children():
		if child.has_meta("outline"):
			debug_overlay.boundaries.append(child.get_meta("outline"))

func _process(_delta: float) -> void:
	if npc_controller.blocks_room_input():
		return
	var nearest := _nearest_interactable()
	prompt_label.text = "[E] %s" % nearest.prompt if nearest != null and not panel.visible else ""
	if Input.is_action_just_pressed("interact"):
		if panel.visible:
			panel.hide()
		elif nearest != null:
			nearest.activate(self)

func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("Could not read %s" % path)
	return {}

func map_gameplay(point: Vector2) -> Vector2:
	var x: float = point.x * float(mapping["x_scale"]) + float(mapping["x_offset"])
	var anchors: Array = mapping["y_anchors"]
	var y := point.y
	for i in range(anchors.size() - 1):
		var a: Array = anchors[i]
		var b: Array = anchors[i + 1]
		if y <= float(b[0]):
			return Vector2(x, lerpf(float(a[1]), float(b[1]), (y - float(a[0])) / (float(b[0]) - float(a[0]))))
	return Vector2(x, float(anchors[-1][1]))

func _build_art() -> void:
	_add_canvas_layer("00_Repainted_Background_Shell", $BackgroundShellAndDeck)
	_add_canvas_layer("01_Floor_Clean", $BackgroundShellAndDeck)
	var manifest := _read_json(MANIFEST)
	for sprite_data in manifest["sprites"]:
		var name: String = sprite_data["name"]
		var texture := load(ART + "sprites/" + name + ".png") as Texture2D
		if texture == null:
			push_error("Missing sprite " + name)
			continue
		var sprite := Sprite2D.new()
		sprite.name = name
		sprite.texture = texture
		sprite.centered = false
		var top_left := Vector2(sprite_data["position_top_left"][0], sprite_data["position_top_left"][1])
		if name == "Window_Architecture":
			$WindowsAndWalls.add_child(sprite)
			sprite.position = top_left
		elif name.begins_with("Foreground_") or name == "Entrance_Threshold":
			$ForegroundArchitecture.add_child(sprite)
			sprite.position = top_left
		else:
			var bounds: Array = sprite_data["bbox_xywh"]
			var foot_y := float(bounds[1]) + float(bounds[3]) * 0.88
			actors.add_child(sprite)
			sprite.position = Vector2(0, foot_y)
			sprite.offset = top_left - sprite.position
			# The sorted origin is the object's floor contact, while offset preserves exact pixels.
	$WindowsAndWalls.z_index = 0
	$PermanentMachinery.z_index = 0
	$InteractiveFurniture.z_index = 0
	actors.z_index = 1
	$ForegroundArchitecture.z_index = 2

func _add_canvas_layer(name: String, parent: Node2D) -> void:
	var sprite := Sprite2D.new()
	sprite.name = name
	sprite.texture = load(ART + "full_canvas/" + name + ".png")
	sprite.centered = false
	parent.add_child(sprite)

func _build_collisions() -> void:
	# These footprints follow the painted walkable deck. ChamberForge markers remain visible in F3 debug.
	var obstacles: Dictionary = {
		"LeftChartDesk": [Vector2(135, 530), Vector2(350, 530), Vector2(335, 575), Vector2(135, 575)],
		"LeftPilotSeat": [Vector2(645, 455), Vector2(735, 455), Vector2(730, 505), Vector2(652, 505)],
		"RightPilotSeat": [Vector2(940, 455), Vector2(1020, 455), Vector2(1015, 505), Vector2(945, 505)],
		"HelmAndControlMachinery": [Vector2(465, 347), Vector2(1160, 347), Vector2(1160, 432), Vector2(1060, 432), Vector2(1050, 389), Vector2(910, 389), Vector2(900, 433), Vector2(760, 433), Vector2(750, 389), Vector2(630, 389), Vector2(618, 435), Vector2(465, 435)],
		"LoungeCouch": [Vector2(38, 645), Vector2(285, 645), Vector2(320, 700), Vector2(285, 790), Vector2(65, 790)],
		"LoungeTable": [Vector2(337, 703), Vector2(447, 703), Vector2(447, 782), Vector2(337, 782)],
		"RightCabinet": [Vector2(1260, 575), Vector2(1525, 575), Vector2(1525, 743), Vector2(1350, 743), Vector2(1260, 690)],
		"LeftFern": [Vector2(387, 481), Vector2(437, 481), Vector2(437, 517), Vector2(387, 517)],
		"LeftStool": [Vector2(345, 555), Vector2(381, 555), Vector2(381, 600), Vector2(345, 600)],
		"RightStool": [Vector2(1261, 657), Vector2(1305, 657), Vector2(1305, 714), Vector2(1261, 714)],
		"RightPlant": [Vector2(1535, 735), Vector2(1590, 735), Vector2(1590, 810), Vector2(1535, 810)]
	}
	for name in obstacles:
		_add_polygon(name, PackedVector2Array(obstacles[name]))
	# Painted room perimeter; closed at the bottom so the player cannot leave without E.
	var edge := PackedVector2Array([Vector2(130, 810), Vector2(75, 650), Vector2(110, 570), Vector2(225, 490), Vector2(370, 435), Vector2(500, 420), Vector2(1160, 420), Vector2(1300, 440), Vector2(1520, 520), Vector2(1590, 650), Vector2(1590, 810), Vector2(1450, 840), Vector2(970, 840), Vector2(970, 914), Vector2(700, 914), Vector2(700, 840), Vector2(225, 840)])
	for i in edge.size():
		_add_wall(edge[i], edge[(i + 1) % edge.size()])

func _add_polygon(name: String, polygon: PackedVector2Array) -> void:
	var body := StaticBody2D.new()
	body.name = name
	var shape := CollisionPolygon2D.new()
	shape.polygon = polygon
	body.add_child(shape)
	collision_root.add_child(body)
	body.set_meta("outline", polygon)

func _add_wall(a: Vector2, b: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = "Wall"
	var shape := CollisionShape2D.new()
	var segment := SegmentShape2D.new()
	segment.a = a
	segment.b = b
	shape.shape = segment
	body.add_child(shape)
	collision_root.add_child(body)
	body.set_meta("outline", PackedVector2Array([a, b]))

func _build_actors_and_interactions() -> void:
	_add_interaction("Inspect Helm", "The Flying Liberty answers to the helm.", Vector2(835, 445), 95)
	_add_interaction("View Navigation", "Routes and weather charts cover the navigation desk.", Vector2(310, 588), 85)
	_add_interaction("Inspect Controls", "Pressure steady. All engines responding.", Vector2(1080, 450), 90)
	var door_data := _object("hubDoor")
	var door := DOOR.new() as CockpitDoor
	door.name = "MainHallDoor"
	door.position = map_gameplay(Vector2(door_data["x"], door_data["y"]))
	door.prompt = "Enter Main Hall"
	door.radius = 85
	door.target_room_id = str(door_data["target"])
	door.locked = bool(door_data.get("locked", false))
	# A later Main Hall scene can be added here without changing the interaction code.
	door.target_scene = "res://scenes/FlyingLibertyMainHall.tscn"
	interactions.add_child(door)
	interactables.append(door)

func _object(kind: String) -> Dictionary:
	for object in layout["objects"]:
		if object["kind"] == kind:
			return object
	return {}

func _add_interaction(prompt: String, message: String, at: Vector2, radius: float) -> void:
	var item := INTERACTABLE.new() as CockpitInteractable
	item.name = prompt.replace(" ", "")
	item.position = at
	item.prompt = prompt
	item.message = message
	item.radius = radius
	interactions.add_child(item)
	interactables.append(item)

func _nearest_interactable() -> CockpitInteractable:
	var nearest: CockpitInteractable
	var distance := INF
	for item in interactables:
		var d := item.global_position.distance_to(player.global_position)
		if d <= item.radius and d < distance:
			nearest = item
			distance = d
	return nearest

func _build_ui() -> void:
	prompt_label = Label.new()
	prompt_label.position = Vector2(485, 625)
	prompt_label.custom_minimum_size = Vector2(310, 40)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 24)
	prompt_label.add_theme_color_override("font_color", Color("ffe6b2"))
	ui.add_child(prompt_label)
	panel = PanelContainer.new()
	panel.position = Vector2(380, 500)
	panel.custom_minimum_size = Vector2(520, 115)
	var box := VBoxContainer.new()
	panel.add_child(box)
	panel_title = Label.new()
	panel_title.add_theme_font_size_override("font_size", 25)
	box.add_child(panel_title)
	panel_text = Label.new()
	panel_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(panel_text)
	ui.add_child(panel)
	panel.hide()
	var hint := Label.new()
	hint.text = "WASD move   E interact   F3 collision / layout"
	hint.position = Vector2(20, 18)
	hint.add_theme_color_override("font_color", Color("fff0ce"))
	ui.add_child(hint)

func show_message(title: String, message: String) -> void:
	panel_title.text = title
	panel_text.text = message + "\n[E] Close"
	panel.show()

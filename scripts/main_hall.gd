extends Node2D

const DOOR := preload("res://scripts/cockpit_door.gd")
const PASSAGE := preload("res://scripts/room_passage.gd")
const JUKEBOX_INTERACTABLE := preload("res://scripts/jukebox_interactable.gd")
const JUKEBOX_SHADER := preload("res://scripts/jukebox_cutout.gdshader")
const WING_START_X := 1590.0
const WING_TOP_Y := 175.0
const WING_TILE_WIDTH := 225.0
const BEDROOM_COUNT := 6

@onready var player: CharacterBody2D = $Player
var doors: Array[CockpitDoor] = []
var interactables: Array[CockpitInteractable] = []
var jukebox_hud: CanvasLayer
var closed_jukebox_frame := -1
var prompt: Label
var panel: PanelContainer
var panel_title: Label
var panel_text: Label

var npc_controller: Node

func _ready() -> void:
	get_node("/root/BackgroundMusic").play_ship()
	add_child(preload("res://scripts/ship_menu.gd").new())
	var entry_id := CockpitDoor.take_entry_id()
	if entry_id == "from_sync":
		player.position = Vector2(521, 335)
	elif entry_id == "from_workshop":
		player.position = Vector2(180, 550)
	else:
		player.position = Vector2(844, 335)
	_build_right_wing()
	_build_collision()
	_build_doors()
	_build_passages()
	_build_jukebox()
	_build_ui()
	npc_controller = preload("res://scripts/ship_npcs.gd").new()
	npc_controller.room_id = "hall"
	add_child(npc_controller)
	$Player/Camera2D.make_current()
	$Player/Camera2D.reset_smoothing()
	$Player/Camera2D.force_update_scroll()

func _process(_delta: float) -> void:
	if npc_controller.blocks_room_input():
		return
	if jukebox_hud != null and jukebox_hud.visible:
		prompt.text = ""
		if Input.is_action_just_pressed("interact"):
			if jukebox_hud.get("opened_frame") != Engine.get_process_frames():
				jukebox_hud.close_jukebox()
		return
	if closed_jukebox_frame == Engine.get_process_frames():
		prompt.text = ""
		return
	var nearest := _nearest_interaction()
	prompt.text = "[E] %s" % nearest.prompt if nearest != null and not panel.visible else ""
	if Input.is_action_just_pressed("interact"):
		if panel.visible:
			panel.hide()
		elif nearest != null:
			nearest.activate(self)

func _build_doors() -> void:
	# Left to right in the supplied hall painting: the second top door is the cockpit.
	_add_door("FirstTopDoor", Vector2(521, 282), "Enter Sync Chamber", "fly_sync", "res://scenes/FlyingLibertySyncChamber.tscn", false)
	_add_door("CockpitDoor", Vector2(844, 277), "Enter Cockpit", "fly_cockpit", "res://scenes/FlyingLibertyCockpit.tscn", false)
	for i in BEDROOM_COUNT:
		var number := i + 1
		_add_door("BedroomDoor%d" % number, Vector2(WING_START_X + 140.0 + i * WING_TILE_WIDTH, WING_TOP_Y + 190.0), "Enter Bedroom %d" % number, "bedroom_%02d" % number, "", false)

func _build_passages() -> void:
	var workshop_entrance := PASSAGE.new()
	workshop_entrance.name = "WorkshopEntrance"
	workshop_entrance.position = Vector2(95, 550)
	workshop_entrance.half_extent = Vector2(25, 45)
	workshop_entrance.target_scene = "res://scenes/FlyingLibertyWorkshop.tscn"
	workshop_entrance.target_entry_id = "from_hall"
	$Passages.add_child(workshop_entrance)

	var sync_entrance := PASSAGE.new()
	sync_entrance.name = "SyncChamberEntrance"
	sync_entrance.position = Vector2(521, 255)
	sync_entrance.half_extent = Vector2(35, 15)
	sync_entrance.target_scene = "res://scenes/FlyingLibertySyncChamber.tscn"
	sync_entrance.target_entry_id = "from_hall"
	$Passages.add_child(sync_entrance)

	var cockpit_entrance := PASSAGE.new()
	cockpit_entrance.name = "CockpitEntrance"
	cockpit_entrance.position = Vector2(844, 255)
	cockpit_entrance.half_extent = Vector2(35, 15)
	cockpit_entrance.target_scene = "res://scenes/FlyingLibertyCockpit.tscn"
	cockpit_entrance.target_entry_id = "from_hall"
	$Passages.add_child(cockpit_entrance)

func _build_right_wing() -> void:
	# Reuse the existing painted left corridor and its top-door artwork as texture regions.
	# No pixels in the source painting are altered. The first tile mirrors the left junction.
	var texture: Texture2D = $HallArtwork.texture
	for i in BEDROOM_COUNT:
		var x := WING_START_X + i * WING_TILE_WIDTH
		_add_wing_strip(texture, "BedroomWall%d" % (i + 1), Rect2(75, 385, 225, 125), Vector2(x, WING_TOP_Y), 1.0)
		_add_wing_strip(texture, "BedroomCarpet%d" % (i + 1), Rect2(75, 510, 225, 70), Vector2(x, WING_TOP_Y + 125), 1.6)
		_add_wing_strip(texture, "BedroomLowerTrim%d" % (i + 1), Rect2(75, 580, 225, 35), Vector2(x, WING_TOP_Y + 237), 1.0)
		var door_art := Sprite2D.new()
		door_art.name = "BedroomDoorArt%d" % (i + 1)
		door_art.texture = texture
		door_art.region_enabled = true
		door_art.region_rect = Rect2(445, 22, 165, 265)
		door_art.centered = false
		door_art.scale = Vector2(0.64, 0.64)
		door_art.position = Vector2(WING_START_X + 90 + i * WING_TILE_WIDTH, WING_TOP_Y + 2)
		$RightBedroomWing.add_child(door_art)

func _add_wing_strip(texture: Texture2D, node_name: String, region: Rect2, at: Vector2, vertical_scale: float) -> void:
	var strip := Sprite2D.new()
	strip.name = node_name
	strip.texture = texture
	strip.region_enabled = true
	strip.region_rect = region
	strip.centered = false
	strip.flip_h = true
	strip.scale.y = vertical_scale
	strip.position = at
	$RightBedroomWing.add_child(strip)

func _add_door(node_name: String, at: Vector2, label: String, target_id: String, target_path: String, is_locked: bool) -> void:
	var door := DOOR.new() as CockpitDoor
	door.name = node_name
	door.position = at
	door.prompt = label
	door.radius = 86.0
	door.target_room_id = target_id
	door.target_scene = target_path
	door.target_entry_id = "from_hall" if target_id == "fly_sync" else ""
	door.locked = is_locked
	$Doors.add_child(door)
	doors.append(door)
	interactables.append(door)

func _nearest_door() -> CockpitDoor:
	var nearest: CockpitDoor
	var distance := INF
	for door in doors:
		var d := door.global_position.distance_to(player.global_position)
		if d <= door.radius and d < distance:
			nearest = door
			distance = d
	return nearest

func _nearest_interaction() -> CockpitInteractable:
	var nearest: CockpitInteractable
	var distance := INF
	for item in interactables:
		var d := item.global_position.distance_to(player.global_position)
		if d <= item.radius and d < distance:
			nearest = item
			distance = d
	return nearest

func _build_jukebox() -> void:
	var jb_container := Node2D.new()
	jb_container.name = "JukeboxProp"
	jb_container.z_index = 0

	var sprite := Sprite2D.new()
	sprite.name = "JukeboxSprite"
	sprite.texture = preload("res://HUD/jukebox.png")
	sprite.centered = false
	sprite.scale = Vector2(0.42, 0.42)
	sprite.position = Vector2(680.0 - (260.0 * 0.42) / 2.0, 280.0 - (348.0 * 0.42))

	var mat := ShaderMaterial.new()
	mat.shader = JUKEBOX_SHADER
	sprite.material = mat
	jb_container.add_child(sprite)
	add_child(jb_container)

	var jb = JUKEBOX_INTERACTABLE.new()
	jb.name = "Jukebox"
	jb.position = Vector2(680.0, 275.0)
	jb.prompt = "Play Jukebox"
	jb.radius = 95.0
	add_child(jb)
	interactables.append(jb)

	_add_obstacle("JukeboxObstacle", PackedVector2Array([
		Vector2(635, 230), Vector2(725, 230),
		Vector2(725, 280), Vector2(635, 280)
	]))

	if has_node("JukeboxHUD"):
		jukebox_hud = get_node("JukeboxHUD") as CanvasLayer
	else:
		jukebox_hud = preload("res://scenes/ui/JukeboxHUD.tscn").instantiate() as CanvasLayer
		add_child(jukebox_hud)
	jukebox_hud.closed.connect(_on_jukebox_closed)

func open_jukebox() -> void:
	player.set("controls_enabled", false)
	jukebox_hud.open_jukebox()

func _on_jukebox_closed() -> void:
	closed_jukebox_frame = Engine.get_process_frames()
	player.set("controls_enabled", true)


func _build_collision() -> void:
	# The hall painting is a single image; collision is fitted to its visible walkable deck.
	var boundary := PackedVector2Array([Vector2(65, 590), Vector2(65, 400), Vector2(330, 400), Vector2(330, 225), Vector2(1545, 225), Vector2(1545, 300), Vector2(2940, 300), Vector2(2940, 410), Vector2(1545, 410), Vector2(1545, 700), Vector2(940, 700), Vector2(940, 850), Vector2(750, 850), Vector2(750, 700), Vector2(300, 700), Vector2(300, 590)])
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
	hint.text = "MAIN HALL   WASD move   Space run   E interact"
	hint.position = Vector2(20, 18)
	hint.add_theme_color_override("font_color", Color("fff0ce"))
	$InteractionUI.add_child(hint)

func show_message(title: String, message: String) -> void:
	panel_title.text = title
	panel_text.text = message + "\n[E] Close"
	panel.show()

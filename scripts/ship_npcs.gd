extends Node

const CATALOG := preload("res://scripts/npc_catalog.gd")
const DIALOGUE := preload("res://scripts/npc_dialogue.gd")
const FIXED := {
	"hall": [{"id":"old_man", "at":Vector2(455,510), "talk":Vector2(455,363)}, {"id":"kids", "at":Vector2(1050,555), "talk":Vector2(1000,540)}, {"id":"cook", "at":Vector2(1465,650)}],
	"sync": [{"id":"handler", "at":Vector2(1215,635)}],
	"workshop": [{"id":"engineer", "at":Vector2(875,845)}, {"id":"mechanic", "at":Vector2(435,650)}]
}
const COCKPIT_POSITIONS := [Vector2(540,555),Vector2(1105,555)]
var room_id := ""
var room: Node2D
var actors: Dictionary = {}
var talk_positions: Dictionary = {}
var dialogue: CanvasLayer
var handled_frame := -1

func _ready() -> void:
	name = "ShipNPCs"
	room = get_parent()
	dialogue = DIALOGUE.new()
	dialogue.name = "NPCDialogue"
	add_child(dialogue)
	dialogue.closed.connect(func(): handled_frame = Engine.get_process_frames())
	if room_id == "cockpit":
		var layout: Dictionary = get_node("/root/ShipCrew").cockpit_layout
		for id in layout:
			_spawn({"id":id,"at":COCKPIT_POSITIONS[layout[id]]})
	else:
		for entry in FIXED.get(room_id, []):
			_spawn(entry)

func _spawn(entry: Dictionary) -> void:
	var actor := Node2D.new()
	actor.name = entry.id.to_pascal_case() + "NPC"
	actor.position = entry.at
	var art := CATALOG.visual(entry.id)
	var data: Dictionary = CATALOG.NPCS[entry.id]
	art.scale = Vector2.ONE * data.scale
	art.position = -data.anchor * data.scale
	actor.add_child(art)
	if room_id == "cockpit":
		room.get_node("PlayerAndNPCs").add_child(actor)
	else:
		room.add_child(actor)
	actors[entry.id] = actor
	talk_positions[entry.id] = entry.get("talk",entry.at)

func can_talk() -> bool:
	return room.player.controls_enabled and not room.panel.visible

func nearest() -> String:
	var found := ""
	var distance := 90.0
	if not can_talk():
		return found
	for id in talk_positions:
		var d: float = room.player.position.distance_to(talk_positions[id])
		if d < distance:
			distance = d
			found = id
	return found

func blocks_room_input() -> bool:
	return dialogue.active or handled_frame == Engine.get_process_frames()

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	if dialogue.active:
		dialogue.advance()
	else:
		var id := nearest()
		if id == "":
			return
		dialogue.open(id,room.player)
	handled_frame = Engine.get_process_frames()
	get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	for actor in actors.values():
		if room_id != "cockpit":
			actor.z_index = 0 if actor.position.y < room.player.position.y else 2
	var prompt: Label = room.prompt_label if room_id == "cockpit" else room.prompt
	if dialogue.active:
		prompt.text = ""
	else:
		var id := nearest()
		if id != "":
			prompt.text = "[E] Talk to " + CATALOG.NPCS[id].name

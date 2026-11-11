extends CockpitInteractable
class_name CockpitDoor

@export var locked := false
@export var target_room_id := "fly_hall"
@export_file("*.tscn") var target_scene := ""
@export var target_entry_id := ""

static var pending_entry_id := ""

static func take_entry_id() -> String:
	var entry := pending_entry_id
	pending_entry_id = ""
	return entry

func activate(room: Node) -> void:
	if locked:
		room.show_message("Door locked", "The way to %s is locked." % target_room_id)
	elif target_scene != "" and ResourceLoader.exists(target_scene):
		pending_entry_id = target_entry_id
		get_tree().change_scene_to_file(target_scene)
	else:
		room.show_message("%s — room pending" % prompt, "This door leads to %s. Its room scene has not been added yet." % target_room_id)

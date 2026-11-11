extends CockpitInteractable
class_name CockpitDoor

@export var locked := false
@export var target_room_id := "fly_hall"
@export_file("*.tscn") var target_scene := ""

func activate(room: Node) -> void:
	if locked:
		room.show_message("Door locked", "The way to %s is locked." % target_room_id)
	elif target_scene != "" and ResourceLoader.exists(target_scene):
		get_tree().change_scene_to_file(target_scene)
	else:
		room.show_message("Main Hall — temporary transition", "Main Hall scene is not in this project yet. This exit targets %s." % target_room_id)

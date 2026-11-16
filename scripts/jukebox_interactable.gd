extends CockpitInteractable
class_name JukeboxInteractable

func activate(room: Node) -> void:
	if room.has_method("open_jukebox"):
		room.open_jukebox()
	elif room.has_node("JukeboxHUD"):
		room.get_node("JukeboxHUD").open_jukebox()
	else:
		room.show_message(prompt, "The Jukebox stands silent.")

extends CockpitInteractable
class_name CoreInteractable

func activate(room: Node) -> void:
	room.open_core_terminal()

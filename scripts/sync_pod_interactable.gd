extends CockpitInteractable
class_name SyncPodInteractable

func activate(room: Node) -> void:
	room.open_run_setup()

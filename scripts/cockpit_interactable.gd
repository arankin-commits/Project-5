extends Node2D
class_name CockpitInteractable

@export var prompt := "Interact"
@export_multiline var message := ""
@export var radius := 75.0

func in_range(point: Vector2) -> bool:
	return global_position.distance_to(point) <= radius

func activate(room: Node) -> void:
	room.show_message(prompt, message)

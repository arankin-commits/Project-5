extends Area2D
class_name RoomPassage

@export var half_extent := Vector2(35, 45)
@export_file("*.tscn") var target_scene := ""
@export var target_entry_id := ""

var transitioning := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := RectangleShape2D.new()
	shape.size = half_extent * 2.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if transitioning or not body is CharacterBody2D or not ResourceLoader.exists(target_scene):
		return
	transitioning = true
	call_deferred("_travel")

func _travel() -> void:
	CockpitDoor.pending_entry_id = target_entry_id
	get_tree().change_scene_to_file(target_scene)

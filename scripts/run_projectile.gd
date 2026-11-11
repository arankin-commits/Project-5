extends Node2D

var velocity := Vector2.ZERO
var target: CharacterBody2D
var damage := 12.0
var lifetime := 5.0

func _ready() -> void:
	z_index = 4

func _physics_process(delta: float) -> void:
	lifetime -= delta
	var next := global_position + velocity*delta
	var query := PhysicsRayQueryParameters2D.create(global_position,next,1)
	if lifetime <= 0 or not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		queue_free()
		return
	if is_instance_valid(target) and Geometry2D.get_closest_point_to_segment(target.global_position,global_position,next).distance_to(target.global_position) < 22:
		target.call("take_damage",damage)
		queue_free()
		return
	global_position = next
	queue_redraw()

func _draw() -> void:
	draw_line(Vector2.ZERO, -velocity.normalized()*22, Color(1,0.3,0.07,0.7),7,true)
	draw_circle(Vector2.ZERO,6,Color("ffca71"))
	draw_circle(Vector2.ZERO,3,Color("fff3c6"))

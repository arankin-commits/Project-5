extends Node2D

var velocity := Vector2.ZERO
var damage := 32.0
var lifetime := 2.5
var can_return := false
var returning := false
var origin_player: CharacterBody2D = null
var rotation_speed := 8.0
var enemies_node: Node2D = null
var projectiles_node: Node2D = null
var effects_callback: Callable

func _ready() -> void:
	z_index = 6

func _physics_process(delta: float) -> void:
	lifetime -= delta
	rotation += rotation_speed * delta
	if lifetime <= 0.0:
		queue_free()
		return
	
	if returning and is_instance_valid(origin_player):
		var to_player := origin_player.global_position - global_position
		if to_player.length() < 28.0:
			queue_free()
			return
		velocity = to_player.normalized() * 520.0

	var next := global_position + velocity * delta
	
	# Deflect enemy projectiles
	if is_instance_valid(projectiles_node):
		for proj in projectiles_node.get_children():
			if is_instance_valid(proj) and proj != self and proj.global_position.distance_to(global_position) < 30.0:
				if effects_callback.is_valid():
					effects_callback.call(proj.global_position, "rocksplosion", 35.0, Color("c89650"))
				proj.queue_free()

	# Damage enemy
	if is_instance_valid(enemies_node):
		for enemy in enemies_node.get_children():
			if is_instance_valid(enemy) and enemy.get("health") > 0:
				if enemy.global_position.distance_to(global_position) < 32.0:
					enemy.call("take_damage", damage, velocity.normalized(), 35.0, "earth")
					if effects_callback.is_valid():
						effects_callback.call(global_position, "rocksplosion", 50.0, Color("c89650"))
					if can_return and not returning:
						returning = true
						damage *= 0.5
						return
					queue_free()
					return

	global_position = next

func _draw() -> void:
	var pts: PackedVector2Array = [
		Vector2(-10, 6),
		Vector2(-4, -10),
		Vector2(8, -8),
		Vector2(11, 4),
		Vector2(3, 10)
	]
	draw_colored_polygon(pts, Color("8d6e53"))
	draw_polyline(pts, Color("d1a873"), 2.0)
	draw_circle(Vector2(-2, -2), 3.0, Color("c89650"))

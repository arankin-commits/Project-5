extends CharacterBody2D

signal defeated(enemy: CharacterBody2D)
signal projectile_requested(origin: Vector2, direction: Vector2, damage: float)
signal impact_requested(point: Vector2, radius: float)

const Space := preload("res://scripts/boiler_space.gd")
var target: CharacterBody2D
var room: Node2D
var kind := "crawler"
var speed := 104.0
var health := 60.0
var max_health := 60.0
var damage := 12.0
var active := true
var state := "chase"
var cooldown := 1.0
var windup := 0.0
var attack_number := 0
var attack_kind := "slam"
var attack_point := Vector2.ZERO
var attack_direction := Vector2.DOWN
var facing := Vector2.DOWN
var wall_stun_timer := 0.0
var slow_timer := 0.0
var phase_two := false
var hit_flash := 0.0
var path_timer := 0.0
var path := PackedVector2Array()
var stride := 0.0
var visual: Sprite2D

func _ready() -> void:
	collision_layer = 4
	collision_mask = 1
	var cell := 3
	var size := 0.24
	if kind == "sentry":
		cell = 4
		size = 0.28
		health = 75
		speed = 0
	elif kind == "brute":
		size = 0.34
		health = 145
		damage = 18
		speed *= 0.7
	elif kind == "boss":
		cell = 5
		size = 0.59
		health = 1250
		damage = 22
		speed *= 0.65
	max_health = health
	var shape := CircleShape2D.new()
	shape.radius = 30.0 if kind == "boss" else 17.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	visual = Sprite2D.new()
	visual.name = "EnemyVisual"
	visual.texture = Space.atlas(cell)
	visual.scale = Vector2.ONE * size
	visual.offset.y = -220
	add_child(visual)

func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(target) or health <= 0:
		return
	slow_timer = maxf(0, slow_timer - delta)
	if wall_stun_timer > 0:
		wall_stun_timer = maxf(0, wall_stun_timer - delta)
		velocity = Vector2.ZERO
		queue_redraw()
		return
	cooldown -= delta
	hit_flash = maxf(0,hit_flash-delta)
	stride += delta * 12
	visual.modulate = Color(2,1.6,1.2) if hit_flash > 0 else Color.WHITE
	if kind == "brute":
		visual.modulate *= Color(1.2,0.72,0.65)
	visual.position.y = -absf(sin(stride))*1.8 if velocity.length() > 5 else 0
	visual.flip_h = facing.x > 0
	velocity = Vector2.ZERO
	phase_two = kind == "boss" and health <= max_health * 0.5
	if state == "windup":
		windup -= delta
		if windup <= 0:
			_release_attack()
	elif state == "charge":
		windup -= delta
		velocity = attack_direction * (620 if phase_two else 490)
		if global_position.distance_to(target.global_position) < 55:
			target.call("take_damage",damage)
		if windup <= 0 or is_on_wall():
			state = "chase"
			cooldown = 1.0
	else:
		var distance := position.distance_to(target.position)
		if cooldown <= 0 and (distance < 87 or kind in ["sentry","boss"]):
			_begin_attack()
		elif kind != "sentry":
			path_timer -= delta
			if path_timer <= 0:
				path = room.call("path_between",position,target.position)
				path_timer = 0.35
			while path.size() > 1 and position.distance_to(path[0]) < 22:
				path.remove_at(0)
			var goal := path[0] if not path.is_empty() else target.position
			if distance < 95:
				goal = target.position
			velocity = position.direction_to(goal) * speed * (1.25 if phase_two else 1.0)
			for other in get_parent().get_children():
				if other != self and is_instance_valid(other) and other is CharacterBody2D:
					var offset: Vector2 = global_position-other.global_position
					if offset.length() < 40 and offset.length() > 1:
						velocity += offset.normalized()*30
	if state == "chase" and velocity.length_squared() > 1:
		facing = facing.slerp(velocity.normalized(), minf(1.0, delta * 5.0)).normalized()
	if slow_timer > 0:
		velocity *= 0.5
	move_and_slide()
	queue_redraw()

func _begin_attack() -> void:
	state = "windup"
	attack_number += 1
	attack_point = target.global_position
	attack_direction = global_position.direction_to(attack_point)
	facing = attack_direction
	attack_kind = "shot" if kind == "sentry" else "slam"
	windup = 0.65
	if kind == "boss":
		attack_kind = ["slam","volley","charge"][attack_number % 3]
		windup = 0.85 if phase_two else 1.1
	elif kind == "brute":
		windup = 0.9
	if kind not in ["sentry","boss"]:
		attack_point = global_position + attack_direction*30

func _release_attack() -> void:
	state = "chase"
	cooldown = 1.5 if kind == "boss" else 1.25
	if phase_two:
		cooldown = 0.85
	match attack_kind:
		"shot":
			projectile_requested.emit(global_position,attack_direction,damage)
		"volley":
			var count := 11 if phase_two else 7
			for i in count:
				var angle := attack_direction.angle() + (i-(count-1)*0.5)*0.22
				projectile_requested.emit(global_position,Vector2.from_angle(angle),damage*0.7)
		"charge":
			state = "charge"
			windup = 0.6
		"slam":
			var radius := attack_radius()
			impact_requested.emit(attack_point,radius)
			var offset := (target.global_position-attack_point)*Vector2(1,1.0/0.65)
			if offset.length() < radius:
				target.call("take_damage",damage)

func attack_radius() -> float:
	if kind == "boss":
		return 180.0 if phase_two else 145.0
	return 105.0 if kind == "brute" else 78.0

func is_backstab(origin: Vector2) -> bool:
	# Rear 120-degree cone; windups and charges retain their committed facing.
	var to_attacker := global_position.direction_to(origin)
	return to_attacker.dot(facing.normalized()) < -0.5

func apply_knockback(direction: Vector2, distance: float) -> void:
	if kind == "boss" or health <= 0:
		return
	var collision := move_and_collide(direction.normalized() * distance)
	if collision != null:
		wall_stun_timer = 1.5
		state = "chase"
		cooldown = 1.0
	queue_redraw()

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO, push_distance := 12.0) -> void:
	if health <= 0:
		return
	health = maxf(0,health-amount)
	hit_flash = 0.12
	if kind != "boss" and knockback.length_squared() > 0:
		apply_knockback(knockback, push_distance)
	if health <= 0:
		active = false
		defeated.emit(self)
		queue_free()
	queue_redraw()

func _draw() -> void:
	if wall_stun_timer > 0:
		draw_arc(Vector2(0,-95), 18, 0, TAU, 24, Color("fff0a0"), 3, true)
	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.5))
	draw_circle(Vector2.ZERO,30 if kind != "boss" else 70,Color(0,0,0,0.45))
	draw_arc(Vector2.ZERO,23 if kind != "boss" else 65,0,TAU,32,Color(1,0.3,0.1,0.65),2,true)
	draw_set_transform(Vector2.ZERO)
	if state == "windup":
		var p := attack_point-global_position
		if attack_kind == "slam":
			draw_set_transform(p,0,Vector2(1,0.65))
			draw_circle(Vector2.ZERO,attack_radius(),Color(1,0.12,0.04,0.17))
			draw_arc(Vector2.ZERO,attack_radius(),0,TAU,48,Color("ff6d36"),3,true)
			draw_arc(Vector2.ZERO,attack_radius()*clampf(1-windup,0,1),0,TAU,48,Color(1,0.7,0.2,0.6),2,true)
		else:
			draw_line(Vector2.ZERO,attack_direction*(360 if attack_kind=="charge" else 270),Color(1,0.35,0.1,0.6),4,true)
		draw_set_transform(Vector2.ZERO)
	if health < max_health and kind != "boss":
		draw_rect(Rect2(-25,-115,50,5),Color("261b17"))
		draw_rect(Rect2(-25,-115,50*health/max_health,5),Color("ef9c55"))

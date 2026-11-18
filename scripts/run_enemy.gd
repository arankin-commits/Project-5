extends CharacterBody2D

signal defeated(enemy: CharacterBody2D)
signal projectile_requested(origin: Vector2, direction: Vector2, damage: float)
signal impact_requested(point: Vector2, radius: float)
signal damaged(amount: float, knockback: Vector2, element: String)

const Space := preload("res://scripts/boiler_space.gd")
const SCREEN_DISTANCE := 750.0
var target: CharacterBody2D
var room: Node2D
var kind := "crawler"
var display_name := "FURNACE WARDEN"
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
var custom_attack_warning := false
var is_in_knockback := false
var is_dead := false
var enemy_size := "Medium"
var elemental_state := ElementalSystem.StatusState.new()
var toxin_tick_timer := 0.0

func _init() -> void:
	collision_layer = 4
	collision_mask = 9

func _ready() -> void:
	collision_layer = 4
	collision_mask = 9
	var cell := 3
	var size := 0.24
	if kind == "sentry":
		cell = 4
		size = 0.28
		health = 75
		speed = 0.0
		enemy_size = "Medium"
	elif kind == "brute":
		size = 0.34
		health = 145
		damage = 18
		enemy_size = "Large"
	elif kind == "boss":
		cell = 5
		size = 0.59
		health = 1250
		damage = 22
		enemy_size = "Large"
	else:
		enemy_size = "Medium"

	var config = get_node_or_null("/root/RunConfig")
	if kind == "sentry":
		speed = 0.0
	elif config != null and config.has_method("get_enemy_speed_by_size"):
		speed = config.get_enemy_speed_by_size(enemy_size)
	else:
		match enemy_size.to_lower():
			"tiny": speed = 331.25
			"small": speed = 304.75
			"medium": speed = 265.0
			"large": speed = 185.5
			_: speed = 265.0
	max_health = health
	elemental_state.is_boss = (kind == "boss")
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
	elemental_state.update(delta)
	if elemental_state.is_burning() and elemental_state.burn_tick_timer <= 0.0:
		elemental_state.burn_tick_timer = 1.0
		var burn_tick_dmg := ElementalSystem.calculate_burn_tick(6.0, elemental_state, 0.50)
		take_damage(burn_tick_dmg, Vector2.ZERO, 0.0, "burn", "dot")
	if elemental_state.is_wet() and is_instance_valid(target) and target.get("cards") != null:
		var p_cards: Array = target.cards
		if p_cards.has("rust") and elemental_state.rust_tick_timer <= 0.0:
			elemental_state.rust_tick_timer = 1.0
			elemental_state.rust_consecutive_ticks += 1
			var rust_dmg := 8.0
			if p_cards.has("wear_and_tear"):
				rust_dmg = minf(32.0, 8.0 + (elemental_state.rust_consecutive_ticks - 1) * 3.0)
			take_damage(rust_dmg, Vector2.ZERO, 0.0, "rust", "dot")
	if elemental_state.is_toxin():
		toxin_tick_timer -= delta
		if toxin_tick_timer <= 0.0:
			toxin_tick_timer = 1.0
			take_damage(7.0, Vector2.ZERO, 0.0, "toxin", "dot")
	if wall_stun_timer > 0 or elemental_state.is_frozen():
		if wall_stun_timer > 0:
			wall_stun_timer = maxf(0, wall_stun_timer - delta)
		velocity = Vector2.ZERO
		move_and_slide()
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
	if elemental_state.is_burning() or elemental_state.is_wet() or elemental_state.is_toxin():
		queue_redraw()
	phase_two = kind == "boss" and health <= max_health * 0.5
	if state == "windup":
		windup -= delta
		if windup <= 0:
			_release_attack()
	elif state == "charge":
		windup -= delta
		velocity = attack_direction * (620 if phase_two else 490)
		if global_position.distance_to(target.global_position) < 55:
			var wet_red := 0.35 if (is_instance_valid(target) and target.get("cards") != null and target.cards.has("water_damage")) else 0.20
			var eff_dmg := damage * (1.0 - wet_red) if elemental_state.is_wet() else damage
			target.call("take_damage", eff_dmg, self, false)
		if windup <= 0 or is_on_wall():
			state = "chase"
			cooldown = 1.0
	else:
		var distance := position.distance_to(target.position)
		if cooldown <= 0 and distance < attack_reach():
			_begin_attack()
		elif kind != "sentry":
			path_timer -= delta
			if path_timer <= 0:
				if is_instance_valid(room):
					path = room.call("path_between",position,target.position)
				else:
					path = PackedVector2Array([target.position])
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
	elif kind == "sentry" and is_instance_valid(target) and position.distance_to(target.position) <= SCREEN_DISTANCE:
		facing = global_position.direction_to(target.global_position)
	if slow_timer > 0:
		velocity *= 0.5
	if elemental_state.is_muddy():
		velocity *= 0.8
	if elemental_state.is_frost():
		velocity *= 0.75
	if elemental_state.is_toxin():
		velocity *= 0.6 if _player_cards().has("paralytic_venom") else 0.75
	move_and_slide()
	queue_redraw()

func has_line_of_sight_to_target() -> bool:
	if not is_instance_valid(target):
		return false
	var space := get_world_2d().direct_space_state
	if space == null:
		return true
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
	return space.intersect_ray(query).is_empty()

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

func attack_reach() -> float:
	if kind == "boss":
		return INF
	if kind == "sentry":
		if not has_line_of_sight_to_target():
			return 0.0
		return SCREEN_DISTANCE
	return 87.0

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
				var wet_red := 0.35 if (is_instance_valid(target) and target.get("cards") != null and target.cards.has("water_damage")) else 0.20
				var eff_dmg := damage * (1.0 - wet_red) if elemental_state.is_wet() else damage
				target.call("take_damage", eff_dmg, self, false)

func attack_radius() -> float:
	if kind == "boss":
		return 180.0 if phase_two else 145.0
	return 105.0 if kind == "brute" else 78.0

func is_backstab(origin: Vector2) -> bool:
	# Rear 120-degree cone; windups and charges retain their committed facing.
	var to_attacker := global_position.direction_to(origin)
	return to_attacker.dot(facing.normalized()) < -0.5

func _player_cards() -> Array:
	if is_instance_valid(target) and "cards" in target and target.cards != null:
		return target.cards
	return []

func calculate_collision_damage(knockback_power: float) -> float:
	if knockback_power <= 0.0:
		return 0.0
	return maxf(1.0, roundf(knockback_power * 0.5))

func apply_knockback(direction: Vector2, distance: float, knockback_source := "regular") -> void:
	if health <= 0 or is_in_knockback:
		return
	var eff_distance := distance * 0.5 if kind == "boss" else distance
	is_in_knockback = true
	var old_mask := collision_mask
	collision_mask |= 4
	var collision := move_and_collide(direction.normalized() * eff_distance)
	collision_mask = old_mask
	if collision != null:
		var collider: Object = collision.get_collider()
		var col_damage := calculate_collision_damage(eff_distance)
		var p_cards: Array = _player_cards()
		if knockback_source == "wind":
			col_damage = maxf(col_damage, 16.0)
			if p_cards.has("come_hither"):
				col_damage += 12.0
			if p_cards.has("wind_bomb") and knockback_source != "secondary" and get_parent() != null:
				for other in get_parent().get_children():
					if other != self and is_instance_valid(other) and other is CharacterBody2D and other.health > 0.0:
						if global_position.distance_to(other.global_position) <= 130.0:
							other.take_damage(24.0, global_position.direction_to(other.global_position), 80.0, "wind", "secondary")
		if kind != "boss":
			wall_stun_timer = 0.3
			state = "chase"
			cooldown = 1.0
		else:
			wall_stun_timer = 0.15 * maxf(0.2, 1.0 - elemental_state.cc_resistance)
			elemental_state.cc_resistance = minf(0.8, elemental_state.cc_resistance + 0.2)
		if is_instance_valid(collider) and collider != self and collider is CharacterBody2D and (target == null or collider != target):
			var enemy_col_damage := 8.0 if p_cards.has("pinball") else col_damage
			if p_cards.has("pinball"):
				col_damage = 8.0
			if knockback_source == "wind" and (elemental_state.is_burning() or elemental_state.is_wet()):
				if collider.get("elemental_state") != null:
					ElementalSystem.apply_wet(collider.elemental_state, 4.0)
			if collider.has_method("take_damage"):
				collider.call("take_damage", enemy_col_damage, Vector2.ZERO, 0.0, "regular")
			if collider.get("kind") != "boss":
				if collider.get("wall_stun_timer") != null:
					collider.set("wall_stun_timer", 0.3)
				if collider.get("state") != null:
					collider.set("state", "chase")
				if collider.get("cooldown") != null:
					collider.set("cooldown", maxf(float(collider.get("cooldown")), 1.0))
			take_damage(col_damage, Vector2.ZERO, 0.0, "regular")
		else:
			take_damage(col_damage, Vector2.ZERO, 0.0, "regular")
	is_in_knockback = false
	if is_instance_valid(self) and not is_queued_for_deletion():
		queue_redraw()

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO, push_distance := 12.0, element := "regular", knockback_source := "regular") -> void:
	if health <= 0 or is_dead:
		return
	var p_cards: Array = _player_cards()
	var eff_amount := amount
	if elemental_state.is_frozen() and p_cards.has("absolute_zero"):
		eff_amount *= 1.4
	if elemental_state.is_wet() and p_cards.has("erosion") and element == "regular":
		var wet_elapsed := 3.0 - elemental_state.wet_timer
		eff_amount *= (1.0 + clampf(floorf(wet_elapsed) * 0.05, 0.0, 0.25))

	var final_amount := ElementalSystem.calculate_elemental_damage(eff_amount, element, elemental_state)
	health = maxf(0, health - final_amount)
	hit_flash = 0.12
	damaged.emit(final_amount, knockback, element)
	
	var is_dot := (element == "burn" or element == "rust" or knockback_source == "dot")
	var is_secondary := (knockback_source == "secondary")
	var elem := element.to_lower().strip_edges()

	# Shatter: Hitting a frozen enemy with heavy attack or Ground Slam instantly shatters them, dealing 80 Ice damage
	if elemental_state.is_frozen() and (knockback_source in ["heavy", "slam", "special"] or elem in ["earth", "physical"]):
		if p_cards.has("shatter") and knockback_source != "secondary":
			elemental_state.frozen_timer = 0.0
			take_damage(80.0, Vector2.ZERO, 0.0, "ice", "secondary")
			if p_cards.has("cold_snap") and get_parent() != null:
				for other in get_parent().get_children():
					if other != self and is_instance_valid(other) and other is CharacterBody2D and other.health > 0.0:
						if global_position.distance_to(other.global_position) <= 140.0:
							other.take_damage(14.0, Vector2.ZERO, 0.0, "ice", "secondary")

	if elem in ["fire", "burn"]:
		if not is_dot:
			var burn_dur := 5.0 if p_cards.has("lasting_fire") else 3.0
			var burn_buildup := 10.0 if p_cards.has("explosion") else 0.0
			var res := ElementalSystem.apply_burn(elemental_state, burn_dur, burn_buildup, true, is_dot, is_secondary)
			if res.get("reaction") == "burn_explosion":
				take_damage(100.0, Vector2.ZERO, 0.0, "explosive", "explosion")
				if p_cards.has("explosive_fury") and get_parent() != null:
					for other in get_parent().get_children():
						if other != self and is_instance_valid(other) and other is CharacterBody2D and other.health > 0.0:
							if global_position.distance_to(other.global_position) <= 150.0:
								other.take_damage(60.0, Vector2.ZERO, 0.0, "explosive", "secondary")
								if other.elemental_state.burn_meter >= 70.0:
									other.elemental_state.burn_meter = 0.0
									other.take_damage(100.0, Vector2.ZERO, 0.0, "explosive", "secondary")
	elif elem in ["ice", "frost"]:
		var frost_dur := 3.0
		var frost_buildup := 15.0 if p_cards.has("flash_freeze") else 10.0
		var has_ff := p_cards.has("flash_freeze")
		var res := ElementalSystem.apply_frost(elemental_state, frost_dur, frost_buildup, true, is_dot, is_secondary, "", 0.0, 0.25, has_ff)
		if res.get("reaction") == "boss_freeze_damage":
			take_damage(res.get("boss_damage", 80.0), Vector2.ZERO, 0.0, "ice", "secondary")
		elif res.get("reaction") == "freeze":
			if p_cards.has("deep_freeze"):
				elemental_state.frozen_timer = 3.0
	elif elem in ["water", "rust"]:
		var wet_dur := 5.0 if p_cards.has("drenched") else 3.0
		ElementalSystem.apply_wet(elemental_state, wet_dur)
	elif elem == "wind":
		ElementalSystem.apply_wind(elemental_state)
	elif elem in ["lightning", "electricity"]:
		var res := ElementalSystem.apply_lightning(elemental_state)
		if res.get("extra_burn_tick", false):
			take_damage(ElementalSystem.calculate_burn_tick(8.0, elemental_state), Vector2.ZERO, 0.0, "burn", "dot")
	elif elem == "earth":
		ElementalSystem.apply_earth(elemental_state)
	elif elem in ["toxin", "poison", "acid"]:
		elemental_state.toxin_timer = 4.0
		
	if health <= 0:
		_die()
		return
	if knockback.length_squared() > 0:
		apply_knockback(knockback, push_distance, knockback_source)
	if is_instance_valid(self) and not is_queued_for_deletion():
		queue_redraw()

func _die() -> void:
	if is_dead:
		return
	var p_cards: Array = _player_cards()
	if p_cards.has("fire_spread") and elemental_state.is_burning() and get_parent() != null:
		var closest_enemy: Node2D = null
		var min_d := INF
		for other in get_parent().get_children():
			if other != self and is_instance_valid(other) and other is CharacterBody2D and other.health > 0.0:
				var d := global_position.distance_to(other.global_position)
				if d < min_d:
					min_d = d
					closest_enemy = other
		if closest_enemy != null:
			ElementalSystem.apply_burn(closest_enemy.elemental_state, 3.0)
	is_dead = true
	active = false
	defeated.emit(self)
	queue_free()

func _draw() -> void:
	if wall_stun_timer > 0.0:
		var halo_center := Vector2(0, -95)
		draw_set_transform(halo_center, 0, Vector2(1, 0.45))
		draw_arc(Vector2.ZERO, 20, 0, TAU, 24, Color("ffe600"), 3, true)
		draw_set_transform(Vector2.ZERO)
		var t_ms := float(Time.get_ticks_msec()) * 0.006
		for s in range(3):
			var a_s := t_ms + float(s) * TAU / 3.0
			var s_pos := halo_center + Vector2(cos(a_s) * 20.0, sin(a_s) * 9.0)
			draw_circle(s_pos, 3.5, Color("fff0a0"))

	draw_set_transform(Vector2.ZERO,0,Vector2(1,0.5))
	draw_circle(Vector2.ZERO,30 if kind != "boss" else 70,Color(0,0,0,0.45))
	draw_arc(Vector2.ZERO,23 if kind != "boss" else 65,0,TAU,32,Color(1,0.3,0.1,0.65),2,true)
	draw_set_transform(Vector2.ZERO)

	# Mud ground effect
	if elemental_state.is_muddy():
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
		draw_circle(Vector2.ZERO, 24, Color(0.39, 0.27, 0.17, 0.6))
		draw_set_transform(Vector2.ZERO)

	# Wet status splash droplets and ripple
	if elemental_state.is_wet():
		var t_wet := float(Time.get_ticks_msec()) * 0.006
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
		draw_arc(Vector2.ZERO, 28, 0, TAU, 24, Color(0.2, 0.6, 1.0, 0.5), 2.5, true)
		draw_set_transform(Vector2.ZERO)
		for i in range(5):
			var a_w := float(i) * 1.3 + t_wet
			var drop_x := cos(a_w) * 18.0
			var drop_y := -15.0 - fmod(float(i) * 12.0 + t_wet * 25.0, 35.0)
			draw_circle(Vector2(drop_x, drop_y), 3.0, Color("52c9fd"))

	# Rust corrosion patina spots
	if elemental_state.rust_consecutive_ticks > 0:
		for r in range(4):
			var r_x := sin(float(r) * 19.0) * 14.0
			var r_y := -30.0 - float(r) * 8.0
			draw_circle(Vector2(r_x, r_y), 4.5, Color(0.15, 0.71, 0.69, 0.7))

	# Burn status flames
	if elemental_state.is_burning():
		var t_burn := float(Time.get_ticks_msec()) * 0.008
		for j in range(6):
			var off_x := sin(float(j) * 1.7 + t_burn * 3.0) * 14.0
			var fy := -25.0 - float(j) * 8.0 - fmod(t_burn * 30.0 + float(j) * 7.0, 22.0)
			var rad := 6.5 * (1.0 - (float(j) / 8.0))
			var f_col := Color("ff3b30") if j % 2 == 0 else Color("ffc75e")
			f_col.a = 0.85
			draw_circle(Vector2(off_x, fy), rad, f_col)

	# Frost crystal spikes
	if elemental_state.is_frost() and not elemental_state.is_frozen():
		for j in range(5):
			var sp_x := -18.0 + float(j) * 9.0
			var sp_h := 14.0 + sin(float(j) * 23.0) * 6.0
			var pts: PackedVector2Array = [
				Vector2(sp_x - 3, -40),
				Vector2(sp_x, -40 - sp_h),
				Vector2(sp_x + 3, -40)
			]
			draw_colored_polygon(pts, Color(0.6, 0.9, 1.0, 0.75))
			draw_polyline(pts, Color.WHITE, 1.2)

	# Freeze translucent ice block encasing enemy
	if elemental_state.is_frozen():
		var w_box := 32.0 if kind != "boss" else 55.0
		var h_box := 75.0 if kind != "boss" else 110.0
		var block_pts: PackedVector2Array = [
			Vector2(-w_box, 8),
			Vector2(-w_box - 4, -h_box * 0.8),
			Vector2(-w_box * 0.3, -h_box),
			Vector2(w_box * 0.8, -h_box * 0.85),
			Vector2(w_box + 4, 8)
		]
		draw_colored_polygon(block_pts, Color(0.34, 0.75, 0.98, 0.35))
		draw_polyline(block_pts, Color("83ecff"), 2.5)
		draw_line(Vector2(-w_box * 0.5, -h_box * 0.7), Vector2(w_box * 0.4, -h_box * 0.2), Color(1, 1, 1, 0.5), 1.5)

	# Toxin bubbling toxic haze
	if elemental_state.is_toxin():
		var t_tox := float(Time.get_ticks_msec()) * 0.007
		for k in range(5):
			var tox_x := sin(float(k) * 2.3 + t_tox * 2.0) * 16.0
			var tox_y := -20.0 - float(k) * 7.0 - fmod(t_tox * 20.0 + float(k) * 5.0, 22.0)
			draw_circle(Vector2(tox_x, tox_y), 4.0, Color(0.53, 0.93, 0.21, 0.75))

	if state == "windup" and not custom_attack_warning:
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

extends "res://scripts/run_enemy.gd"

signal summon_requested(summoner: CharacterBody2D, enemy_key: String, count: int)

const BOSS_CONFIGS := {
	"maintenance": {
		"id": 0,
		"name": "OVERSEER SERAPH",
		"title": "Overseer Seraph",
		"health": 3750.0,
		"damage": 20.0,
		"speed": 180.0,
		"phase_subtitle": "EMERGENCY PROTOCOL",
		"idle_tex": "res://characters/enemies/Four_Bosses_Directional_Animation_Pack/sprite_atlases/Overseer_Seraph_32_Direction_Idle.png",
		"attack_tex": "res://characters/enemies/Four_Bosses_Directional_Animation_Pack/sprite_atlases/Overseer_Seraph_8_Direction_All_Attacks.png",
		"visual_scale": 1.9,
		"visual_offset": Vector2(0, -68),
		"collider_radius": 34.0,
		"hovering": true
	},
	"factory": {
		"id": 1,
		"name": "FOUNDRY TYRANT",
		"title": "Foundry Tyrant",
		"health": 5000.0,
		"damage": 24.0,
		"speed": 135.0,
		"phase_subtitle": "ACCELERATED LINE",
		"idle_tex": "res://characters/enemies/Four_Bosses_Directional_Animation_Pack/sprite_atlases/Foundry_Tyrant_32_Direction_Idle.png",
		"attack_tex": "res://characters/enemies/Four_Bosses_Directional_Animation_Pack/sprite_atlases/Foundry_Tyrant_8_Direction_All_Attacks.png",
		"visual_scale": 2.0,
		"visual_offset": Vector2(0, -70),
		"collider_radius": 38.0,
		"hovering": false
	},
	"boiler": {
		"id": 2,
		"name": "MAGMA COLOSSUS",
		"title": "Magma Colossus",
		"health": 5000.0,
		"damage": 26.0,
		"speed": 120.0,
		"phase_subtitle": "OVERPRESSURE",
		"idle_tex": "res://characters/enemies/Four_Bosses_Directional_Animation_Pack/sprite_atlases/Magma_Colossus_32_Direction_Idle.png",
		"attack_tex": "res://characters/enemies/Four_Bosses_Directional_Animation_Pack/sprite_atlases/Magma_Colossus_8_Direction_All_Attacks.png",
		"visual_scale": 2.1,
		"visual_offset": Vector2(0, -74),
		"collider_radius": 40.0,
		"hovering": false
	},
	"toxin_refinery": {
		"id": 3,
		"name": "VENOM COIL LEVIATHAN",
		"title": "Venom Coil Leviathan",
		"health": 5000.0,
		"damage": 25.0,
		"speed": 195.0,
		"phase_subtitle": "FEEDING FRENZY",
		"idle_tex": "res://characters/enemies/Four_Bosses_Directional_Animation_Pack/sprite_atlases/Venom_Coil_Leviathan_32_Direction_Idle.png",
		"attack_tex": "res://characters/enemies/Four_Bosses_Directional_Animation_Pack/sprite_atlases/Venom_Coil_Leviathan_8_Direction_All_Attacks.png",
		"visual_scale": 1.95,
		"visual_offset": Vector2(0, -64),
		"collider_radius": 36.0,
		"hovering": false
	}
}

var boss_id := 0
var biome_key := "maintenance"
var phase_subtitle := "EMERGENCY PROTOCOL"
var idle_texture: Texture2D
var attack_texture: Texture2D
var attack_move := 0
var charge_timer := 0.0
var hovering := false
var is_biome_boss := true

func _ready() -> void:
	kind = "boss"
	custom_attack_warning = true
	super._ready()
	_apply_boss_configuration()

func configure_boss(biome: String) -> void:
	biome_key = biome if BOSS_CONFIGS.has(biome) else "maintenance"
	if is_inside_tree():
		_apply_boss_configuration()

func _apply_boss_configuration() -> void:
	var cfg: Dictionary = BOSS_CONFIGS.get(biome_key, BOSS_CONFIGS["maintenance"])
	boss_id = cfg.id
	display_name = cfg.name
	phase_subtitle = cfg.phase_subtitle
	hovering = bool(cfg.hovering)
	health = float(cfg.health)
	max_health = health
	damage = float(cfg.damage)
	speed = float(cfg.speed)
	enemy_size = "Large"
	
	if ResourceLoader.exists(cfg.idle_tex):
		idle_texture = load(cfg.idle_tex)
	if ResourceLoader.exists(cfg.attack_tex):
		attack_texture = load(cfg.attack_tex)
	
	if visual != null:
		visual.texture = idle_texture
		visual.hframes = 8
		visual.vframes = 4
		visual.scale = Vector2.ONE * float(cfg.visual_scale)
		visual.offset = cfg.visual_offset
		visual.flip_h = false
		visual.frame = 0
	
	# Update collision shape radius
	for child in get_children():
		if child is CollisionShape2D and child.shape is CircleShape2D:
			child.shape.radius = float(cfg.collider_radius)
			break

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
	hit_flash = maxf(0, hit_flash - delta)
	stride += delta * (11.0 if velocity.length_squared() > 25.0 else 4.0)
	phase_two = (health <= max_health * 0.5)
	
	if state == "windup":
		windup -= delta
		if windup <= 0:
			_release_attack()
	elif state == "charge":
		charge_timer -= delta
		windup = charge_timer
		var charge_speed := 520.0 if not phase_two else 620.0
		if boss_id == 1:
			charge_speed = 460.0
		elif boss_id == 2:
			charge_speed = 540.0
		elif boss_id == 3:
			charge_speed = 640.0
		velocity = attack_direction * charge_speed
		if is_instance_valid(target) and global_position.distance_to(target.global_position) < 65.0:
			_deal_damage_to_target(damage)
		if charge_timer <= 0 or is_on_wall():
			state = "chase"
			cooldown = 1.0
	else:
		var distance := position.distance_to(target.position)
		if cooldown <= 0 and distance < attack_reach():
			_begin_attack()
		else:
			path_timer -= delta
			if path_timer <= 0:
				if is_instance_valid(room):
					path = room.call("path_between", position, target.position)
				else:
					path = PackedVector2Array([target.position])
				path_timer = 0.35
			while path.size() > 1 and position.distance_to(path[0]) < 25:
				path.remove_at(0)
			var goal := path[0] if not path.is_empty() else target.position
			if distance < 110:
				goal = target.position
			velocity = position.direction_to(goal) * speed * (1.25 if phase_two else 1.0)
			for other in get_parent().get_children():
				if other != self and is_instance_valid(other) and other is CharacterBody2D:
					var offset: Vector2 = global_position - other.global_position
					if offset.length() < 50 and offset.length() > 1:
						velocity += offset.normalized() * 35.0
	
	if state == "chase" and velocity.length_squared() > 1:
		facing = facing.slerp(velocity.normalized(), minf(1.0, delta * 5.0)).normalized()
	if slow_timer > 0:
		velocity *= 0.5
	if elemental_state.is_muddy():
		velocity *= 0.8
	if elemental_state.is_frost():
		velocity *= 0.75
	move_and_slide()
	_update_boss_visual()
	queue_redraw()

func _update_boss_visual() -> void:
	if visual == null:
		return
	visual.modulate = Color(2, 1.6, 1.2) if hit_flash > 0 else Color.WHITE
	var yaw := atan2(facing.x / 56.0 + facing.y / 25.0, facing.y / 25.0 - facing.x / 56.0)
	var dir_8 := posmod(roundi(yaw / TAU * 8.0), 8)
	var dir_32 := posmod(roundi(yaw / TAU * 32.0), 32)
	
	if state in ["windup", "charge"] and attack_texture != null:
		if visual.texture != attack_texture:
			visual.texture = attack_texture
		visual.frame = (attack_move % 4) * 8 + dir_8
		visual.position = Vector2.ZERO
	else:
		if idle_texture != null and visual.texture != idle_texture:
			visual.texture = idle_texture
		visual.frame = dir_32
		if hovering:
			visual.position.y = sin(stride * 0.4) * 3.5
		elif velocity.length_squared() > 25.0:
			visual.position.y = -absf(sin(stride)) * 2.5
		else:
			visual.position.y = 0.0

func _begin_attack() -> void:
	state = "windup"
	attack_number += 1
	attack_move = attack_number % 4
	attack_point = target.global_position if is_instance_valid(target) else global_position + facing * 60.0
	attack_direction = global_position.direction_to(attack_point)
	if attack_direction.length_squared() < 0.01:
		attack_direction = facing
	facing = attack_direction
	
	match boss_id:
		0: # Overseer Seraph
			match attack_move:
				0: windup = 0.62 # Evasive Retreat
				1: windup = 1.00 # Summon Cleaning Drones
				2: windup = 0.90 # Elite Upgrade Ray
				3: windup = 0.85 # Six-Hand Barrage
		1: # Foundry Tyrant
			match attack_move:
				0: windup = 0.85 # Gear Burst
				1: windup = 1.05 # Saw Spiral
				2: windup = 0.90 # Conveyor Mines
				3: windup = 1.20 # Forge Beam
		2: # Magma Colossus
			match attack_move:
				0: windup = 0.95 # Spew Lava
				1: windup = 1.00 # Jump and Slam
				2: windup = 0.80 # Explosive Barrel Throw
				3: windup = 1.10 # Rolling Furnace
		3: # Venom Coil Leviathan
			match attack_move:
				0: windup = 0.82 # Lunging Bite
				1: windup = 0.75 # Poison Spit
				2: windup = 0.90 # Tail Smack
				3: windup = 1.05 # Stadium Rush
	
	if phase_two:
		windup *= 0.85
	velocity = Vector2.ZERO

func _release_attack() -> void:
	state = "chase"
	cooldown = 1.35 if not phase_two else 0.85
	match boss_id:
		0: # Overseer Seraph
			match attack_move:
				0: # Evasive Retreat
					velocity = -attack_direction * (450.0 if phase_two else 380.0)
					for offset_ang in [-0.25, 0.25]:
						projectile_requested.emit(global_position, attack_direction.rotated(offset_ang), damage * 0.7)
				1: # Summon Cleaning Drones
					summon_requested.emit(self, "industrial_01", 2 if not phase_two else 3)
					for k in 6:
						var ang := k * TAU / 6.0
						projectile_requested.emit(global_position, Vector2.from_angle(ang), damage * 0.6)
				2: # Elite Upgrade Ray
					var ray_len := 380.0
					var ray_end := global_position + attack_direction * ray_len
					if is_instance_valid(target):
						var p_offset := Geometry2D.get_closest_point_to_segment(target.global_position, global_position, ray_end)
						if p_offset.distance_to(target.global_position) < 42.0:
							_deal_damage_to_target(damage * 1.2)
					impact_requested.emit(ray_end, 40.0)
				3: # Six-Hand Barrage
					var count := 7 if phase_two else 5
					for k in count:
						var angle := attack_direction.angle() + (k - (count - 1) * 0.5) * 0.22
						projectile_requested.emit(global_position, Vector2.from_angle(angle), damage * 0.75)
		1: # Foundry Tyrant
			match attack_move:
				0: # Gear Burst
					var count := 12 if not phase_two else 16
					for k in count:
						if k % 4 == 0: continue
						var ang := k * TAU / count
						projectile_requested.emit(global_position, Vector2.from_angle(ang), damage * 0.7)
				1: # Saw Spiral
					var count := 8 if not phase_two else 10
					for k in count:
						var a1 := attack_direction.angle() + k * 0.35
						var a2 := attack_direction.angle() - k * 0.35
						projectile_requested.emit(global_position, Vector2.from_angle(a1), damage * 0.65)
						projectile_requested.emit(global_position, Vector2.from_angle(a2), damage * 0.65)
				2: # Conveyor Mines
					for step in 3:
						var p := global_position + attack_direction * (80.0 + step * 70.0)
						impact_requested.emit(p, 48.0)
						if is_instance_valid(target) and target.global_position.distance_to(p) < 55.0:
							_deal_damage_to_target(damage * 0.9)
				3: # Forge Beam
					var beam_end := global_position + attack_direction * 420.0
					if is_instance_valid(target):
						var p_beam := Geometry2D.get_closest_point_to_segment(target.global_position, global_position, beam_end)
						if p_beam.distance_to(target.global_position) < 45.0:
							_deal_damage_to_target(damage * 1.3)
					impact_requested.emit(attack_point, 55.0)
					if is_instance_valid(target) and target.global_position.distance_to(attack_point) < 60.0:
						_deal_damage_to_target(damage * 1.0)
		2: # Magma Colossus
			match attack_move:
				0: # Spew Lava
					var count := 4 if phase_two else 3
					for k in count:
						var spread := (k - (count - 1) * 0.5) * 45.0
						var p := attack_point + attack_direction.orthogonal() * spread
						impact_requested.emit(p, 45.0)
						if is_instance_valid(target) and target.global_position.distance_to(p) < 48.0:
							_deal_damage_to_target(damage * 0.8)
				1: # Jump and Slam
					global_position = attack_point
					impact_requested.emit(attack_point, 115.0)
					if is_instance_valid(target) and target.global_position.distance_to(attack_point) < 120.0:
						_deal_damage_to_target(damage * 1.25)
				2: # Explosive Barrel Throw
					var count := 3 if phase_two else 2
					for k in count:
						var offset := Vector2.from_angle(k * TAU / count) * 60.0
						var p := attack_point + offset
						impact_requested.emit(p, 50.0)
						if is_instance_valid(target) and target.global_position.distance_to(p) < 55.0:
							_deal_damage_to_target(damage * 0.95)
				3: # Rolling Furnace
					state = "charge"
					charge_timer = 1.2 if not phase_two else 1.5
					windup = charge_timer
		3: # Venom Coil Leviathan
			match attack_move:
				0: # Lunging Bite
					state = "charge"
					charge_timer = 0.45
					windup = charge_timer
				1: # Poison Spit
					var count := 6 if phase_two else 4
					for k in count:
						var ang := attack_direction.angle() + (k - (count - 1) * 0.5) * 0.28
						projectile_requested.emit(global_position, Vector2.from_angle(ang), damage * 0.7)
						var p := global_position + Vector2.from_angle(ang) * 160.0
						impact_requested.emit(p, 36.0)
				2: # Tail Smack
					impact_requested.emit(global_position + attack_direction * 70.0, 125.0)
					if is_instance_valid(target):
						var to_tgt := global_position.direction_to(target.global_position)
						var dist := global_position.distance_to(target.global_position)
						if dist <= 135.0 and attack_direction.dot(to_tgt) > -0.25:
							_deal_damage_to_target(damage * 1.1)
				3: # Stadium Rush
					state = "charge"
					charge_timer = 0.8 if not phase_two else 1.2
					windup = charge_timer

func _deal_damage_to_target(dmg: float) -> void:
	if not is_instance_valid(target):
		return
	var wet_red := 0.35 if (target.get("cards") != null and target.cards.has("water_damage")) else 0.20
	var eff_dmg := dmg * (1.0 - wet_red) if elemental_state.is_wet() else dmg
	target.call("take_damage", eff_dmg, self, false)

func _draw() -> void:
	if wall_stun_timer > 0:
		draw_arc(Vector2(0, -110), 22, 0, TAU, 24, Color("fff0a0"), 3, true)
	
	# Floor shadow
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
	draw_circle(Vector2.ZERO, 42, Color(0, 0, 0, 0.45))
	draw_arc(Vector2.ZERO, 38, 0, TAU, 32, Color(1, 0.35, 0.1, 0.7), 3, true)
	draw_set_transform(Vector2.ZERO)
	
	# Directional attack telegraphs during windup
	if state == "windup":
		var p := attack_point - global_position
		# Circle telegraph for area/impact moves
		if (boss_id == 2 and attack_move in [0, 1, 2]) or (boss_id == 1 and attack_move == 2):
			var r := 115.0 if (boss_id == 2 and attack_move == 1) else 55.0
			draw_set_transform(p, 0, Vector2(1, 0.65))
			draw_circle(Vector2.ZERO, r, Color(1, 0.12, 0.04, 0.18))
			draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color("ff6d36"), 3, true)
			draw_arc(Vector2.ZERO, r * clampf(1.0 - windup, 0.0, 1.0), 0, TAU, 48, Color(1, 0.7, 0.2, 0.6), 2, true)
			draw_set_transform(Vector2.ZERO)
		# Arc telegraph for tail smack
		elif boss_id == 3 and attack_move == 2:
			var half := deg_to_rad(75.0)
			draw_arc(Vector2.ZERO, 130.0, attack_direction.angle() - half, attack_direction.angle() + half, 32, Color(0.2, 0.9, 0.4, 0.7), 4, true)
		# Line telegraph for charges, beams, rushes
		else:
			var line_len := 420.0 if (boss_id == 1 and attack_move == 3) else 320.0
			var line_color := Color(0.2, 0.8, 1.0, 0.7) if boss_id == 0 else Color(1, 0.4, 0.1, 0.7)
			draw_line(Vector2.ZERO, attack_direction * line_len, line_color, 5, true)

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO, push_distance := 12.0, element := "regular", knockback_source := "regular") -> void:
	super.take_damage(amount, knockback, push_distance, element, knockback_source)
	phase_two = (health <= max_health * 0.5)
	queue_redraw()

extends "res://scripts/run_enemy.gd"

signal summon_requested(summoner: CharacterBody2D, enemy_key: String, count: int)
const ATTACK := preload("res://scripts/industrial_attack.gd")
static var ability_catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies/abilities.json"))

var design: Dictionary
var animation_clock := 0.0
var animation_name := ""
var release_timer := 0.0
var dying := false
var death_clock := 0.0
var moves: Array = []
var move_cooldowns := [0.0,0.0,0.0]
var move_index := -1
var current_move: Dictionary = {}
var recovery_timer := 0.0
var active_timer := 0.0
var dash_remaining := 0.0
var dash_hit := false
var bounced := false
var bent := false
var hooked := false
var hook_timer := 0.0
var guard_timer := 0.0
var guard_arc := 140.0
var buff_timer := 0.0
var is_summon := false
var summoner: WeakRef
var teleport_point := Vector2.ZERO
var attack_generation := 0

func _ready() -> void:
	custom_attack_warning = true
	kind = "brute" if design.role in ["AOE","Shield"] else "crawler"
	super._ready()
	display_name = design.name
	moves = ability_catalog["industrial_%02d" % int(design.id)]
	health = float(design.hp)
	max_health = health
	# Source movement units map to 26 game pixels; retain difficulty modifiers.
	speed = float(design.speed)*26.0*(get_node("/root/RunConfig").enemy_speed()/104.0)
	damage = float(design.get("contact_damage",maxi(4,int(design.danger)*4)))
	visual.texture = load(design.texture)
	visual.hframes = 8
	visual.vframes = 16
	visual.scale = Vector2.ONE*1.6
	visual.offset = Vector2(0,-40.6)
	visual.position = Vector2.ZERO
	visual.flip_h = false
	_update_animation(0.0)

func attack_reach() -> float:
	var next := choose_move()
	return float(moves[next].reach)+20 if next >= 0 else 0.0

func choose_move() -> int:
	for step in 3:
		var index := (move_index+1+step)%3
		if float(move_cooldowns[index]) <= 0 and (str(moves[index].kind) not in ["reel","siphon"] or hooked) and (not is_summon or moves[index].kind not in ["summon","split"]):
			return index
	return -1

func _begin_attack() -> void:
	var next := choose_move()
	if next < 0:
		return
	move_index = next
	current_move = moves[next].duplicate(true)
	attack_generation += 1
	state = "windup"
	attack_kind = str(current_move.kind)
	windup = float(current_move.tell)
	guard_timer = 0
	attack_point = target.global_position
	attack_direction = global_position.direction_to(target.global_position)
	if current_move.get("rear",false):
		attack_direction = -attack_direction
	if attack_kind == "sidestep":
		attack_direction = attack_direction.orthogonal()
	elif attack_kind == "backstep":
		attack_direction = -attack_direction
	facing = attack_direction
	if attack_kind == "teleport":
		teleport_point = safe_destination(target.position-attack_direction*65)
		attack_point = teleport_point
	velocity = Vector2.ZERO

func safe_destination(desired: Vector2) -> Vector2:
	var route: PackedVector2Array = room.path_between(position,desired)
	# Existing navigation guarantees connected floor; keep destinations local.
	var result := position
	for point in route:
		if position.distance_to(point) <= float(current_move.get("reach",180)) and room.is_logical_free(Space.unproject(point),25) and get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(position,point,1)).is_empty():
			result = point
	return result

func effects_parent() -> Node:
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor.has_node("Projectiles"):
			return ancestor.get_node("Projectiles")
		ancestor = ancestor.get_parent()
	return get_parent()

func create_attack(spec: Dictionary, point: Vector2, direction: Vector2) -> Node2D:
	var effect := ATTACK.new()
	effect.source = self
	effect.target = target
	effect.spec = spec.duplicate(true)
	effect.spec.damage = float(spec.get("damage",0))*(1.25 if buff_timer > 0 else 1.0)
	effect.direction = direction
	effect.position = point
	effects_parent().add_child(effect)
	return effect

func _release_attack() -> void:
	if current_move.is_empty():
		return
	move_cooldowns[move_index] = float(current_move.cooldown)
	recovery_timer = float(current_move.recovery)
	active_timer = .25
	release_timer = active_timer+recovery_timer
	state = "ability"
	dash_hit = false
	bounced = false
	bent = false
	var spec := current_move.duplicate(true)
	match str(spec.kind):
		"dash","sidestep","backstep":
			state = "charge"
			dash_remaining = float(spec.reach)
			if spec.get("guard",false):
				guard_timer = 2.0
				guard_arc = float(spec.arc)
		"guard":
			guard_timer = float(spec.duration)
			guard_arc = float(spec.arc)
			active_timer = guard_timer
		"teleport":
			position = teleport_point
			path_timer = 0
			active_timer = .3
		"summon":
			summon_requested.emit(self,str(spec.enemy),int(spec.count))
		"split":
			summon_requested.emit(self,"industrial_%02d" % int(design.id),1)
		"buff":
			var nearest: Node2D
			var distance := float(spec.reach)
			for other in get_parent().get_children():
				if other != self and other.get_script() == get_script() and other.health > 0 and other.design.role in ["Close Range","Charging","Shield"] and position.distance_to(other.position) < distance:
					nearest = other
					distance = position.distance_to(other.position)
			if nearest != null:
				nearest.buff_timer = float(spec.duration)
		"reel","siphon":
			if hooked and target.dash_timer <= 0:
				# Reels use the player's collision-aware movement, never teleportation.
				target.apply_enemy_status(str(spec.kind),float(spec.duration),self,float(spec.get("distance",60)))
				if int(design.id) == 14 and target.enemy_statuses.has("reel"):
					var nearest := target.global_position.distance_to(global_position)
					var destination := global_position
					for hazard in room.layout.get("hazards",[]):
						var point: Vector2 = room.source_point(hazard)
						if target.global_position.distance_to(point) < nearest:
							nearest = target.global_position.distance_to(point)
							destination = point
					target.enemy_statuses.reel.destination = destination
				active_timer = float(spec.duration)
		"regroup":
			move_and_collide(-attack_direction*25)
		"shot","hook","radial":
			var count := int(spec.get("count",1))
			for i in count:
				var direction := attack_direction.rotated(TAU*i/count if spec.kind == "radial" else (i-(count-1)*.5)*.15)
				var projectile := spec.duplicate(true)
				projectile.kind = "hook" if spec.kind == "hook" else "shot"
				create_attack(projectile,global_position,direction)
		"lob":
			for i in int(spec.get("count",1)):
				var lob := spec.duplicate(true)
				lob.kind = "disk"
				lob.delay = .35+i*float(spec.get("delay",.8))
				create_attack(lob,attack_point+attack_direction.orthogonal()*i*42,attack_direction)
			if spec.has("pool"):
				create_attack({"kind":"pool","damage":3,"radius":39,"duration":spec.pool,"delay":.35},attack_point,attack_direction)
		"combo":
			for i in 2:
				var strike := spec.duplicate(true)
				strike.kind = "cone"
				strike.delay = i*float(spec.delay)
				strike.damage = spec.damage if i == 0 else spec.second_damage
				strike.hit_window = .25
				create_attack(strike,global_position,attack_direction.rotated((i-.5)*.35))
				if spec.has("pool"):
					create_attack({"kind":"pool","damage":3,"radius":18,"duration":spec.pool,"delay":strike.delay},global_position+attack_direction.rotated((i-.5)*.35)*float(spec.reach),attack_direction)
			active_timer = float(spec.delay)+.2
		"phantom":
			var phantom := visual.duplicate() as Sprite2D
			phantom.modulate = Color(1,.6,.3,.35)
			add_child(phantom)
			var tween := create_tween()
			tween.tween_property(phantom,"position",attack_direction*90,.25)
			tween.tween_callback(phantom.queue_free)
			spec.kind = "cone"
			spec.delay = .35
			create_attack(spec,global_position,attack_direction)
			active_timer = .55
		"pool":
			for i in int(spec.get("count",1)):
				create_attack(spec,global_position+attack_direction*35+attack_direction.orthogonal()*i*35,attack_direction)
		_:
			create_attack(spec,global_position,attack_direction)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not active or health <= 0 or not is_instance_valid(target):
		return
	for i in 3:
		move_cooldowns[i] = maxf(0,float(move_cooldowns[i])-delta)
	guard_timer = maxf(0,guard_timer-delta)
	buff_timer = maxf(0,buff_timer-delta)
	hook_timer = maxf(0,hook_timer-delta)
	if hook_timer <= 0 or target.dash_timer > 0 or hit_flash > 0:
		hooked = false
	if wall_stun_timer > 0:
		super._physics_process(delta)
		return
	if state in ["ability","recover","charge"]:
		hit_flash = maxf(0,hit_flash-delta)
		velocity = Vector2.ZERO
		if wall_stun_timer > 0:
			state = "recover"
		if state == "charge":
			var amount := minf(dash_remaining,float(current_move.get("velocity",260))*delta)
			var collision := move_and_collide(attack_direction*amount)
			dash_remaining -= amount
			if current_move.get("bend",false) and not bent and dash_remaining < float(current_move.reach)*.5:
				attack_direction = attack_direction.rotated(PI/5)
				bent = true
			if collision != null:
				if current_move.get("bounce",false) and not bounced:
					attack_direction = attack_direction.bounce(collision.get_normal())
					bounced = true
				else:
					dash_remaining = 0
			if not dash_hit and float(current_move.damage) > 0 and global_position.distance_to(target.global_position) < 40:
				var contact := current_move.duplicate(true)
				contact.kind = "disk"
				contact.radius = 40
				create_attack(contact,global_position,attack_direction)
				dash_hit = true
			if current_move.get("trail",false) and int(dash_remaining/20) != int((dash_remaining+amount)/20):
				create_attack({"kind":"pool","damage":5,"radius":20,"duration":1.5},global_position,attack_direction)
			if dash_remaining <= 0:
				state = "recover"
		elif state == "ability":
			active_timer -= delta
			if active_timer <= 0:
				state = "recover"
		else:
			recovery_timer -= delta
			if recovery_timer <= 0:
				state = "chase"
				cooldown = .1
		queue_redraw()
		return
	super._physics_process(delta)

func _process(delta: float) -> void:
	_update_animation(delta)

func _update_animation(delta: float) -> void:
	if visual == null:
		return
	release_timer = maxf(0.0,release_timer-delta)
	var next := "idle"
	if dying:
		next = "death"
	elif wall_stun_timer > 0:
		next = "recover"
	elif state == "windup":
		next = "windup"
	elif state in ["charge","ability"]:
		next = "attack"
	elif state == "recover":
		next = "recover"
	elif active and velocity.length_squared() > 25:
		next = "walk"
	if animation_name != next:
		animation_name = next
		animation_clock = 0
	animation_clock += delta
	var first: int = {"idle":0,"walk":2,"windup":6,"attack":8,"recover":10,"death":12}[next]
	var count := 4 if next in ["walk","death"] else 2
	var rate := 10.0 if next != "death" else 5.0
	var pose := mini(int(animation_clock*rate),3) if next == "death" else int(animation_clock*rate)%count
	var yaw := atan2(facing.x/56.0+facing.y/25.0,facing.y/25.0-facing.x/56.0)
	var direction := posmod(roundi(yaw/TAU*8),8)
	visual.frame = (first+pose)*8+direction
	visual.flip_h = false
	visual.position = Vector2.ZERO
	visual.modulate = Color(2,1.6,1.2) if hit_flash > 0 else Color.WHITE
	if buff_timer > 0:
		visual.modulate *= Color(1.5,1,.65)
	if state == "ability" and current_move.get("transit",false):
		visual.modulate.a = .2
	if state == "windup" and not current_move.is_empty():
		visual.frame = (6+mini(1,int(2*(1-windup/float(current_move.tell)))))*8+direction
	if next == "attack":
		visual.position = facing*sin(animation_clock*PI*4)*5
	elif next == "recover":
		visual.rotation = sin(animation_clock*8)*.03
	else:
		visual.rotation = 0
	if dying:
		death_clock += delta
		visual.modulate.a = clampf((0.9-death_clock)/0.3,0,1)
		if death_clock >= 0.9:
			queue_free()

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO, push_distance := 12.0) -> void:
	if health <= 0:
		return
	# Ground hazards and radial core damage have no incoming direction.
	if guard_timer > 0 and knockback.length_squared() > 0:
		var incoming := -knockback.normalized()
		if incoming.dot(facing) >= cos(deg_to_rad(guard_arc*.5)):
			amount *= .15
			knockback = Vector2.ZERO
	hooked = false
	if amount < health:
		super.take_damage(amount,knockback,push_distance)
		return
	health = 0
	active = false
	dying = true
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	defeated.emit(self)
	queue_redraw()

func _draw() -> void:
	if not dying:
		super._draw()
		if guard_timer > 0:
			var half := deg_to_rad(guard_arc*.5)
			draw_arc(Vector2.ZERO,40,facing.angle()-half,facing.angle()+half,24,Color("85dbff"),5,true)
		if hooked and is_instance_valid(target):
			draw_line(Vector2.ZERO,target.global_position-global_position,Color("c8d5de"),3,true)
		if state == "windup" and not current_move.is_empty():
			var reach := float(current_move.reach)
			var point := attack_point-global_position if attack_kind in ["lob","teleport"] else Vector2.ZERO
			var tint := Color("c998ff") if attack_kind in ["teleport","buff","summon","haze"] else Color("ffb657")
			if attack_kind in ["cone","combo","phantom"]:
				var half := deg_to_rad(float(current_move.get("arc",90))*.5)
				draw_arc(Vector2.ZERO,reach,attack_direction.angle()-half,attack_direction.angle()+half,24,tint,3,true)
				draw_line(Vector2.ZERO,attack_direction.rotated(-half)*reach,tint,2,true)
				draw_line(Vector2.ZERO,attack_direction.rotated(half)*reach,tint,2,true)
			elif attack_kind in ["lob","teleport","ring","pool","haze","disk"]:
				draw_arc(point,float(current_move.get("radius",35 if attack_kind == "teleport" else reach)),0,TAU,48,tint,3,true)
			elif attack_kind in ["dash","sidestep","backstep","shot","hook"]:
				if current_move.get("bend",false):
					var corner := attack_direction*reach*.5
					draw_line(Vector2.ZERO,corner,tint,3,true)
					draw_line(corner,corner+attack_direction.rotated(PI/5)*reach*.5,tint,3,true)
				else:
					draw_line(Vector2.ZERO,attack_direction*reach,tint,3,true)

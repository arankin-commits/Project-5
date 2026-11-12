extends CharacterBody2D

const IDLE_ART := preload("res://art/characters/medium_v2/directions.png")
const WALK_ART := preload("res://art/characters/medium_v2/walk.png")
const STRIKE_ART := preload("res://art/characters/medium_v2/strike.png")

signal attack_requested(origin: Vector2, direction: Vector2, damage: float, reach: float, heavy: bool)
signal damaged(amount: float)
signal dashed
signal grapple_requested(direction: Vector2)
signal core_requested
signal perfect_dodged

var controls_enabled := true
var appearance := "medium"
var speed := 265.0
var damage_multiplier := 1.0
var backstab_multiplier := 2.0
var dash_recharge := 0.7
var facing := Vector2.DOWN
var dash_direction := Vector2.DOWN
var dash_timer := 0.0
var dash_cooldown := 0.0
var attack_cooldown := 0.0
var special_cooldown := 0.0
var invulnerability := 0.0
var combo := 0
var combo_timer := 0.0
var walk_clock := 0.0
var attack_pose := 0.0
var visual: Sprite2D
var base_scale := Vector2(0.32, 0.32)
var skills: Array[String] = []
var energy := 0.0
var charge_time := 0.0
var charging := false
var charged_strike := false
var perfect_reward_timer := 0.0
var dash_elapsed := 0.0
var perfect_triggered := false
var dash_charges := 1
var grapple_cooldown := 0.0
var core_cooldown := 0.0

func configure_skills(unlocked: Array) -> void:
	skills.assign(unlocked)
	dash_charges = 2 if skills.has("double_dodge") else 1

func gain_hit_energy() -> void:
	energy = minf(100.0, energy + (10.0 if skills.has("energy_hit") else 5.0))

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var shape := CircleShape2D.new()
	shape.radius = 13
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	visual = Sprite2D.new()
	visual.name = "CharacterVisual"
	visual.texture = IDLE_ART
	visual.hframes = 4
	visual.vframes = 2
	visual.scale = base_scale
	add_child(visual)
	_update_visual(0.0)

func _physics_process(delta: float) -> void:
	dash_cooldown = maxf(0, dash_cooldown - delta)
	if dash_cooldown <= 0:
		dash_charges = 2 if skills.has("double_dodge") else 1
	dash_elapsed += delta
	perfect_reward_timer = maxf(0, perfect_reward_timer - delta)
	grapple_cooldown = maxf(0, grapple_cooldown - delta)
	core_cooldown = maxf(0, core_cooldown - delta)
	attack_cooldown = maxf(0, attack_cooldown - delta)
	special_cooldown = maxf(0, special_cooldown - delta)
	invulnerability = maxf(0, invulnerability - delta)
	combo_timer = maxf(0, combo_timer - delta)
	attack_pose = maxf(0, attack_pose - delta)
	if combo_timer <= 0:
		combo = 0
	if not controls_enabled:
		velocity = Vector2.ZERO
		dash_timer = 0
		charging = false
		charge_time = 0
		_update_visual(delta)
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_just_pressed("dash"):
		start_dash(input)
	if Input.is_action_just_pressed("grapple") and grapple_cooldown <= 0:
		grapple_requested.emit(_aim_direction())
	if Input.is_action_just_pressed("core_power"):
		core_requested.emit()
	if dash_timer > 0:
		dash_timer -= delta
		velocity = dash_direction * 850.0
	else:
		velocity = input * speed
		if input.length_squared() > 0.01 and attack_pose <= 0:
			facing = input
		if skills.has("charged_attack"):
			if Input.is_action_pressed("attack"):
				charging = true
				facing = _aim_direction()
				charge_time = minf(1.2, charge_time + delta)
			elif charging:
				release_charge(_aim_direction())
		elif Input.is_action_pressed("attack"):
			var direction := facing
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
				direction = global_position.direction_to(get_global_mouse_position())
			perform_attack(direction)
		if Input.is_action_just_pressed("special"):
			var direction := facing
			if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
				direction = global_position.direction_to(get_global_mouse_position())
			perform_attack(direction, true)
	move_and_slide()
	_update_visual(delta)
	queue_redraw()

func start_dash(direction: Vector2) -> bool:
	if dash_cooldown <= 0:
		dash_charges = 2 if skills.has("double_dodge") else 1
	if not controls_enabled or dash_charges <= 0:
		return false
	dash_charges -= 1
	dash_elapsed = 0
	perfect_triggered = false
	charging = false
	charge_time = 0
	dash_direction = direction.normalized() if direction.length_squared() > 0.01 else facing
	facing = dash_direction
	dash_timer = 0.18
	dash_cooldown = dash_recharge
	invulnerability = maxf(invulnerability, 0.24)
	velocity = dash_direction * 850.0
	dashed.emit()
	return true

func perform_attack(direction: Vector2, heavy := false) -> bool:
	if not controls_enabled or attack_cooldown > 0 or dash_timer > 0 or (heavy and special_cooldown > 0):
		return false
	facing = direction.normalized() if direction.length_squared() > 0.01 else facing
	combo = (combo % 3) + 1
	combo_timer = 0.95
	attack_pose = 0.19
	attack_cooldown = 0.3 if combo < 3 else 0.4
	var damage := 24.0 if combo < 3 else 36.0
	var reach := 115.0
	if heavy:
		damage = 55
		reach = 155
		attack_cooldown = 0.55
		special_cooldown = 1.8
	if charged_strike:
		damage *= 2.0
		reach = 155.0
	attack_requested.emit(global_position, facing, damage * damage_multiplier, reach, heavy)
	return true

func _aim_direction() -> Vector2:
	return global_position.direction_to(get_global_mouse_position()) if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) else facing

func release_charge(direction: Vector2) -> bool:
	charged_strike = skills.has("charged_attack") and charge_time >= 0.6
	var success := perform_attack(direction)
	charged_strike = false
	charging = false
	charge_time = 0
	return success

func take_damage(amount: float) -> bool:
	if controls_enabled and dash_timer > 0 and dash_elapsed <= 0.12 and not perfect_triggered:
		perfect_triggered = true
		if skills.has("perfect_dodge"):
			perfect_reward_timer = 5.0
			perfect_dodged.emit()
	if not controls_enabled or invulnerability > 0:
		return false
	invulnerability = 0.7
	damaged.emit(amount)
	return true

func _update_visual(delta: float) -> void:
	var direction_index := posmod(roundi(facing.angle() / (PI / 4.0)), 8)
	visual.frame = [6,7,0,1,2,3,4,5][direction_index]
	walk_clock += delta * (18.0 if velocity.length() > 5 else 3.0)
	visual.texture = IDLE_ART
	# Per-view foot anchors keep the slightly different painted poses grounded.
	var baselines := [430.0,445.0,448.0,452.0,442.0,444.0,454.0,450.0]
	if velocity.length() > 5 and sin(walk_clock) > 0:
		visual.texture = WALK_ART
		baselines = [444.0,449.0,451.0,449.0,452.0,453.0,445.0,439.0]
	if attack_pose > 0:
		visual.texture = STRIKE_ART
		baselines = [442.0,428.0,424.0,426.0,455.0,444.0,451.0,447.0]
	visual.offset = Vector2(0, 256.0 - baselines[visual.frame])
	visual.position = Vector2.ZERO
	visual.position.y = -absf(sin(walk_clock)) * (2.8 if velocity.length() > 5 else 0.5)
	visual.rotation = sin(walk_clock) * 0.025 if velocity.length() > 5 else 0.0
	visual.scale = base_scale
	if attack_pose > 0:
		visual.position += facing * sin(attack_pose / 0.19 * PI) * 9
		visual.rotation += facing.x * -0.09
	if dash_timer > 0:
		visual.rotation = dash_direction.x * 0.13
	visual.modulate = Color(1.2, 1.5, 1.5, 0.8) if invulnerability > 0.25 else Color.WHITE

func _draw() -> void:
	if charging:
		draw_arc(Vector2(0,-45), 34, -PI / 2, -PI / 2 + TAU * minf(charge_time / 0.6, 1.0), 32, Color("ffce83"), 4, true)
	draw_set_transform(Vector2(0,-2), 0, Vector2(1,0.45))
	draw_circle(Vector2.ZERO, 22, Color(0,0,0,0.5))
	draw_arc(Vector2.ZERO, 24, 0, TAU, 40, Color(0.3,0.95,0.9,0.8), 2, true)
	if dash_timer > 0:
		draw_line(-dash_direction * 15, -dash_direction * 100, Color(0.25,0.95,0.9,0.55), 7, true)

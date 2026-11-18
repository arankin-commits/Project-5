extends SceneTree

class Target extends CharacterBody2D:
	var damage := 0.0
	var element := ""
	func take_damage(amount: float, _direction = null, _push = null, kind := "regular") -> void:
		damage += amount
		element = kind

var failures := 0
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var room = load("res://scripts/blockout_room.gd").new()
	world.add_child(room)
	room.set_physics_process(false)
	room.definition = {"geometry": {"biome": "maintenance", "pixel_size": [1122, 1402], "hazards": [{"type": "wires", "direction_degrees": 0}]}}
	room.vents.assign([Vector2(400,400)])
	var player := Target.new()
	world.add_child(player)
	room.player = player
	var enemies := Node2D.new()
	enemies.name = "Enemies"
	world.add_child(enemies)
	var foe := Target.new()
	enemies.add_child(foe)
	player.position = Vector2(900,900)
	foe.position = room.vents[0]
	room.hazards_enabled = true
	await physics_frame
	room._physics_process(0.01)
	check(foe.damage == 32 and foe.element == "electricity", "Enemy must take electric wire damage without a player trigger")
	check(room.trap_triggers.is_empty(), "Enemy triggered wires")
	player.position = foe.position
	room.hazard_tick = 0
	room._physics_process(0.01)
	check(player.damage == 8, "Player must take wire damage")
	room._physics_process(0.01)
	check(player.damage == 8, "Wire damage must respect its tick interval")
	room.definition.geometry.hazards[0].type = "fan"
	var direction: Vector2 = room.hazard_direction(0)
	player.position = room.vents[0] + direction * 100
	foe.position = room.vents[0] + direction * 160
	var before := player.position
	var foe_before := foe.position
	room._physics_process(0.1)
	check((player.position - before).dot(direction) > 10, "Fan did not push player")
	check((foe.position - foe_before).dot(direction) > 10, "Fan did not push enemy")
	check(player.damage == 8, "Fan applied generic contact damage")
	player.position = room.vents[0] - direction * 100
	before = player.position
	room._physics_process(0.1)
	check(player.position == before, "Fan pushed a target behind it")
	room.definition.geometry.hazards[0].type = "turret"
	room.turret_cooldowns[0] = 0.0
	player.position = room.vents[0] + direction * 100
	foe.position = Vector2(900,900)
	room._physics_process(0.01)
	check(room.trap_shots.size() == 1, "Turret did not shoot")
	for i in 25:
		room._physics_process(0.02)
	check(player.damage == 16, "Turret projectile did not hit player")
	player.position = Vector2(900,900)
	foe.position = room.vents[0] + direction * 100
	var enemy_damage := foe.damage
	room.turret_cooldowns[0] = 0.0
	for i in 25:
		room._physics_process(0.02)
	check(foe.damage == enemy_damage + 32, "Turret projectile did not hit enemy")
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 25
	shape.shape = circle
	wall.add_child(shape)
	world.add_child(wall)
	wall.position = room.vents[0] + direction * 55
	await physics_frame
	await physics_frame
	room.turret_cooldowns[0] = 0.0
	enemy_damage = foe.damage
	for i in 25:
		room._physics_process(0.02)
	check(foe.damage == enemy_damage, "Turret shot passed through wall")
	room.definition.geometry.hazards[0].type = "fan"
	foe_before = foe.position
	room._physics_process(0.1)
	check(foe.position == foe_before, "Fan blew through wall")
	room.hazards_enabled = false
	room._physics_process(0.1)
	check(room.trap_shots.is_empty(), "Disabled turret left live projectiles")
	print("TRAP_BEHAVIOR_FAILURES=", failures)
	world.free()
	quit(1 if failures else 0)

extends SceneTree

const ENEMY := preload("res://scripts/industrial_enemy.gd")
const ATTACK := preload("res://scripts/industrial_attack.gd")
var failures := 0
var checks := 0
var run: Node
var catalog: Dictionary

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func spawn_enemy(id: int):
	var enemy := ENEMY.new()
	enemy.design = catalog["industrial_%02d" % id]
	enemy.target = run.player
	enemy.room = run.room
	enemy.position = run.room.spawn_position+Vector2(0,-50)
	run.enemies.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.set_process(false)
	run.player.position = enemy.position+Vector2(40,0)
	run.player.invulnerability = 0
	run.player.dash_timer = 0
	run.player.clear_enemy_statuses()
	return enemy

func start_move(enemy, index: int) -> void:
	enemy.move_cooldowns = [0.0,0.0,0.0]
	enemy.move_index = (index+2)%3
	enemy.hooked = true
	enemy.hook_timer = 10
	enemy._begin_attack()

func step(enemy, seconds: float) -> void:
	var delta := 1.0/60.0
	for i in int(ceil(seconds/delta)):
		enemy._physics_process(delta)
		enemy._update_animation(delta)
		run.player.invulnerability = maxf(0,run.player.invulnerability-delta)
		run.player._tick_enemy_statuses(delta)
		for effect in run.get_node("Projectiles").get_children():
			if effect is ATTACK and not effect.is_queued_for_deletion():
				effect.set_physics_process(false)
				effect._physics_process(delta)

func clear_effects() -> void:
	for effect in run.get_node("Projectiles").get_children():
		effect.free()

func _run() -> void:
	catalog = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies/industrial.json"))
	root.get_node("RunConfig").start_run("medium",{})
	change_scene_to_file("res://scenes/RoguelikeRun.tscn")
	await scene_changed
	run = current_scene
	run.room.hazards_enabled = false
	run.player.set_physics_process(false)
	run.maximum_health = 100000
	run.health = 100000
	for enemy in run.enemies.get_children():
		enemy.free()
	run.living_enemies = 1
	await physics_frame
	# Exercise the real windup/release/recovery code for every authored move.
	for id in 33:
		for index in 3:
			var enemy = spawn_enemy(id)
			start_move(enemy,index)
			check(enemy.move_index == index,"Move selection: %d/%d" % [id,index])
			enemy._update_animation(.01)
			check(enemy.animation_name == "windup","Missing windup")
			var before: float = enemy.windup
			enemy._physics_process(before+.01)
			enemy._update_animation(.01)
			check(enemy.animation_name == "attack","Missing active animation: %d/%d" % [id,index])
			check(enemy.move_cooldowns[index] > 0,"Missing individual cooldown")
			check(enemy.state in ["ability","charge"],"Move did not release")
			# Prevent another move while validating this recovery.
			enemy.move_cooldowns = [100.0,100.0,100.0]
			step(enemy,4.5)
			check(enemy.state == "chase","Recovery stuck: %d/%d" % [id,index])
			enemy.free()
			clear_effects()
			await process_frame
	# Actual health loss from a close-range cone; immunity blocks a second hit.
	var guard = spawn_enemy(3)
	var initial: float = run.health
	start_move(guard,0)
	step(guard,1.2)
	check(run.health == initial-9,"Wrench strike should deal exactly 9 damage")
	clear_effects()
	guard.free()
	# Front guard reduces damage 85%; rear attacks retain full damage.
	var shield = spawn_enemy(12)
	shield.guard_timer = 2
	shield.facing = Vector2.RIGHT
	var hp: float = shield.health
	shield.take_damage(20,Vector2.LEFT)
	check(is_equal_approx(shield.health,hp-3),"Front guard reduction")
	shield.take_damage(20,Vector2.RIGHT,0)
	check(is_equal_approx(shield.health,hp-23),"Rear attack bypass")
	shield.take_damage(32)
	check(is_equal_approx(shield.health,hp-55),"Shield blocked ground hazard damage")
	shield.free()
	# Player debuffs change existing mechanics and expire without stacking.
	var scrambler = spawn_enemy(7)
	run.player.energy = 0
	run.player.apply_enemy_status("interference",3,scrambler)
	run.player.gain_hit_energy()
	check(is_equal_approx(run.player.energy,3),"Interference energy gain")
	run.player.apply_enemy_status("weaken",3,scrambler)
	check(is_equal_approx(run.player.combat_damage_multiplier(),run.player.damage_multiplier*.75),"Weakening multiplier")
	run.player._tick_enemy_statuses(3.1)
	check(run.player.enemy_statuses.is_empty(),"Debuffs did not expire")
	# Hook contact enables reel; dodge and hitting the source break attachments.
	var hook = scrambler.create_attack({"kind":"hook","damage":6,"reach":150},scrambler.position,Vector2.RIGHT)
	step(scrambler,.3)
	check(scrambler.hooked,"Hook projectile did not connect")
	run.player.position = scrambler.position+Vector2(60,0)
	run.player.apply_enemy_status("reel",.75,scrambler,60)
	var old_distance: float = run.player.position.distance_to(scrambler.position)
	run.player._tick_enemy_statuses(.1)
	check(run.player.position.distance_to(scrambler.position) < old_distance,"Reel did not pull")
	run.player.start_dash(Vector2.RIGHT)
	run.player._tick_enemy_statuses(.01)
	check(not run.player.enemy_statuses.has("reel"),"Dodge did not break reel")
	run.player.dash_timer = 0
	run.player.apply_enemy_status("siphon",2,scrambler)
	scrambler.hit_flash = .1
	run.player._tick_enemy_statuses(.01)
	check(not run.player.enemy_statuses.has("siphon"),"Strike did not break siphon")
	scrambler.free()
	clear_effects()
	# Real physics walls stop projectiles and reels, and permit one ricochet.
	var rocket = spawn_enemy(17)
	rocket.position = Vector2(12000,12000)
	run.player.position = rocket.position+Vector2(110,0)
	var wall := StaticBody2D.new()
	wall.position = rocket.position+Vector2(55,0)
	wall.collision_layer = 1
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10,250)
	collider.shape = shape
	wall.add_child(collider)
	run.add_child(wall)
	await physics_frame
	initial = run.health
	rocket.create_attack({"kind":"shot","damage":9,"reach":200},rocket.position,Vector2.RIGHT)
	step(rocket,.6)
	check(run.health == initial,"Projectile passed through a wall")
	clear_effects()
	rocket.position = Vector2(12000,12000)
	start_move(rocket,0)
	rocket._release_attack()
	step(rocket,.25)
	check(rocket.bounced and rocket.attack_direction.x < 0,"Rocket did not ricochet off wall")
	rocket.position = Vector2(12000,12000)
	run.player.position = rocket.position+Vector2(100,0)
	run.player.apply_enemy_status("reel",.75,rocket,120)
	for i in 45:
		run.player._tick_enemy_statuses(1.0/60)
	check(run.player.position.x > wall.position.x,"Reel pulled through a solid wall")
	wall.free()
	rocket.free()
	clear_effects()
	# Delayed lob hits its locked marker, poison ticks twice, buff expires.
	var mortar = spawn_enemy(18)
	start_move(mortar,0)
	mortar._release_attack()
	mortar.move_cooldowns = [100.0,100.0,100.0]
	initial = run.health
	step(mortar,.2)
	check(run.health == initial,"Lob damaged before landing")
	step(mortar,.2)
	check(run.health == initial-12,"Lob did not hit locked marker")
	clear_effects()
	run.player.invulnerability = 0
	run.player.apply_enemy_status("poison",2,mortar)
	initial = run.health
	step(mortar,2.05)
	check(run.health == initial-4,"Poison should tick twice without stacking")
	mortar.free()
	var bellows = spawn_enemy(24)
	var ally = spawn_enemy(21)
	ally.position = bellows.position+Vector2(25,0)
	start_move(bellows,0)
	bellows._release_attack()
	check(ally.buff_timer == 4,"Bellows did not buff nearby melee ally")
	var enhanced = ally.create_attack({"kind":"cone","damage":12,"reach":80},ally.position,Vector2.RIGHT)
	check(enhanced.spec.damage == 15,"Buff should add 25 percent damage")
	ally._physics_process(4.1)
	check(ally.buff_timer == 0,"Buff did not expire")
	bellows.free()
	ally.free()
	clear_effects()
	# Summons are counted, capped, and keep the chamber locked.
	var foreman = spawn_enemy(4)
	foreman.summon_requested.connect(run._spawn_summons)
	start_move(foreman,0)
	foreman._release_attack()
	check(run.living_enemies == 4,"Summons missing from room count")
	run._spawn_summons(foreman,"industrial_01",10)
	check(run.living_enemies == 7,"Six-summon owner cap")
	for child in run.enemies.get_children():
		child.set_physics_process(false)
		if child != foreman:
			check(child.design.biome_key == "maintenance","Wrong summon biome")
	var count: int = run.living_enemies
	run._spawn_summons(foreman,"industrial_25",1)
	check(run.living_enemies == count,"Cross-biome summon accepted")
	# Timed hazards disappear after death or room clear.
	var pool = foreman.create_attack({"kind":"pool","damage":3,"duration":3,"radius":40},run.player.position,Vector2.RIGHT)
	foreman.health = 0
	pool._physics_process(.1)
	check(pool.is_queued_for_deletion(),"Dead caster left an active hazard")
	run.player.apply_enemy_status("poison",2,foreman)
	run._load_room(1)
	check(run.player.enemy_statuses.is_empty(),"Room transition retained status")
	print("INDUSTRIAL_ABILITY_CHECKS=",checks," FAILURES=",failures)
	quit(1 if failures else 0)

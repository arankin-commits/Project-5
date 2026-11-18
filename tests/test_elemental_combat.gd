extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAILED: " + message)
	else:
		print("PASS: " + message)

func frames(count := 2) -> void:
	for i in count:
		await physics_frame
		await process_frame

func _run() -> void:
	print("--- Running Elemental Combat Tests ---")

	var config: Node = root.get_node("RunConfig")
	config.call("start_run", "medium", {})

	var run = load("res://scenes/RoguelikeRun.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	await frames(3)

	var RUN_ENEMY := preload("res://scripts/run_enemy.gd")
	var ELEM := preload("res://scripts/elemental_system.gd")

	# ==========================================
	# TEST 1: Basic Elemental Attacks
	# ==========================================
	# 1A. Fire Attack: applies Burn
	run.player_cards.assign(["fire_attack"])
	run.player.cards.assign(["fire_attack"])
	var e_fire = RUN_ENEMY.new()
	e_fire.position = run.player.position + Vector2(40, 0)
	run.enemies.add_child(e_fire)
	await frames(1)
	run._on_attack(run.player.position, Vector2.RIGHT, 10.0, 80.0, false)
	check(e_fire.elemental_state.is_burning(), "Fire Attack must apply Burn status to struck enemy")
	e_fire.queue_free()

	# 1B. Water Attack: applies Wet
	run.player_cards.assign(["water_attack"])
	run.player.cards.assign(["water_attack"])
	var e_water = RUN_ENEMY.new()
	e_water.position = run.player.position + Vector2(40, 0)
	run.enemies.add_child(e_water)
	await frames(1)
	run._on_attack(run.player.position, Vector2.RIGHT, 10.0, 80.0, false)
	check(e_water.elemental_state.is_wet(), "Water Attack must apply Wet status to struck enemy")
	e_water.queue_free()

	# 1C. Ice Attack: applies Frost
	run.player_cards.assign(["ice_attack"])
	run.player.cards.assign(["ice_attack"])
	var e_ice = RUN_ENEMY.new()
	e_ice.position = run.player.position + Vector2(40, 0)
	run.enemies.add_child(e_ice)
	await frames(1)
	run._on_attack(run.player.position, Vector2.RIGHT, 10.0, 80.0, false)
	check(e_ice.elemental_state.is_frost(), "Ice Attack must apply Frost status to struck enemy")
	e_ice.queue_free()

	# 1D. Lightning Attack: deals bonus damage and triggers lightning element
	run.player_cards.assign(["lightning_attack"])
	run.player.cards.assign(["lightning_attack"])
	var e_light = RUN_ENEMY.new()
	e_light.health = 200.0
	e_light.max_health = 200.0
	e_light.position = run.player.position + Vector2(40, 0)
	run.enemies.add_child(e_light)
	await frames(1)
	var hp_before: float = e_light.health
	run._on_attack(run.player.position, Vector2.RIGHT, 10.0, 80.0, false)
	# 10 physical + 8 lightning = 18 total damage
	check(e_light.health <= hp_before - 18.0, "Lightning Attack must deal combo physical + 8 bonus lightning damage")
	e_light.queue_free()

	# 1E. Earth Attack: deals bonus damage
	run.player_cards.assign(["earth_attack"])
	run.player.cards.assign(["earth_attack"])
	var e_earth = RUN_ENEMY.new()
	e_earth.health = 200.0
	e_earth.max_health = 200.0
	e_earth.position = run.player.position + Vector2(40, 0)
	run.enemies.add_child(e_earth)
	await frames(1)
	hp_before = e_earth.health
	run._on_attack(run.player.position, Vector2.RIGHT, 10.0, 80.0, false)
	# 10 physical + 12 earth = 22 total damage
	check(e_earth.health <= hp_before - 22.0, "Earth Attack must deal combo physical + 12 bonus earth damage")
	e_earth.queue_free()

	# 1F. Wind Attack: deals bonus damage and knockback
	run.player_cards.assign(["wind_attack"])
	run.player.cards.assign(["wind_attack"])
	var e_wind = RUN_ENEMY.new()
	e_wind.health = 200.0
	e_wind.max_health = 200.0
	e_wind.position = run.player.position + Vector2(40, 0)
	run.enemies.add_child(e_wind)
	await frames(1)
	hp_before = e_wind.health
	run._on_attack(run.player.position, Vector2.RIGHT, 10.0, 80.0, false)
	# 10 physical + 5 wind = 15 total damage
	check(e_wind.health <= hp_before - 15.0, "Wind Attack must deal combo physical + 5 bonus wind damage")
	e_wind.queue_free()

	# ==========================================
	# TEST 2: Special / Slam Attacks
	# ==========================================
	# 2A. Lightning Special
	run.player_cards.assign(["lightning_special"])
	run.player.cards.assign(["lightning_special"])
	var e_lspec = RUN_ENEMY.new()
	e_lspec.health = 200.0
	e_lspec.max_health = 200.0
	e_lspec.position = run.player.position + Vector2(40, 0)
	run.enemies.add_child(e_lspec)
	await frames(1)
	hp_before = e_lspec.health
	run._on_attack(run.player.position, Vector2.RIGHT, 20.0, 100.0, true)
	check(e_lspec.health <= hp_before - 40.0, "Lightning Special must deal heavy (20) + special (20) damage")
	e_lspec.queue_free()

	# 2B. Shatter: Heavy attack on frozen enemy
	run.player_cards.assign(["shatter"])
	run.player.cards.assign(["shatter"])
	var e_shatter = RUN_ENEMY.new()
	e_shatter.target = run.player
	e_shatter.health = 300.0
	e_shatter.max_health = 300.0
	e_shatter.elemental_state.frozen_timer = 2.0
	e_shatter.position = run.player.position + Vector2(40, 0)
	run.enemies.add_child(e_shatter)
	await frames(1)
	hp_before = e_shatter.health
	run._on_attack(run.player.position, Vector2.RIGHT, 10.0, 100.0, true)
	# Shatter deals 80 Ice damage on top of heavy attack
	check(e_shatter.health <= hp_before - 90.0, "Shatter card must deal 80 Ice damage when hitting frozen enemy")
	check(not e_shatter.elemental_state.is_frozen(), "Shattered enemy must have frozen state cleared")
	e_shatter.queue_free()

	# ==========================================
	# TEST 3: Dash Cards
	# ==========================================
	# 3A. Lightning Dash
	run.player_cards.assign(["lightning_dash"])
	run.player.cards.assign(["lightning_dash"])
	var e_vdash = RUN_ENEMY.new()
	e_vdash.health = 100.0
	e_vdash.max_health = 100.0
	e_vdash.position = run.player.position + Vector2(100, 0)
	run.enemies.add_child(e_vdash)
	run.player.last_dash_start = run.player.position
	run.player.position += Vector2(200, 0)
	await frames(1)
	hp_before = e_vdash.health
	run._on_player_dashed()
	check(e_vdash.health == hp_before - 18.0, "Lightning Dash must deal 18 Lightning damage to enemies dashed through")
	e_vdash.queue_free()

	# 3B. Fire Dash
	run.player_cards.assign(["fire_dash"])
	run.player.cards.assign(["fire_dash"])
	var e_fdash = RUN_ENEMY.new()
	e_fdash.position = run.player.position + Vector2(50, 0)
	run.enemies.add_child(e_fdash)
	run.player.last_dash_start = run.player.position
	run.player.position += Vector2(100, 0)
	await frames(1)
	run._on_player_dashed()
	check(e_fdash.elemental_state.is_burning(), "Fire Dash must apply Burn to enemies dashed through")
	e_fdash.queue_free()

	# 3C. Fleet Foot speed increase
	run.player_cards.assign(["fleet_foot"])
	run.player.cards.assign(["fleet_foot"])
	var e_fleet = RUN_ENEMY.new()
	e_fleet.position = run.player.position + Vector2(50, 0)
	run.enemies.add_child(e_fleet)
	run.player.last_dash_start = run.player.position
	run.player.position += Vector2(100, 0)
	var base_spd: float = float(run.player.speed)
	await frames(1)
	run._on_player_dashed()
	check(run.player.speed >= base_spd * 1.24, "Fleet Foot must increase player speed by 25% when dashing through an enemy")
	run.player.speed = base_spd
	e_fleet.queue_free()

	# 3D. Light Speed Teleport Dash
	run.player_cards.assign(["light_speed", "lightning_dash"])
	run.player.cards.assign(["light_speed", "lightning_dash"])
	var regular_dash_dist: float = 850.0 * float(run.player.get("dash_duration"))
	var start_pos: Vector2 = run.player.global_position
	var e_ls = RUN_ENEMY.new()
	e_ls.health = 100.0
	e_ls.max_health = 100.0
	e_ls.position = start_pos + Vector2(regular_dash_dist * 0.5, 0)
	run.enemies.add_child(e_ls)

	run.player.dash_cooldown = 0.0
	run.player.start_dash(Vector2.RIGHT)
	var end_pos: Vector2 = run.player.global_position
	var traveled_dist: float = start_pos.distance_to(end_pos)
	check(is_equal_approx(traveled_dist, regular_dash_dist), "Light speed dash distance (%f) must equal regular dash distance (%f)" % [traveled_dist, regular_dash_dist])
	check(run.player.dash_timer > 0, "Light speed dash must remain active during dash duration")
	check(run.player.invulnerability >= run.player.dash_timer, "Invulnerability must cover the full dash duration")
	var took_dmg: bool = run.player.take_damage(20.0)
	check(not took_dmg, "Player cannot be hit while light speed dash is in progress")
	check(e_ls.health == 82.0, "Lightning Dash with Light Speed must strike enemies along the teleport path")
	e_ls.queue_free()

	run.player.dash_timer = 0.0
	run.player.invulnerability = 0.0
	took_dmg = run.player.take_damage(10.0)
	check(took_dmg, "Player can take damage once dash finishes")

	# ==========================================
	# TEST 4: Armor Retaliation & Projectile Restriction
	# ==========================================
	# 4A. Lightning Armor Retaliation on Melee
	run.player_cards.assign(["lightning_armor"])
	run.player.cards.assign(["lightning_armor"])
	run.player_armor_cooldown = 0.0
	var melee_attacker = RUN_ENEMY.new()
	melee_attacker.health = 100.0
	melee_attacker.max_health = 100.0
	run.enemies.add_child(melee_attacker)
	hp_before = melee_attacker.health
	run._on_damage(10.0, melee_attacker, false)
	check(melee_attacker.health == hp_before - 16.0, "Lightning Armor must retaliate 16 Lightning damage to melee attacker")
	check(run.player_armor_cooldown > 0.0, "Armor retaliation must set 0.5s cooldown")

	# 4B. Armor retaliation blocked by cooldown
	run._on_damage(10.0, melee_attacker, false)
	check(melee_attacker.health == hp_before - 16.0, "Armor retaliation within 0.5s cooldown must deal no additional retaliation")

	# 4C. Elemental Armor does NOT work on projectiles
	run.player_armor_cooldown = 0.0
	var proj_attacker = RUN_ENEMY.new()
	proj_attacker.health = 100.0
	proj_attacker.max_health = 100.0
	run.enemies.add_child(proj_attacker)
	hp_before = proj_attacker.health
	run._on_damage(10.0, proj_attacker, true) # is_projectile = true
	check(proj_attacker.health == hp_before, "Elemental Armor effects must NOT trigger on projectiles")
	melee_attacker.queue_free()
	proj_attacker.queue_free()

	# ==========================================
	# TEST 5: Retribution When Hit While Charging Energy
	# ==========================================
	run.player_cards.assign(["lightning_armor"])
	run.player.cards.assign(["lightning_armor"])
	run.player.charging = true
	var charge_attacker = RUN_ENEMY.new()
	charge_attacker.health = 100.0
	charge_attacker.max_health = 100.0
	run.enemies.add_child(charge_attacker)
	hp_before = charge_attacker.health
	run._on_damage(10.0, charge_attacker, true) # Even projectile hit while charging triggers charge retribution
	check(charge_attacker.health == hp_before - 16.0, "Getting hit while charging energy must deal retribution damage")
	run.player.charging = false
	charge_attacker.queue_free()

	# ==========================================
	# TEST 6: DoT Ticks Over Time (Burn & Rust)
	# ==========================================
	var dot_enemy = RUN_ENEMY.new()
	dot_enemy.health = 200.0
	dot_enemy.max_health = 200.0
	dot_enemy.target = run.player
	dot_enemy.room = run.room
	run.enemies.add_child(dot_enemy)
	ELEM.apply_burn(dot_enemy.elemental_state, 3.0)
	dot_enemy.elemental_state.burn_tick_timer = 0.0
	hp_before = dot_enemy.health
	dot_enemy._physics_process(0.01)
	check(dot_enemy.health == hp_before - 6.0, "Burn tick must deal 6 Fire damage when tick timer elapses")

	# Rust tick
	run.player_cards.assign(["rust"])
	run.player.cards.assign(["rust"])
	ELEM.apply_wet(dot_enemy.elemental_state, 3.0)
	dot_enemy.elemental_state.rust_tick_timer = 0.0
	hp_before = dot_enemy.health
	dot_enemy._physics_process(0.01)
	check(dot_enemy.health == hp_before - 8.0, "Rust tick must deal 8 Rust damage when tick timer elapses")
	dot_enemy.queue_free()

	# ==========================================
	# TEST 7: Flying Liberty Room Transitions
	# ==========================================
	var hall = load("res://scenes/FlyingLibertyMainHall.tscn").instantiate()
	root.add_child(hall)
	await frames(2)
	check(hall.has_node("Passages/SyncChamberEntrance"), "Main Hall must have walk-in entrance for Sync Chamber")
	check(hall.has_node("Passages/CockpitEntrance"), "Main Hall must have walk-in entrance for Cockpit")
	check(hall.has_node("Passages/WorkshopEntrance"), "Main Hall must have walk-in entrance for Workshop")
	hall.queue_free()

	var cockpit = load("res://scenes/FlyingLibertyCockpit.tscn").instantiate()
	root.add_child(cockpit)
	await frames(2)
	check(cockpit.has_node("MainHallPassage"), "Cockpit must have walk-in passage to return to Main Hall")
	cockpit.queue_free()

	var sync = load("res://scenes/FlyingLibertySyncChamber.tscn").instantiate()
	root.add_child(sync)
	await frames(2)
	check(sync.has_node("MainHallPassage"), "Sync Chamber must have walk-in passage to return to Main Hall")
	sync.queue_free()

	print("--- Elemental Combat Tests Completed ---")
	print("CHECKS=%d FAILURES=%d" % [checks, failures])
	quit()

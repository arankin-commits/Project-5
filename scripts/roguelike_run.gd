extends Node2D

const ENEMY := preload("res://scripts/run_enemy.gd")
const INDUSTRIAL_ENEMY := preload("res://scripts/industrial_enemy.gd")
const ROOM := preload("res://scripts/boiler_room.gd")
const MAINTENANCE_ROOM := preload("res://scripts/maintenance_room.gd")
const BLOCKOUT_ROOM := preload("res://scripts/blockout_room.gd")
const ROOM_POOL := preload("res://scripts/room_pool.gd")
const PROJECTILE := preload("res://scripts/run_projectile.gd")
const EFFECT := preload("res://scripts/run_effect.gd")
const Space := preload("res://scripts/boiler_space.gd")
const REWARDS := [
	{"id":"power", "name":"FORGED KNUCKLES", "description":"+20% strike damage"},
	{"id":"hull", "name":"RIVETED PLATING", "description":"+20 maximum hull\nRepair 25 hull"},
	{"id":"dash", "name":"QUICK RELEASE", "description":"15% faster dash recharge"},
	{"id":"speed", "name":"PISTON DRIVE", "description":"+10% movement speed"},
	{"id":"repair", "name":"COOLANT RESERVE", "description":"Repair 45 hull"}
]

@onready var player: CharacterBody2D = $World/Player
@onready var enemies: Node2D = $World/Enemies
@onready var hud: CanvasLayer = $RunUI
var config: Node
var rooms: Array
var room: Node2D
var rng := RandomNumberGenerator.new()
var room_index := 0
var wave_index := 0
var living_enemies := 0
var health := 100.0
var maximum_health := 100.0
var kills := 0
var elapsed := 0.0
var state := "combat"
var outcome := ""
var boss: CharacterBody2D
var reward_choices: Array = []
var debug_enabled := false
var camera_shake := 0.0
var progression: Node
var final_stand_used := false
var nanobot_healing := 0
var wall_damage_bonus := 0.0
var run_xp := 0
var run_items := 0
var visited_rooms: Array[int] = []
var perfect_slow_active := false
var perfect_slow_generation := 0
var previous_time_scale := 1.0
var enemy_designs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies/industrial.json"))

func _ready() -> void:
	get_node("/root/BackgroundMusic").play_boiler()
	config = get_node("/root/RunConfig")
	if not config.get("active"):
		config.call("start_run", "medium", {})
	# Developer-only direct access for biome checks.
	if "--boiler-preview" in OS.get_cmdline_user_args():
		config.biome = "boiler"
	rng.seed = int(config.get("run_seed"))
	_prepare_biome()
	maximum_health = config.call("max_health")
	health = maximum_health
	progression = get_node("/root/CoreProgression")
	player.configure_skills(progression.unlocked_skills)
	nanobot_healing = progression.rank("nanobots") * 5
	wall_damage_bonus = progression.rank("wall") * 0.15
	var stats: Dictionary = config.call("robot_stats")
	player.set("appearance", config.get("robot_type"))
	player.set("speed", 265.0 * stats["speed"])
	player.set("damage_multiplier", stats["damage"])
	player.set("backstab_multiplier", stats["backstab"] * (1.0 + progression.rank("backstab") * 0.2))
	player.grapple_requested.connect(use_grapple)
	player.core_requested.connect(use_core_power)
	player.perfect_dodged.connect(_on_perfect_dodge)
	player.attack_requested.connect(_on_attack)
	player.damaged.connect(_on_damage)
	player.dashed.connect(func(): _effect(player.position, "ring", 55, Color("73f7e4")))
	player.dashed.connect(func(): $Audio.play_cue("dash"))
	hud.reward_selected.connect(choose_reward)
	hud.retry_requested.connect(_retry)
	hud.return_requested.connect(return_to_sync_chamber)
	hud.pause_requested.connect(_toggle_pause)
	_load_room(0)
	$Camera2D.make_current()
	$Camera2D.reset_smoothing()
	$Camera2D.force_update_scroll()

func _prepare_biome() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(config.BIOME_DATA[config.biome]))
	rooms = ROOM_POOL.select_rooms(parsed,rng)
	$Camera2D.zoom = Vector2.ONE * (0.7 if config.biome == "maintenance" else 0.82)
	for i in rooms.size():
		rooms[i]["final"] = i == rooms.size()-1
		rooms[i]["room_count"] = rooms.size()
		if rooms[i].get("blockout",false):
			rooms[i]["exit_rewards"] = ["repair","hull","power"]
			if i+1 < rooms.size():
				rooms[i]["next_preview"] = ("BOSS: " + str(rooms[i+1].boss_name)) if rooms[i+1].get("boss",false) else "NEXT: " + str(rooms[i+1].name).to_upper()
		elif config.biome == "maintenance" and i+1 < rooms.size():
			var reward_text := "+20 MAX HULL / REPAIR 25" if rooms[i+1].reward == "hull" else "REPAIR 45 HULL"
			rooms[i]["next_preview"] = ("BOSS: MAINTENANCE GUARDIAN" if rooms[i+1].get("boss",false) else "NEXT: " + str(rooms[i+1].name).to_upper()) + "\n" + reward_text

func _complete_biome() -> void:
	var next: String = config.next_biome()
	if not next.is_empty() and config.BIOME_DATA.has(next):
		config.biome = next
		visited_rooms.clear()
		_prepare_biome()
		_load_room(0)
	else:
		_finish(true)

func _on_perfect_dodge() -> void:
	if state != "combat":
		return
	_effect(player.position, "ring", 90, Color("ffce83"))
	if not perfect_slow_active:
		previous_time_scale = Engine.time_scale
	perfect_slow_active = true
	perfect_slow_generation += 1
	var generation := perfect_slow_generation
	Engine.time_scale = previous_time_scale * 0.25
	hud.perfect_dash_indicator.show()
	# Real-time duration, unaffected by the slowdown or opening the pause menu.
	await get_tree().create_timer(0.3, true, false, true).timeout
	if generation == perfect_slow_generation:
		_end_perfect_slow()

func _end_perfect_slow() -> void:
	perfect_slow_generation += 1
	if perfect_slow_active:
		Engine.time_scale = previous_time_scale
		perfect_slow_active = false
	if is_instance_valid(hud) and is_instance_valid(hud.perfect_dash_indicator):
		hud.perfect_dash_indicator.hide()

func _exit_tree() -> void:
	_end_perfect_slow()

func _load_room(index: int) -> void:
	_end_perfect_slow()
	player.clear_enemy_statuses()
	if not visited_rooms.has(index):
		if not visited_rooms.is_empty():
			health = minf(maximum_health, health + nanobot_healing)
		visited_rooms.append(index)
	if is_instance_valid(room):
		room.free()
	for enemy in enemies.get_children():
		enemy.free()
	_clear_projectiles()
	for effect in $Effects.get_children():
		effect.queue_free()
	room_index = index
	wave_index = 0
	state = "combat"
	boss = null
	room = BLOCKOUT_ROOM.new() if rooms[index].get("blockout",false) else (MAINTENANCE_ROOM.new() if config.biome == "maintenance" else ROOM.new())
	room.name = "Chamber"
	$World.add_child(room)
	if room is BLOCKOUT_ROOM:
		var options: Array[String] = ["repair","hull","power","dash","speed"]
		var pending_core: String = str(rooms[index].reward).trim_prefix("core_") if str(rooms[index].reward).begins_with("core_") else ""
		if config.core_elements.size()+(0 if pending_core.is_empty() else 1) < config.core_limit:
			for element in config.available_elements():
				if element != pending_core:
					options.append("core_"+element)
		rooms[index].exit_rewards = []
		for door in 3:
			rooms[index].exit_rewards.append(options[(index+door)%options.size()])
	room.call("build",rooms[index])
	player.collision_mask = 9 if room is BLOCKOUT_ROOM else 1
	room.set("player",player)
	room.set("hazards_enabled",true)
	room.set("debug_enabled",debug_enabled)
	player.position = room.get("spawn_position")
	player.velocity = Vector2.ZERO
	player.set("controls_enabled",true)
	player.set("invulnerability",1.0)
	player.set("dash_timer",0.0)
	player.set("dash_cooldown",0.0)
	player.set("facing",Vector2.UP)
	config.set("best_room",maxi(int(config.get("best_room")),index+1))
	hud.call("set_room",index,rooms[index],config.get("run_seed"))
	_spawn_wave()

func _spawn_wave() -> void:
	var kinds: Array = rooms[room_index]["waves"][wave_index].duplicate()
	if wave_index == 0 and config.get("modifiers")["reinforcements"]:
		var reinforcement: String = kinds[0] if enemy_designs.has(kinds[0]) else "crawler"
		if kinds[0] == "boss" and rooms[room_index].get("blockout",false):
			for key in enemy_designs:
				if enemy_designs[key].biome_key == config.biome:
					reinforcement = key
					break
		kinds.append_array([reinforcement,reinforcement])
	var points: Array[Vector2] = room.call("safe_spawns",kinds.size(),rng)
	living_enemies = kinds.size()
	for i in kinds.size():
		var enemy = INDUSTRIAL_ENEMY.new() if enemy_designs.has(kinds[i]) else ENEMY.new()
		if enemy_designs.has(kinds[i]):
			enemy.design = enemy_designs[kinds[i]]
			enemy.summon_requested.connect(_spawn_summons)
		enemy.kind = kinds[i]
		enemy.position = points[i]
		if kinds[i] == "boss":
			if not room is MAINTENANCE_ROOM:
				enemy.position = Space.project(Vector2(380,380))
			enemy.display_name = rooms[room_index].get("boss_name","FURNACE WARDEN")
			boss = enemy
		enemy.target = player
		enemy.room = room
		enemy.speed = config.call("enemy_speed")
		enemy.cooldown = 1.4 + i*0.2
		enemy.defeated.connect(_on_enemy_defeated)
		enemy.projectile_requested.connect(_spawn_projectile)
		enemy.impact_requested.connect(_on_impact)
		enemies.add_child(enemy)
		if room is BLOCKOUT_ROOM:
			enemy.collision_mask = 9
		_effect(enemy.position,"ring",60,Color("ef9353"))

func _spawn_summons(summoner: CharacterBody2D, key: String, count: int) -> void:
	if state != "combat" or summoner.health <= 0 or not enemy_designs.has(key):
		return
	if enemy_designs[key].biome_key != config.biome:
		return
	var owned := 0
	for enemy in enemies.get_children():
		if enemy is INDUSTRIAL_ENEMY and enemy.health > 0 and enemy.summoner != null and enemy.summoner.get_ref() == summoner:
			owned += 1
	var cap := 1 if key == "industrial_09" else 6
	count = mini(count,mini(cap-owned,18-living_enemies))
	if count <= 0:
		return
	var points: Array[Vector2] = room.safe_spawns(count,rng)
	for point in points:
		var enemy := INDUSTRIAL_ENEMY.new()
		enemy.design = enemy_designs[key]
		enemy.target = player
		enemy.room = room
		enemy.position = point
		enemy.is_summon = true
		enemy.summoner = weakref(summoner)
		enemy.defeated.connect(_on_enemy_defeated)
		enemy.projectile_requested.connect(_spawn_projectile)
		enemy.impact_requested.connect(_on_impact)
		living_enemies += 1
		enemies.add_child(enemy)
		enemy.collision_mask = 9
		if key == "industrial_09":
			var split_health := maxf(1,summoner.health*.5)
			summoner.health = split_health
			enemy.health = split_health
			enemy.visual.scale *= .7
			summoner.visual.scale *= .7
		_effect(point,"ring",40,Color("c998ff"))

func _process(delta: float) -> void:
	if state == "combat":
		elapsed += delta
		var waves: Array = rooms[room_index]["waves"]
		hud.objective.text = "WAVE %d/%d   /   %d HOSTILES" % [wave_index+1,waves.size(),living_enemies]
	elif state == "exit":
		if room is MAINTENANCE_ROOM:
			room.exit_position = room.nearest_exit(player.position)
		hud.objective.text = "E  CONTINUE" if player.position.distance_to(room.get("exit_position")) < 85 else "REACH THE TEAL LIFT MARKER"
	hud.call("update_stats",health,maximum_health,player.get("dash_cooldown"),player.get("special_cooldown"))
	hud.call("set_boss",boss if is_instance_valid(boss) else null)
	hud.call("update_progression", player.energy, config.core_elements, config.core_limit, run_xp, run_items, player.perfect_reward_timer, player.perfect_damage_timer)
	var desired := Vector2(768,545)+(player.position-Vector2(768,610))*Vector2(0.17,0.12)
	if room is MAINTENANCE_ROOM:
		desired = room.camera_target(player.position)
	$Camera2D.position = $Camera2D.position.lerp(desired,1-exp(-delta*4))
	camera_shake = maxf(0,camera_shake-delta*25)
	$Camera2D.offset = Vector2(sin(elapsed*91),cos(elapsed*107))*camera_shake if get_node("/root/GameSettings").screen_shake else Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and state == "exit":
		try_advance()
	if event.is_action_pressed("toggle_debug"):
		debug_enabled = not debug_enabled
		room.set("debug_enabled",debug_enabled)

func try_advance() -> bool:
	if room is MAINTENANCE_ROOM:
		room.exit_position = room.nearest_exit(player.position)
	if state != "exit" or player.position.distance_to(room.get("exit_position")) >= 85:
		return false
	if room is BLOCKOUT_ROOM:
		var door: int = room.exit_positions.find(room.exit_position)
		rooms[room_index+1].reward = rooms[room_index].exit_rewards[door]
	_load_room(room_index+1)
	return true

func _on_attack(origin: Vector2, direction: Vector2, damage: float, reach: float, heavy: bool) -> void:
	if state != "combat":
		return
	$Audio.play_cue("strike")
	_effect(origin,"ring" if heavy else "slash",reach,Color("ffcc73") if heavy else Color("85ffe2"),direction)
	for enemy in enemies.get_children():
		if enemy.get("health") <= 0:
			continue
		var offset: Vector2 = enemy.position-origin
		var extra := 45.0 if enemy.get("kind") == "boss" else 15.0
		if offset.length() > reach+extra:
			continue
		if not heavy and offset.length() > 15 and offset.normalized().dot(direction) < 0.2:
			continue
		var query := PhysicsRayQueryParameters2D.create(origin,enemy.position,1)
		if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
			continue
		var hit_damage := damage
		if enemy.wall_stun_timer > 0:
			hit_damage *= 1.0 + wall_damage_bonus
		if enemy.call("is_backstab", origin):
			hit_damage *= float(player.get("backstab_multiplier"))
		enemy.call("take_damage",hit_damage,direction,180.0 if player.charged_strike else (65.0 if heavy else 12.0))
		player.gain_hit_energy()
		_damage_number(enemy.position-Vector2(0,70),hit_damage)
		_effect(enemy.position-Vector2(0,35),"burst",35,Color("ffe0a0"))
		camera_shake = 3 if not heavy else 6

func _on_damage(amount: float) -> void:
	if state != "combat":
		return
	health = maxf(0,health-amount)
	$Audio.play_cue("hit")
	camera_shake = 8
	_effect(player.position,"burst",45,Color("ff7654"))
	if health <= 0:
		if player.skills.has("final_stand") and not final_stand_used:
			final_stand_used = true
			health = maximum_health * 0.5
			player.invulnerability = 2.0
			_effect(player.position,"ring",120,Color("7bffbc"))
		else:
			_finish(false)

func _on_enemy_defeated(enemy: CharacterBody2D) -> void:
	if enemy == boss:
		boss = null
	kills += 1
	_award_progress(100 if enemy.kind == "boss" else 10, 1 if enemy.kind == "boss" else 0)
	living_enemies -= 1
	_effect(enemy.position,"burst",85,Color("ffa44f"))
	call_deferred("_check_clear")

func _check_clear() -> void:
	if state != "combat" or living_enemies > 0:
		return
	if wave_index+1 < rooms[room_index]["waves"].size():
		wave_index += 1
		_spawn_wave()
		return
	_clear_projectiles()
	room.set("hazards_enabled",false)
	player.clear_enemy_statuses()
	_award_progress(25, 1 if room_index == 3 else 0)
	state = "reward"
	hud.objective.text = "CHAMBER CLEARED"
	$Audio.play_cue("clear")
	player.set("controls_enabled",false)
	health = minf(maximum_health,health+12)
	reward_choices.clear()
	if config.biome == "maintenance" or room is BLOCKOUT_ROOM:
		for reward in REWARDS:
			if reward.id == rooms[room_index].reward:
				reward_choices.append(reward)
		var promised: String = rooms[room_index].reward
		if promised.begins_with("core_"):
			var element := promised.trim_prefix("core_")
			reward_choices.append({"id":promised,"name":element.to_upper()+" CORE","description":"Bind %s core\nQ / 25 energy" % element})
		hud.call("show_rewards",reward_choices)
		return
	var available := REWARDS.duplicate(true)
	for i in 3:
		var pick := rng.randi_range(0,available.size()-1)
		reward_choices.append(available[pick])
		available.remove_at(pick)
	var elements: Array[String] = config.available_elements()
	if not elements.is_empty():
		var element: String = elements[rng.randi_range(0, elements.size() - 1)]
		var effect_text: String = {"fire": "High-damage burst", "water": "Burst + 3s slow", "lightning": "Burst + knockback"}[element]
		reward_choices[0] = {"id": "core_" + element, "name": element.to_upper() + " CORE", "description": "%s\nBind slot %d/%d\nQ / 25 energy" % [effect_text, config.core_elements.size() + 1, config.core_limit]}
	hud.call("show_rewards",reward_choices)

func choose_reward(id: String) -> bool:
	if state != "reward":
		return false
	var valid := false
	for choice in reward_choices:
		valid = valid or choice["id"] == id
	if not valid:
		return false
	if id.begins_with("core_") and not config.pick_element(id.trim_prefix("core_")):
		return false
	match id:
		"power": player.set("damage_multiplier",float(player.get("damage_multiplier"))+0.2 * config.call("robot_stats")["damage"])
		"hull":
			maximum_health += 20
			health = minf(maximum_health,health+25)
		"dash": player.set("dash_recharge",maxf(0.3,float(player.get("dash_recharge"))*0.85))
		"speed": player.set("speed",float(player.get("speed"))*1.1)
		"repair": health = minf(maximum_health,health+45)
	if room_index == rooms.size()-1:
		hud.modal.hide()
		_complete_biome()
		return true
	state = "exit"
	room.set("exit_enabled",true)
	player.set("controls_enabled",true)
	hud.modal.hide()
	return true

func _award_progress(amount: int, items := 0) -> void:
	if player.perfect_reward_timer > 0:
		amount *= 2
	run_xp += amount
	run_items += items
	progression.award(amount, items)

func use_grapple(direction: Vector2) -> bool:
	if state != "combat" or not player.controls_enabled or player.grapple_cooldown > 0:
		return false
	var target: CharacterBody2D
	var nearest := 360.0
	for enemy in enemies.get_children():
		if enemy.health <= 0 or enemy.kind == "boss" or (enemy.kind == "brute" and not player.skills.has("heavy_grapple")):
			continue
		var offset: Vector2 = enemy.position - player.position
		if offset.length() < nearest and offset.normalized().dot(direction.normalized()) > 0.65:
			if get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(player.position, enemy.position, 1)).is_empty():
				target = enemy
				nearest = offset.length()
	if target == null:
		return false
	player.grapple_cooldown = 2.0
	var line := Line2D.new()
	line.points = PackedVector2Array([player.position, target.position])
	line.width = 4
	line.default_color = Color("ffce83")
	$Effects.add_child(line)
	var tween := create_tween()
	tween.tween_property(line,"modulate:a",0.0,0.25)
	tween.tween_callback(line.queue_free)
	target.apply_knockback(target.position.direction_to(player.position), maxf(0, nearest - 65))
	return true

func use_core_power() -> bool:
	if state != "combat" or not player.controls_enabled or player.energy < 25 or player.core_cooldown > 0 or config.core_elements.is_empty():
		return false
	player.energy -= 25
	player.core_cooldown = 1.0
	for element in config.core_elements:
		var tint: Color = {"fire": Color("ff9955"), "water": Color("55ccff"), "lightning": Color("df88ff")}[element]
		_effect(player.position, "ring", 240, tint)
		for enemy in enemies.get_children():
			if enemy.health <= 0 or enemy.position.distance_to(player.position) > 240:
				continue
			if not get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(player.position,enemy.position,1)).is_empty():
				continue
			var damage := (40.0 if element == "fire" else 25.0) * float(player.combat_damage_multiplier())
			enemy.take_damage(damage)
			if element == "water":
				enemy.slow_timer = 3.0
			elif element == "lightning":
				enemy.apply_knockback(player.position.direction_to(enemy.position), 90)
			_damage_number(enemy.position - Vector2(0,70), damage)
	return true

func _spawn_projectile(origin: Vector2, direction: Vector2, damage: float) -> void:
	if state != "combat":
		return
	var projectile := PROJECTILE.new()
	projectile.position = origin
	projectile.velocity = direction*270
	projectile.target = player
	projectile.damage = damage
	$Projectiles.add_child(projectile)

func _on_impact(point: Vector2, radius: float) -> void:
	_effect(point,"ring",radius,Color("ff914d"))
	camera_shake = 5

func _effect(point: Vector2, kind: String, radius: float, color: Color, direction := Vector2.RIGHT) -> void:
	var effect := EFFECT.new()
	effect.position = point
	effect.kind = kind
	effect.radius = radius
	effect.tint = color
	effect.direction = direction
	$Effects.add_child(effect)

func _damage_number(point: Vector2, amount: float) -> void:
	var label := Label.new()
	label.text = str(roundi(amount))
	label.position = point
	label.add_theme_font_size_override("font_size",24)
	label.add_theme_color_override("font_color",Color("fff0bb"))
	label.z_index = 8
	$Effects.add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label,"position",point-Vector2(0,35),0.55)
	tween.tween_property(label,"modulate:a",0.0,0.55)
	tween.chain().tween_callback(label.queue_free)

func _clear_projectiles() -> void:
	for projectile in $Projectiles.get_children():
		projectile.queue_free()

func _finish(won: bool) -> void:
	if state == "result":
		return
	state = "result"
	_end_perfect_slow()
	outcome = ("MAINTENANCE CLEARED" if config.biome == "maintenance" else "BOILER DISTRICT CLEARED") if won else "FRAME LOST"
	if won and config.biome == "toxin_refinery":
		outcome = "UNDERGROUND ROUTE CLEARED"
	hud.objective.text = "DISTRICT CLEARED" if won else "CORE RECOVERED"
	player.set("controls_enabled",false)
	room.set("hazards_enabled",false)
	for enemy in enemies.get_children():
		enemy.set("active",false)
	_clear_projectiles()
	if won and config.next_biome().is_empty():
		config.set("victories",int(config.get("victories"))+1)
	var victory_text := "Maintenance secured. Return to the Flying Liberty." if config.biome == "maintenance" else "The Furnace Warden is silent. The pressure line is yours."
	if config.biome == "toxin_refinery":
		victory_text = "Toxin Refinery secured. Underground investigation complete. Return to the Flying Liberty."
	if won and not config.next_biome().is_empty():
		victory_text = "%s is not yet available. Returning to the Flying Liberty." % config.next_biome().replace("_"," ").capitalize()
	hud.call("show_result",outcome,"Chamber %d / %d   |   %d hostiles dismantled   |   %d:%02d\n%s" % [room_index+1,rooms.size(),kills,int(elapsed)/60,int(elapsed)%60,victory_text if won else "Your core is safe aboard the Flying Liberty. Rebuild and try again."])
	await get_tree().create_timer(2.0).timeout
	return_to_sync_chamber()

func _toggle_pause() -> void:
	if state == "result":
		return
	get_tree().paused = not get_tree().paused
	if get_tree().paused:
		hud.call("show_pause")
	else:
		hud.call("hide_pause")

func _retry() -> void:
	get_tree().paused = false
	config.call("start_run",config.get("robot_type"),config.get("modifiers").duplicate(),config.route)
	get_tree().change_scene_to_file("res://scenes/RoguelikeRun.tscn")

func return_to_sync_chamber() -> void:
	get_tree().paused = false
	config.call("end_run")
	get_tree().change_scene_to_file("res://scenes/FlyingLibertySyncChamber.tscn")

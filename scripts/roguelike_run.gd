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
const ElementalCards := preload("res://scripts/elemental_cards.gd")
const REWARDS := [
	{"id":"power", "name":"FORGED KNUCKLES", "description":"+20% strike damage"},
	{"id":"hull", "name":"RIVETED PLATING", "description":"+25 maximum hull\nRepair 25 hull"},
	{"id":"dash", "name":"QUICK RELEASE", "description":"15% faster dash recharge"},
	{"id":"speed", "name":"PISTON DRIVE", "description":"+10% movement speed"},
	{"id":"repair", "name":"COOLANT RESERVE", "description":"Repair 45 hull"}
]

const ELEMENT_COLORS: Dictionary = {
	"fire": Color("ff3b30"),
	"burn": Color("ff3b30"),
	"explosive": Color("ff3b30"),
	"earth": Color("a65e2e"),
	"lightning": Color("ffe600"),
	"electricity": Color("ffe600"),
	"water": Color("3399ff"),
	"rust": Color("3399ff"),
	"wind": Color("38d978"),
	"ice": Color("a8f0ff"),
	"frost": Color("a8f0ff"),
	"frozen blue": Color("a8f0ff"),
	"frozen_blue": Color("a8f0ff"),
	"regular": Color("cccccc"),
	"normal": Color("cccccc"),
	"physical": Color("cccccc"),
	"grey": Color("cccccc"),
	"gray": Color("cccccc")
}

const CORE_TINTS: Dictionary = {
	"fire": Color("ff9955"),
	"water": Color("55ccff"),
	"lightning": Color("df88ff"),
	"earth": Color("b26a3c"),
	"wind": Color("55ff99"),
	"ice": Color("a8f0ff")
}

static func element_color(element: String) -> Color:
	var key := element.to_lower().strip_edges()
	return ELEMENT_COLORS.get(key, Color("cccccc"))

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
var health := 50.0
var maximum_health := 50.0
var kills := 0
var elapsed := 0.0
var state := "combat"
var outcome := ""
var boss: CharacterBody2D
var reward_choices: Array = []
var player_cards: Array[String] = []
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
var reward_item: Area2D = null
var reward_collected := false
var door_exit_warned := false
var speech_label: Label = null
var speech_timer := 0.0
var is_trap_room := false
var trap_mode := "timer"
var trap_timer := 0.0
var trap_target_waves := 0
var trap_current_wave := 0
var trap_buff_active := false

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
	enemies.child_entered_tree.connect(_on_enemy_child_entered)
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
			if i+1 < rooms.size():
				rooms[i]["next_preview"] = ("BOSS: " + str(rooms[i+1].boss_name)) if rooms[i+1].get("boss",false) else "NEXT: " + str(rooms[i+1].name).to_upper()
		elif config.biome == "maintenance" and i+1 < rooms.size():
			var reward_text := "+25 MAX HULL / REPAIR 25" if rooms[i+1].reward == "hull" else "REPAIR 45 HULL"
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

func _find_reward_spawn_position() -> Vector2:
	var candidate_offsets: Array[Vector2] = [
		Vector2(60, 0), Vector2(-60, 0), Vector2(0, 60), Vector2(0, -60),
		Vector2(45, 45), Vector2(-45, 45), Vector2(45, -45), Vector2(-45, -45)
	]
	for offset in candidate_offsets:
		var target_pos := player.position + offset
		if room.has_method("is_logical_free"):
			if room.is_logical_free(Space.unproject(target_pos), 25.0):
				return target_pos
		elif room.has_method("_source_free"):
			if room._source_free(target_pos):
				return target_pos
	return player.position

func _spawn_reward_item() -> void:
	if is_instance_valid(reward_item):
		reward_item.queue_free()
		reward_item = null
	
	var pos := _find_reward_spawn_position()
	reward_item = Area2D.new()
	reward_item.name = "RewardItem"
	reward_item.position = pos
	reward_item.z_index = 8
	
	var sprite := Sprite2D.new()
	sprite.name = "Visual"
	sprite.texture = preload("res://rooms/Room Exit Icons/Steampunk Reward Icon Atlas.png")
	var current_reward: String = rooms[room_index].get("reward", "max_hp_increase")
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = sprite.texture
	atlas_tex.region = BLOCKOUT_ROOM.REWARD_ICONS.get(current_reward, Rect2(821, 547, 273, 274))
	atlas_tex.filter_clip = true
	sprite.texture = atlas_tex
	sprite.scale = Vector2.ONE * 0.22
	reward_item.add_child(sprite)
	
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 45.0
	col.shape = circle
	reward_item.add_child(col)
	
	var prompt := Label.new()
	prompt.name = "Prompt"
	prompt.text = "[E] Claim Reward"
	prompt.position = Vector2(-75, -55)
	prompt.size = Vector2(150, 30)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 14)
	prompt.add_theme_color_override("font_color", Color("ffd080"))
	prompt.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt.add_theme_constant_override("shadow_offset_x", 1)
	prompt.add_theme_constant_override("shadow_offset_y", 1)
	reward_item.add_child(prompt)
	
	var tween := reward_item.create_tween()
	tween.tween_property(sprite, "position:y", -8.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_loops()
	
	$World.add_child(reward_item)

func activate_reward_item() -> void:
	if reward_collected or not is_instance_valid(reward_item):
		return
	hud.call("show_rewards", reward_choices)
	player.set("controls_enabled", false)

func interact_reward() -> void:
	activate_reward_item()

func _player_say(text: String) -> void:
	if is_instance_valid(player):
		if speech_label == null or not is_instance_valid(speech_label):
			speech_label = Label.new()
			speech_label.name = "SpeechBubble"
			speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			speech_label.add_theme_font_size_override("font_size", 16)
			speech_label.add_theme_color_override("font_color", Color("fff3cf"))
			speech_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
			speech_label.add_theme_constant_override("shadow_offset_x", 1)
			speech_label.add_theme_constant_override("shadow_offset_y", 1)
			speech_label.z_index = 20
			speech_label.custom_minimum_size = Vector2(300, 40)
			player.add_child(speech_label)
		speech_label.text = text
		speech_label.position = Vector2(-150, -110)
		speech_label.show()
		speech_timer = 2.5
	if is_instance_valid(hud) and is_instance_valid(hud.objective):
		hud.objective.text = text

func _get_save_slots() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/SaveSlots")
	var loop = Engine.get_main_loop()
	if loop != null and loop is SceneTree:
		return loop.root.get_node_or_null("SaveSlots")
	return null

func _generate_unique_exit_rewards(count: int, current_room_index: int) -> Array[String]:
	var exit_rng := RandomNumberGenerator.new()

	exit_rng.seed = int(config.get("run_seed")) + current_room_index * 137
	var pool: Array[String] = []
	pool.append("max_hp_increase")
	var save_slots = _get_save_slots()
	var uncollected: Array[String] = []
	if save_slots != null and save_slots.has_method("get_uncollected_cds"):
		uncollected = save_slots.get_uncollected_cds(config.biome)
	# CD reward: only eligible if current biome has uncollected CDs, and made 3 times as rare to find (1 in 3 chance)
	if not uncollected.is_empty() and exit_rng.randi_range(0, 2) == 0:
		pool.append("cds")
	pool.append("core_xp")
	pool.append("aether_cores")
	# Generic power/speed rewards reuse elemental artwork and cannot be door previews.
	pool.append("trap_room")
	
	var raw_reward_str: String = str(rooms[current_room_index].get("reward", "")) if current_room_index >= 0 and current_room_index < rooms.size() else ""
	var pending_core: String = raw_reward_str.trim_prefix("core_") if config.is_element_reward(raw_reward_str) else ""
	var reserves_slot: bool = not pending_core.is_empty() and not config.core_elements.has(pending_core)
	var current_cores_count: int = config.core_elements.size() + (1 if reserves_slot else 0)
	if current_cores_count < config.core_limit:
		for element in config.available_elements():
			if element != pending_core:
				pool.append("core_" + element)
	
	for element in config.core_elements:
		pool.append("upgrade_" + element)
	
	var selected: Array[String] = []
	var available := pool.duplicate()

	exit_rng.seed = int(config.get("run_seed")) + current_room_index * 137
	# Keep random choices, but prevent long stretches without an owned-core upgrade.
	if count > 0 and not config.core_elements.is_empty() and current_room_index % 3 == 0:
		var element: String = config.core_elements[(current_room_index / 3 as int) % config.core_elements.size()]
		var upgrade := "upgrade_" + element
		selected.append(upgrade)
		available.erase(upgrade)
	
	for i in count - selected.size():
		if available.is_empty():
			break
		var pick_idx := exit_rng.randi_range(0, available.size() - 1)
		selected.append(available[pick_idx])
		var selected_icon: Rect2 = BLOCKOUT_ROOM.REWARD_ICONS[available[pick_idx]]
		available.remove_at(pick_idx)
		# Different reward IDs can use the same atlas artwork.
		for remaining in range(available.size() - 1, -1, -1):
			if BLOCKOUT_ROOM.REWARD_ICONS[available[remaining]] == selected_icon:
				available.remove_at(remaining)
	
	return selected

func _spawn_trap_wave() -> void:
	var enemy_keys := enemy_designs.keys()
	var kinds: Array = []
	for i in (3 if config.get("modifiers")["reinforcements"] else 2):
		var pick: String = enemy_keys[rng.randi_range(0, enemy_keys.size() - 1)]
		kinds.append(pick)
	var points: Array[Vector2] = room.call("safe_spawns", kinds.size(), rng)
	living_enemies += kinds.size()
	for i in kinds.size():
		var kind: String = kinds[i]
		var enemy = INDUSTRIAL_ENEMY.new() if enemy_designs.has(kind) else ENEMY.new()
		enemy.position = points[i] if i < points.size() else player.position + Vector2(200, 0)
		enemy.room = room
		enemy.target = player
		var spawn_size: String = str(enemy_designs[kinds[i]].get("size", "Medium")) if enemy_designs.has(kinds[i]) else ("Large" if kinds[i] in ["boss", "brute"] else "Medium")
		enemy.speed = config.get_enemy_speed_by_size(spawn_size)
		enemy.cooldown = 1.4 + i * 0.2
		if enemy is INDUSTRIAL_ENEMY:
			enemy.design = enemy_designs[kind]
			enemy.summon_requested.connect(_spawn_summons)
			enemy.projectile_requested.connect(_spawn_projectile)
			enemy.impact_requested.connect(_on_impact)
		enemy.defeated.connect(_on_enemy_defeated)
		if not enemy.damaged.is_connected(_on_enemy_damaged):
			enemy.damaged.connect(_on_enemy_damaged.bind(enemy))
		enemies.add_child(enemy)
		if not (enemy is INDUSTRIAL_ENEMY) and (config.biome == "maintenance" or room is MAINTENANCE_ROOM):
			enemy.health *= 3.0
			enemy.max_health = enemy.health
		if room is BLOCKOUT_ROOM:
			enemy.collision_mask = 9
		_effect(enemy.position, "ring", 60, Color("ef9353"))

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
	reward_collected = false
	door_exit_warned = false
	if is_instance_valid(reward_item):
		reward_item.queue_free()
		reward_item = null
	if is_instance_valid(speech_label):
		speech_label.hide()
	is_trap_room = rooms[index].get("reward") == "trap_room"
	if is_trap_room:
		var trap_rng := RandomNumberGenerator.new()
		trap_rng.seed = int(config.get("run_seed")) + index * 43
		if trap_rng.randf() > 0.5:
			trap_mode = "timer"
			trap_timer = trap_rng.randf_range(45.0, 90.0)
		else:
			trap_mode = "waves"
			trap_target_waves = trap_rng.randi_range(10, 15)
			trap_current_wave = 1
	if rooms[index].get("reward") == "cds" and not rooms[index].has("cd_track"):
		var save_slots = _get_save_slots()
		if save_slots != null and save_slots.has_method("get_uncollected_cds"):
			var uncollected: Array[String] = save_slots.get_uncollected_cds(config.biome)
			if not uncollected.is_empty():
				var cd_rng := RandomNumberGenerator.new()
				cd_rng.seed = int(config.get("run_seed")) + index * 313
				var pick := cd_rng.randi_range(0, uncollected.size() - 1)
				rooms[index]["cd_track"] = uncollected[pick]
	room = BLOCKOUT_ROOM.new() if rooms[index].get("blockout",false) else (MAINTENANCE_ROOM.new() if config.biome == "maintenance" else ROOM.new())
	room.name = "Chamber"
	$World.add_child(room)
	if room is BLOCKOUT_ROOM:
		# Exit positions are populated by build(); count the authored doors first.
		var exit_count := 0
		for door in rooms[index].geometry.doors:
			if door.role != "entrance":
				exit_count += 1
		rooms[index].exit_rewards = _generate_unique_exit_rewards(exit_count, index)
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
		var spawn_size: String = str(enemy_designs[kinds[i]].get("size", "Medium")) if enemy_designs.has(kinds[i]) else ("Large" if kinds[i] in ["boss", "brute"] else "Medium")
		enemy.speed = config.get_enemy_speed_by_size(spawn_size)
		enemy.cooldown = 1.4 + i*0.2
		enemy.defeated.connect(_on_enemy_defeated)
		if not enemy.damaged.is_connected(_on_enemy_damaged):
			enemy.damaged.connect(_on_enemy_damaged.bind(enemy))
		enemy.projectile_requested.connect(_spawn_projectile)
		enemy.impact_requested.connect(_on_impact)
		enemies.add_child(enemy)
		if not (enemy is INDUSTRIAL_ENEMY) and (config.biome == "maintenance" or room is MAINTENANCE_ROOM):
			enemy.health *= 3.0
			enemy.max_health = enemy.health
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
		if not enemy.damaged.is_connected(_on_enemy_damaged):
			enemy.damaged.connect(_on_enemy_damaged.bind(enemy))
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
	if speech_timer > 0:
		speech_timer -= delta
		if speech_timer <= 0 and is_instance_valid(speech_label):
			speech_label.hide()
	if state == "combat":
		elapsed += delta
		if is_trap_room and trap_mode == "timer":
			trap_timer -= delta
			if trap_timer > 0:
				hud.objective.text = "SURVIVE: %02d:%02d" % [int(trap_timer) / 60, int(trap_timer) % 60]
				if living_enemies < 2:
					_spawn_trap_wave()
			else:
				hud.objective.text = "TIME SURVIVED!"
				for enemy in enemies.get_children():
					if enemy.health > 0:
						enemy.take_damage(10000)
				living_enemies = 0
				_check_clear()
		elif is_trap_room and trap_mode == "waves":
			hud.objective.text = "SURVIVE WAVES: %d/%d   /   %d HOSTILES" % [trap_current_wave, trap_target_waves, living_enemies]
		else:
			var waves: Array = rooms[room_index]["waves"]
			hud.objective.text = "WAVE %d/%d   /   %d HOSTILES" % [wave_index+1,waves.size(),living_enemies]
	elif state == "reward" or state == "exit":
		if room is MAINTENANCE_ROOM:
			room.exit_position = room.nearest_exit(player.position)
		if is_instance_valid(reward_item) and not reward_collected:
			var near_reward := player.position.distance_to(reward_item.position) <= 85
			var prompt_node = reward_item.get_node_or_null("Prompt")
			if prompt_node:
				prompt_node.modulate.a = 1.0 if near_reward else 0.5
			if near_reward:
				hud.objective.text = "E  CLAIM REWARD"
			elif speech_timer <= 0:
				hud.objective.text = "CHAMBER CLEARED"
		elif state == "exit":
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
	if event.is_action_pressed("interact"):
		if is_instance_valid(reward_item) and not reward_collected and player.position.distance_to(reward_item.position) <= 85:
			activate_reward_item()
			get_viewport().set_input_as_handled()
			return
		if state == "reward" or state == "exit":
			try_advance()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("toggle_debug"):
		debug_enabled = not debug_enabled
		room.set("debug_enabled",debug_enabled)

func try_advance() -> bool:
	if room is MAINTENANCE_ROOM:
		room.exit_position = room.nearest_exit(player.position)
	if state == "combat" or player.position.distance_to(room.get("exit_position")) >= 85:
		return false
	if not reward_collected:
		if not door_exit_warned:
			door_exit_warned = true
			_player_say("I should collect the reward item first.")
			return false
		_player_say("Leaving the reward behind...")
		reward_collected = true
		if is_instance_valid(reward_item):
			reward_item.queue_free()
			reward_item = null
	door_exit_warned = false
	if room is BLOCKOUT_ROOM:
		var door: int = room.exit_positions.find(room.exit_position)
		if door >= 0 and door < rooms[room_index].exit_rewards.size() and room_index + 1 < rooms.size():
			rooms[room_index+1].reward = rooms[room_index].exit_rewards[door]

	call_deferred("_load_room", room_index + 1)
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
	if is_trap_room and trap_mode == "waves" and trap_current_wave < trap_target_waves:
		trap_current_wave += 1
		_spawn_trap_wave()
		return
	if not is_trap_room and wave_index+1 < rooms[room_index]["waves"].size():
		wave_index += 1
		_spawn_wave()
		return
	_clear_projectiles()
	room.set("hazards_enabled",false)
	player.clear_enemy_statuses()
	_award_progress(25, 1 if room_index == 3 else 0)
	if is_trap_room:
		trap_buff_active = true
	state = "reward"
	hud.objective.text = "CHAMBER CLEARED"
	$Audio.play_cue("clear")
	health = minf(maximum_health,health+12)
	reward_choices.clear()
	var promised: String = rooms[room_index].reward
	if config.biome == "maintenance" or room is BLOCKOUT_ROOM:
		var found_promised := false
		for reward in REWARDS:
			if reward.id == promised:
				reward_choices.append(reward)
				found_promised = true
				break
		if not found_promised:
			if config.is_element_reward(promised) or promised.begins_with("upgrade_"):
				var element := promised.trim_prefix("core_").trim_prefix("upgrade_")
				var rolled: Array[Dictionary] = ElementalCards.roll_elemental_cards(element, player_cards, trap_buff_active, rng)
				if not rolled.is_empty():
					for card in rolled:
						reward_choices.append({
							"id": card["id"],
							"element": element,
							"name": card["name"].to_upper(),
							"description": "[%s]
%s" % [card["rarity"].to_upper(), card["description"]],
							"rarity": card["rarity"],
							"is_element_card": true
						})
				elif config.is_element_reward(promised):
					reward_choices.append({"id":promised,"name":element.to_upper()+" CORE","description":"Bind %s core
Q / 25 energy" % element})
				else:
					var bonus_text := "+45% (High Rarity)" if trap_buff_active else "+25%"
					reward_choices.append({"id":promised,"name":element.to_upper()+" UPGRADE","description":"Enhance %s core power
%s effectiveness" % [element, bonus_text]})
			elif promised == "trap_room":
				reward_choices.append({"id":"trap_room","name":"TRAP SURVIVAL CACHE","description":"Upgrade rarity increased for future rewards"})
			elif promised == "core_xp":
				reward_choices.append({"id":"core_xp","name":"KINETIC DYNAMO","description":"+100 Core XP"})
			elif promised == "aether_cores":
				reward_choices.append({"id":"aether_cores","name":"AETHER GEAR","description":"+1 Aether Gear"})
			elif promised == "cds":
				var track_id: String = rooms[room_index].get("cd_track", "")
				var save_slots = _get_save_slots()
				if track_id.is_empty() and save_slots != null and save_slots.has_method("get_uncollected_cds"):
					var uncollected: Array[String] = save_slots.get_uncollected_cds(config.biome)
					if not uncollected.is_empty():
						track_id = uncollected[rng.randi_range(0, uncollected.size() - 1)]
						rooms[room_index]["cd_track"] = track_id
				var track_title := "DISC"
				if not track_id.is_empty() and save_slots != null and save_slots.CD_TRACKS.has(track_id):
					track_title = str(save_slots.CD_TRACKS[track_id].get("title", track_id))
				reward_choices.append({"id":"cds","name":"MUSIC CD: " + track_title.to_upper(),"description":"Acquire '%s' for the Jukebox\n20%% faster dash recharge" % track_title,"track_id":track_id})
			elif promised == "max_hp_increase":
				reward_choices.append({"id":"max_hp_increase","name":"REINFORCED CHASSIS","description":"+25 maximum hull\nRepair 25 hull"})
	else:
		var available := REWARDS.duplicate(true)
		for i in 3:
			var pick := rng.randi_range(0,available.size()-1)
			reward_choices.append(available[pick])
			available.remove_at(pick)
		var elements: Array[String] = config.available_elements()
		if not elements.is_empty():
			var element: String = elements[rng.randi_range(0, elements.size() - 1)]
			var effect_text: String = {
				"fire": "High-damage burn & explosion",
				"water": "Weakening, rust & synergy",
				"lightning": "Burst, speed & chaining",
				"ice": "Slowing, freezing & execution",
				"wind": "Knockback, collision & stuns",
				"earth": "Heavy defense, constructs & rocks"
			}.get(element, "Elemental power")
			reward_choices[0] = {"id": "core_" + element, "name": element.to_upper() + " CORE", "description": "%s\nBind slot %d/%d\nQ / 25 energy" % [effect_text, config.core_elements.size() + 1, config.core_limit]}
	reward_collected = false
	door_exit_warned = false
	player.set("controls_enabled", true)
	_spawn_reward_item()

func choose_reward(id: String) -> bool:
	if state != "reward":
		return false
	var valid := false
	for choice in reward_choices:
		valid = valid or choice["id"] == id
	if not valid:
		return false
	if id.begins_with("upgrade_") and not config.core_elements.has(id.trim_prefix("upgrade_")):
		return false
	if config.is_element_reward(id) and not config.pick_element(id.trim_prefix("core_")):
		return false
	if ElementalCards.has_card(id):
		var card: Dictionary = ElementalCards.get_card(id)
		var elem: String = card.get("element", "")
		if not config.core_elements.has(elem) and config.core_elements.size() < config.core_limit:
			config.pick_element(elem)
		if not player_cards.has(id):
			player_cards.append(id)
		_apply_elemental_card(id)

	var chosen_element := ""
	if config.is_element_reward(id):
		chosen_element = id.trim_prefix("core_")
	elif ElementalCards.has_card(id):
		chosen_element = ElementalCards.get_card(id).get("element", "")

	if not chosen_element.is_empty() and room is BLOCKOUT_ROOM and not rooms[room_index].get("final", false):
		# These previews were built before the player owned the newly collected core.
		var upgrade := "upgrade_" + chosen_element
		var exits: Array = rooms[room_index].exit_rewards
		if not exits.is_empty() and not exits.has(upgrade):
			exits[0] = upgrade
			room.refresh_exit_previews(rooms[room_index])
	reward_collected = true
	door_exit_warned = false
	if is_instance_valid(reward_item):
		reward_item.queue_free()
		reward_item = null
	match id:
		"power": player.set("damage_multiplier",float(player.get("damage_multiplier"))+0.2 * config.call("robot_stats")["damage"])
		"hull":
			maximum_health += 25
			health = minf(maximum_health,health+25)
		"max_hp_increase":
			maximum_health += 25
			health = minf(maximum_health,health+25)
		"dash": player.set("dash_recharge",maxf(0.3,float(player.get("dash_recharge"))*0.85))
		"cds":
			var save_slots = _get_save_slots()
			var awarded_track: String = rooms[room_index].get("cd_track", "")
			if awarded_track.is_empty() and save_slots != null and save_slots.has_method("get_uncollected_cds"):
				var uncollected: Array[String] = save_slots.get_uncollected_cds(config.biome)
				if not uncollected.is_empty():
					awarded_track = uncollected[rng.randi_range(0, uncollected.size() - 1)]
			if not awarded_track.is_empty() and save_slots != null and save_slots.has_method("collect_cd"):
				save_slots.collect_cd(awarded_track)
				var title: String = save_slots.CD_TRACKS.get(awarded_track, {}).get("title", awarded_track)
				_player_say("Acquired Music CD: " + title)
			player.set("dash_recharge", maxf(0.3, float(player.get("dash_recharge")) * 0.80))
		"speed": player.set("speed",float(player.get("speed"))*1.1)
		"repair": health = minf(maximum_health,health+45)
		"core_xp": _award_progress(100, 0)
		"aether_cores": _award_progress(25, 1)
		"trap_room":
			trap_buff_active = true
		"upgrade_fire", "upgrade_lightning", "upgrade_ice", "upgrade_wind", "upgrade_earth":
			var mult: float = 1.45 if trap_buff_active else 1.25
			player.set("damage_multiplier", float(player.get("damage_multiplier")) * mult)
		"upgrade_water":
			var mult: float = 1.45 if trap_buff_active else 1.25
			player.set("speed", float(player.get("speed")) * mult)
	if room_index == rooms.size()-1:
		hud.modal.hide()
		_complete_biome()
		return true
	state = "exit"
	room.set("exit_enabled",true)
	player.set("controls_enabled",true)
	hud.modal.hide()
	return true

func _apply_elemental_card(id: String) -> void:
	var card: Dictionary = ElementalCards.get_card(id)
	if card.is_empty():
		return
	if is_instance_valid(player):
		player.set("cards", player_cards)
		match id:
			"electric_energy":
				player.set("charge_speed_mult", 3.0)
	_player_say("Card Acquired: " + card.get("name", id))

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
		var tint: Color = CORE_TINTS.get(element, Color("ff9955"))
		_effect(player.position, "ring", 240, tint)
		for enemy in enemies.get_children():
			if enemy.health <= 0 or enemy.position.distance_to(player.position) > 240:
				continue
			if not get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(player.position,enemy.position,1)).is_empty():
				continue
			var damage := (40.0 if element == "fire" else 25.0) * float(player.combat_damage_multiplier())
			enemy.take_damage(damage, Vector2.ZERO, 12.0, element)
			if element == "water":
				enemy.slow_timer = 3.0
			elif element == "lightning":
				enemy.apply_knockback(player.position.direction_to(enemy.position), 90)
			elif element == "ice":
				enemy.slow_timer = 3.0
			elif element == "wind":
				enemy.apply_knockback(player.position.direction_to(enemy.position), 120, "wind")
			elif element == "earth":
				enemy.take_damage(28.0, Vector2.ZERO, 0.0, "earth")

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

func _on_enemy_child_entered(node: Node) -> void:
	if node is CharacterBody2D and node.has_signal("damaged"):
		if not node.damaged.is_connected(_on_enemy_damaged):
			node.damaged.connect(_on_enemy_damaged.bind(node))

func _on_enemy_damaged(amount: float, knockback: Vector2, element: String, enemy: CharacterBody2D) -> void:
	if not is_instance_valid(enemy):
		return
	spawn_damage_number(enemy, amount, knockback, element)

func spawn_damage_number(enemy: CharacterBody2D, amount: float, direction := Vector2.ZERO, element := "regular") -> void:
	if not is_instance_valid(enemy) or roundi(amount) <= 0:
		return
	var is_boss: bool = enemy.get("kind") == "boss"
	var side_offset: float = 72.0 if is_boss else 44.0
	var vertical_offset: float = -55.0 if is_boss else -36.0
	var side := 1.0
	if direction.x > 0.05:
		side = 1.0
	elif direction.x < -0.05:
		side = -1.0
	elif is_instance_valid(player):
		side = 1.0 if enemy.position.x >= player.position.x else -1.0
	
	var jitter_y: float = rng.randf_range(-6.0, 6.0) if rng != null else randf_range(-6.0, 6.0)
	var spawn_pos: Vector2
	var label := Label.new()
	label.name = "DamageNumber"
	label.text = str(roundi(amount))
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", element_color(element))
	label.add_theme_color_override("font_outline_color", Color("1a1008"))
	label.add_theme_constant_override("outline_size", 4)
	label.z_index = 8
	label.size = Vector2(70, 32)
	
	if side > 0:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		spawn_pos = enemy.position + Vector2(side_offset, vertical_offset + jitter_y)
	else:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		spawn_pos = enemy.position + Vector2(-side_offset - label.size.x, vertical_offset + jitter_y)
	
	label.position = spawn_pos
	$Effects.add_child(label)
	
	var drift_x: float = side * 12.0
	var drift_y: float = -28.0
	var target_pos: Vector2 = spawn_pos + Vector2(drift_x, drift_y)
	
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "position", target_pos, 0.55).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, 0.55).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(label.queue_free)

func _damage_number(point: Vector2, amount: float, element := "regular") -> void:
	var label := Label.new()
	label.text = str(roundi(amount))
	label.position = point
	label.add_theme_font_size_override("font_size",24)
	label.add_theme_color_override("font_color", element_color(element))
	label.add_theme_color_override("font_outline_color", Color("1a1008"))
	label.add_theme_constant_override("outline_size", 4)
	label.z_index = 8
	$Effects.add_child(label)
	var tween := label.create_tween().set_parallel(true)
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

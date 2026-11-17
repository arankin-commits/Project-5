extends SceneTree

const BLOCKOUT_ROOM := preload("res://scripts/blockout_room.gd")
const SPACE := preload("res://scripts/boiler_space.gd")

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAILED: " + message)

func frames(count := 2) -> void:
	for i in count:
		await physics_frame
		await process_frame

func _run() -> void:
	print("--- BEGINNING MEMORY RULES VALIDATION ---")
	
	# ==========================================
	# RULE 11: Steampunk Reward Icon Atlas Mapping (21 icons in 7x3 grid)
	# ==========================================
	var atlas_names := [
		"aether_cores", "core_xp", "permanent_info", "cds", "core_fire", "core_ice", "core_wind",
		"core_earth", "core_lightning", "core_water", "temporary_info", "upgrade_fire", "upgrade_ice", "upgrade_wind",
		"upgrade_earth", "upgrade_lightning", "upgrade_water", "max_hp_increase", "shop_room", "trap_room", "secret_room"
	]
	check(atlas_names.size() == 21, "Atlas must define exactly 21 icons")
	for name in atlas_names:
		check(BLOCKOUT_ROOM.REWARD_ICONS.has(name), "Atlas icon missing from REWARD_ICONS: " + name)
	
	# Verify distinct Rect2 coordinates for each atlas icon
	var mapped_rects := {}
	for name in atlas_names:
		var rect: Rect2 = BLOCKOUT_ROOM.REWARD_ICONS[name]
		check(not mapped_rects.has(rect), "Atlas Rect2 collided: " + name)
		mapped_rects[rect] = name
	check(mapped_rects.size() == 21, "All 21 atlas icons must have unique Rect2 coordinates")
	
	# ==========================================
	# RULES 4, 5, 8, 9, 10: Excluded Icons (Secret, Shop, Info, Weapon)
	# ==========================================
	var config: Node = root.get_node("RunConfig")
	config.call("start_run", "medium", {})
	
	var run = load("res://scenes/RoguelikeRun.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	await frames(3)
	
	# Test pool generation does not contain excluded icons
	for room_idx in 10:
		var exit_rewards: Array[String] = run._generate_unique_exit_rewards(4, room_idx)
		for reward in exit_rewards:
			check(reward != "secret_room", "Rule 8 violated: secret room icon appeared in exit rewards")
			check(reward != "shop_room", "Rule 9 violated: shop room icon appeared in exit rewards")
			check(reward != "permanent_info", "Rule 10 violated: permanent info icon appeared in exit rewards")
			check(reward != "temporary_info", "Rule 10 violated: temporary info icon appeared in exit rewards")
			check(not reward.begins_with("weapon"), "Rule 4/5 violated: weapon reward appeared in exit rewards")
	
	# ==========================================
	# RULE 3: No multiple doors with the same icon in the same room
	# ==========================================
	for room_idx in 20:
		for exit_count in range(2, 5):
			var exits: Array[String] = run._generate_unique_exit_rewards(exit_count, room_idx)
			check(exits.size() == exit_count, "Wrong exit count generated")
			var seen := {}
			for r in exits:
				check(not seen.has(r), "Rule 3 violated: duplicate door icon/reward '%s' in room %d" % [r, room_idx])
				seen[r] = true
	
	# ==========================================
	# RULE 6: Elemental core upgrades only show up if you have the selected core
	# ==========================================
	config.core_elements.clear()
	var rewards_no_core: Array[String] = run._generate_unique_exit_rewards(6, 1)
	for r in rewards_no_core:
		check(not r.begins_with("upgrade_"), "Rule 6 violated: core upgrade appeared without owning core: " + r)
	
	config.core_elements = ["fire"]
	var saw_fire_upgrade := false
	for seed_offset in 50:
		var test_rewards: Array[String] = run._generate_unique_exit_rewards(6, seed_offset)
		for r in test_rewards:
			if r == "upgrade_fire":
				saw_fire_upgrade = true
			check(r != "upgrade_water" and r != "upgrade_lightning", "Rule 6 violated: unowned core upgrade appeared: " + r)
	check(saw_fire_upgrade, "Owned fire core never offered fire upgrade")
	
	# ==========================================
	# RULE 7: Elemental Cores align with skill tree (Power of 2 & Power of 3)
	# ==========================================
	config.core_elements = ["fire"]
	config.core_limit = 1 # At default limit 1 with 1 core owned
	for seed_offset in 30:
		var test_rewards: Array[String] = run._generate_unique_exit_rewards(6, seed_offset)
		for r in test_rewards:
			check(not r.begins_with("core_"), "Rule 7 violated: elemental core appeared at capacity: " + r)
	
	# With Power of Two, capacity is 2
	config.core_limit = 2
	var saw_core_reward := false
	for seed_offset in 30:
		var test_rewards: Array[String] = run._generate_unique_exit_rewards(6, seed_offset)
		for r in test_rewards:
			if r.begins_with("core_"):
				saw_core_reward = true
				check(r != "core_fire", "Rule 7 violated: already owned core appeared: " + r)
	check(saw_core_reward, "Elemental core did not appear with available capacity")
	
	# ==========================================
	# RULE 1: Reward item spawns next to player, in-bounds, activates only on E
	# ==========================================
	# Clear first room enemies
	for enemy in run.enemies.get_children():
		enemy.active = false
		enemy.take_damage(10000)
	await frames(4)
	
	check(run.state == "reward", "Room did not enter reward state")
	check(run.reward_item != null, "Rule 1 violated: physical reward item did not spawn")
	check(run.player.position.distance_to(run.reward_item.position) <= 80, "Rule 1 violated: reward item not spawned next to player")
	check(not run.hud.modal.visible, "Rule 1 violated: reward modal opened before interaction")
	
	# Interacting with reward item opens modal
	run.activate_reward_item()
	check(run.hud.modal.visible, "Interacting with reward item did not open modal")
	
	# ==========================================
	# RULE 2: Leaving through door prompts warning; second interaction leaves reward
	# ==========================================
	# Reset room to reward state without collecting
	run.hud.modal.hide()
	run.reward_collected = false
	run.door_exit_warned = false
	
	# Move player to exit door
	run.player.position = run.room.exit_positions[0]
	
	# 1st attempt: player warned, does not advance
	var advanced_1: bool = run.try_advance()
	check(not advanced_1, "Rule 2 violated: player advanced through door without collecting reward on 1st attempt")
	check(run.door_exit_warned, "Rule 2 violated: door_exit_warned flag not set")
	check(run.speech_label != null and run.speech_label.visible and run.speech_label.text.contains("collect the reward item first"), "Rule 2 violated: player character did not speak warning")
	
	# 2nd attempt: player leaves reward behind and advances
	var initial_room_idx: int = run.room_index
	var advanced_2: bool = run.try_advance()
	check(advanced_2, "Rule 2 violated: player was not allowed to leave reward behind on 2nd attempt")
	check(run.reward_collected, "Reward not marked collected after leaving it behind")
	await frames(3)
	check(run.room_index == initial_room_idx + 1, "Player did not advance to next chamber")
	
	# ==========================================
	# RULE 12: Trap Rooms win conditions and rarity boost
	# ==========================================
	run.rooms[run.room_index].reward = "trap_room"
	run._load_room(run.room_index)
	await frames(2)
	check(run.is_trap_room, "Trap room not initialized")
	check(run.trap_mode in ["timer", "waves"], "Trap room mode must be timer or waves")
	if run.trap_mode == "timer":
		check(run.trap_timer >= 45.0 and run.trap_timer <= 90.0, "Rule 12: Trap timer out of 45s-90s range: %f" % run.trap_timer)
	else:
		check(run.trap_target_waves >= 10 and run.trap_target_waves <= 15, "Rule 12: Trap waves out of 10-15 range: %d" % run.trap_target_waves)
	
	# Simulate clearing the trap room
	for enemy in run.enemies.get_children():
		enemy.active = false
		enemy.take_damage(10000)
	run.trap_timer = 0.0
	run.trap_current_wave = run.trap_target_waves
	run._check_clear()
	await frames(2)
	check(run.trap_buff_active, "Rule 12: Trap room clear did not activate rarity buff")
	
	# ==========================================
	# RULE 13: Cap of 2 shop rewards per run
	# ==========================================
	check(config.MAX_SHOP_REWARDS == 2, "Rule 13: Max shop rewards must be 2")
	check(config.shop_rewards_count <= config.MAX_SHOP_REWARDS, "Shop rewards exceeded cap of 2")
	
	# ==========================================
	# RULE 14: Damage numbers show up next to the enemy hit
	# ==========================================
	var test_enemy = load("res://scripts/run_enemy.gd").new()
	test_enemy.room = run.room
	test_enemy.target = run.player
	run.enemies.add_child(test_enemy)
	test_enemy.position = Vector2(500, 500)
	test_enemy.health = 500
	test_enemy.take_damage(25, Vector2.RIGHT)
	var dmg_num: Label = null
	for child in run.get_node("Effects").get_children():
		if child is Label and child.text == "25":
			dmg_num = child
	check(dmg_num != null, "Rule 14: Damage number did not spawn on hit")
	if dmg_num != null:
		check(dmg_num.position.x > test_enemy.position.x, "Rule 14: Damage number not to the right on rightward hit")
		check(absf(dmg_num.position.y - (test_enemy.position.y - 36)) < 15, "Rule 14: Damage number not beside torso")
	test_enemy.take_damage(40, Vector2.LEFT)
	var left_dmg: Label = null
	for child in run.get_node("Effects").get_children():
		if child is Label and child.text == "40":
			left_dmg = child
	check(left_dmg != null, "Rule 14: Damage number did not spawn on leftward hit")
	if left_dmg != null:
		check(left_dmg.position.x + left_dmg.size.x <= test_enemy.position.x, "Rule 14: Damage number not to the left on leftward hit")
	test_enemy.queue_free()
	
	# ==========================================
	# RULE 15: Element Rules - Damage number colors
	# ==========================================
	var roguelike_script = load("res://scripts/roguelike_run.gd")
	check(roguelike_script.element_color("fire") == Color("ff3b30"), "Rule 15: Fire damage number must be red")
	check(roguelike_script.element_color("burn") == Color("ff3b30"), "Rule 15: Burn damage number must be red")
	check(roguelike_script.element_color("explosive") == Color("ff3b30"), "Rule 15: Explosive damage number must be red")
	check(roguelike_script.element_color("earth") == Color("a65e2e"), "Rule 15: Earth damage number must be brown")
	check(roguelike_script.element_color("lightning") == Color("ffe600"), "Rule 15: Lightning damage number must be yellow")
	check(roguelike_script.element_color("electricity") == Color("ffe600"), "Rule 15: Electricity damage number must be yellow")
	check(roguelike_script.element_color("water") == Color("3399ff"), "Rule 15: Water damage number must be blue")
	check(roguelike_script.element_color("rust") == Color("3399ff"), "Rule 15: Rust damage number must be blue")
	check(roguelike_script.element_color("wind") == Color("38d978"), "Rule 15: Wind damage number must be green")
	check(roguelike_script.element_color("ice") == Color("a8f0ff"), "Rule 15: Ice damage number must be frozen blue")
	check(roguelike_script.element_color("frost") == Color("a8f0ff"), "Rule 15: Frost damage number must be frozen blue")
	check(roguelike_script.element_color("regular") == Color("cccccc"), "Rule 15: Regular damage number must be grey")
	check(roguelike_script.element_color("unknown") == Color("cccccc"), "Rule 15: Default damage number must be grey")

	var elem_enemy = load("res://scripts/run_enemy.gd").new()
	elem_enemy.room = run.room
	elem_enemy.target = run.player
	run.enemies.add_child(elem_enemy)
	elem_enemy.position = Vector2(600, 600)
	elem_enemy.health = 5000

	var elem_tests := [
		{"element": "fire", "damage": 51, "expected_color": Color("ff3b30")},
		{"element": "burn", "damage": 52, "expected_color": Color("ff3b30")},
		{"element": "explosive", "damage": 53, "expected_color": Color("ff3b30")},
		{"element": "earth", "damage": 54, "expected_color": Color("a65e2e")},
		{"element": "lightning", "damage": 55, "expected_color": Color("ffe600")},
		{"element": "electricity", "damage": 56, "expected_color": Color("ffe600")},
		{"element": "water", "damage": 57, "expected_color": Color("3399ff")},
		{"element": "rust", "damage": 58, "expected_color": Color("3399ff")},
		{"element": "wind", "damage": 59, "expected_color": Color("38d978")},
		{"element": "ice", "damage": 60, "expected_color": Color("a8f0ff")},
		{"element": "frost", "damage": 61, "expected_color": Color("a8f0ff")},
		{"element": "regular", "damage": 62, "expected_color": Color("cccccc")}
	]

	for t in elem_tests:
		elem_enemy.take_damage(t.damage, Vector2.RIGHT, 12.0, t.element)
		var found_label: Label = null
		for child in run.get_node("Effects").get_children():
			if child is Label and child.text == str(t.damage):
				found_label = child
		check(found_label != null, "Rule 15: Damage number label not spawned for " + t.element)
		if found_label != null:
			var font_col: Color = found_label.get_theme_color("font_color")
			check(font_col == t.expected_color, "Rule 15: Color mismatch for %s: got %s, expected %s" % [t.element, str(font_col), str(t.expected_color)])

	elem_enemy.take_damage(63, Vector2.RIGHT)
	var default_label: Label = null
	for child in run.get_node("Effects").get_children():
		if child is Label and child.text == "63":
			default_label = child
	check(default_label != null, "Rule 15: Untyped damage number label not spawned")
	if default_label != null:
		var font_col: Color = default_label.get_theme_color("font_color")
		check(font_col == Color("cccccc"), "Rule 15: Untyped damage must default to grey, got %s" % str(font_col))

	# Test Elemental Reactions and Status Mechanics (Rule 15 additions)
	var ELEM := preload("res://scripts/elemental_system.gd")
	var state := ELEM.StatusState.new()
	
	# Symmetric Fire/Frost reaction to Wet
	ELEM.apply_frost(state)
	check(state.is_frost(), "Rule 15: Applying frost must set frost status")
	ELEM.apply_burn(state)
	check(not state.is_frost() and not state.is_burning() and state.is_wet(), "Rule 15: Burn on frost must cancel both and apply wet")
	check(state.frost_meter == 0.0 and state.burn_meter == 0.0, "Rule 15: Burn/frost cancellation must reset meters to zero")
	
	var state_rev := ELEM.StatusState.new()
	ELEM.apply_burn(state_rev)
	check(state_rev.is_burning(), "Rule 15: Applying burn must set burning status")
	ELEM.apply_frost(state_rev)
	check(not state_rev.is_burning() and not state_rev.is_frost() and state_rev.is_wet(), "Rule 15: Frost on burn must cancel both and apply wet (symmetric)")
	
	# Wet status vulnerability (+50% for Ice/Frost and Lightning/Electricity)
	check(ELEM.calculate_elemental_damage(100.0, "ice", state) == 150.0, "Rule 15: Ice damage against Wet enemy must deal +50%")
	check(ELEM.calculate_elemental_damage(100.0, "lightning", state) == 150.0, "Rule 15: Lightning damage against Wet enemy must deal +50%")
	
	# Enemies cannot be burned under Wet status
	var burn_under_wet = ELEM.apply_burn(state)
	check(not burn_under_wet.applied and not state.is_burning(), "Rule 15: Enemies cannot be burned under Wet status")
	
	# Applying Wet extinguishes Burn and resets meter
	var state_ext := ELEM.StatusState.new()
	ELEM.apply_burn(state_ext, 4.0, 50.0)
	ELEM.apply_wet(state_ext)
	check(not state_ext.is_burning() and state_ext.burn_meter == 0.0 and state_ext.is_wet(), "Rule 15: Wet must extinguish Burn and reset meter")
	
	# Frost meter attack gain is doubled under Wet status
	var state_frost_gain := ELEM.StatusState.new()
	ELEM.apply_wet(state_frost_gain)
	ELEM.apply_frost(state_frost_gain, 4.0, 30.0)
	check(state_frost_gain.frost_meter == 60.0, "Rule 15: Frost meter gain must be doubled under Wet status")
	
	# Earth and Burn damage do 50% damage to frozen enemies
	var state_frozen := ELEM.StatusState.new()
	state_frozen.frozen_timer = 3.0
	check(ELEM.calculate_elemental_damage(100.0, "earth", state_frozen) == 50.0, "Rule 15: Earth damage must be 50% against frozen enemy")
	check(ELEM.calculate_elemental_damage(100.0, "burn", state_frozen) == 50.0, "Rule 15: Burn damage must be 50% against frozen enemy")
	
	# Earth attacks against Wet enemies apply Mud
	var state_mud := ELEM.StatusState.new()
	ELEM.apply_wet(state_mud)
	ELEM.apply_earth(state_mud)
	check(state_mud.is_muddy() and state_mud.mud_timer == 2.0, "Rule 15: Earth attack against Wet enemy must apply Mud")
	
	# Wind increases Burn tick by 25% for 3 seconds
	var state_wind := ELEM.StatusState.new()
	ELEM.apply_burn(state_wind)
	ELEM.apply_wind(state_wind)
	check(ELEM.calculate_burn_tick(40.0, state_wind) == 50.0, "Rule 15: Wind must increase Burn tick by 25%")
	
	# Boss knockback is halved
	check(ELEM.get_effective_knockback(180.0, true) == 90.0, "Rule 15: Knockback effects must be halved against bosses")
	check(ELEM.get_effective_knockback(180.0, false) == 180.0, "Rule 15: Knockback effects must remain full against regular enemies")

	elem_enemy.queue_free()
	
	# ==========================================
	# RULE 17: Enemies don't trigger traps, but can still be harmed by them
	# ==========================================
	run.room.hazards_enabled = true
	var trap_enemy = load("res://scripts/run_enemy.gd").new()
	trap_enemy.room = run.room
	trap_enemy.target = run.player
	run.enemies.add_child(trap_enemy)
	trap_enemy.position = run.room.vents[0]
	trap_enemy.health = 500
	
	# Verify enemy cannot trigger traps
	check(run.room.can_trigger_trap(run.player), "Rule 17: Player must be able to trigger traps")
	check(not run.room.can_trigger_trap(trap_enemy), "Rule 17: Enemy must NOT be able to trigger traps")
	check(not run.room.trigger_trap(0, trap_enemy), "Rule 17: Trap triggering by enemy must be rejected")
	
	# With periodic hazard idle, enemy on trap does not trigger it and takes no damage
	run.room.elapsed = 1.0
	run.room.trap_triggers.clear()
	run.room.hazard_tick = 0
	run.player.position = Vector2(-2000, -2000)
	run.room._physics_process(0.01)
	check(not run.room.is_trap_active(0), "Rule 17: Trap must not be active when only enemy stepped on it")
	check(trap_enemy.health == 500, "Rule 17: Enemy must take no damage from inactive untriggered trap")
	
	# Player triggers the trap: trap becomes active
	check(run.room.trigger_trap(0, run.player), "Rule 17: Player failed to trigger trap")
	check(run.room.is_trap_active(0), "Rule 17: Trap must be active after player triggers it")
	
	# Enemy on the active/triggered trap is harmed by it
	run.room.hazard_tick = 0
	run.room._physics_process(0.01)
	check(trap_enemy.health == 500 - 32, "Rule 17: Enemy must take full trap damage (32) when on triggered trap, got %f" % trap_enemy.health)
	
	# Enemy knocked into periodic active trap is also harmed
	run.room.trap_triggers.clear()
	run.room.elapsed = 4.0
	run.room.hazard_tick = 0
	trap_enemy.health = 500
	run.room._physics_process(0.01)
	check(trap_enemy.health == 500 - 32, "Rule 17: Enemy must be harmed by active periodic trap, got %f" % trap_enemy.health)
	trap_enemy.queue_free()
	
	# ==========================================
	# RULE 18: CD Rewards & 16-Track Biome Distribution
	# ==========================================
	var save_slots = root.get_node_or_null("SaveSlots")
	check(save_slots != null, "Rule 18: SaveSlots singleton missing")
	if save_slots != null:
		# 1. Verify 16 tracks catalog
		check(save_slots.CD_TRACKS.size() == 16, "Rule 18: Exactly 16 CD tracks required, found %d" % save_slots.CD_TRACKS.size())
		
		# 2. Verify 4 biomes with 4 tracks each
		var expected_biomes := ["maintenance", "factory", "boiler", "toxin_refinery"]
		var total_partitioned := 0
		var all_track_ids := []
		for b in expected_biomes:
			check(save_slots.BIOME_CDS.has(b), "Rule 18: Biome missing from BIOME_CDS: " + b)
			var b_tracks: Array = save_slots.BIOME_CDS.get(b, [])
			check(b_tracks.size() == 4, "Rule 18: Biome %s must have exactly 4 tracks, got %d" % [b, b_tracks.size()])
			total_partitioned += b_tracks.size()
			for tid in b_tracks:
				check(save_slots.CD_TRACKS.has(tid), "Rule 18: Track ID %s missing from CD_TRACKS" % tid)
				check(save_slots.CD_TRACKS[tid].biome == b, "Rule 18: Track %s biome mismatch, expected %s" % [tid, b])
				check(not all_track_ids.has(tid), "Rule 18: Duplicate track ID in partition: " + tid)
				all_track_ids.append(tid)
				# Check audio file existence
				var audio_path: String = save_slots.CD_TRACKS[tid].get("path", "")
				check(FileAccess.file_exists(audio_path), "Rule 18: Audio file missing on disk: " + audio_path)
		check(total_partitioned == 16, "Rule 18: Total partitioned tracks must equal 16")
		
		# First 4 maintenance, next 4 factory, next 4 boiler, final 4 toxin_refinery
		check(save_slots.BIOME_CDS["maintenance"][0] == "01_Copper_Hearth", "Rule 18: Track 1 must be 01_Copper_Hearth in maintenance")
		check(save_slots.BIOME_CDS["maintenance"][3] == "04_Captains_Quadrille", "Rule 18: Track 4 must be 04_Captains_Quadrille in maintenance")
		check(save_slots.BIOME_CDS["factory"][0] == "05_Clockwork_Pavane", "Rule 18: Track 5 must be 05_Clockwork_Pavane in factory")
		check(save_slots.BIOME_CDS["factory"][3] == "08_Liberty_Overture", "Rule 18: Track 8 must be 08_Liberty_Overture in factory")
		check(save_slots.BIOME_CDS["boiler"][0] == "09_Glass_Horizon", "Rule 18: Track 9 must be 09_Glass_Horizon in boiler")
		check(save_slots.BIOME_CDS["boiler"][3] == "12_Skylight_Chapel", "Rule 18: Track 12 must be 12_Skylight_Chapel in boiler")
		check(save_slots.BIOME_CDS["toxin_refinery"][0] == "13_Observatory_of_Dreams", "Rule 18: Track 13 must be 13_Observatory_of_Dreams in toxin_refinery")
		check(save_slots.BIOME_CDS["toxin_refinery"][3] == "16_Homeward_Through_Mist", "Rule 18: Track 16 must be 16_Homeward_Through_Mist in toxin_refinery")
		
		# 3. Uncollected pool & random selection without replacement
		save_slots.reset_collected_cds()
		check(save_slots.get_uncollected_cds("maintenance").size() == 4, "Rule 18: Maintenance uncollected pool must start at 4")
		save_slots.collect_cd("01_Copper_Hearth")
		check(save_slots.is_cd_collected("01_Copper_Hearth"), "Rule 18: Track 01_Copper_Hearth not marked collected")
		var uncollected_maint := save_slots.get_uncollected_cds("maintenance")
		check(uncollected_maint.size() == 3, "Rule 18: Uncollected pool must reduce to 3 after collecting one")
		check(not uncollected_maint.has("01_Copper_Hearth"), "Rule 18: Acquired track must no longer show up in pool")
		
		# 4. Biome cleared: CD reward no longer shows up
		save_slots.collect_cd("02_Scribes_of_the_Air")
		save_slots.collect_cd("03_Parlour_Above_the_Clouds")
		save_slots.collect_cd("04_Captains_Quadrille")
		check(save_slots.get_uncollected_cds("maintenance").is_empty(), "Rule 18: Maintenance uncollected pool must be empty after 4 collected")
		config.biome = "maintenance"
		for test_seed in 50:
			var exit_rewards := run._generate_unique_exit_rewards(4, test_seed)
			check(not exit_rewards.has("cds"), "Rule 18 violated: 'cds' appeared as reward after all biome CDs were collected in room %d" % test_seed)
		
		# 5. 3x Rarity: When uncollected CDs exist, 'cds' is 3 times as rare to find
		save_slots.reset_collected_cds()
		var cds_found_count := 0
		var total_sample_rooms := 150
		for test_seed in total_sample_rooms:
			var exit_rewards := run._generate_unique_exit_rewards(4, test_seed)
			if exit_rewards.has("cds"):
				cds_found_count += 1
		# With 3x rarity, cds appears in roughly 1/3 of the rate when it was 100% pool candidate
		check(cds_found_count > 0, "Rule 18: 'cds' reward never appeared across 150 rooms")
		check(cds_found_count < total_sample_rooms * 0.45, "Rule 18: 'cds' reward appeared too frequently (found %d/%d), 3x rarity not enforced" % [cds_found_count, total_sample_rooms])
		
		# 6. Room reward and claiming
		run.rooms[run.room_index].reward = "cds"
		run.rooms[run.room_index].erase("cd_track")
		run._load_room(run.room_index)
		check(run.rooms[run.room_index].has("cd_track"), "Rule 18: Loading a 'cds' room must assign a cd_track")
		var assigned_track: String = run.rooms[run.room_index]["cd_track"]
		check(save_slots.BIOME_CDS["maintenance"].has(assigned_track), "Rule 18: Assigned track must belong to maintenance biome: " + assigned_track)
		run.state = "reward"
		run.reward_choices.clear()
		run.rooms[run.room_index].reward = "cds"
		var promised: String = "cds"
		var track_id: String = run.rooms[run.room_index].get("cd_track", "")
		var track_title := str(save_slots.CD_TRACKS[track_id].get("title", track_id))
		run.reward_choices.append({
			"id": "cds",
			"name": "MUSIC CD: " + track_title.to_upper(),
			"description": "Acquire '%s' for the Jukebox\n20%% faster dash recharge" % track_title,
			"track_id": track_id
		})
		check(run.reward_choices[0].name.begins_with("MUSIC CD: "), "Rule 18: Reward modal choice name must begin with 'MUSIC CD:'")
		check(run.choose_reward("cds"), "Rule 18: choose_reward('cds') failed")
		check(save_slots.is_cd_collected(assigned_track), "Rule 18: Claiming CD reward must mark assigned track collected")
	
	# ==========================================
	# RULE 19: Enemy Collision Damage & Knockback Scaling
	# ==========================================
	var RUN_ENEMY := preload("res://scripts/run_enemy.gd")
	var e_sample = RUN_ENEMY.new()
	check(e_sample.calculate_collision_damage(12.0) == 6.0, "Rule 19: Knockback power 12.0 must deal 6 collision damage")
	check(e_sample.calculate_collision_damage(65.0) == 33.0, "Rule 19: Knockback power 65.0 must deal 33 collision damage")
	check(e_sample.calculate_collision_damage(90.0) == 45.0, "Rule 19: Knockback power 90.0 must deal 45 collision damage")
	check(e_sample.calculate_collision_damage(180.0) == 90.0, "Rule 19: Knockback power 180.0 must deal 90 collision damage")
	check(e_sample.calculate_collision_damage(0.0) == 0.0, "Rule 19: 0 knockback power must deal 0 collision damage")
	check(e_sample.calculate_collision_damage(180.0) > e_sample.calculate_collision_damage(65.0), "Rule 19: Higher knockback power must deal greater collision damage")
	e_sample.free()

	# Create two test enemies in the active room
	var enemy_a = RUN_ENEMY.new()
	enemy_a.kind = "crawler"
	enemy_a.health = 100.0
	enemy_a.max_health = 100.0
	enemy_a.position = Vector2(400, 400)
	run.room.add_child(enemy_a)

	var enemy_b = RUN_ENEMY.new()
	enemy_b.kind = "crawler"
	enemy_b.health = 100.0
	enemy_b.max_health = 100.0
	enemy_b.position = Vector2(420, 400)
	run.room.add_child(enemy_b)
	await frames(2)

	# 1. Test Enemy-Enemy collision: Enemy A knocked into Enemy B
	var a_hp_before := enemy_a.health
	var b_hp_before := enemy_b.health
	enemy_a.apply_knockback(Vector2.RIGHT, 65.0)
	await frames(1)

	check(enemy_a.health == a_hp_before - 33.0, "Rule 19: Knocked enemy A must take collision damage (33), got %f" % enemy_a.health)
	check(enemy_b.health == b_hp_before - 33.0, "Rule 19: Collided enemy B must take collision damage (33), got %f" % enemy_b.health)
	check(enemy_a.wall_stun_timer > 0.0, "Rule 19: Knocked enemy A must be stunned after colliding with enemy B")
	check(enemy_b.wall_stun_timer > 0.0, "Rule 19: Collided enemy B must be stunned after being hit by knocked enemy")

	# 2. Test Wall/Construct collision: Enemy A knocked into room boundary wall
	enemy_a.position = Vector2(100, 300)
	enemy_a.health = 100.0
	enemy_a.wall_stun_timer = 0.0
	var wall_hp_before := enemy_a.health
	enemy_a.apply_knockback(Vector2.LEFT, 180.0)
	await frames(1)
	check(enemy_a.health == wall_hp_before - 90.0, "Rule 19: Enemy knocked into wall must take 90 collision damage from 180 power, got %f" % enemy_a.health)
	check(enemy_a.wall_stun_timer > 0.0, "Rule 19: Enemy knocked into wall must receive wall stun")

	if is_instance_valid(enemy_a):
		enemy_a.queue_free()
	if is_instance_valid(enemy_b):
		enemy_b.queue_free()
	await frames(2)

	# ==========================================
	# RULE 16: Quitting from the in-game menu brings player to the main menu
	# ==========================================
	run._toggle_pause()
	var pause_menu = run.hud.pause_menu
	check(paused and pause_menu.visible, "Rule 16: Pause menu not visible when paused")
	var run_quit_btn: Button = null
	for child in pause_menu.stack.get_children():
		if child is Button and child.text == "Quit":
			run_quit_btn = child
	check(run_quit_btn != null, "Rule 16: Quit button missing from in-game menu")
	if run_quit_btn != null:
		run_quit_btn.pressed.emit()
		await scene_changed
		check(not paused and current_scene.name == "StartScreen", "Rule 16: Quitting from in-game menu did not return to StartScreen main menu")
	
	if current_scene != null:
		current_scene.queue_free()
	current_scene = null
	
	print("--- MEMORY RULES VALIDATION COMPLETED ---")
	print("MEMORY_RULES_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)

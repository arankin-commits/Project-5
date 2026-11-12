extends SceneTree

const DATA := preload("res://scripts/core_progression.gd")
const Space := preload("res://scripts/boiler_space.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var progress = root.get_node("CoreProgression")
	progress.persistence_enabled = false
	check(not progress.unlock_skill("final_stand"), "Regular node unlocked without XP")
	progress.award(10000)
	check(not progress.unlock_skill("power_two"), "XP purchased special node")
	check(not progress.unlock_skill("nanobots_2"), "Prerequisite was bypassed")
	check(progress.unlock_skill("final_stand") and progress.xp == 9850, "XP cost wrong")
	check(not progress.unlock_skill("final_stand"), "Node bought twice")
	progress.award(0,20)
	var xp: int = progress.xp
	check(progress.unlock_skill("power_two") and progress.xp == xp and progress.special_items == 18, "Special node currency wrong")
	var config = root.get_node("RunConfig")
	for capacity in [1,2,3]:
		progress.unlocked_skills.assign(["root"])
		if capacity >= 2:
			progress.unlocked_skills.append("power_two")
		if capacity == 3:
			progress.unlocked_skills.append("power_three")
		config.start_run("medium",{})
		check(config.core_limit == capacity, "Capacity not applied")
		for i in capacity:
			check(config.pick_element(config.ELEMENTS[i]), "Core pick rejected below capacity")
			check(not config.pick_element(config.ELEMENTS[i]), "Duplicate core accepted")
		check(config.available_elements().is_empty(), "Core encounter available at capacity")
		check(not config.pick_element("invalid"), "Invalid element accepted")
		config.start_run("medium",{})
		check(config.core_elements.is_empty(), "Core elements carried to new run")
	progress.unlocked_skills.assign(["root"])
	for id in DATA.SKILLS:
		if id != "root":
			check(progress.unlock_skill(id), "Cannot unlock " + id)
	check(progress.rank("nanobots") == 5 and progress.rank("wall") == 3 and progress.rank("backstab") == 3, "Rank calculation wrong")
	# Persistence uses a workspace fixture, never the player's save.
	progress.persistence_enabled = true
	progress.save_progress("res://reviews/skill-test-save.cfg")
	progress.unlocked_skills.assign(["root"])
	progress.xp = 0
	progress.load_progress("res://reviews/skill-test-save.cfg")
	check(progress.has_skill("heavy_grapple") and progress.xp > 0, "Save/load lost progression")
	progress.persistence_enabled = false
	config.start_run("medium",{})
	var run = load("res://scenes/RoguelikeRun.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	await physics_frame
	run.room.hazards_enabled = false
	for foe in run.enemies.get_children():
		foe.active = false
	var player = run.player
	player.position = Space.project(Vector2(730,730))
	check(is_equal_approx(player.backstab_multiplier,3.2), "Backstab ranks not applied")
	player.energy = 0
	player.gain_hit_energy()
	check(player.energy == 10, "Energy Siphon did not grant extra 5")
	player.energy = 98
	player.gain_hit_energy()
	check(player.energy == 100, "Energy exceeded cap")
	player.dash_cooldown = 0
	check(player.start_dash(Vector2.RIGHT), "First dodge rejected")
	check(player.start_dash(Vector2.LEFT), "Chained dodge rejected")
	check(not player.start_dash(Vector2.RIGHT), "Third dodge accepted")
	check(not player.take_damage(10) and player.perfect_reward_timer == 5, "Perfect dodge did not grant buff")
	var initial_xp: int = progress.xp
	var initial_items: int = progress.special_items
	run._award_progress(10,1)
	check(progress.xp == initial_xp+20 and progress.special_items == initial_items+2, "Perfect dodge did not double rewards")
	check(run.run_xp == 20 and run.run_items == 2, "Run reward counters did not double")
	player.perfect_reward_timer = 1.0
	player.dash_cooldown = 0
	player.start_dash(Vector2.RIGHT)
	player.take_damage(10)
	check(player.perfect_reward_timer == 5.0, "Second perfect dodge did not reset timer")
	run._award_progress(10,1)
	check(progress.xp == initial_xp+40 and progress.special_items == initial_items+4, "Reward multiplier stacked above 2x")
	player.perfect_reward_timer = 0.01
	player.set_physics_process(false)
	player._physics_process(0.02)
	run._award_progress(10,1)
	check(player.perfect_reward_timer == 0 and progress.xp == initial_xp+50 and progress.special_items == initial_items+5, "Rewards stayed doubled after expiration")
	player.set_physics_process(true)
	player.perfect_reward_timer = 5.0
	player.dash_timer = 0
	var enemy = run.enemies.get_child(0)
	for other in run.enemies.get_children():
		if other != enemy:
			other.position = Vector2(-1000,-1000)
	enemy.position = player.position + Vector2(70,0)
	enemy.facing = Vector2.LEFT
	enemy.health = 1000
	enemy.wall_stun_timer = 1.5
	player.combo = 0
	player.attack_cooldown = 0
	player.perform_attack(Vector2.RIGHT)
	check(is_equal_approx(1000-enemy.health,24*1.45), "Perfect dodge must not boost damage; wall bonus wrong")
	player.perfect_reward_timer = 0
	enemy.wall_stun_timer = 0
	enemy.position = player.position + Vector2(70,0)
	enemy.health = 1000
	player.combo = 0
	player.attack_cooldown = 0
	player.charge_time = 0.7
	player.release_charge(Vector2.RIGHT)
	check(is_equal_approx(1000-enemy.health,48), "Charged attack damage wrong")
	check(enemy.position.distance_to(player.position) > 180, "Charged attack did not knock back")
	# Collision-based wall stun, without manually setting the status.
	enemy.position = Space.project(Vector2(915,550))
	enemy.apply_knockback(Space.AXIS_X,250)
	check(enemy.wall_stun_timer > 0, "Knockback against wall did not stun")
	enemy.kind = "brute"
	enemy.position = player.position + Vector2(220,0)
	player.grapple_cooldown = 0
	check(run.use_grapple(Vector2.RIGHT), "Heavy grapple cannot pull brute")
	check(enemy.position.distance_to(player.position) < 100, "Grapple failed to pull enemy")
	player.skills.erase("heavy_grapple")
	player.grapple_cooldown = 0
	enemy.position = player.position + Vector2(220,0)
	check(not run.use_grapple(Vector2.RIGHT), "Normal grapple pulled brute")
	enemy.kind = "crawler"
	check(run.use_grapple(Vector2.RIGHT), "Base grapple cannot pull small enemy")
	player.energy = 100
	config.pick_element("fire")
	config.pick_element("water")
	config.pick_element("lightning")
	enemy.position = player.position + Vector2(70,0)
	enemy.health = 1000
	check(run.use_core_power() and player.energy == 75, "Core burst energy cost wrong")
	check(is_equal_approx(enemy.health,910) and enemy.slow_timer == 3, "Multi-core effects missing")
	check(not run.use_core_power(), "Core cooldown bypassed")
	run._on_damage(1000)
	check(run.health == run.maximum_health*0.5 and run.final_stand_used and run.state == "combat", "Final Stand failed")
	run.health = 30
	run._load_room(1)
	check(run.health == 55, "Nanobots did not heal on new room")
	run._load_room(1)
	check(run.health == 55, "Nanobots healed twice in same room")
	# Reward generation must omit elemental cores once capacity is reached.
	for foe in run.enemies.get_children():
		foe.active = false
	run.wave_index = run.rooms[1]["waves"].size()-1
	run.living_enemies = 0
	run._check_clear()
	for choice in run.reward_choices:
		check(not choice.id.begins_with("core_"), "Core offered after capacity filled")
	run.state = "combat"
	run._on_damage(1000)
	check(run.state == "result", "Final Stand triggered twice")
	run.queue_free()
	await process_frame
	current_scene = null
	var tree = load("res://scenes/ui/CoreTerminal.tscn").instantiate()
	root.add_child(tree)
	tree.open_terminal()
	check(tree.skill_buttons.size() == 20, "Image tree missing nodes")
	tree._select_skill("power_three")
	check(tree.skill_detail.text.contains("three") and tree.unlock_button.disabled, "Selected node detail wrong")
	print("SKILL_TREE_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)

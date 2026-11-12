extends SceneTree

const Space := preload("res://scripts/boiler_space.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("TEST FAILED: " + message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func _run() -> void:
	if root.get_node_or_null("RunConfig") == null:
		var config: Node = load("res://scripts/run_config.gd").new()
		config.name = "RunConfig"
		root.add_child(config)
	var config: Node = root.get_node("RunConfig")
	check(not config.call("start_run","invalid",{}),"Invalid robot type accepted")
	var chamber: Node2D = load("res://scenes/FlyingLibertySyncChamber.tscn").instantiate()
	root.add_child(chamber)
	current_scene = chamber
	await process_frame
	chamber.get_node("Player").position = Vector2(650,630)
	chamber.get_node("Interactions/SyncPod").activate(chamber)
	var setup = chamber.get_node("RunSetup")
	check(setup.visible and not chamber.get_node("Player").controls_enabled,"Pod did not lock player/open UI")
	check(not setup.robot_choice.is_item_disabled(1) and not setup.robot_choice.is_item_disabled(2),"Robot choices locked")
	setup.overclock_checkbox.button_pressed = true
	setup.reinforcements_checkbox.button_pressed = true
	setup.fragile_checkbox.button_pressed = true
	setup.start_button.pressed.emit()
	await scene_changed
	await process_frame
	var run = current_scene
	check(run.name == "RoguelikeRun","Start did not enter run")
	check(config.max_health() == 70 and config.enemy_speed() == 130.0,"Difficulty not applied")
	check(run.health == 70 and run.living_enemies == 5,"Initial hull/reinforcements wrong")
	check(run.rooms.size() == 8 and run.rooms[7].get("boss",false),"Eight rooms/boss data missing")
	var player = run.player
	check(player.visual.hframes == 4 and player.visual.vframes == 2,"Eight-direction robot atlas missing")
	for enemy in run.enemies.get_children():
		enemy.active = false
	run.room.hazards_enabled = false
	# Real movement input and normalized diagonal speed.
	player.position = Space.project(Vector2(730,730))
	Input.action_press("move_right")
	await frames(4)
	var axial: float = player.velocity.length()
	Input.action_press("move_up")
	await frames(4)
	check(is_equal_approx(axial,player.velocity.length()),"Diagonal movement changes speed")
	Input.action_release("move_right")
	Input.action_release("move_up")
	await frames(1)
	# Confirm front/back views really differ, rather than mirroring a side pose.
	player.facing = Vector2.UP
	await frames(2)
	check(player.visual.frame == 4,"Back-facing sprite missing")
	player.facing = Vector2.DOWN
	await frames(2)
	check(player.visual.frame == 0,"Front-facing sprite missing")
	# Hit arc, cooldown, and knockback use the actual combat signal path.
	player.position = Space.project(Vector2(730,730))
	var enemy = run.enemies.get_child(0)
	enemy.position = player.position+Vector2(70,0)
	var initial: float = enemy.health
	check(player.perform_attack(Vector2.RIGHT),"First strike rejected")
	check(enemy.health < initial,"Strike failed to damage enemy in front")
	check(not player.perform_attack(Vector2.RIGHT),"Attack cooldown bypassed")
	player.attack_cooldown = 0
	var after_hit: float = enemy.health
	player.perform_attack(Vector2.LEFT)
	check(enemy.health == after_hit,"Strike hit enemy behind player")
	# Melee must not pass through solid boiler cover.
	var cover := Space.project(Vector2(260,430))
	player.position = cover-Vector2(110,0)
	enemy.position = cover+Vector2(110,0)
	await frames(2)
	run._on_attack(player.position,Vector2.RIGHT,10,300,false)
	check(enemy.health == after_hit,"Melee passed through machinery")
	# Dash cannot cross walls or furniture, and damage respects invulnerability.
	player.position = Space.project(Vector2(915,550))
	player.invulnerability = 0
	var before: float = run.health
	check(player.take_damage(10) and run.health == before-10,"Damage did not reduce hull")
	check(not player.take_damage(10),"Hurt invulnerability missing")
	player.invulnerability = 0
	player.dash_cooldown = 0
	check(player.start_dash(Space.AXIS_X.normalized()),"Dash rejected")
	check(not player.take_damage(10),"Dash invulnerability missing")
	await frames(20)
	check(Space.unproject(player.position).x < 945,"Dash escaped room wall")
	check(not player.start_dash(Vector2.LEFT),"Dash cooldown bypassed")
	player.position = Space.project(Vector2(430,430))
	await frames(1)
	player.move_and_collide(Space.AXIS_X * -230)
	check(not run.room.footprints[0].has_point(Space.unproject(player.position)),"Player crossed boiler footprint")
	# Pausing freezes the simulation and resumes through the shared HUD.
	run._toggle_pause()
	check(paused and run.hud.pause_menu.visible,"Pause did not freeze run")
	run._toggle_pause()
	check(not paused and not run.hud.pause_menu.visible,"Resume failed")
	# Clear every wave through damage/death callbacks, then collect a valid reward
	# and use the range-gated exit. No direct room loads in this progression test.
	for index in 8:
		check(run.room_index == index,"Room order skipped or repeated")
		var path: PackedVector2Array = run.room.path_between(run.room.spawn_position,run.room.exit_position)
		check(path.size() > 1,"Entrance cannot reach exit in room %d" % (index+1))
		for enemy_node in run.enemies.get_children():
			check(run.room.is_logical_free(Space.unproject(enemy_node.position),0),"Enemy spawned inside cover/wall")
			check(run.room.path_between(enemy_node.position,run.room.spawn_position).size() > 1,"Enemy cannot reach player")
		run.room.hazards_enabled = false
		if index == 7:
			var boss = run.boss
			check(is_instance_valid(boss) and boss.max_health == 1250,"Final boss missing")
			boss.take_damage(630)
			await frames(2)
			check(boss.phase_two,"Boss did not enter overpressure phase")
			boss.active = false
			boss.attack_number = 0
			boss._begin_attack()
			check(boss.attack_kind == "volley" and boss.windup > 0,"Boss volley not telegraphed")
			boss._release_attack()
			check(run.get_node("Projectiles").get_child_count() == 11,"Overpressure volley missing")
			boss._begin_attack()
			check(boss.attack_kind == "charge","Boss charge missing")
			boss._release_attack()
			check(boss.state == "charge","Charge did not start")
			boss._begin_attack()
			check(boss.attack_kind == "slam" and boss.attack_radius() == 180,"Boss slam/phase scaling missing")
		var guard := 0
		while run.state == "combat" and guard < 5:
			for foe in run.enemies.get_children():
				foe.active = false
				foe.take_damage(10000)
			await frames(3)
			guard += 1
		if index < 7:
			check(run.state == "reward" and run.hud.modal.visible,"Room clear reward missing")
			check(not run.choose_reward("invalid"),"Invalid reward accepted")
			var selected: String = run.reward_choices[0]["id"]
			check(run.choose_reward(selected),"Reward selection rejected")
			check(not run.choose_reward(selected),"Reward applied twice")
			check(not run.try_advance(),"Exit worked outside interaction range")
			run.player.position = run.room.exit_position
			check(run.try_advance(),"Cleared room exit failed")
			await frames(2)
	check(run.state == "result" and run.outcome == "BOILER DISTRICT CLEARED","Eight-room victory missing")
	check(config.victories == 1,"Victory counted incorrectly")
	check(root.get_node("CoreProgression").xp > 0,"Run did not award XP")
	check(root.get_node("CoreProgression").special_items == 2,"Chamber 4 and boss did not award special items")
	check(run.hud.modal.visible and not run.player.controls_enabled,"Victory UI/control lock missing")
	# Victory returns automatically, plays the pod exit, and restores control.
	await scene_changed
	await process_frame
	chamber = current_scene
	check(chamber.returning and not chamber.player.controls_enabled,"Victory return cinematic missing")
	check(not config.active and not config.sync_return_pending,"Return state was not consumed")
	await create_timer(3.5).timeout
	check(not chamber.returning and chamber.player.controls_enabled,"Cinematic did not restore controls")
	check(chamber.player.position.distance_to(Vector2(648,625)) < 2,"Character did not exit machine")
	chamber.open_run_setup()
	chamber._on_start_requested(config.modifiers.duplicate())
	await scene_changed
	await process_frame
	run = current_scene
	check(run.room_index == 0 and run.health == 70 and run.player.damage_multiplier == 1.0,"Retry retained run upgrades")
	run.player.invulnerability = 0
	run.player.take_damage(1000)
	check(run.outcome == "FRAME LOST" and run.hud.modal.visible,"Death result missing")
	await scene_changed
	await process_frame
	check(current_scene.name == "FlyingLibertySyncChamber" and not config.active,"Return to Sync Chamber failed")
	check(current_scene.returning and not current_scene.player.controls_enabled,"Death return cinematic missing")
	await create_timer(3.5).timeout
	check(current_scene.player.controls_enabled,"Death return left controls locked")
	change_scene_to_file("res://scenes/FlyingLibertySyncChamber.tscn")
	await scene_changed
	check(not current_scene.returning,"Ordinary room entry replayed return cinematic")
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/RoguelikeRun.tscn","Game does not start in roguelite")
	print("BOILER_RUN_CHECKS=",checks," FAILURES=",failures)
	if failures == 0:
		print("RUN_SETUP_TESTS_PASSED")
	quit(1 if failures else 0)

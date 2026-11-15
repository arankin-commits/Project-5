extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func frames(count := 2) -> void:
	for i in count:
		await physics_frame
		await process_frame

func _run() -> void:
	var config := root.get_node("RunConfig")
	change_scene_to_file("res://scenes/FlyingLibertySyncChamber.tscn")
	await scene_changed
	var setup = current_scene.run_setup
	check(setup.route_choice.item_count == 2,"Route selection must still offer two routes")
	setup.route_choice.select(1)
	setup._update_route(1)
	setup._on_start_pressed()
	await scene_changed
	var run = current_scene
	var victories_before: int = config.victories
	var ids := {}
	var biomes := ["maintenance","factory","boiler","toxin_refinery"]
	for biome in biomes:
		check(config.biome == biome,"Incorrect biome order at "+biome)
		for index in 9:
			check(run.room_index == index,"Wrong chamber index")
			check(not ids.has(run.rooms[index].id),"Room repeated across full run")
			ids[run.rooms[index].id] = true
			check(bool(run.rooms[index].get("boss",false)) == (index == 8),"Boss not ninth")
			run.room.hazards_enabled = false
			run.player.invulnerability = 9999
			for enemy in run.enemies.get_children():
				enemy.active = false
			if index == 0:
				var start: Vector2 = run.player.position
				Input.action_press("move_right")
				await frames(3)
				Input.action_release("move_right")
				check(run.player.position.distance_to(start) > 1,"Player cannot move in "+biome)
				run.player.position = start
			for point in run.room.exit_positions:
				run.player.position = point
				check(not run.try_advance(),"Combat exit unlocked")
			var guard := 0
			while run.state == "combat" and guard < 8:
				for enemy in run.enemies.get_children():
					enemy.active = false
					enemy.take_damage(10000)
				await frames()
				guard += 1
			check(run.state == "reward","Room did not clear")
			check(not run.try_advance(),"Exit unlocked before reward")
			var reward: String = run.rooms[index].reward
			check(run.reward_choices.size() == 1 and run.reward_choices[0].id == reward,"Reward differs from door preview")
			var speed_before: float = run.player.speed
			var kills_before: int = run.kills
			check(run.choose_reward(reward),"Could not claim room reward")
			if index < 8:
				var door: int = index % run.room.exit_positions.size()
				var expected: String = run.rooms[index].exit_rewards[door]
				run.player.position = run.room.exit_positions[door]
				check(run.try_advance(),"Cleared exit failed")
				check(run.rooms[index+1].reward == expected,"Selected door reward not carried into next room")
			elif biome != "toxin_refinery":
				check(config.biome == biomes[biomes.find(biome)+1],"Boss did not advance biome")
				check(run.room_index == 0 and run.state == "combat","Next biome did not start")
				check(run.player.speed == speed_before and run.kills == kills_before,"Run progress reset across biome transition")
		print("BIOME_RUN_CLEARED=",biome)
	check(ids.size() == 36,"Full route must contain 36 unique rooms")
	check(run.outcome == "UNDERGROUND ROUTE CLEARED","Final refinery boss did not finish route")
	check(config.victories == victories_before+1,"Route victory not recorded exactly once")
	await scene_changed
	check(current_scene.name == "FlyingLibertySyncChamber","Completed route did not return to ship")
	print("UNDERGROUND_ROUTE_CHECKS=",checks," FAILURES=",failures)
	quit(1 if failures else 0)

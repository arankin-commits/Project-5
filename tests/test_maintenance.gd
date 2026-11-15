extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func frames(count := 3) -> void:
	for i in count:
		await physics_frame
		await process_frame

func _run() -> void:
	var config := root.get_node("RunConfig")
	change_scene_to_file("res://scenes/FlyingLibertySyncChamber.tscn")
	await scene_changed
	var setup = current_scene.run_setup
	check(setup.route_choice.item_count == 2, "Dropdown must offer exactly two routes")
	check(not setup.route_choice.get_item_text(0).contains("Storage") and not setup.route_choice.get_item_text(1).contains("Maintenance"), "Dropdown exposed biome order")
	setup.route_choice.select(0)
	setup._update_route(0)
	check(setup.start_button.disabled, "Unimplemented above-ground route can start")
	check(not config.start_run("medium",{},"above_ground"), "RunConfig accepted missing Storage")
	setup._on_start_pressed()
	check(current_scene.name == "FlyingLibertySyncChamber", "Unavailable route left ship")
	setup.route_choice.select(1)
	setup._update_route(1)
	check(not setup.start_button.disabled, "Below-ground route is disabled")
	check(not setup.route_note.text.contains("Factory"), "Route note exposed ordered biomes")
	setup._on_start_pressed()
	await scene_changed
	await frames()
	var run = current_scene
	check(config.biome == "maintenance", "Setup did not select Maintenance")
	check(run.rooms.size() == 9, "Eight regular rooms plus boss required")
	check(config.next_biome() == "factory", "Maintenance must lead to Factory, not Boiler")
	check(run.room.spawn_position.x < 768, "First entrance must be bottom left")
	var start: Vector2 = run.player.position
	Input.action_press("move_right")
	await frames(10)
	Input.action_release("move_right")
	check(run.player.position.distance_to(start) > 10, "Movement input did not move the player")
	run.player.position = run.room.spawn_position
	# Collision is exercised with the real character body, not just navigation.
	for polygon in run.room.obstacle_polygons:
		var center := Vector2.ZERO
		for point in polygon:
			center += point
		center /= polygon.size()
		var top: float = center.y
		for point in polygon:
			top = minf(top,point.y)
		run.player.position = Vector2(center.x,top-50)
		await frames(1)
		run.player.move_and_collide(center-run.player.position)
		check(not Geometry2D.is_point_in_polygon(run.player.position,polygon), "Player crossed machinery collision")
	run.player.position = run.room.spawn_position
	var initial_health: float = run.health
	for foe in run.enemies.get_children():
		foe.active = false
	var enemy = run.enemies.get_child(0)
	var enemy_health: float = enemy.health
	run.player.position = run.room.vents[0]
	run.player.invulnerability = 0
	enemy.position = run.room.vents[0]
	run.room.elapsed = 4.0
	run.room.hazard_tick = 0
	run.room._physics_process(0.01)
	check(run.health == initial_health-8, "Electrical hazard did not damage player")
	check(enemy.health == enemy_health-32, "Electrical hazard did not damage enemy more")
	run.player.position = run.room.spawn_position
	for index in 9:
		check(bool(run.rooms[index].get("boss",false)) == (index == 8), "Boss must appear only in room nine")
		if index == 8:
			check(is_instance_valid(run.boss), "Ninth-room boss did not spawn")
		check(run.room_index == index, "Room progression failed")
		check(run.room.get_node("MaintenanceArtwork").texture != null, "Missing room art")
		check(run.room.is_logical_free(run.Space.unproject(run.room.spawn_position),0), "Entry outside floor")
		check(run.room.is_logical_free(run.Space.unproject(run.room.exit_position),0), "Exit outside floor")
		check(run.room.path_between(run.room.spawn_position,run.room.exit_position).size() > 1, "Exit unreachable")
		for foe in run.enemies.get_children():
			check(run.room.is_logical_free(run.Space.unproject(foe.position),0), "Enemy outside floor")
			check(run.room.path_between(foe.position,run.room.spawn_position).size() > 1, "Enemy cannot reach entry")
		check(not run.try_advance(), "Combat exit was not locked")
		run.room.hazards_enabled = false
		var guard := 0
		while run.state == "combat" and guard < 5:
			for foe in run.enemies.get_children():
				foe.active = false
				foe.take_damage(10000)
			await frames()
			guard += 1
		check(run.state == "reward", "Reward missing after waves")
		check(not run.room.exit_enabled and not run.try_advance(), "Exit unlocked before claiming reward")
		check(run.reward_choices.size() == 1 and run.reward_choices[0].id == run.rooms[index].reward, "Reward does not match preview")
		check(run.choose_reward(run.rooms[index].reward), "Reward could not be claimed")
		if index < 8:
			run.player.position = run.room.exit_positions[-1]
			check(run.try_advance(), "Cleared exit failed")
			await frames()
	check(run.outcome == "MAINTENANCE CLEARED", "Maintenance completion missing")
	check(config.biome == "maintenance" and config.victories == 0, "Missing Factory was skipped or route was marked complete")
	check(run.hud.modal_description.text.contains("Factory is not yet available"), "Missing Factory message absent")
	await scene_changed
	check(current_scene.name == "FlyingLibertySyncChamber", "Maintenance did not return to ship")
	print("MAINTENANCE_CHECKS=",checks," FAILURES=",failures)
	quit(1 if failures else 0)

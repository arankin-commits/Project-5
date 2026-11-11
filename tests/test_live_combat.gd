extends SceneTree

# Drives normal movement and attack controls against live, unmodified enemies.
# This is a first-encounter smoke test, not a difficulty/balance certification.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var config: Node = load("res://scripts/run_config.gd").new()
	config.name = "RunConfig"
	root.add_child(config)
	config.call("start_run","medium",{})
	config.set("run_seed",38417)
	var run = load("res://scenes/RoguelikeRun.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	await process_frame
	var player = run.player
	var ticks := 0
	while run.state == "combat" and ticks < 3000:
		var closest: CharacterBody2D
		var distance := INF
		for enemy in run.enemies.get_children():
			var d: float = player.position.distance_to(enemy.position)
			if enemy.health > 0 and d < distance:
				closest = enemy
				distance = d
		if closest == null:
			await physics_frame
			continue
		var aim: Vector2 = player.position.direction_to(closest.position)
		var movement := Vector2.ZERO
		if distance > 105:
			var path: PackedVector2Array = run.room.path_between(player.position,closest.position)
			if path.size() > 1:
				movement = player.position.direction_to(path[1])
			else:
				movement = aim
		else:
			player.perform_attack(aim,true)
			player.perform_attack(aim)
		if closest.state == "windup" and distance < 110:
			player.start_dash(-aim)
		for action in ["move_left","move_right","move_up","move_down"]:
			Input.action_release(action)
		if movement.x < 0:
			Input.action_press("move_left",-movement.x)
		else:
			Input.action_press("move_right",movement.x)
		if movement.y < 0:
			Input.action_press("move_up",-movement.y)
		else:
			Input.action_press("move_down",movement.y)
		await physics_frame
		ticks += 1
	for action in ["move_left","move_right","move_up","move_down"]:
		Input.action_release(action)
	print("LIVE_COMBAT state=",run.state," kills=",run.kills," hull=",run.health," physics_ticks=",ticks)
	var passed: bool = run.state == "reward" and run.kills == 3 and run.health > 0
	print("LIVE_COMBAT_PASSED" if passed else "LIVE_COMBAT_FAILED")
	# Let the final hit tweens/audio finish before releasing the test scene.
	await create_timer(0.7).timeout
	run.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	quit(0 if passed else 1)

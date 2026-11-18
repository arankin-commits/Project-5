extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var progression = root.get_node("CoreProgression")
	var saved_skills: Array[String] = progression.unlocked_skills.duplicate()
	progression.unlocked_skills.clear()
	progression.unlocked_skills.append("root")
	var config = root.get_node("RunConfig")
	var expected := {"heavy": [185.5, 75, 1.3, 2.0], "light": [331.25, 30, 0.7, 6.0], "medium": [265.0, 50, 1.0, 2.0]}
	for kind in expected:
		config.start_run(kind, {})
		config.biome = "boiler"
		var run = load("res://scenes/RoguelikeRun.tscn").instantiate()
		root.add_child(run)
		current_scene = run
		var stats: Array = expected[kind]
		check(is_equal_approx(run.player.speed, stats[0]), kind + " speed")
		check(run.health == stats[1], kind + " health")
		check(is_equal_approx(run.player.damage_multiplier, stats[2]), kind + " damage")
		check(run.player.backstab_multiplier == stats[3], kind + " backstab")
		run.room.hazards_enabled = false
		run.state = "combat"
		var enemy = run.enemies.get_child(0)
		enemy.collision_mask = 0
		for foe in run.enemies.get_children():
			if foe != enemy:
				foe.queue_free()
			else:
				foe.active = false
		await process_frame
		run.player.position = run.room.spawn_position
		for rear in [false, true]:
			for heavy in [false, true]:
				enemy.position = run.player.position + Vector2(70,0)
				enemy.facing = Vector2.RIGHT if rear else Vector2.LEFT
				enemy.health = 1000
				run.player.combo = 0
				run.player.attack_cooldown = 0
				run.player.special_cooldown = 0
				run.player.perform_attack(Vector2.RIGHT, heavy)
				var damage: float = (55.0 if heavy else 24.0) * stats[2] * (stats[3] if rear else 1.0)
				check(is_equal_approx(1000 - enemy.health, damage), kind + " actual hit damage")
		check(not enemy.is_backstab(enemy.position + Vector2(0,70)), "Side hit counted as backstab")
		config.start_run(kind, {"fragile_frame": true})
		check(config.max_health() == stats[1] - 30, kind + " fragile frame")
		run.queue_free()
		await process_frame
		current_scene = null
	progression.unlocked_skills.clear()
	progression.unlocked_skills.append_array(saved_skills)
	print("ROBOT_STATS_FAILURES=", failures)
	quit(1 if failures else 0)

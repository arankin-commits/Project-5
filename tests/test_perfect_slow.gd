extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var run = load("res://scenes/RoguelikeRun.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	run.player.configure_skills([])
	run.room.hazards_enabled = false
	for enemy in run.enemies.get_children():
		enemy.active = false
	await process_frame
	await process_frame
	# Let initial resource loading settle before measuring subsecond timers.
	await create_timer(0.5,true,false,true).timeout
	run.player.start_dash(Vector2.RIGHT)
	run.player.take_damage(10)
	check(run.player.perfect_reward_timer == 5.0, "Base-kit perfect dodge did not grant XP bonus")
	check(run.player.perfect_damage_timer == 0 and run.player.combat_damage_multiplier() == run.player.damage_multiplier, "Base-kit dodge granted locked damage bonus")
	var progress = root.get_node("CoreProgression")
	var xp: int = progress.xp
	var gears: int = progress.special_items
	run._award_progress(10,1)
	check(progress.xp == xp+20 and progress.special_items == gears+1, "Base-kit rewards must double XP only")
	check(is_equal_approx(Engine.time_scale, 0.25), "Perfect dash did not slow gameplay")
	check(run.hud.perfect_dash_indicator.visible, "Perfect dash indicator missing")
	await create_timer(0.15,true,false,true).timeout
	check(run.perfect_slow_active, "Slowdown ended early")
	run.player.dash_cooldown = 0
	run.player.start_dash(Vector2.LEFT)
	run.player.take_damage(10)
	await create_timer(0.2,true,false,true).timeout
	check(run.perfect_slow_active, "Previous timer cut off refreshed slowdown")
	await create_timer(0.15,true,false,true).timeout
	check(is_equal_approx(Engine.time_scale,1.0) and not run.hud.perfect_dash_indicator.visible, "Slowdown did not end after 0.3 real seconds")
	check(run.player.perfect_reward_timer > 4, "Slowdown broke reward buff")
	run._on_perfect_dodge()
	run._toggle_pause()
	await create_timer(0.35,true,false,true).timeout
	check(paused and is_equal_approx(Engine.time_scale,1.0), "Pause left global slowdown stuck")
	run._toggle_pause()
	run._on_perfect_dodge()
	run.return_to_sync_chamber()
	await scene_changed
	check(is_equal_approx(Engine.time_scale,1.0), "Slowdown leaked into the ship")
	print("PERFECT_SLOW_FAILURES=", failures)
	quit(1 if failures else 0)

extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	if root.get_node_or_null("RunConfig") == null:
		var config: Node = load("res://scripts/run_config.gd").new()
		config.name = "RunConfig"
		root.add_child(config)
	root.get_node("RunConfig").call("start_run", "medium", {})
	root.get_node("RunConfig").set("run_seed", 38417)
	var run: Node2D = load("res://scenes/RoguelikeRun.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reviews"))
	for i in 8:
		if i > 0:
			run.call("_load_room",i)
		for enemy in run.enemies.get_children():
			enemy.set("active",false)
		run.player.position = Vector2(768,745)
		run.player.set("facing",Vector2(-1,-0.5))
		run.player.set("invulnerability",0.0)
		var camera: Camera2D = run.get_node("Camera2D")
		camera.position = Vector2(768,545)
		camera.reset_smoothing()
		camera.force_update_scroll()
		await physics_frame
		await process_frame
		await process_frame
		print("ROOM_",i+1,"_SCREENSHOT=",root.get_texture().get_image().save_png("res://reviews/boiler_room_%02d.png" % (i+1)))
	run.boss.state = "windup"
	run.boss.attack_kind = "slam"
	run.boss.attack_point = run.player.position
	run.boss.windup = 0.5
	run.boss.queue_redraw()
	await process_frame
	await process_frame
	print("BOSS_TELEGRAPH=",root.get_texture().get_image().save_png("res://reviews/boiler_boss_telegraph.png"))
	run.player.perform_attack(Vector2(-1,-0.5).normalized())
	await process_frame
	await process_frame
	print("ROBOT_STRIKE=",root.get_texture().get_image().save_png("res://reviews/boiler_robot_strike.png"))
	run.call("_load_room",0)
	for enemy in run.enemies.get_children():
		enemy.call("take_damage",10000)
	await process_frame
	await process_frame
	await process_frame
	print("REWARD_SCREENSHOT=",root.get_texture().get_image().save_png("res://reviews/boiler_rewards.png"))
	await create_timer(0.7).timeout
	run.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	quit()

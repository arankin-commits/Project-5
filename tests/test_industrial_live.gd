extends SceneTree

const ENEMY := preload("res://scripts/industrial_enemy.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var config := root.get_node("RunConfig")
	config.start_run("medium",{})
	config.run_seed = 38417
	change_scene_to_file("res://scenes/RoguelikeRun.tscn")
	await scene_changed
	var run = current_scene
	run.room.hazards_enabled = false
	run.maximum_health = 10000
	run.health = 10000
	var first = run.enemies.get_child(0)
	var path: PackedVector2Array = run.room.path_between(run.player.position,first.position)
	if path.size() > 2:
		run.player.position = path[maxi(0,path.size()-3)]
	var attacks := 0
	for i in 360:
		if i == 100:
			run.player.start_dash(Vector2.RIGHT)
		if i == 180:
			run.player.perform_attack(run.player.position.direction_to(first.position),true)
		await physics_frame
		for enemy in run.enemies.get_children():
			if enemy is ENEMY:
				attacks = maxi(attacks,enemy.attack_generation)
	await process_frame
	if DisplayServer.get_name() != "headless":
		print("LIVE_CAPTURE=",root.get_texture().get_image().save_png("res://reviews/industrial_live_combat.png"))
	print("INDUSTRIAL_LIVE attacks=",attacks," damage_received=",10000-run.health," state=",run.state)
	var passed: bool = attacks > 0 and run.health < 10000 and run.health > 0
	print("INDUSTRIAL_LIVE_PASSED=",passed)
	quit(0 if passed else 1)

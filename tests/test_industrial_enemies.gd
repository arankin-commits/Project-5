extends SceneTree

const ENEMY := preload("res://scripts/industrial_enemy.gd")
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
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies/industrial.json"))
	var config := root.get_node("RunConfig")
	check(catalog.size() == 33,"Expected all 33 designs")
	var seen := {}
	for biome in ["maintenance","factory","boiler","toxin_refinery"]:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(config.BIOME_DATA[biome]))
		for room in data.rooms:
			for wave in room.waves:
				for key in wave:
					check(catalog.has(key) and catalog[key].biome_key == biome,"Wrong enemy in "+biome)
					seen[key] = true
	check(seen.size() == 33,"Some enemies cannot spawn")
	config.start_run("medium",{})
	change_scene_to_file("res://scenes/RoguelikeRun.tscn")
	await scene_changed
	var run = current_scene
	run.room.hazards_enabled = false
	for existing in run.enemies.get_children():
		existing.queue_free()
	await process_frame
	for key in catalog:
		var enemy := ENEMY.new()
		enemy.design = catalog[key]
		enemy.target = run.player
		enemy.room = run.room
		enemy.position = run.room.spawn_position
		run.enemies.add_child(enemy)
		check(enemy.health == float(catalog[key].hp),"Wrong health: "+key)
		check(is_equal_approx(enemy.speed,float(catalog[key].speed)*26),"Wrong speed: "+key)
		check(enemy.visual.texture != null and enemy.visual.texture.get_size() == Vector2(1024,2048),"Invalid animation atlas: "+key)
		var directions := {}
		for angle in 8:
			enemy.facing = Vector2.from_angle(angle*TAU/8)
			enemy._update_animation(0.1)
			directions[enemy.visual.frame%8] = true
		check(directions.size() == 8,"Directional frame selection failed: "+key)
		enemy.velocity = Vector2(40,0)
		enemy._update_animation(0.15)
		check(enemy.animation_name == "walk","Walking pose missing: "+key)
		enemy._begin_attack()
		enemy._update_animation(0.1)
		check(enemy.animation_name == "windup","Windup pose missing: "+key)
		run.player.position = enemy.position+Vector2(1000,1000)
		enemy._release_attack()
		enemy._update_animation(0.05)
		check(enemy.animation_name == "attack","Attack pose missing: "+key)
		if enemy.design.role == "Projectile":
			check(enemy.attack_kind == "lob","Mortar did not use its authored lob")
		if enemy.design.role == "Charging":
			check(enemy.state == "charge","Charging role did not charge")
		var defeats := [0]
		enemy.defeated.connect(func(_dead): defeats[0] += 1)
		enemy.take_damage(10000)
		enemy.take_damage(10000)
		enemy._update_animation(0.1)
		check(defeats[0] == 1,"Death counted more than once: "+key)
		check(enemy.animation_name == "death" and enemy.collision_layer == 0 and enemy.collision_mask == 0,"Corpse remains interactive: "+key)
		enemy._update_animation(1.0)
		await process_frame
		check(not is_instance_valid(enemy),"Corpse was not removed: "+key)
	print("INDUSTRIAL_ENEMY_CHECKS=",checks," FAILURES=",failures)
	quit(1 if failures else 0)

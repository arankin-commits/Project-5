extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var config := root.get_node("RunConfig")
	config.start_run("medium",{})
	config.run_seed = 38417
	change_scene_to_file("res://scenes/RoguelikeRun.tscn")
	await scene_changed
	var run = current_scene
	for biome in ["maintenance","factory","boiler","toxin_refinery"]:
		if OS.get_cmdline_user_args().has("--biome=" + biome) == false and OS.get_cmdline_user_args().has("--all") == false:
			continue
		config.biome = biome
		run._prepare_biome()
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(config.BIOME_DATA[biome]))
		for index in [0,6,20]:
			var definition: Dictionary = data.rooms[index].duplicate(true)
			definition.exit_rewards = ["repair","hull","power"]
			definition.next_preview = "NEXT CHAMBER"
			definition.room_count = 9
			run.rooms[0] = definition
			run._load_room(0)
			run.room.hazards_enabled = true
			run.room.elapsed = 4.0
			run.room.set_physics_process(false)
			for enemy in run.enemies.get_children():
				enemy.active = false
			var camera: Camera2D = run.get_node("Camera2D")
			camera.position = run.room.camera_target(run.player.position)
			camera.reset_smoothing()
			camera.force_update_scroll()
			await process_frame
			await process_frame
			print("BIOME_CAPTURE=",biome," ",index," RESULT=",root.get_texture().get_image().save_png("res://reviews/painted_%s_%02d.png" % [biome,index]))
			if index == 0:
				# A separate whole-room view makes comparison with the references useful.
				var previous_zoom := camera.zoom
				run.set_process(false)
				camera.position = run.room.world_bounds.get_center() - Vector2(0, 65)
				camera.zoom = Vector2.ONE * minf(1120.0 / (run.room.world_bounds.size.x + 180), 560.0 / (run.room.world_bounds.size.y + 230))
				camera.reset_smoothing()
				camera.force_update_scroll()
				run.hud.hide()
				await process_frame
				await process_frame
				print("OVERVIEW_CAPTURE=", biome, " RESULT=", root.get_texture().get_image().save_png("res://reviews/painted_%s_overview.png" % biome))
				run.hud.show()
				camera.zoom = previous_zoom
				run.set_process(true)
	current_scene.queue_free()
	await process_frame
	if OS.get_cmdline_user_args().has("--enemy-gallery"):
		await _capture_enemies()
	quit()


func _capture_enemies() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies/industrial.json"))
	for biome in ["maintenance","factory","boiler","toxin_refinery"]:
		var gallery := Node2D.new()
		root.add_child(gallery)
		var title := Label.new()
		title.text = biome.replace("_"," ").to_upper()+" - ENEMY ART / ANIMATION CHECK"
		title.position = Vector2(30,20)
		title.add_theme_font_size_override("font_size",24)
		gallery.add_child(title)
		var roster: Array = []
		for key in catalog:
			if catalog[key].biome_key != biome:
				continue
			var enemy = load("res://scripts/industrial_enemy.gd").new()
			enemy.design = catalog[key]
			enemy.position = Vector2(210+(roster.size()%3)*420,210+(roster.size()/3)*200)
			gallery.add_child(enemy)
			roster.append(enemy)
			var label := Label.new()
			label.text = "%s\n%s | %s HP" % [enemy.design.name,enemy.design.role,enemy.design.hp]
			label.position = enemy.position+Vector2(-180,25)
			label.size.x = 360
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			gallery.add_child(label)
		for phase in ["walk","windup","attack","death"]:
			for enemy in roster:
				enemy.facing = Vector2(1,0.5).normalized()
				enemy.velocity = Vector2(60,30) if phase == "walk" else Vector2.ZERO
				enemy.state = "windup" if phase == "windup" else ("ability" if phase == "attack" else "chase")
				enemy.attack_point = enemy.position+Vector2(40,10)
				enemy.release_timer = 1.0 if phase == "attack" else 0.0
				if phase == "death":
					enemy.take_damage(10000)
			await create_timer(0.22).timeout
			await process_frame
			await process_frame
			print("ENEMY_CAPTURE=",biome," ",phase," RESULT=",root.get_texture().get_image().save_png("res://reviews/polish_enemies_%s_%s.png" % [biome,phase]))
		gallery.queue_free()
		await process_frame


extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var config := root.get_node("RunConfig")
	change_scene_to_file("res://scenes/FlyingLibertySyncChamber.tscn")
	await scene_changed
	current_scene.open_run_setup()
	var setup = current_scene.run_setup
	for selection in [0,1]:
		setup.route_choice.select(selection)
		setup._update_route(selection)
		await process_frame
		await process_frame
		print("ROUTE_CAPTURE=",root.get_texture().get_image().save_png("res://reviews/route_selection_%d.png" % selection))
	config.start_run("medium",{})
	config.run_seed = 38417
	change_scene_to_file("res://scenes/RoguelikeRun.tscn")
	await scene_changed
	var run = current_scene
	for i in [0,7,8]:
		run._load_room(i)
		for enemy in run.enemies.get_children():
			enemy.active = false
		run.room.hazards_enabled = false
		await process_frame
		await process_frame
		await create_timer(0.2).timeout
		print("CAPTURE=",root.get_texture().get_image().save_png("res://reviews/maintenance_%d.png" % i))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/maintenance/rooms.json"))
	run.rooms = data.rooms.duplicate(true)
	for i in run.rooms.size():
		run._load_room(i)
		for enemy in run.enemies.get_children():
			enemy.active = false
		run.room.hazards_enabled = false
		var camera: Camera2D = run.get_node("Camera2D")
		camera.position = run.room.camera_target(run.player.position)
		camera.reset_smoothing()
		camera.force_update_scroll()
		await process_frame
		await process_frame
		print("LAYOUT_CAPTURE=",root.get_texture().get_image().save_png("res://reviews/maintenance_layout_%02d.png" % i))
		# Full-room review image; keep the actual gameplay zoom unchanged.
		run.set_process(false)
		run.hud.hide()
		var normal_zoom := camera.zoom
		var art_size: Vector2 = run.room.layout.crop.size * float(run.room.layout.scale)
		camera.zoom = Vector2.ONE * minf(1150.0/art_size.x,600.0/art_size.y)
		camera.position = Vector2(768,620)
		camera.reset_smoothing()
		camera.force_update_scroll()
		await process_frame
		await process_frame
		print("OVERVIEW_CAPTURE=",root.get_texture().get_image().save_png("res://reviews/painted_overview_%02d.png" % i))
		camera.zoom = normal_zoom
		run.hud.show()
		run.set_process(true)
	quit()

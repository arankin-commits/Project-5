extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var config := root.get_node("RunConfig")
	config.start_run("medium",{})
	config.run_seed = 38417
	change_scene_to_file("res://scenes/RoguelikeRun.tscn")
	await scene_changed
	var run = current_scene
	run.set_process(false)
	run.hud.hide()
	run.player.hide()
	run.enemies.hide()
	run.get_node("Effects").hide()
	var camera: Camera2D = run.get_node("Camera2D")
	for biome in ["maintenance","boiler"]:
		config.biome = biome
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/%s/rooms.json" % biome))
		run.rooms = data.rooms.duplicate(true)
		run._load_room(3 if biome == "maintenance" else 0)
		run.room.hazards_enabled = false
		for enemy in run.enemies.get_children():
			enemy.active = false
		var background: CanvasItem = run.room.get_node("MaintenanceArtwork" if biome == "maintenance" else "PaintedBoilerShell")
		for child in run.room.get_children():
			if child is CanvasItem and child != background:
				child.hide()
		var material := background.material
		camera.position = Vector2(768,620)
		for zoom_value in [0.4,0.82,1.5]:
			camera.zoom = Vector2.ONE*zoom_value
			camera.reset_smoothing()
			camera.force_update_scroll()
			var samples: Array[Image] = []
			for sharp in [false,true]:
				background.material = material if sharp else null
				await process_frame
				await process_frame
				var screenshot := root.get_texture().get_image()
				samples.append(screenshot)
				screenshot.save_png("res://reviews/sampling_%s_%s_%s.png" % [biome,str(zoom_value),"sharp" if sharp else "linear"])
			var changed := 0
			for y in range(0,samples[0].get_height(),4):
				for x in range(0,samples[0].get_width(),4):
					if samples[0].get_pixel(x,y) != samples[1].get_pixel(x,y):
						changed += 1
			var enlarged: bool = biome == "maintenance" or zoom_value > 1.0
			if (enlarged and changed == 0) or (not enlarged and changed != 0):
				failures += 1
				push_error("Map sampling did not respect enlargement: %s %s" % [biome,zoom_value])
			print("MAP_SAMPLING ",biome," ZOOM=",zoom_value," CHANGED_PIXELS=",changed)
	print("MAP_SAMPLING_FAILURES=",failures)
	quit(1 if failures else 0)

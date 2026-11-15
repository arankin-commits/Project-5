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
			run.room.hazards_enabled = false
			for enemy in run.enemies.get_children():
				enemy.active = false
			var camera: Camera2D = run.get_node("Camera2D")
			camera.position = run.room.camera_target(run.player.position)
			camera.reset_smoothing()
			camera.force_update_scroll()
			await process_frame
			await process_frame
			print("BIOME_CAPTURE=",biome," ",index," RESULT=",root.get_texture().get_image().save_png("res://reviews/%s_blockout_%02d.png" % [biome,index]))
	quit()

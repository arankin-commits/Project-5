extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for room_name in ["MainHall","SyncChamber","Workshop","Cockpit"]:
		change_scene_to_file("res://scenes/FlyingLiberty%s.tscn" % room_name)
		await scene_changed
		var room = current_scene
		var camera: Camera2D = room.player.get_node("Camera2D")
		camera.top_level = true
		camera.global_position = Vector2(820,480) if room_name != "MainHall" else Vector2(815,450)
		camera.zoom = Vector2(0.78,0.78)
		camera.reset_smoothing()
		camera.force_update_scroll()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reviews/npcs_" + room_name + ".png")
		for id in room.npc_controller.actors:
			room.npc_controller.dialogue.open(id, room.player)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://reviews/dialogue_" + id + ".png")
			room.npc_controller.dialogue.close()
	print("NPC_CAPTURES_COMPLETE")
	quit()

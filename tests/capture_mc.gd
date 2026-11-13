extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	change_scene_to_file("res://scenes/FlyingLibertyMainHall.tscn")
	await scene_changed
	var player = current_scene.player
	player.position = Vector2(850,500)
	player.set_physics_process(false)
	player.get_node("Camera2D").reset_smoothing()
	player.get_node("Camera2D").force_update_scroll()
	for animation in ["idle","walk"]:
		player.visual.play(animation)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reviews/mc_" + animation + ".png")
	print("MC_CAPTURES_COMPLETE")
	quit()

extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene: Node2D = load("res://scenes/FlyingLibertyCockpit.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reviews"))
	var game_image := root.get_texture().get_image()
	print("GAME_SCREENSHOT=", game_image.save_png("res://reviews/cockpit_playable.png"))
	var pilot = scene.get_node("PlayerAndNPCs/PilotNPC")
	scene.get_node("PlayerAndNPCs/Player").position = pilot.position + Vector2(0, 135)
	scene.get_node("PlayerAndNPCs/Player/Camera2D").reset_smoothing()
	scene.get_node("PlayerAndNPCs/Player/Camera2D").force_update_scroll()
	await process_frame
	await process_frame
	print("PILOT_SCREENSHOT=", root.get_texture().get_image().save_png("res://reviews/cockpit_pilot.png"))
	# Use a separate native-size viewport so the game's window stretch cannot scale the art.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1672, 941)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.world_2d = World2D.new()
	root.add_child(viewport)
	var art_scene: Node2D = load("res://scenes/FlyingLibertyCockpit.tscn").instantiate()
	viewport.add_child(art_scene)
	art_scene.get_node("PlayerAndNPCs/Player").hide()
	art_scene.get_node("PlayerAndNPCs/PilotNPC").hide()
	art_scene.get_node("InteractionUI").hide()
	art_scene.get_node("PlayerAndNPCs/Player/Camera2D").enabled = false
	await process_frame
	await process_frame
	var art_image := viewport.get_texture().get_image()
	print("ART_SCREENSHOT=", art_image.save_png("res://reviews/cockpit_art_assembly.png"))
	quit()

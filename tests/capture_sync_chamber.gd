extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var chamber: Node2D = load("res://scenes/FlyingLibertySyncChamber.tscn").instantiate()
	root.add_child(chamber)
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reviews"))
	print("SYNC_CHAMBER_SCREENSHOT=", root.get_texture().get_image().save_png("res://reviews/sync_chamber_playable.png"))
	chamber.get_node("Player").position = Vector2(650, 630)
	chamber.get_node("Interactions/SyncPod").activate(chamber)
	await process_frame
	await process_frame
	print("RUN_SETUP_SCREENSHOT=", root.get_texture().get_image().save_png("res://reviews/sync_pod_run_setup.png"))
	quit()

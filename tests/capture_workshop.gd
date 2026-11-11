extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var workshop: Node2D = load("res://scenes/FlyingLibertyWorkshop.tscn").instantiate()
	root.add_child(workshop)
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reviews"))
	print("WORKSHOP_SCREENSHOT=", root.get_texture().get_image().save_png("res://reviews/workshop_playable.png"))
	quit()

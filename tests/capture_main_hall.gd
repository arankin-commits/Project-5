extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var hall: Node2D = load("res://scenes/FlyingLibertyMainHall.tscn").instantiate()
	root.add_child(hall)
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reviews"))
	print("MAIN_HALL_SCREENSHOT=", root.get_texture().get_image().save_png("res://reviews/main_hall_cockpit_door.png"))
	quit()

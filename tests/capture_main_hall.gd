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
	var player: CharacterBody2D = hall.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	player.position = Vector2(170, 550)
	camera.reset_smoothing()
	camera.force_update_scroll()
	await process_frame
	await process_frame
	print("WORKSHOP_DOOR_SCREENSHOT=", root.get_texture().get_image().save_png("res://reviews/main_hall_workshop_door.png"))
	player.position = Vector2(2040, 365)
	camera.reset_smoothing()
	camera.force_update_scroll()
	await process_frame
	await process_frame
	print("BEDROOM_PROMPT=", hall.prompt.text)
	print("BEDROOM_WING_SCREENSHOT=", root.get_texture().get_image().save_png("res://reviews/main_hall_bedroom_wing.png"))
	player.position = Vector2(2820, 365)
	camera.reset_smoothing()
	camera.force_update_scroll()
	await process_frame
	await process_frame
	print("BEDROOM_WING_END_SCREENSHOT=", root.get_texture().get_image().save_png("res://reviews/main_hall_bedroom_wing_end.png"))
	quit()

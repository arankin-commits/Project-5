extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var hall: Node2D = load("res://scenes/FlyingLibertyMainHall.tscn").instantiate()
	root.add_child(hall)
	await process_frame
	await process_frame

	var player: CharacterBody2D = hall.get_node("Player")
	var camera: Camera2D = player.get_node("Camera2D")
	player.position = Vector2(680, 315)
	camera.reset_smoothing()
	camera.force_update_scroll()
	hall._process(0.016)
	await process_frame
	await process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reviews"))
	print("JUKEBOX_PROMPT_SCREENSHOT=", root.get_texture().get_image().save_png("res://reviews/main_hall_jukebox_prompt.png"))

	var jb = hall.get_node("Jukebox")
	jb.activate(hall)
	await process_frame
	await process_frame

	print("JUKEBOX_HUD_OPEN_SCREENSHOT=", root.get_texture().get_image().save_png("res://reviews/jukebox_hud_open.png"))

	var hud: CanvasLayer = hall.get_node("JukeboxHUD") as CanvasLayer
	hud.selected_index = 2 # Parlour Above the Clouds
	hud.play_selected_song()
	await process_frame
	await process_frame

	print("JUKEBOX_HUD_PLAYING_SCREENSHOT=", root.get_texture().get_image().save_png("res://reviews/jukebox_hud_playing.png"))

	print("JUKEBOX_CAPTURES_COMPLETED")
	quit()

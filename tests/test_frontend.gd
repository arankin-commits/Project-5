extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func capture(file: String) -> void:
	await process_frame
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://reviews/" + file + ".png")

func _run() -> void:
	var saves = root.get_node("SaveSlots")
	saves.directory = "res://reviews/frontend-test"
	DirAccess.make_dir_recursive_absolute(saves.directory)
	var progress = root.get_node("CoreProgression")
	progress.persistence_enabled = true
	check(saves.select_slot(1) == OK,"Create slot failed")
	progress.xp = 321
	progress.save_progress()
	check(saves.select_slot(2) == OK,"Create second slot failed")
	progress.xp = 17
	progress.save_progress()
	saves.select_slot(1)
	check(progress.xp == 321,"Slot progress leaked or failed to reload")
	saves.select_slot(2)
	check(progress.xp == 17,"Second slot did not persist")
	var screen = load("res://scenes/ui/StartScreen.tscn").instantiate()
	root.add_child(screen)
	current_scene = screen
	await capture("frontend-title")
	screen.show_slots()
	check(screen.page == "slots","Play did not open slot selection")
	await capture("frontend-slots")
	screen._settings()
	check(screen.settings_menu.visible,"Settings did not open")
	screen.settings_menu.back()
	check(not screen.settings_menu.visible,"Settings back failed")
	screen._choose(1)
	await scene_changed
	check(current_scene.name == "FlyingLibertyMainHall","Slot did not enter ship")
	change_scene_to_file("res://scenes/FlyingLibertySyncChamber.tscn")
	await scene_changed
	current_scene.open_run_setup()
	var setup = current_scene.run_setup
	setup._select_route(0)
	check(setup.start_button.disabled,"Unimplemented route selectable")
	setup._select_route(1)
	setup.robot_choice.select(2)
	setup._robot_changed(2)
	check(setup.selected_robot() == "heavy","Robot selection failed")
	await capture("frontend-sync")
	setup.close_setup()
	var menu = current_scene.get_node("ShipMenu")
	menu.open_menu()
	await capture("frontend-pause")
	menu.resume()
	print("FRONTEND_FAILURES=",failures)
	quit(1 if failures else 0)

extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var run = load("res://scenes/RoguelikeRun.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	await process_frame
	run._toggle_pause()
	var menu = run.hud.pause_menu
	check(paused and menu.visible, "Menu must pause gameplay")
	var names: Array[String] = []
	for child in menu.stack.get_children():
		if child is Button:
			names.append(child.text)
	check(names == ["Resume", "Settings", "Controls", "Give Up", "Quit"], "Incorrect menu actions")
	var before: float = run.elapsed
	await create_timer(0.1).timeout
	check(run.elapsed == before, "Gameplay advanced while paused")
	menu.stack.get_child(2).pressed.emit()
	check(paused and menu.page == "settings", "Settings unpaused the game")
	var settings = root.get_node("GameSettings")
	var volume: float = settings.volume
	menu.stack.get_node("Volume").value = 25
	check(is_equal_approx(AudioServer.get_bus_volume_linear(0), 0.25), "Volume control did not apply")
	menu.stack.get_node("Volume").value = volume * 100
	menu.show_controls()
	check(paused and menu.page == "controls", "Controls unpaused the game")
	menu.back()
	check(paused and menu.page == "menu", "Back should return to paused menu")
	menu.stack.get_child(1).pressed.emit()
	check(not paused and not menu.visible, "Resume failed")
	# A menu opened over salvage must preserve the underlying reward choice.
	run.state = "reward"
	run.hud.show_rewards([{ "id": "power", "name": "POWER", "description": "Damage" }])
	run._toggle_pause()
	menu.back()
	check(not paused and run.hud.modal.visible, "Resume discarded reward selection")
	run._toggle_pause()
	menu.stack.get_child(4).pressed.emit()
	await scene_changed
	check(not paused and current_scene.name == "FlyingLibertySyncChamber", "Give Up failed to return to ship")
	check(current_scene.returning and not root.get_node("RunConfig").active, "Give Up skipped sync return")
	check(root.get_node("ShipCrew").return_count == 1, "Give Up did not update cockpit crew")
	print("RUN_MENU_FAILURES=", failures)
	quit(1 if failures else 0)

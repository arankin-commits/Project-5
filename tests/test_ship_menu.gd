extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _run() -> void:
	for room_name in ["MainHall", "Cockpit", "Workshop", "SyncChamber"]:
		change_scene_to_file("res://scenes/FlyingLiberty%s.tscn" % room_name)
		await scene_changed
		var room = current_scene
		var ship_menu = room.get_node("ShipMenu")
		await escape()
		check(paused and ship_menu.menu.visible, room_name + " Esc did not open menu")
		check(ship_menu.menu.stack.get_child(4).disabled, "Give Up must be disabled aboard ship")
		var position: Vector2 = room.player.position
		Input.action_press("move_right")
		await create_timer(0.1).timeout
		Input.action_release("move_right")
		check(room.player.position == position, room_name + " moved while paused")
		ship_menu.menu.show_settings()
		check(paused and ship_menu.menu.page == "settings", "Settings must remain paused")
		ship_menu.menu.show_controls()
		await escape()
		check(paused and ship_menu.menu.page == "menu", "Esc did not return to menu")
		await escape()
		check(not paused and not ship_menu.menu.visible, "Esc did not resume")
		if room_name == "Workshop" or room_name == "SyncChamber":
			if room_name == "Workshop":
				room.open_core_terminal()
			else:
				room.open_run_setup()
			ship_menu.open_menu()
			ship_menu.resume()
			check(not room.player.controls_enabled, "Resume bypassed terminal control lock")
	# Pausing during the return animation must freeze its tween too.
	root.get_node("RunConfig").end_run()
	change_scene_to_file("res://scenes/FlyingLibertySyncChamber.tscn")
	await scene_changed
	var chamber = current_scene
	chamber.get_node("ShipMenu").open_menu()
	var position: Vector2 = chamber.player.position
	await create_timer(0.2).timeout
	check(chamber.returning and chamber.player.position == position, "Return animation advanced while paused")
	chamber.get_node("ShipMenu").resume()
	await create_timer(3.5).timeout
	check(not chamber.returning and chamber.player.controls_enabled, "Return animation failed after resume")
	print("SHIP_MENU_FAILURES=", failures)
	quit(1 if failures else 0)

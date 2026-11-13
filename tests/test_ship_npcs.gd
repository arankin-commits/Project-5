extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func press_interact() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _run() -> void:
	var crew = root.get_node("ShipCrew")
	var config = root.get_node("RunConfig")
	var expected := {"MainHall":["cook","kids","old_man"],"SyncChamber":["handler"],"Workshop":["engineer","mechanic"],"Cockpit":["pilot","copilot"]}
	for room_name in expected:
		change_scene_to_file("res://scenes/FlyingLiberty%s.tscn" % room_name)
		await scene_changed
		await process_frame
		var room = current_scene
		var npcs = room.npc_controller
		check(npcs.actors.size() == expected[room_name].size(), room_name + " NPC count wrong")
		for id in expected[room_name]:
			check(npcs.actors.has(id), "Missing " + id)
			var visual: Polygon2D = npcs.actors[id].get_child(0)
			check(visual.texture.resource_path.ends_with(npcs.CATALOG.NPCS[id].file + ".png"), "Incorrect NPC art")
			room.player.position = npcs.talk_positions[id] + Vector2(0,-25)
			check(npcs.nearest() == id, "NPC cannot be approached: " + id)
			await press_interact()
			check(npcs.dialogue.active and not room.player.controls_enabled, "Dialogue failed to open: " + id)
			check(npcs.dialogue.npc_id == id and npcs.dialogue.portrait.texture == visual.texture, "Wrong dialogue portrait")
			check(npcs.dialogue.portrait.polygon != visual.polygon, "Portrait uses in-game half")
			var position: Vector2 = room.player.position
			Input.action_press("move_right")
			await create_timer(0.1).timeout
			Input.action_release("move_right")
			check(room.player.position.distance_to(position) < 1.0, "Player moved during dialogue: " + id)
			room.get_node("ShipMenu").open_menu()
			room.get_node("ShipMenu").resume()
			check(not room.player.controls_enabled, "Menu bypassed dialogue control lock")
			await press_interact()
			check(npcs.dialogue.active and npcs.dialogue.line_index == 1, "Dialogue did not advance")
			await press_interact()
			check(not npcs.dialogue.active and room.player.controls_enabled, "Dialogue failed to release player")
		check(not npcs.actors.has("cyber_security") and not npcs.actors.has("info_broker"), "Future computer-room NPC was placed")
		if room_name == "Workshop":
			check(room.get_node("WorkshopArtwork").texture.resource_path.ends_with("Engineering Workshop Without Engineer.png"), "Old baked-in engineer remains")
	var initial_layout: Dictionary = crew.cockpit_layout.duplicate()
	for i in 3:
		change_scene_to_file("res://scenes/FlyingLibertyMainHall.tscn")
		await scene_changed
		change_scene_to_file("res://scenes/FlyingLibertyCockpit.tscn")
		await scene_changed
		check(crew.cockpit_layout == initial_layout, "Room visit reshuffled cockpit")
	config.start_run("medium",{})
	check(crew.cockpit_layout == initial_layout, "Starting run reshuffled cockpit early")
	config.end_run()
	check(crew.cockpit_layout != initial_layout and crew.return_count == 1, "Returning from run did not update crew")
	var returned_layout: Dictionary = crew.cockpit_layout.duplicate()
	config.end_run()
	check(crew.cockpit_layout == returned_layout and crew.return_count == 1, "Duplicate end_run reshuffled crew")
	for layout in crew.COCKPIT_LAYOUTS:
		crew.cockpit_layout = layout.duplicate()
		change_scene_to_file("res://scenes/FlyingLibertyCockpit.tscn")
		await scene_changed
		var npcs = current_scene.npc_controller
		check(npcs.actors.size() == layout.size(), "Single/dual crew state wrong")
		for id in layout:
			check(npcs.actors[id].position == npcs.COCKPIT_POSITIONS[layout[id]], "Crew at wrong X")
	print("SHIP_NPC_CHECKS=",checks," FAILURES=",failures)
	quit(1 if failures else 0)

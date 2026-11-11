extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var room: Node2D = load("res://scenes/FlyingLibertyCockpit.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await physics_frame
	var player: CharacterBody2D = room.get_node("PlayerAndNPCs/Player")
	var spawn := player.position
	assert(spawn.distance_to(Vector2(811.8, 809.2)) < 3.0, "Spawn mapping is wrong")
	Input.action_press("move_up")
	for i in 12:
		await physics_frame
	Input.action_release("move_up")
	assert(player.position.y < spawn.y - 20.0, "WASD movement failed")
	# Approach the pilot chair from the deck; the seat must stop upward movement.
	player.position = Vector2(690, 550)
	Input.action_press("move_up")
	for i in 50:
		await physics_frame
	Input.action_release("move_up")
	assert(player.position.y >= 505.0, "Pilot seat collision failed")
	player.position = Vector2(820, 870)
	Input.action_press("move_down")
	for i in 50:
		await physics_frame
	Input.action_release("move_down")
	assert(player.position.y <= 916.0, "Room boundary collision failed")
	var door = room.get_node("Interactions/MainHallDoor")
	player.position = Vector2(800, 780)
	assert(door.in_range(player.position), "Door should be in range")
	var pilot = room.get_node("Interactions/TalktoPilot")
	assert(not pilot.in_range(player.position), "Pilot should be out of range")
	player.position = pilot.position + Vector2(0, 80)
	assert(pilot.in_range(player.position), "Pilot should be approachable")
	pilot.activate(room)
	assert(room.panel.visible and room.panel_title.text == "Talk to Pilot", "Pilot dialogue failed")
	room.panel.hide()
	door.locked = true
	door.activate(room)
	assert(room.panel_title.text == "Door locked", "Locked door failed")
	room.panel.hide()
	door.locked = false
	door.activate(room)
	await process_frame
	await process_frame
	assert(current_scene != null and current_scene.name == "FlyingLibertyMainHall", "Cockpit to Main Hall transition failed")
	var hall := current_scene
	var hall_player: CharacterBody2D = hall.get_node("Player")
	assert(hall_player.position.distance_to(Vector2(844, 315)) < 1.0, "Main Hall entrance spawn failed")
	var first_door = hall.get_node("Doors/FirstTopDoor")
	assert(first_door.locked, "First top door should remain locked")
	var second_door = hall.get_node("Doors/CockpitDoor")
	assert(not second_door.locked and second_door.in_range(hall_player.position), "Second top door is not the cockpit entrance")
	second_door.activate(hall)
	for i in 6:
		await process_frame
	assert(current_scene != null and current_scene.name == "FlyingLibertyCockpit", "Main Hall to Cockpit transition failed")
	var return_player: CharacterBody2D = current_scene.get_node("PlayerAndNPCs/Player")
	assert(return_player.position.distance_to(Vector2(811.8, 809.2)) < 3.0, "Cockpit return spawn failed")
	print("COCKPIT_TESTS_PASSED")
	quit()

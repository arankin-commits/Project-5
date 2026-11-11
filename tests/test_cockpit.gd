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
	assert(not first_door.locked and first_door.target_room_id == "fly_sync", "First top door should enter the Sync Chamber")
	var second_door = hall.get_node("Doors/CockpitDoor")
	assert(not second_door.locked and second_door.in_range(hall_player.position), "Second top door is not the cockpit entrance")
	for i in range(1, 7):
		var bedroom = hall.get_node("Doors/BedroomDoor%d" % i)
		assert(bedroom != null and bedroom.target_room_id == "bedroom_%02d" % i, "Bedroom door %d is missing" % i)
		assert(bedroom.in_range(bedroom.position + Vector2(0, 40)), "Bedroom door %d cannot be approached" % i)
	hall_player.position = Vector2(1510, 365)
	Input.action_press("move_right")
	for i in 70:
		await physics_frame
	Input.action_release("move_right")
	assert(hall_player.position.x > 1700, "Right bedroom wing is not walkable")
	hall_player.position = Vector2(2875, 365)
	Input.action_press("move_right")
	for i in 35:
		await physics_frame
	Input.action_release("move_right")
	assert(hall_player.position.x <= 2942, "Bedroom wing end boundary failed")
	var bedroom_one = hall.get_node("Doors/BedroomDoor1")
	hall_player.position = bedroom_one.position + Vector2(0, 25)
	bedroom_one.activate(hall)
	assert(hall.panel.visible and hall.panel_title.text.contains("room pending"), "Bedroom placeholder interaction failed")
	hall.panel.hide()
	hall_player.position = Vector2(521, 315)
	assert(first_door.in_range(hall_player.position), "Sync Chamber door is not approachable")
	first_door.activate(hall)
	for i in 6:
		await process_frame
	assert(current_scene != null and current_scene.name == "FlyingLibertySyncChamber", "Main Hall to Sync Chamber transition failed")
	var sync_room := current_scene
	var sync_player: CharacterBody2D = sync_room.get_node("Player")
	assert(sync_player.position.distance_to(Vector2(793, 825)) < 1.0, "Sync Chamber entrance spawn failed")
	sync_player.position = Vector2(650, 650)
	Input.action_press("move_up")
	for i in 40:
		await physics_frame
	Input.action_release("move_up")
	assert(sync_player.position.y >= 608, "Sync machine collision failed")
	var sync_pod = sync_room.get_node("Interactions/SyncPod")
	assert(sync_pod.in_range(sync_player.position), "Sync pod is not approachable")
	sync_pod.activate(sync_room)
	assert(sync_room.panel.visible and sync_room.panel_title.text == "Inspect Sync Pod", "Sync pod interaction failed")
	sync_room.panel.hide()
	sync_player.position = Vector2(793, 825)
	var sync_exit = sync_room.get_node("Interactions/MainHallDoor")
	assert(sync_exit.in_range(sync_player.position), "Sync Chamber exit is not approachable")
	sync_exit.activate(sync_room)
	for i in 6:
		await process_frame
	assert(current_scene != null and current_scene.name == "FlyingLibertyMainHall", "Sync Chamber return transition failed")
	hall = current_scene
	hall_player = hall.get_node("Player")
	assert(hall_player.position.distance_to(Vector2(521, 315)) < 1.0, "Sync Chamber returned to the wrong Main Hall door")
	second_door = hall.get_node("Doors/CockpitDoor")
	second_door.activate(hall)
	for i in 6:
		await process_frame
	assert(current_scene != null and current_scene.name == "FlyingLibertyCockpit", "Main Hall to Cockpit transition failed")
	var return_player: CharacterBody2D = current_scene.get_node("PlayerAndNPCs/Player")
	assert(return_player.position.distance_to(Vector2(811.8, 809.2)) < 3.0, "Cockpit return spawn failed")
	print("COCKPIT_TESTS_PASSED")
	quit()

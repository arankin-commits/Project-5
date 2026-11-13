extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if root.get_node_or_null("CoreProgression") == null:
		var progression: Node = load("res://scripts/core_progression.gd").new()
		progression.name = "CoreProgression"
		root.add_child(progression)
	var room: Node2D = load("res://scenes/FlyingLibertyCockpit.tscn").instantiate()
	root.add_child(room)
	current_scene = room
	await physics_frame
	var player: CharacterBody2D = room.get_node("PlayerAndNPCs/Player")
	assert(player.get_node("CharacterVisual").sprite_frames.get_frame_count("walk") == 8, "Main character animation was not loaded")
	assert(room.get_node("PlayerAndNPCs/PilotNPC").position == Vector2(540,555), "New pilot is not at the marked floor position")
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
	assert(not room.has_node("Interactions/TalktoPilot"), "Removed pilot still has dialogue")
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
	var run_setup = sync_room.get_node("RunSetup")
	assert(run_setup.visible and not sync_player.get("controls_enabled"), "Sync pod setup did not open or pause movement")
	assert(not run_setup.robot_choice.is_item_disabled(1) and not run_setup.robot_choice.is_item_disabled(2), "Robot types are locked")
	run_setup.close_setup()
	assert(not run_setup.visible and sync_player.get("controls_enabled"), "Sync pod setup did not close")
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
	var workshop_entrance = hall.get_node("Passages/WorkshopEntrance")
	assert(workshop_entrance.target_scene == "res://scenes/FlyingLibertyWorkshop.tscn", "Left hallway workshop entrance is missing")
	hall_player.position = Vector2(170, 550)
	Input.action_press("move_left")
	for i in 40:
		await physics_frame
		if current_scene != null and current_scene.name == "FlyingLibertyWorkshop":
			break
	Input.action_release("move_left")
	assert(current_scene != null and current_scene.name == "FlyingLibertyWorkshop", "Main Hall to Workshop transition failed")
	var workshop := current_scene
	var workshop_player: CharacterBody2D = workshop.get_node("Player")
	assert(workshop_player.position.distance_to(Vector2(1445, 490)) < 1.0, "Workshop entrance spawn failed")
	workshop_player.position = Vector2(800, 630)
	Input.action_press("move_up")
	for i in 40:
		await physics_frame
	Input.action_release("move_up")
	assert(workshop_player.position.y >= 608, "Workshop power core collision failed")
	var core_interaction = workshop.get_node("Interactions/PowerCoreTerminal")
	assert(core_interaction.in_range(workshop_player.position), "Workshop core cannot be approached")
	assert(workshop._nearest_interaction() == core_interaction, "Core interaction is obscured by another prompt")
	core_interaction.activate(workshop)
	var core_terminal = workshop.get_node("CoreTerminal")
	assert(core_terminal.visible and not workshop_player.get("controls_enabled"), "Core terminal did not open or pause movement")
	assert(core_terminal.skill_buttons.size() == 20 and core_terminal.unlock_button.disabled, "Skill tree nodes missing")
	var progression: Node = root.get_node("CoreProgression")
	assert(progression.has_skill("root") and progression.core_capacity() == 1, "Starting skill state is wrong")
	assert(not progression.can_unlock_skill("power_three"), "Special skill bypassed its prerequisite")
	core_terminal.close_terminal()
	assert(not core_terminal.visible and workshop_player.get("controls_enabled"), "Core terminal did not restore movement")
	var station = workshop.get_node("Interactions/AutomatonStation")
	workshop_player.position = Vector2(1110, 810)
	assert(station.in_range(workshop_player.position), "Automaton station is not approachable")
	station.activate(workshop)
	assert(workshop.panel.visible, "Automaton station interaction failed")
	workshop.panel.hide()
	workshop_player.position = Vector2(1445, 490)
	var workshop_exit = workshop.get_node("Passages/MainHallReturn")
	assert(workshop_exit.target_entry_id == "from_workshop", "Workshop return passage is missing")
	Input.action_press("move_right")
	for i in 40:
		await physics_frame
		if current_scene != null and current_scene.name == "FlyingLibertyMainHall":
			break
	Input.action_release("move_right")
	assert(current_scene != null and current_scene.name == "FlyingLibertyMainHall", "Workshop to Main Hall transition failed")
	hall = current_scene
	hall_player = hall.get_node("Player")
	assert(hall_player.position.distance_to(Vector2(170, 550)) < 1.0, "Workshop returned to the wrong Main Hall doorway")
	second_door = hall.get_node("Doors/CockpitDoor")
	second_door.activate(hall)
	for i in 6:
		await process_frame
	assert(current_scene != null and current_scene.name == "FlyingLibertyCockpit", "Main Hall to Cockpit transition failed")
	var return_player: CharacterBody2D = current_scene.get_node("PlayerAndNPCs/Player")
	assert(return_player.position.distance_to(Vector2(811.8, 809.2)) < 3.0, "Cockpit return spawn failed")
	print("COCKPIT_TESTS_PASSED")
	quit()

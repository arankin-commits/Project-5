extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	change_scene_to_file("res://scenes/FlyingLibertyMainHall.tscn")
	await process_frame
	await create_timer(0.4).timeout
	var hall = current_scene
	var entrance = hall.get_node("Passages/ComputerRoomEntrance")
	check(entrance.position == Vector2(844,820), "Wrong hall arch")
	hall.player.position = Vector2(844,815)
	await create_timer(0.3).timeout
	check(current_scene.name == "FlyingLibertyComputerRoom", "Hall arch did not enter computer room")
	if current_scene.name != "FlyingLibertyComputerRoom":
		quit(1)
		return
	var room = current_scene
	await create_timer(0.4).timeout
	check(room.npc_controller.actors.has("cyber_security"), "Missing analyst")
	check(room.npc_controller.actors.has("info_broker"), "Missing broker")
	for id in ["cyber_security", "info_broker"]:
		room.player.position = room.npc_controller.talk_positions[id] + Vector2(0,45)
		var query := PhysicsPointQueryParameters2D.new()
		query.position = room.player.position - Vector2(0,15)
		query.collision_mask = 1
		check(room.get_world_2d().direct_space_state.intersect_point(query).is_empty(), "NPC approach blocked: " + id)
		check(room.npc_controller.nearest() == id, "NPC cannot be approached: " + id)
		room.npc_controller.dialogue.open(id,room.player)
		check(room.npc_controller.dialogue.active, "NPC dialogue failed")
		while room.npc_controller.dialogue.active:
			room.npc_controller.dialogue.advance()
	room.player.position = Vector2(1000,440)
	room.get_node("Player/Camera2D").reset_smoothing()
	room.get_node("Player/Camera2D").force_update_scroll()
	await process_frame
	await process_frame
	if not DisplayServer.get_name() == "headless":
		root.get_texture().get_image().save_png("res://reviews/computer-room.png")
	room.player.position = Vector2(820,275)
	await create_timer(0.4).timeout
	check(current_scene.name == "FlyingLibertyMainHall", "Return doorway failed")
	if current_scene.name == "FlyingLibertyMainHall":
		check(current_scene.player.position.distance_to(Vector2(844,735)) < 5, "Wrong hall return point")
	await create_timer(0.4).timeout
	check(current_scene.name == "FlyingLibertyMainHall", "Return caused a travel loop")
	print("COMPUTER_ROOM_FAILURES=",failures)
	quit(1 if failures else 0)

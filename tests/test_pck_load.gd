extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- Deep testing scenes from index.pck ---")
	var success = ProjectSettings.load_resource_pack("res://index.pck")
	print("load_resource_pack: ", success)

	# 1. StartScreen and Save Selection
	print("Instantiating StartScreen...")
	var start_scene = load("res://scenes/ui/StartScreen.tscn").instantiate()
	root.add_child(start_scene)
	current_scene = start_scene
	await process_frame
	await process_frame
	print("StartScreen title OK")
	print("Testing Save Selection screen...")
	start_scene.show_slots()
	await process_frame
	await process_frame
	print("StartScreen save slots OK")
	start_scene.queue_free()
	await process_frame

	# 2. RoguelikeRun
	print("Instantiating RoguelikeRun...")
	var config = root.get_node("RunConfig")
	config.call("start_run", "medium", {})
	var run_scene = load("res://scenes/RoguelikeRun.tscn").instantiate()
	root.add_child(run_scene)
	current_scene = run_scene
	await process_frame
	await process_frame
	print("RoguelikeRun frame OK")
	
	# Test card rewards display
	print("Testing HUD reward display in RoguelikeRun...")
	var choices: Array[Dictionary] = [
		{"id": "lightning_attack", "element": "lightning", "rarity": "common", "name": "Lightning Attack", "description": "Normal attacks now do lightning damage."},
		{"id": "fire_slam", "element": "fire", "rarity": "rare", "name": "Fire Slam", "description": "Ground Slam produces an expanding ring of fire."},
		{"id": "ice_slam", "element": "ice", "rarity": "epic", "name": "Ice Slam", "description": "Ground Slam creates ice pillars trapping enemies."}
	]
	run_scene.hud.show_rewards(choices)
	await process_frame
	print("HUD modal visible: ", run_scene.hud.modal.visible)
	print("HUD cards count: ", run_scene.hud.modal_actions.get_child_count())
	print("HUD first card text: ", run_scene.hud.modal_actions.get_child(0).title_label.text)
	
	run_scene.queue_free()
	await process_frame

	# 3. FlyingLibertyMainHall
	print("Instantiating FlyingLibertyMainHall...")
	var hall_scene = load("res://scenes/FlyingLibertyMainHall.tscn").instantiate()
	root.add_child(hall_scene)
	current_scene = hall_scene
	await process_frame
	await process_frame
	print("FlyingLibertyMainHall frame OK")
	hall_scene.queue_free()
	await process_frame

	# 4. FlyingLibertyCockpit
	print("Instantiating FlyingLibertyCockpit...")
	var cockpit_scene = load("res://scenes/FlyingLibertyCockpit.tscn").instantiate()
	root.add_child(cockpit_scene)
	current_scene = cockpit_scene
	await process_frame
	await process_frame
	print("FlyingLibertyCockpit frame OK")
	cockpit_scene.queue_free()
	await process_frame

	# 5. FlyingLibertySyncChamber
	print("Instantiating FlyingLibertySyncChamber...")
	var sync_scene = load("res://scenes/FlyingLibertySyncChamber.tscn").instantiate()
	root.add_child(sync_scene)
	current_scene = sync_scene
	await process_frame
	await process_frame
	print("FlyingLibertySyncChamber frame OK")
	sync_scene.queue_free()
	await process_frame

	# 6. FlyingLibertyWorkshop
	print("Instantiating FlyingLibertyWorkshop...")
	var workshop_scene = load("res://scenes/FlyingLibertyWorkshop.tscn").instantiate()
	root.add_child(workshop_scene)
	current_scene = workshop_scene
	await process_frame
	await process_frame
	print("FlyingLibertyWorkshop frame OK")
	workshop_scene.queue_free()
	await process_frame

	# 7. FlyingLibertyComputerRoom
	print("Instantiating FlyingLibertyComputerRoom...")
	var comp_scene = load("res://scenes/FlyingLibertyComputerRoom.tscn").instantiate()
	root.add_child(comp_scene)
	current_scene = comp_scene
	await process_frame
	await process_frame
	print("FlyingLibertyComputerRoom frame OK, NPC controller: ", comp_scene.npc_controller != null)
	comp_scene.queue_free()
	await process_frame

	print("ALL PCK SCENES FUNCTIONED PERFECTLY!")
	quit(0)

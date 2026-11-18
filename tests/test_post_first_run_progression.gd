extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAILURE: " + message)

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
	print("--- BEGINNING POST-FIRST-RUN PROGRESSION TESTS ---")
	var config = root.get_node("RunConfig")
	var crew = root.get_node("ShipCrew")

	# Reset state to fresh game
	config.runs_completed = 0
	config.skill_tree_opened_after_run = false
	crew.return_count = 0

	# 1. Fresh state check
	check(not config.is_sync_machine_locked(), "Sync machine should NOT be locked before first run")
	var pre_eng_lines: Array = config.get_npc_dialogue("engineer")
	check(pre_eng_lines.is_empty(), "Engineer should not have progression dialogue before first run")

	# 2. Complete first run
	config.active = true
	config.end_run()
	config.sync_return_pending = false  # Skip cinematic in test
	check(config.get_runs_completed() >= 1, "Runs completed should be at least 1 after end_run")
	check(config.is_sync_machine_locked(), "Sync machine MUST be locked after first run before opening skill tree")

	# 3. Test Sync Chamber interaction when locked
	change_scene_to_file("res://scenes/FlyingLibertySyncChamber.tscn")
	await scene_changed
	await process_frame
	var sync_room = current_scene
	check(sync_room != null, "Sync chamber scene failed to load")

	# Activate sync machine
	sync_room.open_run_setup()
	await process_frame

	check(not sync_room.run_setup.visible, "RunSetup MUST NOT open when sync machine is locked")
	check(sync_room.npc_controller.dialogue.active, "Handler dialogue MUST open when trying to use locked sync machine")

	var expected_handler_text := "What are you doing? You know the machine has to recharge before you can use it again. You should go relax; we need you at your best when you sync up. The eccentric one needed you for something. Why don’t you go talk to her?"
	check(sync_room.npc_controller.dialogue.dialogue_text.text == expected_handler_text, "Handler text does not match expected blocked warning")
	check(sync_room.npc_controller.dialogue.speaker.text == "HANDLER", "Speaker is not HANDLER")

	# Close dialogue
	sync_room.npc_controller.dialogue.close()
	await process_frame
	check(not sync_room.npc_controller.dialogue.active, "Dialogue failed to close")

	# 4. Test Workshop: Mechanic dialogue
	change_scene_to_file("res://scenes/FlyingLibertyWorkshop.tscn")
	await scene_changed
	await process_frame
	var workshop_room = current_scene
	check(workshop_room != null, "Workshop scene failed to load")

	var mechanic_lines: Array = config.get_npc_dialogue("mechanic")
	check(mechanic_lines.size() == 1, "Mechanic should have 1 progression dialogue line")
	var expected_mechanic_text := "Heya Josh. May’s been bugging me all day about this machine of hers; why don’t you go talk to her?"
	check(mechanic_lines[0].text == expected_mechanic_text, "Mechanic text does not match prompt")

	workshop_room.npc_controller.dialogue.open("mechanic", workshop_room.player)
	await process_frame
	check(workshop_room.npc_controller.dialogue.dialogue_text.text == expected_mechanic_text, "Mechanic dialogue text mismatch on open")
	check(workshop_room.npc_controller.dialogue.speaker.text == "MECHANIC", "Speaker is not MECHANIC")
	workshop_room.npc_controller.dialogue.close()
	await process_frame

	# 5. Test Workshop: Engineer conversation 1 (multi-turn back-and-forth)
	var engineer_lines: Array = config.get_npc_dialogue("engineer")
	check(engineer_lines.size() == 5, "Engineer intro conversation should have 5 lines, got " + str(engineer_lines.size()))

	var expected_eng_conv := [
		{"speaker": "ENGINEER", "portrait": "engineer", "text": "Why hello there, my fellow bipedal primate, I have used my grand ingenuity to create that machine in the middle of the room. What machine, you ask? The large one in front of your face. Well, pray tell, what does it do? I’m glad you asked, my meat-headed companion; this machine is able to strengthen the core of your combat robots. All you need to do is fight, and this puppy’ll do the rest. Through an automated telemetry acquisition system, it continuously receives, processes, and analyzes combat data transmitted from your robot, cataloging everything from energy consumption and elemental output to combat efficiency and core performance. Using advanced adaptive algorithms, it identifies structural inefficiencies…"},
		{"speaker": "JOSH", "portrait": "josh", "text": "As much as I would love to hear more about the.. Intricacies of this machine of yours, how about we keep it short?"},
		{"speaker": "ENGINEER", "portrait": "engineer", "text": "Fine. Do fight. Get strong. Was that short enough?"},
		{"speaker": "JOSH", "portrait": "josh", "text": "Very funny. I’ll listen to the whole rundown later. Just give the synopsis."},
		{"speaker": "ENGINEER", "portrait": "engineer", "text": "Basically, the power you siphon from enemies can be used to strengthen your robot cores; it’s easier shown than told. Why don’t you walk over there and test it out?"}
	]

	workshop_room.npc_controller.dialogue.open("engineer", workshop_room.player)
	await process_frame

	for step in range(expected_eng_conv.size()):
		var cur_step: Dictionary = expected_eng_conv[step]
		check(workshop_room.npc_controller.dialogue.active, "Dialogue inactive at step " + str(step))
		check(workshop_room.npc_controller.dialogue.speaker.text == cur_step.speaker, "Speaker mismatch at step " + str(step) + ": got " + workshop_room.npc_controller.dialogue.speaker.text + ", expected " + cur_step.speaker)
		check(workshop_room.npc_controller.dialogue.dialogue_text.text == cur_step.text, "Text mismatch at step " + str(step))
		check(workshop_room.npc_controller.dialogue.current_portrait_id == cur_step.portrait, "Portrait mismatch at step " + str(step) + ": got " + workshop_room.npc_controller.dialogue.current_portrait_id + ", expected " + cur_step.portrait)
		workshop_room.npc_controller.dialogue.advance()
		await process_frame

	check(not workshop_room.npc_controller.dialogue.active, "Dialogue should be closed after 5th step")

	# Verify sync machine is STILL locked before opening skill tree
	check(config.is_sync_machine_locked(), "Sync machine should still be locked before opening skill tree")

	# 6. Open skill tree (terminal) in Workshop
	workshop_room.open_core_terminal()
	await process_frame
	check(workshop_room.core_terminal.visible, "Core terminal did not open")
	check(config.skill_tree_opened_after_run, "skill_tree_opened_after_run must be true after opening core terminal")
	check(not config.is_sync_machine_locked(), "Sync machine MUST BE UNLOCKED after opening skill tree")

	workshop_room.core_terminal.close_terminal()
	await process_frame

	# 7. Test Engineer conversation 2 (after opening skill tree)
	var eng_post_lines: Array = config.get_npc_dialogue("engineer")
	check(eng_post_lines.size() == 3, "Engineer follow-up should have 3 lines, got " + str(eng_post_lines.size()))

	var expected_eng_post := [
		{"speaker": "ENGINEER", "portrait": "engineer", "text": "Sooooooooo what you’d think? Impressive right. Genius even."},
		{"speaker": "JOSH", "portrait": "josh", "text": "Yeah, I gotta admit it’s impressive. This’ll be a big help, thanks."},
		{"speaker": "ENGINEER", "portrait": "engineer", "text": "No problem, just make sure to find some aether cores or, even better, some Lancrest blueprints. Oh, if only he wasn’t so evil."}
	]

	workshop_room.npc_controller.dialogue.open("engineer", workshop_room.player)
	await process_frame

	for step in range(expected_eng_post.size()):
		var cur_step: Dictionary = expected_eng_post[step]
		check(workshop_room.npc_controller.dialogue.active, "Post-dialogue inactive at step " + str(step))
		check(workshop_room.npc_controller.dialogue.speaker.text == cur_step.speaker, "Speaker mismatch at post step " + str(step) + ": got " + workshop_room.npc_controller.dialogue.speaker.text + ", expected " + cur_step.speaker)
		check(workshop_room.npc_controller.dialogue.dialogue_text.text == cur_step.text, "Text mismatch at post step " + str(step))
		check(workshop_room.npc_controller.dialogue.current_portrait_id == cur_step.portrait, "Portrait mismatch at post step " + str(step))
		workshop_room.npc_controller.dialogue.advance()
		await process_frame

	check(not workshop_room.npc_controller.dialogue.active, "Post-dialogue should be closed after 3rd step")

	# 8. Return to Sync Chamber and verify run setup opens now!
	change_scene_to_file("res://scenes/FlyingLibertySyncChamber.tscn")
	await scene_changed
	await process_frame
	sync_room = current_scene
	check(not config.is_sync_machine_locked(), "Sync machine is still reported as locked")

	sync_room.open_run_setup()
	await process_frame
	check(sync_room.run_setup.visible, "RunSetup MUST open after skill tree has been opened!")
	check(not sync_room.npc_controller.dialogue.active, "Handler dialogue should not have opened")

	sync_room.run_setup.close_setup()
	await process_frame
	check(not sync_room.run_setup.visible, "RunSetup failed to close")

	print("--- POST-FIRST-RUN PROGRESSION TESTS COMPLETE ---")
	print("PROGRESSION_CHECKS=" + str(checks) + " FAILURES=" + str(failures))
	if failures > 0:
		print("FAILED with " + str(failures) + " failures.")
	else:
		print("ALL CHECKS PASSED.")
	quit(failures)

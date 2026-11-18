extends SceneTree

var failures: int = 0

func check(condition: bool, message: String) -> void:
	if not condition:
		print("FAIL: ", message)
		failures += 1
	else:
		print("PASS: ", message)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- Running Card Selection HUD Tests ---")
	await test_reference_cards()
	await test_hud_integration()
	await test_skip_functionality()
	print("CARD_HUD_FAILURES=", failures)
	quit(1 if failures else 0)

func test_reference_cards() -> void:
	var CardChoiceButtonClass = preload("res://scripts/card_choice_button.gd")

	# Test 1: Lightning Attack (Common)
	var c1_data: Dictionary = {
		"id": "lightning_attack",
		"element": "lightning",
		"rarity": "common",
		"name": "Lightning Attack",
		"description": "[COMMON]\nCombo strikes deal 8 / 8 / 12 elemental Lightning damage."
	}
	var card1 = CardChoiceButtonClass.new(c1_data)
	root.add_child(card1)
	await process_frame
	check(card1.rarity == "common", "Card 1 rarity is common")
	check(card1.element == "lightning", "Card 1 element is lightning")
	check(card1.title_label.text == "Lightning Attack", "Card 1 title is 'Lightning Attack'")
	check(card1.rarity_label.text == "COMMON", "Card 1 rarity badge is 'COMMON'")
	check(card1.art_rect.texture != null, "Card 1 art texture is loaded")
	check(card1.crest_rect.texture != null, "Card 1 crest texture is loaded")
	check(card1.mini_icon_rect.texture != null, "Card 1 mini icon is loaded")
	check(card1.stat_primary_label.text == "+8 / +8 / +12", "Card 1 stat primary matches reference")
	check(card1.stat_secondary_label.text.contains("Lightning Damage"), "Card 1 stat secondary contains 'Lightning Damage'")

	# Test 2: Fire Slam (Rare)
	var c2_data: Dictionary = {
		"id": "fire_slam",
		"element": "fire",
		"rarity": "rare",
		"name": "Fire Slam",
		"description": "[RARE]\nGround Slam produces a ring of fire that expands outwards and burns enemies it passes through."
	}
	var card2 = CardChoiceButtonClass.new(c2_data)
	root.add_child(card2)
	await process_frame
	check(card2.rarity == "rare", "Card 2 rarity is rare")
	check(card2.element == "fire", "Card 2 element is fire")
	check(card2.title_label.text == "Fire Slam", "Card 2 title is 'Fire Slam'")
	check(card2.rarity_label.text == "RARE", "Card 2 rarity badge is 'RARE'")
	check(card2.art_rect.texture != null, "Card 2 art texture is loaded")
	check(card2.crest_rect.texture != null, "Card 2 crest texture is loaded")
	check(card2.stat_primary_label.text == "18 Fire Damage", "Card 2 stat primary matches reference")
	check(card2.stat_secondary_label.text.contains("Applies Burn"), "Card 2 stat secondary contains 'Applies Burn'")

	# Test 3: Ice Slam (Epic)
	var c3_data: Dictionary = {
		"id": "ice_slam",
		"element": "ice",
		"rarity": "epic",
		"name": "Ice Slam",
		"description": "[EPIC]\nGround Slam creates ice pillars around enemies caught in its area, temporarily trapping them."
	}
	var card3 = CardChoiceButtonClass.new(c3_data)
	root.add_child(card3)
	await process_frame
	check(card3.rarity == "epic", "Card 3 rarity is epic")
	check(card3.element == "ice", "Card 3 element is ice")
	check(card3.title_label.text == "Ice Slam", "Card 3 title is 'Ice Slam'")
	check(card3.rarity_label.text == "EPIC", "Card 3 rarity badge is 'EPIC'")
	check(card3.art_rect.texture != null, "Card 3 art texture is loaded")
	check(card3.crest_rect.texture != null, "Card 3 crest texture is loaded")
	check(card3.stat_primary_label.text == "22 Ice Damage", "Card 3 stat primary matches reference")
	check(card3.stat_secondary_label.text.contains("Traps for 2s"), "Card 3 stat secondary contains 'Traps for 2s'")

	# Test Focus & Hover
	card2.grab_focus()
	check(card2.is_hovered == true, "Focused card has is_hovered == true")
	card2.release_focus()
	check(card2.is_hovered == false, "Unfocused card has is_hovered == false")

	card1.queue_free()
	card2.queue_free()
	card3.queue_free()
	await process_frame

func test_hud_integration() -> void:
	var RunHUDClass = preload("res://scripts/run_hud.gd")
	var hud = RunHUDClass.new()
	root.add_child(hud)
	await process_frame

	var choices: Array[Dictionary] = [
		{"id": "lightning_attack", "element": "lightning", "rarity": "common", "name": "Lightning Attack", "description": "Normal attacks now do lightning damage."},
		{"id": "fire_slam", "element": "fire", "rarity": "rare", "name": "Fire Slam", "description": "Ground Slam produces an expanding ring of fire."},
		{"id": "ice_slam", "element": "ice", "rarity": "epic", "name": "Ice Slam", "description": "Ground Slam creates ice pillars trapping enemies."}
	]
	hud.show_rewards(choices)
	await process_frame
	check(hud.modal.visible == true, "HUD modal is visible")
	check(hud.card_view.visible == true, "HUD card_view is visible")
	check(hud.result_panel.visible == false, "HUD result_panel is hidden during rewards")
	check(hud.modal_actions.get_child_count() == 3, "HUD modal_actions contains 3 card choices")
	check(hud.modal_actions.get_child(0).has_focus(), "First card grabbed focus")

	var selected := [""]
	hud.reward_selected.connect(func(id: String): selected[0] = id)
	var btn = hud.modal_actions.get_child(1)
	btn.pressed.emit()
	check(selected[0] == "fire_slam", "Pressing second card emitted 'fire_slam'")

	# Test show_result hides card_view and shows result_panel
	hud.show_result("MISSION ACCOMPLISHED", "The boiler was conquered.")
	await process_frame
	check(hud.card_view.visible == false, "HUD card_view hidden during show_result")
	check(hud.result_panel.visible == true, "HUD result_panel visible during show_result")
	check(hud.modal_title.text == "MISSION ACCOMPLISHED", "HUD modal_title updated")

	hud.queue_free()
	await process_frame

func test_skip_functionality() -> void:
	var RunHUDClass = preload("res://scripts/run_hud.gd")
	var hud = RunHUDClass.new()
	root.add_child(hud)
	await process_frame

	var choices: Array[Dictionary] = [
		{"id": "power", "name": "POWER", "description": "Damage"}
	]
	hud.show_rewards(choices)
	await process_frame

	var selected := [""]
	hud.reward_selected.connect(func(id: String): selected[0] = id)

	# Click skip button
	hud.skip_button.pressed.emit()
	check(selected[0] == "skip", "Clicking skip button emitted 'skip'")

	hud.queue_free()
	await process_frame

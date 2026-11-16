extends SceneTree

const JUKEBOX_SCRIPT := preload("res://scripts/jukebox_interactable.gd")

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("--- BEGIN JUKEBOX TESTS ---")

	var hall: Node2D = load("res://scenes/FlyingLibertyMainHall.tscn").instantiate()
	root.add_child(hall)
	await process_frame
	await process_frame

	# 1. Verify Jukebox in-world components
	assert(hall.has_node("Jukebox"), "Jukebox interactable node missing from Main Hall")
	var jb = hall.get_node("Jukebox")
	assert(jb != null, "Jukebox node is null")
	assert(jb.prompt == "Play Jukebox", "Jukebox prompt should be 'Play Jukebox'")
	assert(jb.position.distance_to(Vector2(680, 275)) < 1.0, "Jukebox position should be (680, 275)")
	assert(jb.radius >= 85.0, "Jukebox interact radius should be >= 85.0")

	assert(hall.has_node("JukeboxProp"), "JukeboxProp visual missing from Main Hall")
	var prop := hall.get_node("JukeboxProp")
	assert(prop.has_node("JukeboxSprite"), "JukeboxSprite missing inside JukeboxProp")
	var sprite: Sprite2D = prop.get_node("JukeboxSprite") as Sprite2D
	assert(sprite.texture != null, "JukeboxSprite texture should not be null")
	assert(sprite.texture.resource_path == "res://HUD/jukebox.png", "JukeboxSprite should use res://HUD/jukebox.png")
	assert(sprite.material != null, "JukeboxSprite should have arch cutout shader material")

	assert(hall.has_node("Collision/JukeboxObstacle"), "Jukebox collision obstacle missing from Main Hall Collision")

	# 2. Verify Doors still exist and work
	assert(hall.has_node("Doors/FirstTopDoor"), "FirstTopDoor missing")
	assert(hall.has_node("Doors/CockpitDoor"), "CockpitDoor missing")
	for i in range(1, 7):
		assert(hall.has_node("Doors/BedroomDoor%d" % i), "BedroomDoor%d missing" % i)

	# 3. Verify Player approach and prompt
	var player: CharacterBody2D = hall.get_node("Player")
	player.position = Vector2(680, 315)
	await process_frame
	hall._process(0.016)
	assert(hall.prompt.text == "[E] Play Jukebox", "Prompt text should be '[E] Play Jukebox' when near Jukebox, got: %s" % hall.prompt.text)

	# 4. Verify JukeboxHUD node
	assert(hall.has_node("JukeboxHUD"), "JukeboxHUD node missing from Main Hall")
	var hud: CanvasLayer = hall.get_node("JukeboxHUD") as CanvasLayer
	assert(not hud.visible, "JukeboxHUD should be hidden by default")

	# 5. Open Jukebox HUD
	jb.activate(hall)
	await process_frame
	assert(hud.visible, "JukeboxHUD should become visible on activation")
	assert(not player.controls_enabled, "Player controls should be disabled while JukeboxHUD is open")

	# 6. Song Navigation
	assert(hud.selected_index == 0, "Initial selected song should be index 0 (Copper Hearth)")
	assert(hud.page_indicator.text == "1 / 6", "Initial page indicator should be '1 / 6'")

	hud.select_next()
	assert(hud.selected_index == 1, "After select_next(), index should be 1")
	assert(hud.page_indicator.text == "2 / 6", "Page indicator should be '2 / 6'")

	hud.select_previous()
	assert(hud.selected_index == 0, "After select_previous(), index should be 0")
	assert(hud.page_indicator.text == "1 / 6", "Page indicator should be '1 / 6'")

	hud.select_previous() # Wrap-around
	assert(hud.selected_index == 5, "Wrap-around should set index to 5 (Father's Photograph)")
	assert(hud.page_indicator.text == "6 / 6", "Page indicator should be '6 / 6'")

	# 7. Song Playback
	# Select song 2: Parlour Above the Clouds
	hud.selected_index = 2
	hud._update_selection()
	assert(hud.page_indicator.text == "3 / 6", "Page indicator should be '3 / 6'")

	hud.play_selected_song()
	await process_frame

	var bg: Node = root.get_node("/root/BackgroundMusic")
	assert(bg.get_active_song_id() == "parlour_clouds", "Active song ID should be 'parlour_clouds'")
	assert(abs(bg.pitch_scale - 0.88) < 0.01, "Song pitch should be 0.88 for Parlour Above the Clouds")
	assert(bg.playing, "BackgroundMusic should be actively playing")
	assert(hud.playing_badges[2].visible, "Playing badge for slot 2 should be visible")
	assert(not hud.playing_badges[0].visible, "Playing badge for slot 0 should be hidden")

	# 8. Close HUD
	hud.close_jukebox()
	await process_frame
	assert(not hud.visible, "JukeboxHUD should be hidden after close_jukebox()")
	assert(player.controls_enabled, "Player controls should be re-enabled after closing HUD")
	assert(bg.playing and bg.get_active_song_id() == "parlour_clouds", "Selected song should keep playing after HUD closes")

	# 8b. Test closing HUD with E key (interact / KEY_E input)
	jb.activate(hall)
	await process_frame
	await process_frame
	assert(hud.visible, "JukeboxHUD should be open again")
	assert(not player.controls_enabled, "Player controls disabled when HUD is open")

	# Simulate pressing E key event and frame processing
	var key_ev := InputEventKey.new()
	key_ev.pressed = true
	key_ev.keycode = KEY_E
	key_ev.physical_keycode = KEY_E
	hud._input(key_ev)
	hall._process(0.016)
	await process_frame
	hall._process(0.016)
	assert(not hud.visible, "JukeboxHUD should be closed after pressing E and not re-opened by _process")
	assert(player.controls_enabled, "Player controls should be re-enabled after pressing E to close")

	# 9. Verify ship room transitions retain jukebox song
	bg.play_ship()
	assert(bg.get_active_song_id() == "parlour_clouds", "play_ship() should retain custom jukebox song")
	assert(abs(bg.pitch_scale - 0.88) < 0.01, "play_ship() should retain custom pitch")

	bg.play_boiler()
	assert(abs(bg.pitch_scale - 1.0) < 0.01, "play_boiler() should reset pitch to 1.0")

	bg.play_ship()
	assert(bg.get_active_song_id() == "parlour_clouds", "Returning to ship should restore custom jukebox song")
	assert(abs(bg.pitch_scale - 0.88) < 0.01, "Returning to ship should restore custom pitch")

	print("JUKEBOX_TESTS_PASSED")
	quit()

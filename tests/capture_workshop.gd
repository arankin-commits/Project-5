extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	if root.get_node_or_null("CoreProgression") == null:
		var progression: Node = load("res://scripts/core_progression.gd").new()
		progression.name = "CoreProgression"
		root.add_child(progression)
	var workshop: Node2D = load("res://scenes/FlyingLibertyWorkshop.tscn").instantiate()
	root.add_child(workshop)
	await process_frame
	await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://reviews"))
	print("WORKSHOP_SCREENSHOT=", root.get_texture().get_image().save_png("res://reviews/workshop_playable.png"))
	var player: CharacterBody2D = workshop.get_node("Player")
	player.position = Vector2(800, 610)
	var camera: Camera2D = player.get_node("Camera2D")
	camera.reset_smoothing()
	camera.force_update_scroll()
	workshop.get_node("Interactions/PowerCoreTerminal").activate(workshop)
	await process_frame
	await process_frame
	print("CORE_TERMINAL_SCREENSHOT=", root.get_texture().get_image().save_png("res://reviews/workshop_core_skill_tree.png"))
	workshop.get_node("CoreTerminal")._select_skill("power_two")
	await process_frame
	await process_frame
	print("SKILL_TREE_SCREENSHOT=", root.get_texture().get_image().save_png("res://reviews/workshop_skill_tree.png"))
	quit()

extends SceneTree

const ROOM := preload("res://scripts/blockout_room.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var config := root.get_node("RunConfig")
	config.start_run("medium", {})
	var run = load("res://scenes/RoguelikeRun.tscn").instantiate()
	root.add_child(run)
	current_scene = run
	run.set_process(false)
	# Exercise the real loading path, including preview sprites and door selection.
	for biome in config.BIOME_DATA:
		config.biome = biome
		run._prepare_biome()
		run._load_room(0)
		var rewards: Array = run.rooms[0].exit_rewards
		check(rewards.size() == run.room.exit_positions.size(), biome + ": missing exit rewards")
		var seen := {}
		for i in rewards.size():
			var sprite: Sprite2D = run.room.get_node("ExitRewardPreview%d" % i)
			var region: Rect2 = sprite.texture.region
			check(region == ROOM.REWARD_ICONS[rewards[i]], biome + ": incorrect preview")
			check(not seen.has(region), biome + ": duplicate preview")
			seen[region] = true
		for i in rewards.size():
			run._load_room(0)
			run.state = "reward"
			run.reward_collected = true
			run.player.position = run.room.exit_positions[i]
			var expected: String = run.rooms[0].exit_rewards[i]
			check(run.try_advance(), biome + ": door did not advance")
			check(run.rooms[1].reward == expected, biome + ": destination reward differs from preview")
	# Collecting a core refreshes the actual door sprites and destination reward.
	for element in config.ELEMENTS:
		config.core_elements.clear()
		config.core_limit = 1
		run.rooms[0].reward = "core_" + element
		run._load_room(0)
		run.state = "reward"
		run.reward_choices = [{"id": "core_" + element}]
		check(run.choose_reward("core_" + element), "Core collection failed")
		check(run.rooms[0].exit_rewards[0] == "upgrade_" + element, "New upgrade missing from exits")
		var preview: Sprite2D = run.room.get_node("ExitRewardPreview0")
		check(preview.texture.region == ROOM.REWARD_ICONS["upgrade_" + element], "Upgrade sprite did not refresh")
		run.player.position = run.room.exit_positions[0]
		check(run.try_advance(), "Upgrade exit did not advance")
		check(run.rooms[1].reward == "upgrade_" + element, "Upgrade destination mismatch")
	# Cover artwork aliases with and without owned elemental cores.
	for owned in [[], ["lightning"], ["wind", "lightning"]]:
		config.core_elements.assign(owned)
		config.core_limit = 3
		for seed_value in 100:
			config.run_seed = seed_value
			var rewards: Array[String] = run._generate_unique_exit_rewards(4, 0)
			check(rewards.size() == 4, "Missing generated rewards")
			var seen := {}
			for reward in rewards:
				var region: Rect2 = ROOM.REWARD_ICONS[reward]
				check(not seen.has(region), "Duplicate artwork: " + reward)
				seen[region] = true
	run.free()
	print("EXIT_REWARD_ICON_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)

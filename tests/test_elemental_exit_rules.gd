extends SceneTree

const RUN := preload("res://scripts/roguelike_run.gd")
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
	var progress := root.get_node("CoreProgression")
	progress.persistence_enabled = false
	var run := RUN.new()
	run.config = config
	run.rooms = [{"reward": "max_hp_increase"}]
	for capacity in [1, 2, 3]:
		progress.unlocked_skills.assign(["root"])
		if capacity >= 2:
			progress.unlocked_skills.append("power_two")
		if capacity == 3:
			progress.unlocked_skills.append("power_three")
		config.start_run("medium", {})
		check(config.core_limit == capacity, "Skill capacity mismatch")
		for owned_count in range(capacity + 1):
			config.core_elements.clear()
			for i in owned_count:
				config.pick_element(config.ELEMENTS[i])
			for pending in ["max_hp_increase", "core_xp", "core_fire", "core_water", "core_lightning"]:
				run.rooms[0].reward = pending
				var reserved := 1 if config.is_element_reward(pending) and not config.core_elements.has(pending.trim_prefix("core_")) else 0
				var observed := {}
				for seed_value in 100:
					config.run_seed = seed_value
					var rewards := run._generate_unique_exit_rewards(4, 0)
					check(rewards.size() == 4, "Missing exit choices")
					for reward in rewards:
						observed[reward] = true
						var icon: Rect2 = ROOM.REWARD_ICONS[reward]
						# Check actual artwork, so aliases cannot bypass eligibility.
						for element in ["fire", "water", "lightning", "wind", "ice", "earth"]:
							if icon == ROOM.REWARD_ICONS["core_" + element]:
								check(config.ELEMENTS.has(element) and owned_count + reserved < capacity and not config.core_elements.has(element) and pending != "core_" + element, "Ineligible elemental icon: " + reward)
							if icon == ROOM.REWARD_ICONS["upgrade_" + element]:
								check(config.core_elements.has(element), "Unowned upgrade icon: " + reward)
				for element in config.core_elements:
					check(observed.has("upgrade_" + element), "Owned upgrade never offered")
				if owned_count + reserved < capacity:
					for element in config.available_elements():
						if pending != "core_" + element:
							check(observed.has("core_" + element), "Eligible core never offered")
	check(not config.is_element_reward("core_xp"), "Core XP misclassified")
	# No run may go ten chambers without an upgrade offer after acquiring a core.
	config.core_elements.assign(["fire"])
	config.core_limit = 1
	run.rooms.clear()
	for i in 10:
		run.rooms.append({"reward": "max_hp_increase"})
	for seed_value in 100:
		config.run_seed = seed_value
		var drought := 0
		for index in 10:
			var rewards := run._generate_unique_exit_rewards(2, index)
			drought = 0 if rewards.has("upgrade_fire") else drought + 1
			check(drought < 3, "Upgrade offer drought exceeded two rooms")
	run.free()
	print("ELEMENTAL_EXIT_CHECKS=", checks, " FAILURES=", failures)
	quit(1 if failures else 0)

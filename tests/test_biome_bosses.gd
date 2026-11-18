extends SceneTree

const ROGUELIKE_RUN := preload("res://scenes/RoguelikeRun.tscn")
const BIOME_BOSS := preload("res://scripts/biome_boss.gd")

var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: %s" % message)
	else:
		failures += 1
		push_error("FAIL: %s" % message)
		print("FAIL: %s" % message)

func frames(count: int) -> Signal:
	return create_timer(count * (1.0 / 60.0)).timeout

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("--- Running Biome Bosses Tests ---")
	
	var expected_bosses := {
		"maintenance": {
			"name": "OVERSEER SERAPH",
			"health": 3750.0,
			"phase_sub": "EMERGENCY PROTOCOL"
		},
		"factory": {
			"name": "FOUNDRY TYRANT",
			"health": 5000.0,
			"phase_sub": "ACCELERATED LINE"
		},
		"boiler": {
			"name": "MAGMA COLOSSUS",
			"health": 5000.0,
			"phase_sub": "OVERPRESSURE"
		},
		"toxin_refinery": {
			"name": "VENOM COIL LEVIATHAN",
			"health": 5000.0,
			"phase_sub": "FEEDING FRENZY"
		}
	}
	
	# Test 1: Direct configuration and stat checks for all 4 bosses
	for biome in expected_bosses.keys():
		var exp_data: Dictionary = expected_bosses[biome]
		var boss_inst := BIOME_BOSS.new()
		boss_inst.configure_boss(biome)
		root.add_child(boss_inst)
		await frames(1)
		
		check(boss_inst.display_name == exp_data["name"], "%s boss name must be '%s', got '%s'" % [biome, exp_data["name"], boss_inst.display_name])
		check(is_equal_approx(boss_inst.health, exp_data["health"]), "%s boss health must be %f, got %f" % [biome, exp_data["health"], boss_inst.health])
		check(is_equal_approx(boss_inst.max_health, exp_data["health"]), "%s boss max_health must be %f, got %f" % [biome, exp_data["health"], boss_inst.max_health])
		check(boss_inst.phase_subtitle == exp_data["phase_sub"], "%s boss phase subtitle must be '%s', got '%s'" % [biome, exp_data["phase_sub"], boss_inst.phase_subtitle])
		check(boss_inst.idle_texture != null, "%s boss idle texture must load successfully" % biome)
		check(boss_inst.attack_texture != null, "%s boss attack texture must load successfully" % biome)
		check(boss_inst.kind == "boss", "%s boss kind must be 'boss'" % biome)
		
		# Test attack cycle
		for move_num in 4:
			boss_inst._begin_attack()
			check(boss_inst.state == "windup", "%s boss move %d must enter windup" % [biome, move_num])
			check(boss_inst.attack_move == (move_num + 1) % 4, "%s boss move index must match cycle" % biome)
			boss_inst._release_attack()
			check(boss_inst.state in ["chase", "charge"], "%s boss move %d must transition to chase or charge" % [biome, move_num])
		
		boss_inst.queue_free()
		await frames(1)
	
	# Test 2: In-run spawning and HUD integration
	var run: Node = ROGUELIKE_RUN.instantiate()
	root.add_child(run)
	await frames(3)
	
	for biome in ["maintenance", "factory", "boiler", "toxin_refinery"]:
		run.config.biome = biome
		run._prepare_biome()
		await frames(2)
		
		var exp_data: Dictionary = expected_bosses[biome]
		var boss_node := BIOME_BOSS.new()
		boss_node.configure_boss(biome)
		boss_node.target = run.player
		boss_node.room = run.room
		run.boss = boss_node
		run.enemies.add_child(boss_node)
		await frames(2)
		
		check(is_instance_valid(run.boss), "Run boss must be active for biome %s" % biome)
		check(run.boss.display_name == exp_data["name"], "Run boss display_name must be '%s'" % exp_data["name"])
		check(is_equal_approx(run.boss.max_health, exp_data["health"]), "Run boss health must be %f in %s" % [exp_data["health"], biome])
		
		# HUD integration check
		run.hud.set_boss(run.boss)
		check(run.hud.boss_box.visible, "Boss HUD bar must be visible")
		check(run.hud.boss_bar.max_value == exp_data["health"], "Boss HUD max_value must match boss max_health")
		check(run.hud.boss_title.text.begins_with(exp_data["name"]), "Boss HUD title must begin with boss name")
		
		# Phase two transition
		run.boss.take_damage(exp_data["health"] * 0.55)
		check(run.boss.phase_two, "Boss must enter phase two at <= 50%% HP")
		run.hud.set_boss(run.boss)
		check(run.hud.boss_title.text.contains(exp_data["phase_sub"]), "Boss HUD title must display phase subtitle '%s'" % exp_data["phase_sub"])
		
		boss_node.queue_free()
		run.boss = null
		await frames(2)
	
	run.queue_free()
	await frames(2)
	
	print("--- Biome Bosses Tests Completed ---")
	print("BIOME_BOSS_CHECKS=%d FAILURES=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)

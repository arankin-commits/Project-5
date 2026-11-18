extends SceneTree

const INDUSTRIAL_ENEMY := preload("res://scripts/industrial_enemy.gd")
const BASE_ENEMY := preload("res://scripts/run_enemy.gd")

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAILURE: " + message)
	else:
		print("  PASS: " + message)

func _run() -> void:
	print("--- Running test_ranged_shooting.gd ---")
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies/industrial.json"))

	# Create a mock target (player)
	var player := CharacterBody2D.new()
	player.position = Vector2(0, 0)
	root.add_child(player)

	# 1. Test Sentry from run_enemy.gd
	var sentry := BASE_ENEMY.new()
	sentry.kind = "sentry"
	sentry.target = player
	root.add_child(sentry)

	sentry.position = Vector2(500, 0)
	check(sentry.attack_reach() == BASE_ENEMY.SCREEN_DISTANCE, "Sentry reach is SCREEN_DISTANCE (750)")
	check(sentry.position.distance_to(player.position) < sentry.attack_reach(), "Sentry within screen distance (500 < 750) can attack")

	sentry.position = Vector2(900, 0)
	check(sentry.position.distance_to(player.position) >= sentry.attack_reach(), "Sentry outside screen distance (900 >= 750) does not attack")

	# 2. Test Condensate Mortar (industrial_18, role="Projectile", moves=['lob', 'lob', 'cone'])
	var mortar := INDUSTRIAL_ENEMY.new()
	mortar.design = catalog["industrial_18"]
	mortar.target = player
	root.add_child(mortar)

	mortar.position = Vector2(600, 0)
	var mortar_reach := mortar.attack_reach()
	check(mortar_reach >= INDUSTRIAL_ENEMY.SCREEN_DISTANCE, "Mortar reach is at least SCREEN_DISTANCE at 600px range")
	var mortar_move_idx := mortar.choose_move(true)
	check(mortar_move_idx >= 0, "Mortar finds an available attack at 600px")
	check(str(mortar.moves[mortar_move_idx].kind) == "lob", "Mortar chooses 'lob' attack at 600px distance")
	mortar._begin_attack()
	check(mortar.state == "windup", "Mortar enters windup state at screen distance")
	check(mortar.attack_kind == "lob", "Mortar begins lob attack at screen distance")

	mortar.position = Vector2(1000, 0)
	check(mortar.attack_reach() < 1000, "Mortar does not attack beyond screen distance (1000px)")

	# 3. Test Inspection Wasp (industrial_00, kinds=['dash', 'shot', 'sidestep'])
	var wasp := INDUSTRIAL_ENEMY.new()
	wasp.design = catalog["industrial_00"]
	wasp.target = player
	root.add_child(wasp)

	wasp.position = Vector2(550, 0)
	var wasp_reach := wasp.attack_reach()
	check(wasp_reach >= INDUSTRIAL_ENEMY.SCREEN_DISTANCE, "Inspection Wasp attack_reach at 550px is >= SCREEN_DISTANCE")
	var wasp_move_idx := wasp.choose_move(true)
	check(wasp_move_idx >= 0, "Inspection Wasp finds attack at 550px")
	check(str(wasp.moves[wasp_move_idx].kind) == "shot", "Inspection Wasp prioritizes 'shot' at long range (550px)")
	wasp._begin_attack()
	check(wasp.state == "windup", "Wasp enters windup at 550px")
	check(wasp.attack_kind == "shot", "Wasp attack kind is 'shot'")
	check(float(wasp.current_move.reach) >= INDUSTRIAL_ENEMY.SCREEN_DISTANCE, "Wasp current_move.reach set to SCREEN_DISTANCE for long projectile flight")

	wasp.position = Vector2(950, 0)
	check(wasp.position.distance_to(player.position) >= wasp.attack_reach(), "Wasp does not shoot when beyond screen distance (950px)")

	# 4. Test Pure Melee Enemy: Shearblade (industrial_11, kinds=['combo', 'cone', 'dash'])
	var shearblade := INDUSTRIAL_ENEMY.new()
	shearblade.design = catalog["industrial_11"]
	shearblade.target = player
	root.add_child(shearblade)

	shearblade.position = Vector2(500, 0)
	check(shearblade.attack_reach() < 500, "Melee enemy (Shearblade) reach at 500px is not boosted to screen distance")
	check(shearblade.choose_move(true) == -1, "Melee enemy has no valid attack at 500px")

	shearblade.position = Vector2(50, 0)
	check(shearblade.attack_reach() >= 50, "Melee enemy can attack at melee range (50px)")
	check(shearblade.choose_move(true) >= 0, "Melee enemy chooses attack at melee range (50px)")

	# Clean up
	player.queue_free()
	sentry.queue_free()
	mortar.queue_free()
	wasp.queue_free()
	shearblade.queue_free()
	await process_frame

	print("--- RANGED_SHOOTING_CHECKS=%d FAILURES=%d ---" % [checks, failures])
	quit(1 if failures > 0 else 0)

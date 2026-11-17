extends SceneTree

var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _run() -> void:
	for room_name in ["MainHall","Cockpit","SyncChamber","Workshop"]:
		change_scene_to_file("res://scenes/FlyingLiberty%s.tscn" % room_name)
		await scene_changed
		var player = current_scene.player
		for animation in ["idle","walk","run"]:
			check(player.visual.sprite_frames.get_frame_count(animation) == 8,"Missing MC frames for " + animation)
			for frame in 8:
				var texture = player.visual.sprite_frames.get_frame_texture(animation,frame)
				check(texture is AtlasTexture and texture.atlas.resource_path.begins_with("res://characters/MC/"),"Old ship artwork still in use for " + animation)
		player.facing = Vector2.UP
		player._face_idle()
		check(player.visual.frame == 4 and not player.visual.flip_h,"Back-facing idle missing")
		player.facing = Vector2.LEFT
		player._face_idle()
		check(player.visual.frame == 6,"Left-facing idle missing")
		player.visual.play("walk")
		check(player.visual.material.get_shader_parameter("clean_walk"),"Walk background filter missing")
		player.visual.play("run")
		check(not player.visual.material.get_shader_parameter("clean_walk"),"Walk filter applied to run art")
		player.visual.play("idle")
		check(not player.visual.material.get_shader_parameter("clean_walk"),"Walk filter applied to standing art")

		# Test running when holding space while moving
		Input.action_press("move_right")
		await physics_frame
		check(player.visual.animation == "walk", "Moving without space should walk")
		check(is_equal_approx(player.velocity.x, player.speed), "Velocity should match walk speed")
		check(not player.is_running, "is_running should be false while walking")

		Input.action_press("dash")
		await physics_frame
		check(player.visual.animation == "run", "Holding space while moving should run")
		check(is_equal_approx(player.velocity.x, player.run_speed), "Velocity should match run speed")
		check(player.is_running, "is_running should be true while running")

		Input.action_release("dash")
		await physics_frame
		check(player.visual.animation == "walk", "Releasing space should return to walk")
		check(is_equal_approx(player.velocity.x, player.speed), "Velocity should return to walk speed")
		check(not player.is_running, "is_running should be false after releasing space")

		Input.action_release("move_right")
		await physics_frame
		check(player.visual.animation == "idle", "Stopping movement should return to idle")
		check(player.velocity == Vector2.ZERO, "Velocity should be zero when stopped")
	print("SHIP_MC_FAILURES=",failures)
	quit(1 if failures else 0)

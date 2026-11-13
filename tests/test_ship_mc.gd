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
		for animation in ["idle","walk"]:
			check(player.visual.sprite_frames.get_frame_count(animation) == 8,"Missing MC frames")
			for frame in 8:
				var texture = player.visual.sprite_frames.get_frame_texture(animation,frame)
				check(texture is AtlasTexture and texture.atlas.resource_path.begins_with("res://characters/MC/"),"Old ship artwork still in use")
		player.facing = Vector2.UP
		player._face_idle()
		check(player.visual.frame == 4 and not player.visual.flip_h,"Back-facing idle missing")
		player.facing = Vector2.LEFT
		player._face_idle()
		check(player.visual.frame == 6,"Left-facing idle missing")
		player.visual.play("walk")
		check(player.visual.material.get_shader_parameter("clean_walk"),"Walk background filter missing")
		player.visual.play("idle")
		check(not player.visual.material.get_shader_parameter("clean_walk"),"Walk filter applied to standing art")
	print("SHIP_MC_FAILURES=",failures)
	quit(1 if failures else 0)

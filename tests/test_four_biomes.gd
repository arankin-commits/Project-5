extends SceneTree

const ROOM := preload("res://scripts/blockout_room.gd")
const POOL := preload("res://scripts/room_pool.gd")
const SPACE := preload("res://scripts/boiler_space.gd")
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
	var all_ids := {}
	for biome in ["maintenance","factory","boiler","toxin_refinery"]:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(config.BIOME_DATA[biome]))
		check(data.rooms.size() == 30,"Biome must have 30 rooms: "+biome)
		var first_seen := {}
		for seed_value in 200:
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var selected := POOL.select_rooms(data,rng)
			var used := {}
			for i in selected.size():
				check(not used.has(selected[i].id),"Repeated room")
				used[selected[i].id] = true
				check(bool(selected[i].get("boss",false)) == (i == 8),"Boss must be ninth")
			check(selected.size() == 9,"Wrong room count")
			first_seen[selected[0].id] = true
		check(first_seen.size() == 30,"First-room pool excludes layouts: "+biome)
		for definition in data.rooms:
			var filter := ""
			for argument in OS.get_cmdline_user_args():
				if argument.begins_with("--room="):
					filter = argument.trim_prefix("--room=")
			if not filter.is_empty() and definition.id != filter:
				continue
			check(not all_ids.has(definition.id),"Room ID repeats across biomes")
			all_ids[definition.id] = true
			definition.exit_rewards = ["repair","hull","power"]
			var room := ROOM.new()
			root.add_child(room)
			room.build(definition)
			await physics_frame
			check(room.is_logical_free(SPACE.unproject(room.spawn_position),18),"Entry blocked: "+definition.id)
			for point in room.exit_positions:
				check(room.is_logical_free(SPACE.unproject(point),18),"Exit blocked: "+definition.id)
				check(room.path_between(room.spawn_position,point).size() > 1,"Exit disconnected: "+definition.id)
			var rng := RandomNumberGenerator.new()
			rng.seed = 42
			var points := room.safe_spawns(7,rng)
			check(points.size() == 7,"Not enough safe enemy spawns: "+definition.id)
			var icons := {}
			for child in room.get_children():
				if child is Sprite2D and str(child.name).begins_with("ExitRewardPreview"):
					var region: Rect2 = child.texture.region
					check(not icons.has(region),"Duplicate door icon: "+definition.id)
					icons[region] = true
			check(icons.size() == room.exit_positions.size(),"Missing door icon")
			room.free()
		print("BIOME_LAYOUTS_CHECKED=",biome)
	print("FOUR_BIOME_CHECKS=",checks," FAILURES=",failures)
	quit(1 if failures else 0)

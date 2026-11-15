extends SceneTree

const POOL := preload("res://scripts/room_pool.gd")
const SPACE := preload("res://scripts/boiler_space.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/maintenance/rooms.json"))
	var boiler: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/boiler/rooms.json"))
	var first_seen := {}
	var seen := {}
	for seed_value in 500:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var rooms := POOL.select_rooms(data,rng)
		var layouts := {}
		check(rooms.size() == 9, "Run must contain nine rooms")
		for i in rooms.size():
			check(not layouts.has(rooms[i].layout), "Repeated Maintenance layout at seed %d" % seed_value)
			layouts[rooms[i].layout] = true
			seen[rooms[i].layout] = true
			check(bool(rooms[i].get("boss",false)) == (i == 8), "Boss is not ninth")
		first_seen[rooms[0].layout] = true
		rng.seed = seed_value
		check(POOL.select_rooms(data,rng) == rooms, "Seed is not reproducible")
		var boiler_rooms := POOL.select_rooms(boiler,rng)
		var boiler_seen := {}
		for room in boiler_rooms:
			check(not boiler_seen.has(room.name), "Repeated Boiler room")
			boiler_seen[room.name] = true
	check(seen.size() == 15 and first_seen.size() == 15, "Not all sizes/layouts can be drawn, including first room")
	var config := root.get_node("RunConfig")
	config.start_run("medium",{})
	change_scene_to_file("res://scenes/RoguelikeRun.tscn")
	await scene_changed
	var run = current_scene
	run.rooms = data.rooms.duplicate(true)
	var smallest := INF
	var largest := 0.0
	for i in run.rooms.size():
		run._load_room(i)
		run.room.hazards_enabled = false
		for enemy in run.enemies.get_children():
			enemy.active = false
		await physics_frame
		await process_frame
		var room = run.room
		check(room.is_logical_free(SPACE.unproject(room.spawn_position),18), "Entry outside floor/inside machinery: %d" % i)
		check(room.spawn_position.x < 768, "First-room entry must be on bottom-left side: %d" % i)
		check(room.is_logical_free(SPACE.unproject(room.exit_position),18), "Exit outside floor/inside machinery: %d" % i)
		check(room.path_between(room.spawn_position,room.exit_position).size() > 1, "Exit unreachable: %d" % i)
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run.rooms[i].metadata))
		check(room.get_node("MaintenanceArtwork").texture.resource_path.contains("Maintenance_Rebuild_v2/rooms/"), "Wrong room background active")
		check(room.exit_positions.size() == meta.exits.size(), "Authored exit missing: %d" % i)
		for exit_point in room.exit_positions:
			check(room.is_logical_free(SPACE.unproject(exit_point),18), "Authored exit blocked: %d" % i)
			check(room.path_between(room.spawn_position,exit_point).size() > 1, "Authored exit unreachable: %d" % i)
			check(room.nearest_exit(exit_point).is_equal_approx(exit_point), "Nearest exit not selected: %d" % i)
		for j in room.obstacle_polygons.size():
			var center := Vector2.ZERO
			for point in room.obstacle_polygons[j]:
				center += point
			center /= room.obstacle_polygons[j].size()
			# A concave pit can wrap around a walkable platform; its average
			# vertex position can lie outside the pit. Pick an interior probe.
			if not Geometry2D.is_point_in_polygon(center,room.obstacle_polygons[j]):
				var polygon: PackedVector2Array = room.obstacle_polygons[j]
				for k in polygon.size():
					var edge := polygon[(k+1)%polygon.size()]-polygon[k]
					var middle := polygon[k]+edge*0.5
					for side in [-1,1]:
						var probe: Vector2 = middle+Vector2(-edge.y,edge.x).normalized()*5*side
						if Geometry2D.is_point_in_polygon(probe,polygon):
							center = probe
			check(not room.is_logical_free(SPACE.unproject(center),0), "Painted pit or machinery is walkable: %d" % i)
			var top: float = center.y
			for point in room.obstacle_polygons[j]:
				top = minf(top,point.y)
			run.player.position = Vector2(center.x,top-50)
			run.player.move_and_collide(center-run.player.position)
			check(not Geometry2D.is_point_in_polygon(run.player.position,room.obstacle_polygons[j]), "Player crossed a painted pit or machinery: %d" % i)
		run.player.position = room.spawn_position
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		var points: Array[Vector2] = room.safe_spawns(7,rng)
		check(points.size() == 7, "Insufficient safe spawn points: %d" % i)
		for point in points:
			check(room.is_logical_free(SPACE.unproject(point),50), "Spawn clips geometry: %d" % i)
			check(room.path_between(point,room.spawn_position).size() > 1, "Spawn disconnected from entry: %d" % i)
			for other in points:
				check(point == other or point.distance_to(other) >= 50, "Spawned enemy bodies overlap: %d" % i)
		for point in room.vents:
			check(room.is_logical_free(SPACE.unproject(point),0), "Hazard outside playable floor: %d" % i)
		if i < 3:
			for spawn_seed in 32:
				rng.seed = spawn_seed
				check(room.safe_spawns(7,rng).size() == 7, "Small-room spawn capacity failed at layout %d seed %d" % [i,spawn_seed])
		var area: float = room.world_bounds.get_area()
		smallest = minf(smallest,area)
		largest = maxf(largest,area)
		print("LAYOUT_",i," SIZE=",room.world_bounds.size," SPAWNS=",points.size())
	check(largest > smallest*2, "Large rooms were normalized to small-room size")
	run.queue_free()
	await process_frame
	print("ROOM_POOL_CHECKS=",checks," FAILURES=",failures)
	quit(1 if failures else 0)

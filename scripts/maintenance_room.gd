extends "res://scripts/boiler_room.gd"

const HAZARD_SHEET := preload("res://rooms/Hazards/Maintenance.png")
const ICON_SHEET := preload("res://rooms/Room Exit Icons/Steampunk Reward Icon Atlas.png")
const PAINTED_ROOMS := preload("res://rooms/Maintenance_Rebuild_v2/art pass/Flying Liberty Maintenance Room Set-2.png")
const PAINTED_FANS := preload("res://rooms/Maintenance_Rebuild_v2/art pass/Steampunk Maintenance Fan Modules-1.png")

var floor_polygon := PackedVector2Array()
var obstacle_polygons: Array[PackedVector2Array] = []
var layout: Dictionary
var hazard_sprites: Array[Sprite2D] = []
var hazard_tick := 0.0
var preview: Label
var world_bounds := Rect2()
var exit_positions: Array[Vector2] = []
var exit_previews: Array[Label] = []

func source_point(point: Vector2) -> Vector2:
	return Vector2(768,620) + (point - Vector2(layout.center)) * float(layout.scale)

func crop_texture(sheet: Texture2D, region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	texture.region = region
	texture.filter_clip = true
	return texture

func _points(values: Array) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for value in values:
		result.append(Vector2(value[0],value[1]))
	return result

func _load_layout(data: Dictionary) -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(data.metadata))
	var size := Vector2(meta.canvas_px[0],meta.canvas_px[1])
	layout = {"center":size*0.5,"scale":1.0,"crop":Rect2(Vector2.ZERO,size),"floor":[],"obstacles":[],"hazards":[]}
	for point in meta.world_polygon_px:
		layout.floor.append(_project_authored(Vector2(point[0],point[1]),size))
	for box in data.obstacles:
		var polygon: Array = []
		for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
			polygon.append(_project_authored((Vector2(box[0],box[1])+corner*Vector2(box[2],box[3]))*size,size))
		layout.obstacles.append(polygon)
	for door in meta.exits:
		var a := Vector2(door.wall_a_world_px[0],door.wall_a_world_px[1])
		var b := Vector2(door.wall_b_world_px[0],door.wall_b_world_px[1])
		exit_positions.append(source_point(_safe_source_point(_project_authored((a+b)*0.5,size))))
	layout.exit = exit_positions[0]-Vector2(768,620)+Vector2(layout.center)
	layout.entry = _safe_source_point(size*Vector2(0.25,0.65))
	for point in [Vector2(0.48,0.62),Vector2(0.65,0.65)]:
		layout.hazards.append(_safe_source_point(size*point))

func _project_authored(point: Vector2, size: Vector2) -> Vector2:
	var uv := point/size-Vector2(0.5,0.5)
	return Vector2(size.x*(0.5+0.56*uv.x-0.43*uv.y),size.y*(0.60+0.26*uv.x+0.33*uv.y))

func _source_free(point: Vector2) -> bool:
	var polygon := PackedVector2Array(layout.floor)
	if not Geometry2D.is_point_in_polygon(point,polygon):
		return false
	for i in polygon.size():
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point,polygon[i],polygon[(i+1)%polygon.size()])) * float(layout.scale) < 65:
			return false
	for obstacle in layout.obstacles:
		if Geometry2D.is_point_in_polygon(point,PackedVector2Array(obstacle)):
			return false
		for i in obstacle.size():
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point,obstacle[i],obstacle[(i+1)%obstacle.size()])) * float(layout.scale) < 40:
				return false
	return true

func _safe_source_point(desired: Vector2) -> Vector2:
	if _source_free(desired):
		return desired
	var nearest := desired
	var distance := INF
	var crop: Rect2 = layout.crop
	for x in range(int(crop.position.x), int(crop.end.x), 16):
		for y in range(int(crop.position.y), int(crop.end.y), 16):
			var candidate := Vector2(x, y)
			if candidate.distance_squared_to(desired) < distance and _source_free(candidate):
				nearest = candidate
				distance = candidate.distance_squared_to(desired)
	if distance < INF:
		var fine_min_x := maxi(int(crop.position.x), int(nearest.x) - 24)
		var fine_max_x := mini(int(crop.end.x), int(nearest.x) + 24)
		var fine_min_y := maxi(int(crop.position.y), int(nearest.y) - 24)
		var fine_max_y := mini(int(crop.end.y), int(nearest.y) + 24)
		for x in range(fine_min_x, fine_max_x, 2):
			for y in range(fine_min_y, fine_max_y, 2):
				var candidate := Vector2(x, y)
				if candidate.distance_squared_to(desired) < distance and _source_free(candidate):
					nearest = candidate
					distance = candidate.distance_squared_to(desired)
	else:
		for x in range(int(crop.position.x), int(crop.end.x), 2):
			for y in range(int(crop.position.y), int(crop.end.y), 2):
				var candidate := Vector2(x, y)
				if candidate.distance_squared_to(desired) < distance and _source_free(candidate):
					nearest = candidate
					distance = candidate.distance_squared_to(desired)
	assert(distance < INF, "Painted Maintenance room has no safe interior")
	return nearest

func build(data: Dictionary) -> void:
	definition = data
	_load_layout(data)
	y_sort_enabled = true
	var background := Polygon2D.new()
	background.name = "MaintenanceArtwork"
	background.texture = load(data.image)
	var map_material := ShaderMaterial.new()
	map_material.shader = MAP_TEXTURE
	background.material = map_material
	var rect: Rect2 = layout.crop
	var outline: Array = layout.get("art_outline",[rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	var pixels := PackedVector2Array()
	var world := PackedVector2Array()
	for point in outline:
		pixels.append(point)
		world.append(source_point(point))
	background.polygon = world
	background.uv = pixels
	background.z_index = -10
	add_child(background)
	for point in layout.floor:
		floor_polygon.append(source_point(point))
	world_bounds = Rect2(floor_polygon[0],Vector2.ZERO)
	for point in floor_polygon:
		world_bounds = world_bounds.expand(point)
	blockers.append(floor_polygon)
	for i in floor_polygon.size():
		var body := StaticBody2D.new()
		var collision := CollisionShape2D.new()
		var segment := SegmentShape2D.new()
		segment.a = floor_polygon[i]
		segment.b = floor_polygon[(i+1) % floor_polygon.size()]
		collision.shape = segment
		body.add_child(collision)
		add_child(body)
	for points in layout.get("obstacles",[]):
		var polygon := PackedVector2Array()
		for point in points:
			polygon.append(source_point(point))
		obstacle_polygons.append(polygon)
		blockers.append(polygon)
		var body := StaticBody2D.new()
		var collision := CollisionPolygon2D.new()
		collision.polygon = polygon
		body.add_child(collision)
		add_child(body)
	spawn_position = source_point(layout.entry)
	exit_position = source_point(layout.exit)
	for i in layout.hazards.size():
		var point := source_point(layout.hazards[i])
		vents.append(point)
		var art := Sprite2D.new()
		art.name = "ElectricalHazard%d" % i
		# Lower-row electrical hazards only; the crossed-out fan is excluded.
		art.texture = crop_texture(HAZARD_SHEET, Rect2(5,665,495,365) if i == 0 else Rect2(925,660,515,360))
		art.position = point
		art.scale = Vector2.ONE * 0.28
		art.z_index = -4
		add_child(art)
		hazard_sprites.append(art)
	_build_navigation()
	for point in exit_positions:
		_build_exit_preview(data,point)
	var marks := Node2D.new()
	marks.name = "FloorSignals"
	marks.z_index = -3
	marks.draw.connect(_draw_floor.bind(marks))
	add_child(marks)

func nearest_exit(point: Vector2) -> Vector2:
	var nearest := exit_positions[0]
	for candidate in exit_positions:
		if point.distance_squared_to(candidate) < point.distance_squared_to(nearest):
			nearest = candidate
	return nearest

func _build_exit_preview(data: Dictionary, point: Vector2) -> void:
	var fan := Polygon2D.new()
	fan.name = "PaintedFanExit"
	fan.texture = PAINTED_FANS
	var outline := PackedVector2Array([Vector2(0,320),Vector2(40,296),Vector2(42,251),Vector2(55,230),Vector2(55,90),Vector2(47,76),Vector2(52,57),Vector2(78,48),Vector2(80,20),Vector2(112,6),Vector2(188,24),Vector2(219,38),Vector2(225,62),Vector2(270,79),Vector2(295,41),Vector2(321,32),Vector2(351,41),Vector2(365,58),Vector2(515,85),Vector2(537,108),Vector2(567,143),Vector2(609,154),Vector2(610,116),Vector2(641,94),Vector2(673,104),Vector2(671,150),Vector2(715,158),Vector2(710,181),Vector2(688,199),Vector2(687,289),Vector2(711,299),Vector2(714,327),Vector2(701,337),Vector2(733,352),Vector2(732,375),Vector2(598,466),Vector2(0,344)])
	var right_wall := point.x > world_bounds.get_center().x
	var pixels := PackedVector2Array()
	var shape := PackedVector2Array()
	for pixel in outline:
		pixels.append(Vector2(1536-pixel.x,pixel.y) if right_wall else pixel)
		var local := (pixel-Vector2(380,420))*0.38
		shape.append(Vector2(-local.x,local.y) if right_wall else local)
	fan.uv = pixels
	fan.polygon = shape
	fan.position = point-Vector2(0,25)
	fan.z_index = -2
	add_child(fan)
	var icon := Sprite2D.new()
	icon.name = "ExitRewardPreview"
	var reward_region: Rect2 = Rect2(821,547,273,274)
	if data.has("exit_rewards") and not data.exit_rewards.is_empty():
		var reward_name: String = str(data.exit_rewards[0])
		var blockout_script = preload("res://scripts/blockout_room.gd")
		if blockout_script.REWARD_ICONS.has(reward_name):
			reward_region = blockout_script.REWARD_ICONS[reward_name]
	icon.texture = crop_texture(ICON_SHEET, reward_region)
	icon.position = point - Vector2(0,205)
	icon.scale = Vector2.ONE * 0.25
	icon.z_index = 5
	add_child(icon)
	preview = Label.new()
	preview.text = str(data.get("next_preview", "RETURN TO SHIP"))
	preview.position = point - Vector2(150,290)
	preview.size = Vector2(300,55)
	preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview.add_theme_font_size_override("font_size",16)
	preview.add_theme_color_override("font_shadow_color",Color.BLACK)
	preview.add_theme_constant_override("shadow_offset_x",2)
	preview.add_theme_constant_override("shadow_offset_y",2)
	preview.z_index = 5
	add_child(preview)
	exit_previews.append(preview)
	if data.get("final",false):
		fan.hide()
		icon.hide()
		preview.hide()

func is_logical_free(point: Vector2, clearance := 20.0) -> bool:
	var world := Space.project(point)
	if not Geometry2D.is_point_in_polygon(world,floor_polygon):
		return false
	for polygon in obstacle_polygons:
		if Geometry2D.is_point_in_polygon(world,polygon):
			return false
		for i in polygon.size():
			if world.distance_to(Geometry2D.get_closest_point_to_segment(world,polygon[i],polygon[(i+1)%polygon.size()])) < clearance:
				return false
	for i in floor_polygon.size():
		var nearest := Geometry2D.get_closest_point_to_segment(world,floor_polygon[i],floor_polygon[(i+1)%floor_polygon.size()])
		if world.distance_to(nearest) < clearance:
			return false
	return true

func _build_navigation() -> void:
	var bounds := Rect2(Space.unproject(floor_polygon[0]),Vector2.ZERO)
	for point in floor_polygon:
		bounds = bounds.expand(Space.unproject(point))
	var start := Vector2i((bounds.position / 40.0).floor()) - Vector2i.ONE
	var end := Vector2i((bounds.end / 40.0).ceil()) + Vector2i.ONE
	navigation.region = Rect2i(start,end-start)
	navigation.cell_size = Vector2(40,40)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for x in range(start.x,end.x):
		for y in range(start.y,end.y):
			navigation.set_point_solid(Vector2i(x,y),not is_logical_free(Vector2(x,y)*40,32))

func _nearest_cell(point: Vector2) -> Vector2i:
	var cell := Vector2i((Space.unproject(point)/40.0).round())
	if navigation.region.has_point(cell) and not navigation.is_point_solid(cell):
		return cell
	var best := navigation.region.position
	var distance := INF
	for x in range(navigation.region.position.x,navigation.region.end.x):
		for y in range(navigation.region.position.y,navigation.region.end.y):
			var candidate := Vector2i(x,y)
			if not navigation.is_point_solid(candidate) and Vector2(candidate-cell).length_squared() < distance:
				best = candidate
				distance = Vector2(candidate-cell).length_squared()
	return best

func camera_target(point: Vector2) -> Vector2:
	# Keep a fixed world scale. Larger floors scroll instead of being shrunk.
	var travel := (world_bounds.size - Vector2(1100,600)).max(Vector2.ZERO) * 0.5
	var center := world_bounds.get_center() - Vector2(0,100)
	return point.clamp(center-travel,center+travel)

func safe_spawns(count: int, rng: RandomNumberGenerator) -> Array[Vector2]:
	var choices: Array[Vector2] = []
	# Sample between navigation cells so narrow rooms retain enough clear space.
	for x in range(navigation.region.position.x*2,navigation.region.end.x*2):
		for y in range(navigation.region.position.y*2,navigation.region.end.y*2):
			var logical := Vector2(x,y)*20
			var point := Space.project(logical)
			if is_logical_free(logical,55) and point.distance_to(spawn_position) > 150 and path_between(point,spawn_position).size() > 1:
				choices.append(point)
	var result: Array[Vector2] = []
	for i in count:
		if choices.is_empty():
			break
		var pick := rng.randi_range(0,choices.size()-1)
		var selected := choices[pick]
		result.append(selected)
		for j in range(choices.size()-1,-1,-1):
			if choices[j].distance_to(selected) < 50:
				choices.remove_at(j)
	return result

func is_trap_active(index: int) -> bool:
	if not hazards_enabled:
		return false
	if trap_triggers.get(index, 0.0) > 0.0:
		return true
	var phase := fmod(elapsed + index * 1.1, 4.8)
	return phase >= 3.8

func _physics_process(delta: float) -> void:
	if not hazards_enabled:
		return
	elapsed += delta
	for i in vents.size():
		if trap_triggers.has(i) and trap_triggers[i] > 0.0:
			trap_triggers[i] = maxf(0.0, trap_triggers[i] - delta)
		if is_instance_valid(player) and ((player.position-vents[i])*Vector2(1,2)).length() < 65:
			trigger_trap(i, player)
	hazard_tick -= delta
	if hazard_tick > 0:
		return
	hazard_tick = 0.5
	for i in vents.size():
		if not is_trap_active(i):
			continue
		if is_instance_valid(player) and ((player.position-vents[i])*Vector2(1,2)).length() < 65:
			player.take_damage(8)
		var enemies := get_parent().get_node_or_null("Enemies")
		if enemies:
			for enemy in enemies.get_children():
				if ((enemy.position-vents[i])*Vector2(1,2)).length() < 65:
					enemy.take_damage(32, Vector2.ZERO, 12.0, hazard_damage_type(i))

func _draw_floor(canvas: Node2D) -> void:
	for i in vents.size():
		var phase := fmod(elapsed+i*1.1,4.8)
		var active := is_trap_active(i)
		var warning := hazards_enabled and (active or phase >= 2.6)
		hazard_sprites[i].modulate = Color.WHITE if active else Color(0.45,0.5,0.55)
		canvas.draw_set_transform(vents[i],0,Vector2(1,0.5))
		if warning:
			canvas.draw_circle(Vector2.ZERO,65,Color(0.3,0.7,1,0.3 if active else 0.12))
			canvas.draw_arc(Vector2.ZERO,65,0,TAU,40,Color("8bdfff"),3,true)
	if not definition.get("final",false):
		for point in exit_positions:
			canvas.draw_set_transform(point,0,Vector2(1,0.5))
			canvas.draw_arc(Vector2.ZERO,40,0,TAU,40,Color("6de4d7") if exit_enabled else Color("c77b54"),3,true)
		for label in exit_previews:
			label.modulate = Color.WHITE if exit_enabled else Color("dba986")
	canvas.draw_set_transform(Vector2.ZERO)
	if debug_enabled:
		for polygon in blockers:
			var closed := polygon.duplicate()
			closed.append(polygon[0])
			canvas.draw_polyline(closed,Color.GREEN,2)

func hazard_damage_type(_index: int) -> String:
	return "electricity"

extends "res://scripts/maintenance_room.gd"

const REWARD_ICONS := {
	"aether_cores": Rect2(0, 0, 273, 273),
	"core_xp": Rect2(273, 0, 274, 273),
	"permanent_info": Rect2(547, 0, 274, 273),
	"cds": Rect2(821, 0, 273, 273),
	"core_fire": Rect2(1094, 0, 274, 273),
	"core_ice": Rect2(1368, 0, 274, 273),
	"core_wind": Rect2(1642, 0, 274, 273),
	"core_earth": Rect2(0, 273, 273, 274),
	"core_lightning": Rect2(273, 273, 274, 274),
	"core_water": Rect2(547, 273, 274, 274),
	"temporary_info": Rect2(821, 273, 273, 274),
	"upgrade_fire": Rect2(1094, 273, 274, 274),
	"upgrade_ice": Rect2(1368, 273, 274, 274),
	"upgrade_wind": Rect2(1642, 273, 274, 274),
	"upgrade_earth": Rect2(0, 547, 273, 274),
	"upgrade_lightning": Rect2(273, 547, 274, 274),
	"upgrade_water": Rect2(547, 547, 274, 274),
	"max_hp_increase": Rect2(821, 547, 273, 274),
	"shop_room": Rect2(1094, 547, 274, 274),
	"trap_room": Rect2(1368, 547, 274, 274),
	"secret_room": Rect2(1642, 547, 274, 274),
	"repair": Rect2(821, 547, 273, 274),
	"hull": Rect2(0, 547, 273, 274),
	"power": Rect2(273, 547, 274, 274),
	"dash": Rect2(1642, 273, 274, 274),
	"speed": Rect2(1642, 0, 274, 273),
	"core_toxin": Rect2(821, 273, 273, 274),
	"upgrade_toxin": Rect2(547, 0, 274, 273),
	"weapon_upgrade": Rect2(1642, 547, 274, 274)
}
const REWARD_TEXT := {
	"repair": "+25 MAX HULL / REPAIR 25",
	"hull": "+25 MAX HULL / REPAIR 25",
	"power": "+20% STRIKE DAMAGE",
	"dash": "15% FASTER DASH RECHARGE",
	"speed": "+10% MOVEMENT SPEED",
	"weapon_upgrade": "WEAPON UPGRADE",
	"max_hp_increase": "+25 MAX HULL / REPAIR 25",
	"cds": "MUSIC CD",
	"core_xp": "+100 CORE XP",
	"aether_cores": "+1 AETHER GEAR",
	"trap_room": "TRAP SURVIVAL CHAMBER",
	"core_fire": "FIRE CORE",
	"core_water": "WATER CORE",
	"core_lightning": "LIGHTNING CORE",
	"core_ice": "ICE CORE",
	"core_wind": "WIND CORE",
	"core_earth": "EARTH CORE",
	"core_toxin": "TOXIN CORE",
	"upgrade_fire": "FIRE CORE UPGRADE",
	"upgrade_water": "WATER CORE UPGRADE",
	"upgrade_lightning": "LIGHTNING CORE UPGRADE",
	"upgrade_ice": "ICE CORE UPGRADE",
	"upgrade_wind": "WIND CORE UPGRADE",
	"upgrade_earth": "EARTH CORE UPGRADE",
	"upgrade_toxin": "TOXIN CORE UPGRADE"
}
var turret_cooldowns: Dictionary = {}
var trap_shots: Array[Dictionary] = []

var movement_only: Array[bool] = []
var reachable := {}
var painted_traps: Array[Sprite2D] = []
var painted_trap_indices: Array[int] = []
const TRAP_ART := {
	"maintenance": {"sheet": "res://rooms/Hazards/Maintenance.png", "regions": {
		"turret": Rect2(0, 0, 450, 650), "fan": Rect2(450, 0, 490, 650), "wires": Rect2(0, 650, 490, 390)}},
	"factory": {"sheet": "res://rooms/Hazards/Factory.png", "regions": {
		"saw": Rect2(0, 0, 440, 470), "tesla": Rect2(0, 480, 440, 560), "press": Rect2(440, 470, 300, 570)}},
	"boiler_room": {"sheet": "res://rooms/Hazards/Boiler Room.png", "regions": {
		"spinner": Rect2(0, 0, 780, 470), "spitter": Rect2(790, 60, 650, 370),
		"oven": Rect2(20, 490, 450, 520), "vent": Rect2(500, 590, 245, 150), "can": Rect2(1150, 600, 270, 380)}},
	"toxin_refinery": {"sheet": "res://rooms/Hazards/Toxin Refinery.png", "regions": {
		"acid": Rect2(65, 0, 360, 365), "spikes": Rect2(25, 390, 415, 280), "barrel": Rect2(80, 700, 320, 365)}}
}

func _project_pack(point: Vector2, size: Vector2) -> Vector2:
	return Vector2(size.x*0.5+(point.x-50)*0.51*size.x/100-(point.y-37)*0.45*size.x/74,
		size.y*0.535+(point.x-50)*0.19*size.y/100+(point.y-37)*0.37*size.y/74)

func _load_layout(data: Dictionary) -> void:
	var meta: Dictionary = data.geometry
	var size := Vector2(meta.pixel_size[0],meta.pixel_size[1])
	# Exclude the source PNG's title and design legend from the game view.
	layout = {"center":size*0.5,"scale":2.0,"crop":Rect2(0,size.y*0.12,size.x,size.y*0.72),"floor":[],"obstacles":[],"hazards":[]}
	# Pressure Nook's source neck needs additional character clearance.
	if data.id == "boi_05":
		layout.scale = 2.5
	for point in _points(meta.floor_polygon):
		layout.floor.append(_project_pack(point,size))
	for kind in ["obstacles","partial_cover","gaps"]:
		for item in meta[kind]:
			var polygon: Array[Vector2] = []
			if kind == "gaps":
				for point in _points(item.polygon):
					polygon.append(_project_pack(point,size))
			else:
				var center := Vector2(item.center[0],item.center[1])
				var half := Vector2(item.size[0],item.size[1])*0.5
				for corner in [Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]:
					polygon.append(_project_pack(center+corner*half,size))
			layout.obstacles.append(polygon)
			movement_only.append(kind != "obstacles")
	for door in meta.doors:
		var point := _clear_door_point(_project_pack(Vector2(door.approach[0],door.approach[1]),size))
		if door.role == "entrance":
			layout.entry = point
		else:
			exit_positions.append(source_point(point))
	layout.exit = (exit_positions[0]-Vector2(768,620))/float(layout.scale)+Vector2(layout.center)
	# Every authored trap participates in the same telegraphed hazard cycle.
	for hazard in meta.hazards:
		layout.hazards.append(_project_pack(Vector2(hazard.center[0],hazard.center[1]),size))

func _clear_door_point(desired: Vector2) -> Vector2:
	if _source_free(desired):
		return desired
	for radius in range(2,82,2):
		for direction in 32:
			var candidate := desired+Vector2.from_angle(direction*TAU/32)*radius
			if _source_free(candidate):
				return candidate
	return _safe_source_point(desired)

func build(data: Dictionary) -> void:
	super.build(data)
	var painted := preload("res://scripts/painted_biome_room.gd").new()
	painted.name = "PaintedEnvironment"
	add_child(painted)
	painted.build(self, data)
	get_node("MaintenanceArtwork").hide()
	for sprite in hazard_sprites:
		sprite.hide() # Biome-specific painted trap sprites replace this inherited art.
	_build_reference_hazards(data)
	var index := 0
	for child in get_children():
		if child is StaticBody2D and child.get_child(0) is CollisionPolygon2D:
			if movement_only[index]:
				child.collision_layer = 8
			index += 1

func _build_reference_hazards(data: Dictionary) -> void:
	var biome: String = str(data.geometry.biome)
	if not TRAP_ART.has(biome):
		return
	var sheet: Texture2D = load(TRAP_ART[biome].sheet)
	var size := Vector2(data.geometry.pixel_size[0], data.geometry.pixel_size[1])
	var active_index := -1
	for hazard in data.geometry.hazards:
		active_index += 1
		var timed: bool = hazard.type in ["wires", "tesla", "vent", "spikes"]
		if hazard.type in ["saw", "oven"]:
			# These atlas silhouettes interlock; a rectangular crop cuts the
			# machinery or includes the neighboring asset. Trace the outer edge.
			var outline := PackedVector2Array([Vector2(30, 350), Vector2(450, 0), Vector2(630, 0), Vector2(635, 145), Vector2(225, 470), Vector2(30, 425)]) if hazard.type == "saw" else PackedVector2Array([Vector2(0, 490), Vector2(465, 490), Vector2(465, 790), Vector2(855, 940), Vector2(855, 1040), Vector2(0, 1040)])
			var machine := Polygon2D.new()
			machine.name = "PaintedTrap_%s_%d" % [hazard.type, get_child_count()]
			machine.texture = sheet
			machine.uv = outline
			var local := PackedVector2Array()
			var anchor := Vector2(320, 350) if hazard.type == "saw" else Vector2(270, 920)
			for point in outline:
				local.append((point - anchor) * 0.25)
			machine.polygon = local
			machine.position = source_point(_project_pack(Vector2(hazard.center[0], hazard.center[1]), size))
			machine.z_index = -4
			add_child(machine)
			continue
		if TRAP_ART[biome].regions.has(hazard.type):
			var art := Sprite2D.new()
			var region: Rect2 = TRAP_ART[biome].regions[hazard.type]
			art.texture = crop_texture(sheet, region)
			art.name = "PaintedTrap_%s_%d" % [hazard.type, get_child_count()]
			art.scale = Vector2.ONE * (125.0 / region.size.x)
			art.position = source_point(_project_pack(Vector2(hazard.center[0], hazard.center[1]), size))
			art.offset.y = -region.size.y * (0.08 if timed else 0.28)
			art.z_index = -4
			add_child(art)
			painted_traps.append(art)
			painted_trap_indices.append(active_index)

func _draw_floor(canvas: Node2D) -> void:
	for j in painted_traps.size():
		var index := painted_trap_indices[j]
		painted_traps[j].modulate = Color.WHITE if index < 0 or is_trap_active(index) else Color(0.52, 0.57, 0.59)
		if str(painted_traps[j].name).begins_with("PaintedTrap_spikes_"):
			# The supplied sheet contains retracted, warning, and extended poses.
			var region := Rect2(25, 390, 415, 280)
			if is_trap_active(index):
				region = Rect2(985, 365, 440, 305)
			elif hazards_enabled and fmod(elapsed + index * 1.1, 4.8) >= 2.6:
				region = Rect2(495, 390, 420, 280)
			var atlas := painted_traps[j].texture as AtlasTexture
			if atlas.region != region:
				atlas.region = region
	# Match the reference's energy palette while retaining the exact damage footprint.
	var biome: String = str(definition.geometry.biome)
	var energy: Color = {"maintenance": Color("73e6ef"), "factory": Color("87bbff"),
		"boiler_room": Color("ff9a43"), "toxin_refinery": Color("c1ef60")}.get(biome, Color("73e6ef"))
	for i in vents.size():
		if hazard_kind(i) in ["turret", "fan"]:
			continue
		var active := is_trap_active(i)
		var phase := fmod(elapsed + i * 1.1, 4.8)
		var warning := hazards_enabled and (active or phase >= 2.6)
		canvas.draw_set_transform(vents[i], 0, Vector2(1, 0.5))
		# Small status lamps remain distinct from the full damage-radius warning.
		canvas.draw_circle(Vector2(0, 10), 4, energy if warning else Color("485459"))
		if warning:
			canvas.draw_circle(Vector2.ZERO, 65, Color(energy, 0.20 if active else 0.07))
			canvas.draw_arc(Vector2.ZERO, 65, 0, TAU, 48, energy, 2.5, true)
			if not active:
				canvas.draw_arc(Vector2.ZERO, 60, -PI / 2, -PI / 2 + TAU * clampf((phase - 2.6) / 1.2, 0, 1), 48, Color("fff0ce"), 3, true)
			else:
				for ray in 6:
					var angle := ray * TAU / 6 + elapsed * 2
					var tip := Vector2.from_angle(angle) * (30 + 12 * sin(elapsed * 19 + ray))
					if biome == "boiler_room":
						canvas.draw_line(tip, tip + Vector2(3 * sin(elapsed * 12 + ray), -28), Color(energy, 0.65), 4, true)
					elif biome == "toxin_refinery":
						canvas.draw_circle(tip, 3 + 2 * sin(elapsed * 8 + ray), Color(energy, 0.7))
					else:
						canvas.draw_polyline(PackedVector2Array([Vector2.ZERO, tip * 0.4 + Vector2(5, -8), tip * 0.65, tip]), Color(energy, 0.9), 2, true)
	draw_mechanical_traps(canvas)
	for point in exit_positions:
		if definition.get("final", false):
			break
		canvas.draw_set_transform(point, 0, Vector2(1, 0.5))
		var exit_color := Color("6de4d7") if exit_enabled else Color("c77b54")
		canvas.draw_arc(Vector2.ZERO, 40, 0, TAU, 40, exit_color, 3, true)
		for step in 3:
			var y := float(step * 13 - 18)
			canvas.draw_polyline(PackedVector2Array([Vector2(-9, y + 5), Vector2(0, y), Vector2(9, y + 5)]), Color(exit_color, 0.7), 2, true)
	for label in exit_previews:
		label.modulate = Color.WHITE if exit_enabled else Color("dba986")
	canvas.draw_set_transform(Vector2.ZERO)
	if debug_enabled:
		for polygon in blockers:
			var closed := polygon.duplicate()
			closed.append(polygon[0])
			canvas.draw_polyline(closed, Color.GREEN, 2)

func refresh_exit_previews(data: Dictionary) -> void:
	for child in get_children():
		if str(child.name).begins_with("ExitRewardPreview") or (child is Label and child in exit_previews):
			remove_child(child)
			child.queue_free()
	exit_previews.clear()
	for point in exit_positions:
		_build_exit_preview(data, point)

func _build_exit_preview(data: Dictionary, point: Vector2) -> void:
	if data.get("final",false):
		return
	var index := exit_positions.find(point)
	var reward: String = data.exit_rewards[index] if (data.has("exit_rewards") and index >= 0 and index < data.exit_rewards.size()) else "max_hp_increase"
	var icon := Sprite2D.new()
	icon.name = "ExitRewardPreview%d" % index
	var icon_rect: Rect2 = REWARD_ICONS.get(reward, REWARD_ICONS["max_hp_increase"])
	icon.texture = crop_texture(ICON_SHEET, icon_rect)
	icon.position = point-Vector2(0,90)
	icon.scale = Vector2.ONE*0.22
	icon.z_index = 5
	add_child(icon)
	var label := Label.new()
	label.text = str(data.get("next_preview","NEXT CHAMBER"))+"\n"+REWARD_TEXT.get(reward, "SALVAGE CACHE")
	label.position = point-Vector2(160,150)
	label.size = Vector2(320,50)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",14)
	label.add_theme_color_override("font_shadow_color",Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x",2)
	label.add_theme_constant_override("shadow_offset_y",2)
	label.z_index = 5
	add_child(label)
	exit_previews.append(label)

func _build_navigation() -> void:
	var bounds := Rect2(Space.unproject(floor_polygon[0]),Vector2.ZERO)
	for point in floor_polygon:
		bounds = bounds.expand(Space.unproject(point))
	var start := Vector2i((bounds.position / 20.0).floor()) - Vector2i.ONE
	var end := Vector2i((bounds.end / 20.0).ceil()) + Vector2i.ONE
	navigation.region = Rect2i(start,end-start)
	navigation.cell_size = Vector2(20,20)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for x in range(start.x,end.x):
		for y in range(start.y,end.y):
			navigation.set_point_solid(Vector2i(x,y),not is_logical_free(Vector2(x,y)*20,18))

	# Cache the entrance's connected component once for wave spawn selection.
	var start_cell := _nearest_cell(spawn_position)
	var pending: Array[Vector2i] = [start_cell]
	reachable[start_cell] = true
	var cursor := 0
	while cursor < pending.size():
		var cell := pending[cursor]
		cursor += 1
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var neighbor: Vector2i = cell+offset
			if navigation.region.has_point(neighbor) and not reachable.has(neighbor) and not navigation.is_point_solid(neighbor):
				reachable[neighbor] = true
				pending.append(neighbor)

func _nearest_cell(point: Vector2) -> Vector2i:
	var cell := Vector2i((Space.unproject(point)/20.0).round())
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

func path_between(from: Vector2, to: Vector2) -> PackedVector2Array:
	var ids := navigation.get_id_path(_nearest_cell(from),_nearest_cell(to))
	var path := PackedVector2Array()
	for id in ids:
		path.append(Space.project(Vector2(id)*20))
	return path

func safe_spawns(count: int, rng: RandomNumberGenerator) -> Array[Vector2]:
	var choices: Array[Vector2] = []
	# Sample between navigation cells so narrow rooms retain enough clear space.
	for x in range(navigation.region.position.x,navigation.region.end.x):
		for y in range(navigation.region.position.y,navigation.region.end.y):
			var logical := Vector2(x,y)*20
			var point := Space.project(logical)
			if is_logical_free(logical,55) and point.distance_to(spawn_position) > 150 and reachable.has(Vector2i(x,y)):
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


func hazard_damage_type(_index: int) -> String:
	match str(definition.geometry.biome):
		"boiler_room": return "fire"
		"toxin_refinery": return "water"
		"factory":
			return "electricity" if definition.geometry.hazards[_index].type == "tesla" else "regular"
	return "electricity"

func hazard_kind(index: int) -> String:
	return str(definition.geometry.hazards[index].type)

func uses_contact_damage(index: int) -> bool:
	return hazard_kind(index) not in ["turret", "fan"]

func is_trap_active(index: int) -> bool:
	if index >= 0 and index < vents.size() and hazard_kind(index) in ["wires", "turret", "fan"]:
		return hazards_enabled
	return super.is_trap_active(index)

func hazard_direction(index: int) -> Vector2:
	var angle := deg_to_rad(float(definition.geometry.hazards[index].get("direction_degrees", 0)))
	var size := Vector2(definition.geometry.pixel_size[0], definition.geometry.pixel_size[1])
	return (_project_pack(Vector2.from_angle(angle), size) - _project_pack(Vector2.ZERO, size)).normalized()

func hazard_targets() -> Array[CharacterBody2D]:
	var targets: Array[CharacterBody2D] = []
	if is_instance_valid(player):
		targets.append(player)
	var enemies := get_parent().get_node_or_null("Enemies")
	if enemies:
		for enemy in enemies.get_children():
			if enemy is CharacterBody2D and enemy.has_method("take_damage"):
				targets.append(enemy)
	return targets

func hazard_blocked(start: Vector2, finish: Vector2) -> bool:
	return not get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(to_global(start), to_global(finish), 1)).is_empty()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not hazards_enabled:
		trap_shots.clear()
		return
	var targets := hazard_targets()
	for i in vents.size():
		var direction := hazard_direction(i)
		match hazard_kind(i):
			"turret":
				turret_cooldowns[i] = float(turret_cooldowns.get(i, 0.8)) - delta
				if turret_cooldowns[i] <= 0:
					turret_cooldowns[i] = 1.5
					trap_shots.append({"position": vents[i], "direction": direction, "distance": 0.0})
			"fan":
				for target in targets:
					var offset := to_local(target.global_position) - vents[i]
					var forward := offset.dot(direction)
					if forward >= 0 and forward < 300 and absf(offset.cross(direction)) < 42 + forward * 0.2:
						if not hazard_blocked(vents[i], to_local(target.global_position)):
							target.move_and_collide(direction * 180.0 * delta)
	for j in range(trap_shots.size() - 1, -1, -1):
		var shot := trap_shots[j]
		var start: Vector2 = shot.position
		var finish: Vector2 = start + Vector2(shot.direction) * 320.0 * delta
		var wall := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(to_global(start), to_global(finish), 1))
		if not wall.is_empty():
			finish = to_local(wall.position)
		var victim: CharacterBody2D = null
		var nearest := INF
		for target in targets:
			var point := to_local(target.global_position)
			if Geometry2D.get_closest_point_to_segment(point, start, finish).distance_to(point) < 20:
				var distance := start.distance_to(point)
				if distance < nearest:
					nearest = distance
					victim = target
		if victim != null:
			if victim == player:
				victim.take_damage(8, null, true)
			else:
				victim.take_damage(32, Vector2.ZERO, 0.0, "regular")
		shot.position = finish
		shot.distance += 320.0 * delta
		if victim != null or not wall.is_empty() or shot.distance >= 700:
			trap_shots.remove_at(j)

func draw_mechanical_traps(canvas: Node2D) -> void:
	canvas.draw_set_transform(Vector2.ZERO)
	if not hazards_enabled:
		return
	for i in vents.size():
		var direction := hazard_direction(i)
		if hazard_kind(i) == "fan":
			var side := direction.orthogonal()
			for lane in range(-2, 3):
				var travel := fmod(elapsed * 180 + lane * 47, 270.0)
				var start := vents[i] + direction * travel + side * lane * (16 + travel * 0.04)
				canvas.draw_line(start, start + direction * 28, Color(0.65, 0.94, 1, 0.65), 2, true)
		elif hazard_kind(i) == "turret":
			canvas.draw_line(vents[i], vents[i] + direction * 65, Color("ffbf52"), 2, true)
	for shot in trap_shots:
		canvas.draw_line(shot.position - shot.direction * 16, shot.position, Color("ffbf52"), 4, true)
		canvas.draw_circle(shot.position, 5, Color("fff0ce"))

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
	"speed": Rect2(1642, 0, 274, 273)
}
const REWARD_TEXT := {
	"repair": "+25 MAX HULL / REPAIR 25",
	"hull": "+25 MAX HULL / REPAIR 25",
	"power": "+20% STRIKE DAMAGE",
	"dash": "15% FASTER DASH RECHARGE",
	"speed": "+10% MOVEMENT SPEED",
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
	"upgrade_fire": "FIRE CORE UPGRADE",
	"upgrade_water": "WATER CORE UPGRADE",
	"upgrade_lightning": "LIGHTNING CORE UPGRADE",
	"upgrade_ice": "ICE CORE UPGRADE",
	"upgrade_wind": "WIND CORE UPGRADE",
	"upgrade_earth": "EARTH CORE UPGRADE"
}
var movement_only: Array[bool] = []
var reachable := {}

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
	# Ground traps reuse the established timed damage pulse. Other drawn
	# machinery remains blockout art until its specialized behavior is added.
	for hazard in meta.hazards:
		if hazard.type in ["wires","tesla","vent","spikes"]:
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
	for sprite in hazard_sprites:
		sprite.hide() # The supplied background already draws its own hazards.
	var index := 0
	for child in get_children():
		if child is StaticBody2D and child.get_child(0) is CollisionPolygon2D:
			if movement_only[index]:
				child.collision_layer = 8
			index += 1

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


extends Node2D
## Painted modular environment fitted to the existing authored geometry.
## All nodes here are visual: the parent still owns collision and navigation.

const FLOOR_SHADER := preload("res://scripts/painted_floor.gdshader")
const SHEETS := {
	"maintenance": "res://art/painted_biomes/maintenance-atlas.png",
	"factory": "res://art/painted_biomes/factory-atlas.png",
	"boiler_room": "res://art/painted_biomes/boiler-atlas.png",
	"toxin_refinery": "res://art/painted_biomes/toxin-atlas.png"
}
const FLOOR := Rect2(53, 46, 423, 425)
const WALL := Rect2(550, 42, 435, 430)
const DOOR := Rect2(1041, 40, 469, 434)
const CRATES := Rect2(25, 530, 475, 465)
const MACHINE := Rect2(530, 520, 475, 475)
const SERVICE := Rect2(1028, 520, 500, 480)

var room: Node2D
var sheet: Texture2D
var geometry: Dictionary
var canvas_size: Vector2
var accent: Color
var refinery := false

func build(owner_room: Node2D, definition: Dictionary) -> void:
	room = owner_room
	geometry = definition.geometry
	canvas_size = Vector2(geometry.pixel_size[0], geometry.pixel_size[1])
	sheet = load(SHEETS[str(geometry.biome)])
	refinery = str(geometry.biome) == "toxin_refinery"
	accent = {"maintenance": Color("3fb6ba"), "factory": Color("b8502c"),
		"boiler_room": Color("e96520"), "toxin_refinery": Color("89ba26")}[str(geometry.biome)]
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var floor_points := PackedVector2Array()
	var floor_uv := PackedVector2Array()
	for p in geometry.floor_polygon:
		floor_points.append(_point(p))
		# Source canvases grow with room size; keep plate size constant in-world.
		floor_uv.append(Vector2(p[0], p[1]) * (canvas_size / Vector2(1280, 720)) * (448.0 / 24.0) * float(room.layout.scale) / 2.0)
	if refinery:
		var bounds: Rect2 = room.world_bounds.grow(1800)
		_liquid(PackedVector2Array([bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)]), -40)
	_build_depth(floor_points)
	var floor_art := Polygon2D.new()
	floor_art.name = "PaintedSteelFloor"
	floor_art.polygon = floor_points
	floor_art.uv = floor_uv
	floor_art.texture = sheet
	var material := ShaderMaterial.new()
	material.shader = FLOOR_SHADER
	material.set_shader_parameter("tile_region", Vector4(FLOOR.position.x, FLOOR.position.y, FLOOR.size.x, FLOOR.size.y))
	floor_art.material = material
	floor_art.z_index = -10
	add_child(floor_art)
	_build_walls(floor_points)
	_build_gaps()
	_build_cover()
	_build_doors()
	_build_atmosphere(floor_points)

func _point(p: Array) -> Vector2:
	return room.source_point(room._project_pack(Vector2(p[0], p[1]), canvas_size))

func _quad(points: PackedVector2Array, region: Rect2, depth: int, tint := Color.WHITE) -> Polygon2D:
	var art := Polygon2D.new()
	art.polygon = points
	art.texture = sheet
	art.uv = PackedVector2Array([region.position, Vector2(region.end.x, region.position.y), region.end, Vector2(region.position.x, region.end.y)])
	art.z_index = depth
	art.color = tint
	add_child(art)
	return art

func _solid(points: PackedVector2Array, color: Color, depth: int) -> void:
	var art := Polygon2D.new()
	art.polygon = points
	art.color = color
	art.z_index = depth
	add_child(art)

func _sprite(region: Rect2, point: Vector2, width: float, depth: int, tint := Color.WHITE) -> Sprite2D:
	var sprite := Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = region
	atlas.filter_clip = true
	sprite.texture = atlas
	sprite.position = point
	sprite.offset = Vector2(0, -region.size.y * 0.46)
	sprite.scale = Vector2.ONE * width / region.size.x
	sprite.modulate = tint
	sprite.z_index = depth
	add_child(sprite)
	return sprite

func _build_depth(points: PackedVector2Array) -> void:
	var shadow := points.duplicate()
	for i in shadow.size():
		shadow[i] += Vector2(20, 75)
	_solid(shadow, Color("070c10"), -25)
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		_quad(PackedVector2Array([a, b, b + Vector2(0, 64), a + Vector2(0, 64)]), FLOOR if refinery else WALL, -12, Color(0.30, 0.35, 0.38))
		# Narrow lit service openings below the walkable platform.
		var direction := b - a
		for j in range(1, int(direction.length() / 100)):
			var c := a + direction.normalized() * j * 100.0 + Vector2(0, 24)
			_solid(PackedVector2Array([c, c + Vector2(18, 0), c + Vector2(18, 30), c + Vector2(0, 30)]), Color(accent, 0.32), -11)

func _build_walls(points: PackedVector2Array) -> void:
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		var direction := (b - a).normalized()
		var distance := a.distance_to(b)
		var back := b.x < a.x and not refinery
		var height := 180.0 if back else 20.0
		var count := maxi(1, int(ceil(distance / 210.0)))
		for j in count:
			var start := a.lerp(b, float(j) / count)
			var end := a.lerp(b, float(j + 1) / count)
			var region := WALL if back else Rect2(FLOOR.position if refinery else WALL.position, Vector2(423, 65))
			_quad(PackedVector2Array([start - Vector2(0, height), end - Vector2(0, height), end, start]), region, -7)
			# Painted wall cap adds a visible thickness to the silhouette.
			var cap_offset := Vector2(direction.y, -direction.x) * 13.0
			_quad(PackedVector2Array([start - Vector2(0, height), end - Vector2(0, height), end - Vector2(0, height) + cap_offset, start - Vector2(0, height) + cap_offset]), Rect2(55 if refinery else 555, 45, 420, 60), -6, Color(0.8, 0.8, 0.8))
		# Large service machinery sits beyond the back wall, never in a route.
		if back and distance > 330:
			var center := (a + b) * 0.5
			_sprite(SERVICE, center + Vector2(0, 8), minf(distance * 0.65, 440), -8, Color(0.7, 0.75, 0.75))

func _build_gaps() -> void:
	for gap in geometry.gaps:
		var points := PackedVector2Array()
		for p in gap.polygon:
			points.append(_point(p))
		if refinery:
			_liquid(points, -9)
		else:
			_solid(points, Color("070e11"), -9)
		for i in points.size():
			var a := points[i]
			var b := points[(i + 1) % points.size()]
			_quad(PackedVector2Array([a, b, b + Vector2(0, 12), a + Vector2(0, 12)]), Rect2(55 if refinery else 550, 425, 420, 45), -8, Color(0.6, 0.6, 0.6))

func _build_cover() -> void:
	var serial := 0
	for kind in ["obstacles", "partial_cover"]:
		for item in geometry[kind]:
			var center := Vector2(item.center[0], item.center[1])
			var half := Vector2(item.size[0], item.size[1]) * 0.5
			var points := PackedVector2Array()
			for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				var p: Vector2 = center + corner * half
				points.append(_point([p.x, p.y]))
			var bounds := Rect2(points[0], Vector2.ZERO)
			for p in points:
				bounds = bounds.expand(p)
			var shadow := points.duplicate()
			for j in shadow.size():
				shadow[j] += Vector2(12, 10)
			_solid(shadow, Color(0, 0, 0, 0.38), -8)
			if kind == "partial_cover":
				var height := Vector2(0, 24)
				for j in [1, 2]:
					var k: int = (j + 1) % 4
					_quad(PackedVector2Array([points[j] - height, points[k] - height, points[k], points[j]]), Rect2(55 if refinery else 550, 360, 420, 112), -5)
				var top := points.duplicate()
				for j in top.size():
					top[j] -= height
				_quad(top, Rect2(55, 47, 210, 105), -5, Color(0.8, 0.8, 0.8))
			else:
				var region := MACHINE if serial % 3 == 2 and bounds.size.x > 115 else CRATES
				_sprite(region, bounds.get_center() + Vector2(0, bounds.size.y * 0.46), bounds.size.x * 1.08, -4)
			serial += 1

func _build_doors() -> void:
	for door in geometry.doors:
		var center := _point(door.mid)
		var a := _point(door.a)
		var b := _point(door.b)
		var direction := (b - a).normalized()
		if direction.x < 0:
			direction = -direction
		var half_width := minf(a.distance_to(b) * 0.42, 96)
		var left := center - direction * half_width
		var right := center + direction * half_width
		var door_region := Rect2(1020, 92, 490, 350) if refinery else DOOR
		_quad(PackedVector2Array([left - Vector2(0, 195), right - Vector2(0, 195), right, left]), door_region, -5)

func _build_atmosphere(points: PackedVector2Array) -> void:
	var center: Vector2 = room.world_bounds.get_center()
	if refinery:
		for door in geometry.doors:
			var edge := _point(door.mid)
			var outside := edge + center.direction_to(edge) * 220.0
			var tram := _sprite(SERVICE, outside + Vector2(0, 90), 420, -15, Color(0.8, 0.85, 0.8))
			tram.flip_h = outside.x > center.x
		return
	for i in points.size():
		if i % 3 != 0:
			continue
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		var middle := (a + b) * 0.5
		var outside := middle + center.direction_to(middle) * 180.0
		_sprite(MACHINE if i % 2 == 0 else SERVICE, outside + Vector2(0, 110), 350, -30, Color(0.12, 0.16, 0.18))

func _liquid(points: PackedVector2Array, depth: int) -> void:
	var surface := Polygon2D.new()
	surface.texture = sheet
	surface.polygon = points
	var uv := PackedVector2Array()
	for point in points:
		uv.append(point * Vector2(0.65, 1.1))
	surface.uv = uv
	surface.z_index = depth
	var material := ShaderMaterial.new()
	material.shader = FLOOR_SHADER
	material.set_shader_parameter("tile_region", Vector4(555, 48, 422, 420))
	material.set_shader_parameter("liquid", true)
	material.set_shader_parameter("surface_tint", Color(0.8, 0.85, 0.8))
	surface.material = material
	add_child(surface)

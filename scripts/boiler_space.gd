class_name BoilerSpace
extends RefCounted

# Logical deck coordinates are independent of painted pixels. Both floor axes
# use the same 2:1 oblique projection; sprites stay upright, never skewed.
const ORIGIN := Vector2(768, 272)
const AXIS_X := Vector2(0.724, 0.337)
const AXIS_Y := Vector2(-0.724, 0.337)
const MIN := 55.0
const MAX := 945.0

static func project(point: Vector2) -> Vector2:
	return ORIGIN + AXIS_X * point.x + AXIS_Y * point.y

static func unproject(point: Vector2) -> Vector2:
	var p := point - ORIGIN
	return Vector2((p.x / AXIS_X.x + p.y / AXIS_X.y) * 0.5, (p.y / AXIS_X.y - p.x / AXIS_X.x) * 0.5)

static func polygon(center: Vector2, half_size: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for corner in [Vector2(-1,-1), Vector2(1,-1), Vector2(1,1), Vector2(-1,1)]:
		result.append(project(center + corner * half_size))
	return result

static func atlas(cell: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = load("res://art/boiler/machinery_and_enemies.png")
	texture.region = Rect2((cell % 3) * 512, floori(cell / 3.0) * 512, 512, 512)
	return texture

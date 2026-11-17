extends CockpitInteractable
class_name CoreInteractable

@export var interaction_rect := Rect2(620, 455, 355, 125)
@export var interaction_polygon: PackedVector2Array = [
	Vector2(620, 455),
	Vector2(975, 455),
	Vector2(975, 580),
	Vector2(620, 580)
]

func closest_point(point: Vector2) -> Vector2:
	if interaction_polygon.size() >= 3:
		if Geometry2D.is_point_in_polygon(point, interaction_polygon):
			return point
		var closest := point
		var min_dist := INF
		for i in interaction_polygon.size():
			var p1 := interaction_polygon[i]
			var p2 := interaction_polygon[(i + 1) % interaction_polygon.size()]
			var proj := Geometry2D.get_closest_point_to_segment(point, p1, p2)
			var d := point.distance_to(proj)
			if d < min_dist:
				min_dist = d
				closest = proj
		return closest
	var cx := clampf(point.x, interaction_rect.position.x, interaction_rect.end.x)
	var cy := clampf(point.y, interaction_rect.position.y, interaction_rect.end.y)
	return Vector2(cx, cy)

func distance_to_point(point: Vector2) -> float:
	var closest := closest_point(point)
	global_position = closest
	return point.distance_to(closest)

func in_range(point: Vector2) -> bool:
	return distance_to_point(point) <= radius

func activate(room: Node) -> void:
	room.open_core_terminal()

func _process(_delta: float) -> void:
	var room := get_node_or_null("../..")
	if room != null and "player" in room and room.player != null:
		global_position = closest_point(room.player.global_position)

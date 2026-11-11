extends Node2D

var markers: Array[Dictionary] = []
var boundaries: Array[PackedVector2Array] = []
var enabled := false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_debug"):
		enabled = not enabled
		queue_redraw()

func _draw() -> void:
	if not enabled:
		return
	for polygon in boundaries:
		draw_polyline(polygon, Color(0.2, 1.0, 0.3, 0.9), 3.0, true)
	for marker in markers:
		var point: Vector2 = marker["position"]
		draw_circle(point, 5.0, Color(1.0, 0.3, 0.1))
		draw_line(point - Vector2(9, 0), point + Vector2(9, 0), Color.YELLOW, 2.0)
		draw_line(point - Vector2(0, 9), point + Vector2(0, 9), Color.YELLOW, 2.0)
		draw_string(ThemeDB.fallback_font, point + Vector2(10, -7), str(marker["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)

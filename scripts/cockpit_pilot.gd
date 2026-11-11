extends Node2D

func _draw() -> void:
	# Temporary independent NPC silhouette at the ChamberForge pilot marker.
	draw_circle(Vector2(0, -70), 12, Color("bb805c"))
	draw_rect(Rect2(-14, -84, 28, 9), Color("353c43"))
	draw_colored_polygon(PackedVector2Array([Vector2(-15,-57),Vector2(15,-57),Vector2(12,-28),Vector2(-12,-28)]), Color("476477"))
	draw_line(Vector2(-7,-27), Vector2(-7,0), Color("293446"), 8)
	draw_line(Vector2(7,-27), Vector2(7,0), Color("293446"), 8)
	draw_line(Vector2(-13,-51), Vector2(-20,-30), Color("bb805c"), 6)
	draw_line(Vector2(13,-51), Vector2(20,-30), Color("bb805c"), 6)

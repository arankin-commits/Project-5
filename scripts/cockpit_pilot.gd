extends Node2D

func _ready() -> void:
	# The pack has no distinct Pilot asset; use a separate sheet pose until one is supplied.
	var visual := Sprite2D.new()
	visual.name = "PilotVisual"
	visual.texture = load("res://art/characters/main_walk_0.png")
	visual.scale = Vector2(0.75, 0.75)
	visual.position.y = -39.0
	visual.modulate = Color(0.83, 0.9, 1.0)
	add_child(visual)

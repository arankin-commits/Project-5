extends Node2D

var lifetime := 0.35
var remaining := 0.35
var radius := 80.0
var direction := Vector2.RIGHT
var tint := Color("72f8e5")
var kind := "slash"

func _ready() -> void:
	remaining = lifetime
	z_index = 5

func _process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var progress := 1.0 - remaining/lifetime
	var color := tint
	color.a *= 1.0-progress
	if kind == "slash":
		draw_arc(Vector2(0,-15),radius*(0.6+progress*0.4),direction.angle()-0.9,direction.angle()+0.9,24,color,8*(1-progress)+1,true)
	elif kind == "burst":
		for i in 10:
			var radial := Vector2.from_angle(i*TAU/10)
			draw_line(radial*radius*progress,radial*(radius*progress+8),color,3,true)
	else:
		draw_set_transform(Vector2.ZERO,0,Vector2(1,0.5))
		draw_arc(Vector2.ZERO,radius*progress,0,TAU,48,color,5,true)

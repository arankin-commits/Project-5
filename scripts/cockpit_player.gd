extends CharacterBody2D

@export var speed := 220.0

func _ready() -> void:
	var shape := CapsuleShape2D.new()
	shape.radius = 12.0
	shape.height = 30.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position.y = -15.0
	add_child(collision)
	queue_redraw()

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	queue_redraw()

func _draw() -> void:
	# Temporary character drawn at the feet origin, independent of the room painting.
	draw_ellipse(Vector2(0, -2), 16.0, 5.5, Color(0.02, 0.01, 0.01, 0.4))
	draw_rect(Rect2(-10, -28, 8, 25), Color("273545"))
	draw_rect(Rect2(2, -28, 8, 25), Color("273545"))
	draw_colored_polygon(PackedVector2Array([Vector2(-15,-54),Vector2(15,-54),Vector2(13,-27),Vector2(-13,-27)]), Color("cf9a48"))
	draw_circle(Vector2(0,-63), 12, Color("e0b18a"))
	draw_rect(Rect2(-13,-75,26,8), Color("3b2525"))
	draw_line(Vector2(-12,-50), Vector2(-20,-30), Color("e0b18a"), 6)
	draw_line(Vector2(12,-50), Vector2(20,-30), Color("e0b18a"), 6)

extends CharacterBody2D

@export var speed := 220.0
@export_enum("main", "medium") var appearance := "main"
var controls_enabled := true
var visual: AnimatedSprite2D

func _ready() -> void:
	var shape := CapsuleShape2D.new()
	shape.radius = 12.0
	shape.height = 30.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position.y = -15.0
	add_child(collision)
	_build_visual()

func _build_visual() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_animation("walk")
	var prefix := "main_walk_"
	var frame_count := 8
	var frame_rate := 10.0
	if appearance == "medium":
		prefix = "medium_walk_"
		frame_count = 8
		frame_rate = 10.0
	for i in frame_count:
		var texture := load("res://art/characters/%s%d.png" % [prefix, i]) as Texture2D
		if texture != null:
			frames.add_frame("walk", texture)
			if i == 0:
				frames.add_frame("idle", texture)
	frames.set_animation_speed("walk", frame_rate)
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("idle", 1.0)
	visual = AnimatedSprite2D.new()
	visual.name = "CharacterVisual"
	visual.sprite_frames = frames
	visual.scale = Vector2(0.7, 0.7) if appearance == "medium" else Vector2(0.75, 0.75)
	visual.position.y = -22.0 if appearance == "medium" else -39.0
	add_child(visual)
	visual.play("idle")

func _physics_process(_delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	if direction != Vector2.ZERO:
		if visual.animation != "walk":
			visual.play("walk")
		if direction.x != 0.0:
			visual.flip_h = direction.x < 0.0
	elif visual.animation != "idle":
		visual.play("idle")

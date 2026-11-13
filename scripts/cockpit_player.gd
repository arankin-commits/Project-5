extends CharacterBody2D

@export var speed := 220.0
@export_enum("main", "medium") var appearance := "main"
var controls_enabled := true
var visual: AnimatedSprite2D
var facing := Vector2.DOWN
const MC_IDLE := "res://characters/MC/ChatGPT Image Nov 13, 2026, 01_04_23 AM-1.png"
const MC_WALK := "res://characters/MC/ChatGPT Image Nov 13, 2026, 01_04_24 AM-2.png"
const IDLE_BASELINES := [500,510,510,505,514,507,512,510]
const WALK_BASELINES := [522,520,531,520,530,531,530,526]

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
	for i in 8:
		if appearance == "main":
			for animation in ["idle","walk"]:
				var texture := AtlasTexture.new()
				texture.atlas = load(MC_IDLE if animation == "idle" else MC_WALK)
				texture.region = Rect2((i % 4) * 362, (i / 4) * 543, 362, 543)
				texture.filter_clip = true
				frames.add_frame(animation, texture)
		else:
			var texture := load("res://art/characters/medium_walk_%d.png" % i) as Texture2D
			frames.add_frame("walk", texture)
			if i == 0:
				frames.add_frame("idle", texture)
	frames.set_animation_speed("walk", 8.333)
	frames.set_animation_loop("walk", true)
	# Directional standing poses are selected explicitly, never cycled.
	frames.set_animation_speed("idle", 0.0)
	visual = AnimatedSprite2D.new()
	visual.name = "CharacterVisual"
	visual.sprite_frames = frames
	visual.scale = Vector2(0.7, 0.7) if appearance == "medium" else Vector2(0.22, 0.22)
	visual.position.y = -22.0 if appearance == "medium" else 0.0
	if appearance == "main":
		visual.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var shader := Shader.new()
		# The supplied walk PNG has a translucent checker matte (alpha ~0.5).
		# Its painted character is nearly opaque; discard the matte at draw time.
		shader.code = "shader_type canvas_item; uniform bool clean_walk = false; varying vec4 tint; void vertex(){tint=COLOR;} void fragment(){vec4 c=texture(TEXTURE,UV); if(clean_walk){c.a=smoothstep(0.80,0.96,c.a);} COLOR=c*tint;}"
		var material := ShaderMaterial.new()
		material.shader = shader
		visual.material = material
		visual.frame_changed.connect(_align_visual)
		visual.animation_changed.connect(_align_visual)
	add_child(visual)
	visual.play("idle")
	_align_visual()

func _align_visual() -> void:
	if appearance != "main":
		return
	var walking := visual.animation == "walk"
	var baseline: float = WALK_BASELINES[visual.frame] if walking else IDLE_BASELINES[visual.frame]
	visual.offset = Vector2(0,271.5-baseline)
	visual.material.set_shader_parameter("clean_walk",walking)

func _face_idle() -> void:
	if appearance == "main":
		visual.flip_h = false
		var direction_index := posmod(roundi(facing.angle() / (PI / 4.0)),8)
		visual.frame = [2,1,0,7,6,5,4,3][direction_index]

func _physics_process(_delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	if direction != Vector2.ZERO:
		facing = direction
		if visual.animation != "walk":
			visual.play("walk")
		if direction.x != 0.0:
			visual.flip_h = direction.x < 0.0
	else:
		if visual.animation != "idle":
			visual.play("idle")
		_face_idle()

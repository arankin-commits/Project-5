extends CharacterBody2D

@export var speed := 220.0
@export var run_speed := 360.0
@export_enum("main", "medium") var appearance := "main"
var controls_enabled := true
var is_running := false
var visual: AnimatedSprite2D
var facing := Vector2.DOWN
const MC_IDLE := "res://characters/MC/ChatGPT Image Nov 13, 2026, 01_04_23 AM-1.png"
const MC_WALK := "res://characters/MC/ChatGPT Image Nov 13, 2026, 01_04_24 AM-2.png"
const MC_RUN := "res://characters/MC/ChatGPT Image Nov 13, 2026, 01_04_26 AM-3.png"
const IDLE_BASELINES := [500,510,510,505,514,507,512,510]
const WALK_BASELINES := [522,520,531,520,530,531,530,526]
const RUN_BASELINES := [525,526,526,526,527,526,527,526]

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
	frames.add_animation("run")
	for i in 8:
		if appearance == "main":
			for animation in ["idle","walk","run"]:
				var texture := AtlasTexture.new()
				var atlas_path := MC_IDLE
				if animation == "walk":
					atlas_path = MC_WALK
				elif animation == "run":
					atlas_path = MC_RUN
				texture.atlas = load(atlas_path)
				texture.region = Rect2((i % 4) * 362, (i / 4) * 543, 362, 543)
				texture.filter_clip = true
				frames.add_frame(animation, texture)
		else:
			var texture := load("res://art/characters/medium_walk_%d.png" % i) as Texture2D
			frames.add_frame("walk", texture)
			if i < 6:
				var dash_texture := load("res://art/characters/medium_dash_%d.png" % i) as Texture2D
				frames.add_frame("run", dash_texture)
			else:
				frames.add_frame("run", texture)
			if i == 0:
				frames.add_frame("idle", texture)
	frames.set_animation_speed("walk", 8.333)
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("run", 12.5)
	frames.set_animation_loop("run", true)
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
	var baseline: float
	if visual.animation == "run":
		baseline = RUN_BASELINES[visual.frame]
	elif walking:
		baseline = WALK_BASELINES[visual.frame]
	else:
		baseline = IDLE_BASELINES[visual.frame]
	visual.offset = Vector2(0, 271.5 - baseline)
	visual.material.set_shader_parameter("clean_walk", walking)

func _face_idle() -> void:
	if appearance == "main":
		visual.flip_h = false
		var direction_index := posmod(roundi(facing.angle() / (PI / 4.0)),8)
		visual.frame = [2,1,0,7,6,5,4,3][direction_index]

func _physics_process(_delta: float) -> void:
	if not controls_enabled:
		is_running = false
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var holding_space := Input.is_action_pressed("dash") or Input.is_physical_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SPACE)
	is_running = holding_space and direction != Vector2.ZERO
	var active_speed := run_speed if is_running else speed
	velocity = direction * active_speed
	move_and_slide()
	if direction != Vector2.ZERO:
		facing = direction
		var target_animation := "run" if is_running else "walk"
		if visual.animation != target_animation:
			visual.play(target_animation)
		if direction.x != 0.0:
			visual.flip_h = direction.x < 0.0
	else:
		if visual.animation != "idle":
			visual.play("idle")
		_face_idle()

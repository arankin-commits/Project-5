extends Node2D

# All temporary attacks live in the run's Projectiles container and clear with it.
var source: CharacterBody2D
var target: CharacterBody2D
var spec: Dictionary = {}
var direction := Vector2.RIGHT
var age := 0.0
var tick := 0.0
var struck := false
var previous_radius := 0.0
var elapsed_active := 0.0

func blocked(from: Vector2, to: Vector2) -> bool:
	return not get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(from,to,1)).is_empty()

func contains(point: Vector2) -> bool:
	var offset := point-global_position
	var radius := float(spec.get("radius",spec.get("reach",90)))
	match str(spec.kind):
		"cone":
			return offset.length() <= radius+13 and (offset.length() < 15 or offset.normalized().dot(direction) >= cos(deg_to_rad(float(spec.get("arc",90))*.5)))
		"ring":
			var front := radius*clampf(elapsed_active/.45,0,1)
			return offset.length() <= front+17 and offset.length() >= previous_radius-17
		"pool":
			return offset.length() <= radius and (not spec.has("arc") or offset.normalized().dot(direction) >= cos(deg_to_rad(float(spec.arc)*.5)))
	return offset.length() <= radius+13

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target) or not is_instance_valid(source) or source.health <= 0:
		queue_free()
		return
	age += delta
	queue_redraw()
	var delay := float(spec.get("delay",0))
	if age < delay:
		return
	elapsed_active = age-delay
	var kind := str(spec.kind)
	var duration := float(spec.get("duration",.5 if kind == "ring" else .2))
	if kind in ["shot","hook"]:
		var next := global_position+direction*float(spec.get("velocity",210))*delta
		if blocked(global_position,next):
			queue_free()
			return
		if Geometry2D.get_closest_point_to_segment(target.global_position,global_position,next).distance_to(target.global_position) < 21:
			hit()
			queue_free()
		global_position = next
		if elapsed_active*float(spec.get("velocity",210)) >= float(spec.get("reach",260)):
			queue_free()
		return
	if elapsed_active > duration:
		queue_free()
		return
	tick -= delta
	if contains(target.global_position) and not blocked(global_position,target.global_position):
		if kind == "haze":
			target.apply_enemy_status("haze",.15,source)
		elif kind == "pool":
			if tick <= 0:
				hit()
				tick = 1.0
		elif not struck:
			hit()
	if kind == "ring":
		previous_radius = float(spec.get("reach",90))*clampf(elapsed_active/.45,0,1)

func hit() -> void:
	struck = true
	var amount := float(spec.get("damage",0))
	var accepted: bool = target.take_damage(amount)
	if not accepted:
		return
	if spec.has("hit_window"):
		target.invulnerability = minf(target.invulnerability,float(spec.hit_window))
	var status := str(spec.get("status",""))
	if spec.kind == "hook" or status == "hook":
		source.hooked = true
		source.hook_timer = float(spec.get("hook_duration",4))
		if spec.get("auto_reel",false):
			target.apply_enemy_status("reel",.6,source,float(spec.get("distance",60)))
	elif status == "steal":
		target.energy = maxf(0,target.energy-12)
	elif not status.is_empty():
		target.apply_enemy_status(status,float(spec.get("status_duration",3 if status in ["weaken","interference"] else 2)),source)
	if float(spec.get("push",0)) > 0:
		target.move_and_collide(direction*float(spec.push))

func _draw() -> void:
	var warning := age < float(spec.get("delay",0))
	var tint := Color("ffbf52") if warning else Color("ff734c")
	if spec.kind in ["pool","haze"]:
		tint = Color("9cdb62") if spec.kind == "pool" else Color("b5b0a4")
	var radius := float(spec.get("radius",spec.get("reach",90)))
	if spec.kind in ["shot","hook"]:
		draw_line(-direction*18,Vector2.ZERO,tint,5,true)
		draw_circle(Vector2.ZERO,7,tint)
		if spec.kind == "hook" and is_instance_valid(source):
			draw_line(source.global_position-global_position,Vector2.ZERO,Color("b8c5cb"),2,true)
	elif spec.kind == "cone":
		var half := deg_to_rad(float(spec.get("arc",90))*.5)
		draw_arc(Vector2.ZERO,radius,direction.angle()-half,direction.angle()+half,24,tint,4,true)
		draw_line(Vector2.ZERO,direction.rotated(-half)*radius,tint,2,true)
		draw_line(Vector2.ZERO,direction.rotated(half)*radius,tint,2,true)
	else:
		if spec.kind == "ring" and not warning:
			radius *= clampf(elapsed_active/.45,0,1)
		draw_circle(Vector2.ZERO,radius,Color(tint,.12 if warning else .22))
		draw_arc(Vector2.ZERO,radius,0,TAU,48,tint,2,true)

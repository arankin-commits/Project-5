extends Node2D

var lifetime := 0.35
var remaining := 0.35
var radius := 80.0
var direction := Vector2.RIGHT
var tint := Color("72f8e5")
var kind := "slash"

func _ready() -> void:
	if kind in ["lightning_slam", "fire_slam", "tidal_slam", "earth_slam", "ice_slam", "whirlpool"]:
		lifetime = 0.55
	elif kind in ["lightning_bolt", "shockwave", "rocksplosion", "earth_fissure"]:
		lifetime = 0.40
	remaining = lifetime
	z_index = 5

func _process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var progress := 1.0 - remaining / lifetime
	var color := tint
	color.a *= 1.0 - progress
	
	match kind:
		"slash":
			draw_arc(Vector2(0, -15), radius * (0.6 + progress * 0.4), direction.angle() - 0.9, direction.angle() + 0.9, 24, color, 8 * (1 - progress) + 1, true)
		"burst":
			for i in range(10):
				var radial := Vector2.from_angle(float(i) * TAU / 10.0)
				draw_line(radial * radius * progress, radial * (radius * progress + 8.0), color, 3.0, true)
		"ring":
			draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
			draw_arc(Vector2.ZERO, radius * progress, 0, TAU, 48, color, 5.0, true)
			draw_set_transform(Vector2.ZERO)
		"lightning_bolt":
			_draw_lightning_bolt(progress, color)
		"lightning_slam":
			_draw_lightning_slam(progress, color)
		"fire_slam":
			_draw_fire_slam(progress, color)
		"tidal_slam":
			_draw_tidal_slam(progress, color)
		"ice_slam", "ice_spikes":
			_draw_ice_spikes(progress, color)
		"earth_slam", "earth_fissure":
			_draw_earth_fissure(progress, color)
		"swirl", "cyclone":
			_draw_swirl(progress, color)
		"shockwave":
			_draw_shockwave(progress, color)
		"splash":
			_draw_splash(progress, color)
		"flame":
			_draw_flame(progress, color)
		"rocksplosion":
			_draw_rocksplosion(progress, color)
		"whirlpool":
			_draw_whirlpool(progress, color)
		_:
			draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
			draw_arc(Vector2.ZERO, radius * progress, 0, TAU, 48, color, 5.0, true)
			draw_set_transform(Vector2.ZERO)

func _draw_lightning_bolt(progress: float, col: Color) -> void:
	var target := direction * radius
	var normal := Vector2(-direction.y, direction.x).normalized()
	var pts: Array[Vector2] = [Vector2.ZERO]
	var segs := 8
	for i in range(1, segs):
		var p := float(i) / float(segs)
		var offset := sin(float(i) * 37.1 + progress * 20.0) * (14.0 * (1.0 - progress * 0.5))
		pts.append(target * p + normal * offset)
	pts.append(target)
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i+1], col, 4.0 * (1.0 - progress) + 1.0, true)
		draw_line(pts[i], pts[i+1], Color.WHITE, 1.5 * (1.0 - progress), true)
	for i in range(6):
		var ang := float(i) * TAU / 6.0 + progress * 5.0
		var r_dist := 12.0 * progress
		draw_line(target, target + Vector2.from_angle(ang) * r_dist, col, 2.0, true)

func _draw_lightning_slam(progress: float, col: Color) -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
	draw_arc(Vector2.ZERO, radius * progress, 0, TAU, 36, col, 4.0 * (1.0 - progress) + 1.0, true)
	draw_set_transform(Vector2.ZERO)
	if progress < 0.6:
		var p_bolt := progress / 0.6
		var top := Vector2(0, -220)
		var bot := Vector2.ZERO
		var pts: Array[Vector2] = [top]
		for i in range(1, 10):
			var t_i := float(i) / 10.0
			var off := sin(float(i) * 53.2 + progress * 30.0) * 18.0
			pts.append(top.lerp(bot, t_i) + Vector2(off, 0))
		pts.append(bot)
		for i in range(pts.size() - 1):
			draw_line(pts[i], pts[i+1], col, 8.0 * (1.0 - p_bolt) + 2.0, true)
			draw_line(pts[i], pts[i+1], Color.WHITE, 3.0 * (1.0 - p_bolt), true)
	for i in range(12):
		var ang := float(i) * TAU / 12.0
		var r_dist := radius * 0.8 * progress
		draw_line(Vector2.from_angle(ang) * (r_dist * 0.4), Vector2.from_angle(ang) * r_dist, col, 2.5 * (1.0 - progress), true)

func _draw_fire_slam(progress: float, col: Color) -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
	draw_arc(Vector2.ZERO, radius * progress, 0, TAU, 36, col, 5.0 * (1.0 - progress) + 1.0, true)
	draw_set_transform(Vector2.ZERO)
	var count := 16
	for i in range(count):
		var a := float(i) * TAU / float(count) + progress * 2.0
		var r_curr := radius * progress
		var pos := Vector2(cos(a) * r_curr, sin(a) * r_curr * 0.5 - 12.0 * progress)
		var fire_size := 10.0 * (1.0 - progress * 0.7)
		draw_circle(pos, fire_size, col)
		draw_circle(pos - Vector2(0, 3), fire_size * 0.55, Color("ffc75e"))

func _draw_tidal_slam(progress: float, col: Color) -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
	draw_arc(Vector2.ZERO, radius * progress, 0, TAU, 36, col, 6.0 * (1.0 - progress) + 1.0, true)
	if progress > 0.2:
		draw_arc(Vector2.ZERO, radius * (progress - 0.2) * 1.1, 0, TAU, 36, Color("52c9fd"), 3.0 * (1.0 - progress), true)
	draw_set_transform(Vector2.ZERO)
	var count := 18
	for i in range(count):
		var a := float(i) * TAU / float(count)
		var r_curr := radius * progress
		var pos := Vector2(cos(a) * r_curr, sin(a) * r_curr * 0.5 - sin(float(i) * 13.0 + progress * 8.0) * 16.0 * (1.0 - progress))
		draw_circle(pos, 4.0 * (1.0 - progress), Color("a8f0ff"))

func _draw_ice_spikes(progress: float, col: Color) -> void:
	var count := 8
	for i in range(count):
		var off_x := (float(i) - float(count) * 0.5) * (radius * 0.25)
		var off_y := sin(float(i) * 29.3) * (radius * 0.15)
		var base_pos := Vector2(off_x, off_y)
		var height := (32.0 + sin(float(i) * 41.7) * 16.0) * clampf(progress * 3.0, 0.0, 1.0) * (1.0 - progress * 0.3)
		var w := 9.0 * (1.0 - progress * 0.3)
		var pts: PackedVector2Array = [
			base_pos + Vector2(-w, 0),
			base_pos + Vector2(0, -height),
			base_pos + Vector2(w, 0)
		]
		var fill_col := col
		fill_col.a = 0.7 * (1.0 - progress)
		draw_colored_polygon(pts, fill_col)
		draw_polyline(pts, Color.WHITE, 1.5 * (1.0 - progress))

func _draw_earth_fissure(progress: float, col: Color) -> void:
	var count := 8
	var pts: PackedVector2Array = []
	for i in range(count):
		var p_t := float(i) / float(count - 1)
		var crack_pos := Vector2((p_t - 0.5) * radius * 1.8, sin(float(i) * 31.4) * 12.0)
		pts.append(crack_pos)
		if i % 2 == 1:
			var slab_h := (24.0 + sin(float(i) * 17.1) * 12.0) * clampf(progress * 3.0, 0.0, 1.0) * (1.0 - progress * 0.2)
			var slab_pts: PackedVector2Array = [
				crack_pos + Vector2(-12, 0),
				crack_pos + Vector2(-4, -slab_h),
				crack_pos + Vector2(10, -slab_h * 0.8),
				crack_pos + Vector2(14, 0)
			]
			var f_col := col
			f_col.a = 0.85 * (1.0 - progress)
			draw_colored_polygon(slab_pts, f_col)
			draw_polyline(slab_pts, Color("d1a873"), 1.8 * (1.0 - progress))
	draw_polyline(pts, Color("554435"), 3.0 * (1.0 - progress))

func _draw_swirl(progress: float, col: Color) -> void:
	for q in range(4):
		var r_curr := radius * (0.35 + float(q) * 0.22)
		var start_ang := progress * 8.0 + float(q) * 0.8
		var end_ang := start_ang + PI * 1.2
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
		draw_arc(Vector2.ZERO, r_curr, start_ang, end_ang, 24, col, 3.5 * (1.0 - progress) + 0.8, true)
		draw_set_transform(Vector2.ZERO)

func _draw_shockwave(progress: float, col: Color) -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
	draw_arc(Vector2.ZERO, radius * progress, 0, TAU, 36, col, 5.0 * (1.0 - progress) + 1.0, true)
	draw_set_transform(Vector2.ZERO)
	for i in range(14):
		var ang := float(i) * TAU / 14.0 + sin(float(i) * 11.0) * 0.2
		var inner := radius * 0.2 * progress
		var outer := radius * (0.7 + sin(float(i) * 23.0) * 0.3) * progress
		var p1 := Vector2(cos(ang) * inner, sin(ang) * inner * 0.5)
		var p2 := Vector2(cos(ang) * outer, sin(ang) * outer * 0.5)
		draw_line(p1, p2, col, 3.0 * (1.0 - progress), true)

func _draw_splash(progress: float, col: Color) -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
	draw_arc(Vector2.ZERO, radius * 0.8 * progress, 0, TAU, 24, col, 2.5 * (1.0 - progress), true)
	draw_set_transform(Vector2.ZERO)
	for i in range(10):
		var a := float(i) * TAU / 10.0
		var drop_r := radius * progress
		var drop_pos := Vector2(cos(a) * drop_r, sin(a) * drop_r * 0.4 - sin(progress * PI) * 20.0)
		draw_circle(drop_pos, 3.0 * (1.0 - progress), Color("52c9fd"))

func _draw_flame(progress: float, col: Color) -> void:
	for j in range(7):
		var off_x := (sin(float(j) * 21.0) * 25.0) * (1.0 - progress * 0.5)
		var fy := -progress * 45.0 - float(j) * 5.0
		var f_rad := 8.0 * (1.0 - progress * 0.7)
		var f_col := col if j % 2 == 0 else Color("ffc75e")
		draw_circle(Vector2(off_x, fy), f_rad, f_col)

func _draw_rocksplosion(progress: float, col: Color) -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
	draw_arc(Vector2.ZERO, radius * progress, 0, TAU, 24, Color("d1a873"), 3.0 * (1.0 - progress), true)
	draw_set_transform(Vector2.ZERO)
	for i in range(12):
		var a := float(i) * TAU / 12.0 + sin(float(i) * 17.0) * 0.3
		var dist := radius * progress * (0.8 + sin(float(i) * 31.0) * 0.4)
		var r_pos := Vector2(cos(a) * dist, sin(a) * dist * 0.6)
		var r_size := 6.0 * (1.0 - progress * 0.5)
		var pts: PackedVector2Array = [
			r_pos + Vector2(-r_size, r_size * 0.6),
			r_pos + Vector2(0, -r_size),
			r_pos + Vector2(r_size, r_size * 0.4)
		]
		draw_colored_polygon(pts, Color("554435"))
		draw_polyline(pts, Color("c19b66"), 1.2 * (1.0 - progress))

func _draw_whirlpool(progress: float, col: Color) -> void:
	for q in range(5):
		var r_curr := radius * (1.0 - float(q) * 0.18) * (1.0 - progress * 0.2)
		var start_ang := progress * 10.0 + float(q) * 1.1
		draw_set_transform(Vector2.ZERO, 0, Vector2(1, 0.5))
		draw_arc(Vector2.ZERO, r_curr, start_ang, start_ang + PI * 1.3, 32, col, 3.0 * (1.0 - progress) + 0.8, true)
		draw_set_transform(Vector2.ZERO)

extends Node2D

const Space := preload("res://scripts/boiler_space.gd")
var definition: Dictionary
var navigation := AStarGrid2D.new()
var footprints: Array[Rect2] = []
var vents: Array[Vector2] = []
var blockers: Array[PackedVector2Array] = []
var hazards_enabled := false
var exit_enabled := false
var debug_enabled := false
var elapsed := 0.0
var player: CharacterBody2D
var exit_position := Space.project(Vector2(140,140))
var spawn_position := Space.project(Vector2(815,815))

func build(data: Dictionary) -> void:
	definition = data
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var background := Sprite2D.new()
	background.name = "PaintedBoilerShell"
	background.texture = load("res://art/boiler/%s.png" % data.get("background","chamber"))
	background.centered = false
	background.z_index = -10
	background.modulate = Color(data.get("tint", "ffffff"))
	add_child(background)
	var boundary := Space.polygon(Vector2(500,500), Vector2(445,445))
	blockers.append(boundary)
	for i in 4:
		var body := StaticBody2D.new()
		var collision := CollisionShape2D.new()
		var shape := SegmentShape2D.new()
		shape.a = boundary[i]
		shape.b = boundary[(i + 1) % 4]
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
	for entry in data["props"]:
		_build_prop(entry[0], Vector2(entry[1],entry[2]))
	for vent in data["vents"]:
		vents.append(Space.project(Vector2(vent[0],vent[1])))
	_build_navigation()
	var floor_marks := Node2D.new()
	floor_marks.name = "FloorSignals"
	floor_marks.z_index = -5
	floor_marks.draw.connect(_draw_floor.bind(floor_marks))
	add_child(floor_marks)

func _build_prop(kind: String, logical: Vector2) -> void:
	var half := Vector2(55,55)
	var cell := 0
	var sprite_scale := 0.38
	if kind == "coal":
		cell = 1
		half = Vector2(60,60)
		sprite_scale = 0.31
	elif kind == "condenser":
		cell = 2
		half = Vector2(70,65)
		sprite_scale = 0.37
	footprints.append(Rect2(logical-half, half*2))
	var body := StaticBody2D.new()
	body.name = kind.capitalize() + str(get_child_count())
	body.position = Space.project(logical)
	var points := Space.polygon(logical,half)
	blockers.append(points)
	var collider := CollisionPolygon2D.new()
	var local_points := PackedVector2Array()
	for point in points:
		local_points.append(point-body.position)
	collider.polygon = local_points
	body.add_child(collider)
	var sprite := Sprite2D.new()
	sprite.texture = Space.atlas(cell)
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.offset.y = -206
	# Artwork base spans the collision footprint; sort origin is its south edge.
	var sort_offset := half.y * 0.337
	body.position.y += sort_offset
	collider.position.y -= sort_offset
	sprite.position.y -= sort_offset
	body.add_child(sprite)
	add_child(body)

func _build_navigation() -> void:
	navigation.region = Rect2i(0,0,26,26)
	navigation.cell_size = Vector2(40,40)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	for x in 26:
		for y in 26:
			navigation.set_point_solid(Vector2i(x,y), not is_logical_free(Vector2(x,y)*40, 32))

func is_logical_free(point: Vector2, clearance := 20.0) -> bool:
	if point.x < Space.MIN + clearance or point.y < Space.MIN + clearance or point.x > Space.MAX-clearance or point.y > Space.MAX-clearance:
		return false
	for rect in footprints:
		if rect.grow(clearance).has_point(point):
			return false
	return true

func _nearest_cell(point: Vector2) -> Vector2i:
	var cell := Vector2i((Space.unproject(point) / 40.0).round()).clamp(Vector2i.ZERO,Vector2i(25,25))
	if not navigation.is_point_solid(cell):
		return cell
	var best := Vector2i(3,3)
	var distance := INF
	for x in 26:
		for y in 26:
			var candidate := Vector2i(x,y)
			if not navigation.is_point_solid(candidate) and Vector2(candidate-cell).length_squared() < distance:
				best = candidate
				distance = Vector2(candidate-cell).length_squared()
	return best

func path_between(from: Vector2, to: Vector2) -> PackedVector2Array:
	var ids := navigation.get_id_path(_nearest_cell(from), _nearest_cell(to))
	var path := PackedVector2Array()
	for id in ids:
		path.append(Space.project(Vector2(id) * 40))
	return path

func safe_spawns(count: int, rng: RandomNumberGenerator) -> Array[Vector2]:
	var choices: Array[Vector2] = []
	for x in range(160,900,120):
		for y in range(160,900,120):
			var point := Vector2(x,y)
			if is_logical_free(point, 55) and Space.project(point).distance_to(spawn_position) > 210:
				choices.append(Space.project(point))
	var result: Array[Vector2] = []
	for i in count:
		if choices.is_empty():
			break
		var index := rng.randi_range(0,choices.size()-1)
		result.append(choices[index])
		choices.remove_at(index)
	return result

func _physics_process(delta: float) -> void:
	if not hazards_enabled:
		return
	elapsed += delta
	for i in vents.size():
		var phase := fmod(elapsed + i * 1.1, 4.8)
		if phase > 4.0 and is_instance_valid(player) and ((player.position-vents[i])*Vector2(1,2)).length() < 49:
			player.call("take_damage", 12)

func _process(_delta: float) -> void:
	var marks := get_node_or_null("FloorSignals")
	if marks:
		marks.queue_redraw()

func _draw_floor(canvas: Node2D) -> void:
	for i in vents.size():
		var p := vents[i]
		var phase := fmod(elapsed + i * 1.1, 4.8)
		var active := hazards_enabled and phase > 4.0
		var warning := hazards_enabled and phase > 2.8
		canvas.draw_set_transform(p,0,Vector2(1,0.5))
		canvas.draw_circle(Vector2.ZERO,49,Color("1b2024"))
		canvas.draw_arc(Vector2.ZERO,49,0,TAU,48,Color("98714b"),3,true)
		for offset in range(-28,35,14):
			canvas.draw_line(Vector2(-32,offset),Vector2(32,offset),Color("6e6356"),3,true)
		if warning:
			canvas.draw_circle(Vector2.ZERO,55,Color(1,0.35,0.1,0.26 if active else 0.12))
			canvas.draw_arc(Vector2.ZERO,58,0,TAU,48,Color(1,0.5,0.16,0.8),3,true)
		canvas.draw_set_transform(p)
		if active:
			for n in 5:
				var rise := fmod(elapsed * 90 + n * 20,90)
				canvas.draw_circle(Vector2(sin(n*2.3)*25,-rise), 10+rise*0.15, Color(0.8,0.88,0.87,(1-rise/100)*0.45))
	canvas.draw_set_transform(exit_position,0,Vector2(1,0.5))
	var color := Color("6de4d7") if exit_enabled else Color("775439")
	canvas.draw_arc(Vector2.ZERO,42,0,TAU,48,color,3,true)
	canvas.draw_arc(Vector2.ZERO,32,0,TAU,48,color*Color(1,1,1,0.45),2,true)
	for i in 8:
		var radial := Vector2.from_angle(i*TAU/8)
		canvas.draw_line(radial*44,radial*51,color,3,true)
	canvas.draw_set_transform(Vector2.ZERO)
	if debug_enabled:
		for polygon in blockers:
			var closed := polygon.duplicate()
			closed.append(polygon[0])
			canvas.draw_polyline(closed,Color.GREEN,2)

extends SceneTree

const ENEMY := preload("res://scripts/industrial_enemy.gd")
const PLAYER := preload("res://scripts/medium_robot.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies/industrial.json"))
	var canvas := Node2D.new()
	root.add_child(canvas)
	var title := Label.new()
	title.text = "INDUSTRIAL ABILITIES — WARNINGS / ACTIVE EFFECTS"
	title.position = Vector2(30,15)
	canvas.add_child(title)
	var enemies: Array = []
	for i in 6:
		var id: int = [2,12,5,18,30,10][i]
		var enemy := ENEMY.new()
		enemy.design = catalog["industrial_%02d" % id]
		enemy.position = Vector2(140+(i%3)*410,205+(i/3)*320)
		var player := PLAYER.new()
		player.position = enemy.position+Vector2(95,0)
		canvas.add_child(player)
		player.set_physics_process(false)
		enemy.target = player
		canvas.add_child(enemy)
		enemy.set_physics_process(false)
		enemy.move_index = 0 if id == 12 else 2
		enemy._begin_attack()
		enemies.append(enemy)
		var label := Label.new()
		label.text = enemy.design.name+"\n"+enemy.current_move.name
		label.position = enemy.position+Vector2(-100,90)
		canvas.add_child(label)
	await create_timer(.15).timeout
	await process_frame
	print("WARNINGS_CAPTURE=",root.get_texture().get_image().save_png("res://reviews/industrial_ability_warnings.png"))
	for enemy in enemies:
		enemy._release_attack()
	await create_timer(.38).timeout
	await process_frame
	print("ACTIVE_CAPTURE=",root.get_texture().get_image().save_png("res://reviews/industrial_ability_active.png"))
	quit()

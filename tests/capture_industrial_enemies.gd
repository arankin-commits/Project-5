extends SceneTree

const ENEMY := preload("res://scripts/industrial_enemy.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/enemies/industrial.json"))
	for biome in ["maintenance","factory","boiler","toxin_refinery"]:
		var gallery := Node2D.new()
		root.add_child(gallery)
		var title := Label.new()
		title.text = biome.replace("_"," ").to_upper()+" — ENEMY ANIMATION CHECK"
		title.position = Vector2(30,20)
		title.add_theme_font_size_override("font_size",24)
		gallery.add_child(title)
		var roster: Array = []
		for key in catalog:
			if catalog[key].biome_key != biome:
				continue
			var enemy := ENEMY.new()
			enemy.design = catalog[key]
			enemy.position = Vector2(210+(roster.size()%3)*420,210+(roster.size()/3)*200)
			gallery.add_child(enemy)
			roster.append(enemy)
			var label := Label.new()
			label.text = "%s\n%s | %s HP" % [enemy.design.name,enemy.design.role,enemy.design.hp]
			label.position = enemy.position+Vector2(-180,25)
			label.size.x = 360
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			gallery.add_child(label)
		for phase in ["walk","windup","attack","death"]:
			for enemy in roster:
				enemy.facing = Vector2(1,0.5).normalized()
				enemy.velocity = Vector2(60,30) if phase == "walk" else Vector2.ZERO
				enemy.state = "windup" if phase == "windup" else ("ability" if phase == "attack" else "chase")
				enemy.attack_point = enemy.position+Vector2(40,10)
				enemy.release_timer = 1.0 if phase == "attack" else 0.0
				if phase == "death":
					enemy.take_damage(10000)
			await create_timer(0.22).timeout
			await process_frame
			await process_frame
			print("ENEMY_CAPTURE=",biome," ",phase," RESULT=",root.get_texture().get_image().save_png("res://reviews/enemies_%s_%s.png" % [biome,phase]))
		gallery.queue_free()
		await process_frame
	quit()

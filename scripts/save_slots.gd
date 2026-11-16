extends Node

var active_slot := 0
var directory := "user://"

func path(slot: int) -> String:
	return directory.path_join("slot_%d.cfg" % slot)

func info(slot: int) -> Dictionary:
	var data := ConfigFile.new()
	var exists := data.load(path(slot)) == OK
	# The original single save remains intact and is offered as file 1.
	if not exists and slot == 1:
		exists = data.load(directory.path_join("skill_tree.cfg")) == OK
	return {"exists": exists, "xp": data.get_value("progress", "xp", 0),
		"skills": data.get_value("progress", "skills", ["root"]).size(),
		"victories": data.get_value("ship", "victories", 0),
		"returns": data.get_value("ship", "returns", 0)}

func is_slot_empty(slot: int) -> bool:
	var inf := info(slot)
	if not inf.exists:
		return true
	return inf.xp == 0 and inf.victories == 0 and inf.skills <= 1 and int(inf.get("returns", 0)) == 0

func select_slot(slot: int) -> Error:
	if slot < 1 or slot > 3:
		return ERR_INVALID_PARAMETER
	var progress = get_node("/root/CoreProgression")
	var config = get_node("/root/RunConfig")
	var crew = get_node("/root/ShipCrew")
	active_slot = slot
	progress.active_save_path = path(slot)
	progress.xp = 0
	progress.special_items = 0
	progress.unlocked_skills.assign(["root"])
	var source := path(slot)
	if not FileAccess.file_exists(source) and slot == 1:
		source = directory.path_join("skill_tree.cfg")
	progress.load_progress(source)
	var data := ConfigFile.new()
	data.load(source)
	config.best_room = int(data.get_value("ship", "best_room", 0))
	config.victories = int(data.get_value("ship", "victories", 0))
	config.active = false
	config.sync_return_pending = false
	config.core_elements.clear()
	crew.return_count = int(data.get_value("ship", "returns", 0))
	crew.cockpit_layout = data.get_value("ship", "crew", crew.COCKPIT_LAYOUTS[0]).duplicate()
	progress.changed.emit()
	return save_current()

func save_current() -> Error:
	if active_slot == 0:
		return OK
	var progress = get_node("/root/CoreProgression")
	if not progress.persistence_enabled:
		return OK
	var data := ConfigFile.new()
	data.load(path(active_slot))
	data.set_value("progress", "xp", progress.xp)
	data.set_value("progress", "items", progress.special_items)
	data.set_value("progress", "skills", progress.unlocked_skills)
	var config = get_node("/root/RunConfig")
	var crew = get_node("/root/ShipCrew")
	data.set_value("ship", "best_room", config.best_room)
	data.set_value("ship", "victories", config.victories)
	data.set_value("ship", "returns", crew.return_count)
	data.set_value("ship", "crew", crew.cockpit_layout)
	return data.save(path(active_slot))

extends Node

const ROBOT_STATS := {
	"heavy": {"speed": 0.7, "health": 1.5, "damage": 1.3, "backstab": 2.0},
	"light": {"speed": 1.25, "health": 0.6, "damage": 0.7, "backstab": 6.0},
	"medium": {"speed": 1.0, "health": 1.0, "damage": 1.0, "backstab": 2.0}
}

var robot_type := "medium"
var modifiers := {
	"overclocked_enemies": false,
	"reinforcements": false,
	"fragile_frame": false
}
var active := false
var run_seed := 0
var best_room := 0
var victories := 0
var sync_return_pending := false
const ELEMENTS := ["fire", "water", "lightning"]
var core_elements: Array[String] = []
var core_limit := 1

func start_run(selected_robot: String, selected_modifiers: Dictionary) -> bool:
	if not ROBOT_STATS.has(selected_robot):
		return false
	robot_type = selected_robot
	for key in modifiers:
		modifiers[key] = bool(selected_modifiers.get(key, false))
	active = true
	core_elements.clear()
	core_limit = get_node("/root/CoreProgression").core_capacity()
	sync_return_pending = false
	run_seed = randi()
	return true

func end_run() -> void:
	if active:
		get_node("/root/ShipCrew").returned_from_run()
	active = false
	sync_return_pending = true

func consume_sync_return() -> bool:
	var pending := sync_return_pending
	sync_return_pending = false
	return pending

func max_health() -> int:
	return roundi(100 * ROBOT_STATS[robot_type]["health"]) - (30 if modifiers["fragile_frame"] else 0)

func robot_stats() -> Dictionary:
	return ROBOT_STATS[robot_type]

func available_elements() -> Array[String]:
	var available: Array[String] = []
	if core_elements.size() < core_limit:
		for element in ELEMENTS:
			if not core_elements.has(element):
				available.append(element)
	return available

func pick_element(element: String) -> bool:
	if not available_elements().has(element):
		return false
	core_elements.append(element)
	return true

func enemy_count() -> int:
	return 5 if modifiers["reinforcements"] else 3

func enemy_speed() -> float:
	return 130.0 if modifiers["overclocked_enemies"] else 104.0

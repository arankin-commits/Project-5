extends Node

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

func start_run(selected_robot: String, selected_modifiers: Dictionary) -> bool:
	if selected_robot != "medium":
		return false
	robot_type = selected_robot
	for key in modifiers:
		modifiers[key] = bool(selected_modifiers.get(key, false))
	active = true
	sync_return_pending = false
	run_seed = randi()
	return true

func end_run() -> void:
	active = false
	sync_return_pending = true

func consume_sync_return() -> bool:
	var pending := sync_return_pending
	sync_return_pending = false
	return pending

func max_health() -> int:
	return 70 if modifiers["fragile_frame"] else 100

func enemy_count() -> int:
	return 5 if modifiers["reinforcements"] else 3

func enemy_speed() -> float:
	return 130.0 if modifiers["overclocked_enemies"] else 104.0

extends Node

const ROBOT_STATS := {
	"heavy": {"speed": 0.7, "health": 1.5, "damage": 1.3, "backstab": 2.0},
	"light": {"speed": 1.25, "health": 0.6, "damage": 0.7, "backstab": 6.0},
	"medium": {"speed": 1.0, "health": 1.0, "damage": 1.0, "backstab": 2.0}
}

var robot_type := "medium"
const ROUTES := {
	"above_ground": ["storage", "flying_ship_gallery", "executive", "summit_chambers"],
	"below_ground": ["maintenance", "factory", "boiler", "toxin_refinery"]
}
const BIOME_DATA := {
	"maintenance": "res://data/blockouts/maintenance.json",
	"factory": "res://data/blockouts/factory.json",
	"boiler": "res://data/blockouts/boiler.json",
	"toxin_refinery": "res://data/blockouts/toxin_refinery.json"
}
var route := "below_ground"
var biome := "maintenance"
var modifiers := {
	"overclocked_enemies": false,
	"reinforcements": false,
	"fragile_frame": false
}
var active := false
var run_seed := 0
var best_room := 0
var victories := 0
var runs_completed := 0
var skill_tree_opened_after_run := false
var sync_return_pending := false
# Standard elements catalog: const ELEMENTS := ["fire", "water", "lightning", "ice", "wind", "earth"]
const BASE_ELEMENTS := ["fire", "water", "lightning", "ice", "wind", "earth"]
var ELEMENTS: Array = ["fire", "water", "lightning", "ice", "wind", "earth"]
var core_elements: Array = []
var core_limit := 1
var trap_buff_active := false
var shop_rewards_count := 0
const MAX_SHOP_REWARDS := 2

func get_all_elements() -> Array[String]:
	var list: Array[String] = ["fire", "water", "lightning", "ice", "wind", "earth"]
	var loop = Engine.get_main_loop()
	if loop != null and loop is SceneTree and loop.root != null and loop.root.has_node("CoreProgression"):
		var prog = loop.root.get_node("CoreProgression")
		if prog.has_skill("toxin_mastery"):
			list.append("toxin")
	return list

func refresh_elements() -> void:
	ELEMENTS = get_all_elements()

func start_run(selected_robot: String, selected_modifiers: Dictionary, selected_route := "below_ground") -> bool:
	if not ROBOT_STATS.has(selected_robot) or not ROUTES.has(selected_route):
		return false
	var first: String = ROUTES[selected_route][0]
	if not BIOME_DATA.has(first):
		return false
	route = selected_route
	biome = first
	robot_type = selected_robot
	for key in modifiers:
		modifiers[key] = bool(selected_modifiers.get(key, false))
	active = true
	core_elements.clear()
	refresh_elements()
	core_limit = get_node("/root/CoreProgression").core_capacity()
	sync_return_pending = false
	trap_buff_active = false
	shop_rewards_count = 0
	run_seed = randi()
	return true

func next_biome() -> String:
	var path: Array = ROUTES[route]
	var index := path.find(biome)
	return str(path[index+1]) if index >= 0 and index+1 < path.size() else ""

func end_run() -> void:
	if active:
		get_node("/root/ShipCrew").returned_from_run()
	runs_completed += 1
	active = false
	sync_return_pending = true
	trap_buff_active = false
	shop_rewards_count = 0
	get_node("/root/SaveSlots").save_current()

func get_runs_completed() -> int:
	var crew = get_node_or_null("/root/ShipCrew")
	var crew_returns: int = crew.return_count if crew != null else 0
	return maxi(runs_completed, crew_returns)

func is_sync_machine_locked() -> bool:
	return get_runs_completed() >= 1 and not skill_tree_opened_after_run

func mark_skill_tree_opened() -> void:
	if not skill_tree_opened_after_run:
		skill_tree_opened_after_run = true
		var saves = get_node_or_null("/root/SaveSlots")
		if saves != null and saves.has_method("save_current"):
			saves.save_current()

func get_npc_dialogue(npc_id: String) -> Array:
	if is_sync_machine_locked():
		match npc_id:
			"handler":
				return [
					{
						"speaker": "HANDLER",
						"portrait": "handler",
						"text": "What are you doing? You know the machine has to recharge before you can use it again. You should go relax; we need you at your best when you sync up. The eccentric one needed you for something. Why don’t you go talk to her?"
					}
				]
			"mechanic":
				return [
					{
						"speaker": "MECHANIC",
						"portrait": "mechanic",
						"text": "Heya Josh. May’s been bugging me all day about this machine of hers; why don’t you go talk to her?"
					}
				]
			"engineer":
				return [
					{
						"speaker": "ENGINEER",
						"portrait": "engineer",
						"text": "Why hello there, my fellow bipedal primate, I have used my grand ingenuity to create that machine in the middle of the room. What machine, you ask? The large one in front of your face. Well, pray tell, what does it do? I’m glad you asked, my meat-headed companion; this machine is able to strengthen the core of your combat robots. All you need to do is fight, and this puppy’ll do the rest. Through an automated telemetry acquisition system, it continuously receives, processes, and analyzes combat data transmitted from your robot, cataloging everything from energy consumption and elemental output to combat efficiency and core performance. Using advanced adaptive algorithms, it identifies structural inefficiencies…"
					},
					{
						"speaker": "JOSH",
						"portrait": "josh",
						"text": "As much as I would love to hear more about the.. Intricacies of this machine of yours, how about we keep it short?"
					},
					{
						"speaker": "ENGINEER",
						"portrait": "engineer",
						"text": "Fine. Do fight. Get strong. Was that short enough?"
					},
					{
						"speaker": "JOSH",
						"portrait": "josh",
						"text": "Very funny. I’ll listen to the whole rundown later. Just give the synopsis."
					},
					{
						"speaker": "ENGINEER",
						"portrait": "engineer",
						"text": "Basically, the power you siphon from enemies can be used to strengthen your robot cores; it’s easier shown than told. Why don’t you walk over there and test it out?"
					}
				]
	elif skill_tree_opened_after_run:
		match npc_id:
			"engineer":
				return [
					{
						"speaker": "ENGINEER",
						"portrait": "engineer",
						"text": "Sooooooooo what you’d think? Impressive right. Genius even."
					},
					{
						"speaker": "JOSH",
						"portrait": "josh",
						"text": "Yeah, I gotta admit it’s impressive. This’ll be a big help, thanks."
					},
					{
						"speaker": "ENGINEER",
						"portrait": "engineer",
						"text": "No problem, just make sure to find some aether cores or, even better, some Lancrest blueprints. Oh, if only he wasn’t so evil."
					}
				]
	return []

func consume_sync_return() -> bool:
	var pending := sync_return_pending
	sync_return_pending = false
	return pending

func max_health() -> int:
	return roundi(50 * ROBOT_STATS[robot_type]["health"]) - (30 if modifiers["fragile_frame"] else 0)

func robot_stats() -> Dictionary:
	return ROBOT_STATS[robot_type]

func is_element_reward(reward: String) -> bool:
	refresh_elements()
	return reward.begins_with("core_") and ELEMENTS.has(reward.trim_prefix("core_"))

func available_elements() -> Array[String]:
	refresh_elements()
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

const BASE_MEDIUM_ROBOT_SPEED := 265.0

func enemy_speed() -> float:
	return 130.0 if modifiers["overclocked_enemies"] else 104.0

func get_base_enemy_speed_by_size(size_category: String) -> float:
	var base_medium := BASE_MEDIUM_ROBOT_SPEED
	var heavy_speed := base_medium * ROBOT_STATS["heavy"]["speed"]
	match size_category.to_lower().strip_edges():
		"tiny":
			return base_medium * 1.25
		"small":
			return base_medium * 1.15
		"medium":
			return base_medium
		"large":
			return heavy_speed
		_:
			return base_medium

func get_enemy_speed_by_size(size_category: String) -> float:
	var base_spd := get_base_enemy_speed_by_size(size_category)
	var mult: float = (enemy_speed() / 104.0)
	return base_spd * mult

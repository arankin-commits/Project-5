extends Node

signal changed
const SAVE_PATH := "user://skill_tree.cfg"
# Coordinates match the supplied 1122 x 1402 skill-tree artwork.
const SKILLS := {
	"root": {"name":"Awakened", "description":"Your permanent upgrades begin here.", "requires":"", "xp":0, "item":0, "at":Vector2(535,1270), "radius":76},
	"backstab_1": {"name":"Backstab I", "description":"+20% backstab damage.", "requires":"root", "xp":100, "item":0, "at":Vector2(296,259), "radius":50},
	"backstab_2": {"name":"Backstab II", "description":"+40% backstab damage total.", "requires":"backstab_1", "xp":150, "item":0, "at":Vector2(296,379), "radius":50},
	"backstab_3": {"name":"Backstab III", "description":"+60% backstab damage total.", "requires":"backstab_2", "xp":200, "item":0, "at":Vector2(296,505), "radius":52},
	"wall_1": {"name":"Wall Stun I", "description":"+15% damage against wall-stunned enemies.", "requires":"backstab_1", "xp":100, "item":0, "at":Vector2(141,259), "radius":50},
	"wall_2": {"name":"Wall Stun II", "description":"+30% damage against wall-stunned enemies total.", "requires":"wall_1", "xp":150, "item":0, "at":Vector2(141,379), "radius":50},
	"wall_3": {"name":"Wall Stun III", "description":"+45% damage against wall-stunned enemies total.", "requires":"wall_2", "xp":200, "item":0, "at":Vector2(141,505), "radius":52},
	"double_dodge": {"name":"Chain Dodge", "description":"Chain two dodges before recharging.", "requires":"wall_3", "xp":0, "item":1, "at":Vector2(320,770), "radius":57},
	"perfect_reprisal": {"name":"Perfect Reprisal", "description":"After a perfect dodge, gain +25% damage for 5 seconds. Another perfect dodge resets the timer to 5 seconds.", "requires":"wall_3", "xp":0, "item":1, "at":Vector2(145,770), "radius":57},
	"energy_hit": {"name":"Energy Siphon", "description":"Gain 5 more energy per enemy hit (10 instead of 5).", "requires":"double_dodge", "xp":0, "item":1, "at":Vector2(320,940), "radius":60},
	"charged_attack": {"name":"Charged Strike", "description":"Hold strike for 0.6s, then release for double damage and powerful knockback. Tap for a normal strike.", "requires":"perfect_reprisal", "xp":0, "item":1, "at":Vector2(145,940), "radius":60},
	"heavy_grapple": {"name":"Heavy Grapple", "description":"Your grappling hook can also pull large brutes. Bosses remain anchored.", "requires":"charged_attack", "xp":0, "item":1, "at":Vector2(236,1098), "radius":65},
	"power_two": {"name":"The Power of Two", "description":"Hold two distinct elemental cores. Core encounters stop once both slots are filled.", "requires":"root", "xp":0, "item":2, "at":Vector2(538,809), "radius":101},
	"power_three": {"name":"The Power of Three", "description":"Hold three distinct elemental cores. Core encounters stop once all three slots are filled.", "requires":"power_two", "xp":0, "item":3, "at":Vector2(538,554), "radius":105},
	"toxin_mastery": {"name":"Toxin Core Unlocked", "description":"Toxin core now enters the pool of possible elemental cores.", "requires":"power_three", "xp":0, "item":2, "at":Vector2(538,290), "radius":85},
	"final_stand": {"name":"Final Stand", "description":"Once per run, survive lethal damage with half your maximum health and 2 seconds of protection.", "requires":"root", "xp":150, "item":0, "at":Vector2(872,272), "radius":69},
	"nanobots_1": {"name":"Nanobots I", "description":"Heal 5 health when entering a new room.", "requires":"final_stand", "xp":100, "item":0, "at":Vector2(714,435), "radius":37},
	"nanobots_2": {"name":"Nanobots II", "description":"Heal 10 health when entering a new room.", "requires":"nanobots_1", "xp":150, "item":0, "at":Vector2(794,435), "radius":37},
	"nanobots_3": {"name":"Nanobots III", "description":"Heal 15 health when entering a new room.", "requires":"nanobots_2", "xp":200, "item":0, "at":Vector2(874,435), "radius":37},
	"nanobots_4": {"name":"Nanobots IV", "description":"Heal 20 health when entering a new room.", "requires":"nanobots_3", "xp":250, "item":0, "at":Vector2(954,435), "radius":37},
	"nanobots_5": {"name":"Nanobots V", "description":"Heal 25 health when entering a new room.", "requires":"nanobots_4", "xp":300, "item":0, "at":Vector2(1034,435), "radius":37},
	"core_weapon_rewards": {"name":"Core & Weapon Bounty", "description":"Increases the chance of finding core and weapon rewards over other rewards.", "requires":"final_stand", "xp":200, "item":0, "at":Vector2(870,770), "radius":55},
	"rarer_cards": {"name":"Rare Discoveries", "description":"Increases the chance of finding rarer cards for core and weapon upgrades.", "requires":"core_weapon_rewards", "xp":250, "item":0, "at":Vector2(730,770), "radius":55},
	"trap_rooms": {"name":"Hazard Hunter", "description":"Increases the chance of finding trap rooms.", "requires":"core_weapon_rewards", "xp":200, "item":0, "at":Vector2(1010,770), "radius":55},
	"affinity_fire": {"name":"Fire Affinity", "description":"Makes it more likely to see fire element rewards.", "requires":"core_weapon_rewards", "xp":150, "item":0, "at":Vector2(680,935), "radius":36},
	"affinity_ice": {"name":"Ice Affinity", "description":"Makes it more likely to see ice element rewards.", "requires":"core_weapon_rewards", "xp":150, "item":0, "at":Vector2(755,935), "radius":36},
	"affinity_water": {"name":"Water Affinity", "description":"Makes it more likely to see water element rewards.", "requires":"core_weapon_rewards", "xp":150, "item":0, "at":Vector2(825,935), "radius":36},
	"affinity_lightning": {"name":"Lightning Affinity", "description":"Makes it more likely to see lightning element rewards.", "requires":"core_weapon_rewards", "xp":150, "item":0, "at":Vector2(895,935), "radius":36},
	"affinity_earth": {"name":"Earth Affinity", "description":"Makes it more likely to see earth element rewards.", "requires":"core_weapon_rewards", "xp":150, "item":0, "at":Vector2(970,935), "radius":36},
	"affinity_wind": {"name":"Wind Affinity", "description":"Makes it more likely to see wind element rewards.", "requires":"core_weapon_rewards", "xp":150, "item":0, "at":Vector2(1040,935), "radius":36},
	"reroll_element": {"name":"Element Flux", "description":"Allows the player to reroll element cards once per reward chamber.", "requires":"rarer_cards", "xp":0, "item":1, "at":Vector2(760,1105), "radius":55},
	"reroll_weapon": {"name":"Arsenal Recalibration", "description":"Allows the player to reroll weapon cards once per reward chamber.", "requires":"trap_rooms", "xp":0, "item":1, "at":Vector2(930,1105), "radius":55}
}

var unlocked_skills: Array[String] = ["root"]
var active_save_path := SAVE_PATH
var xp := 0
var special_items := 0
var persistence_enabled := true

func _ready() -> void:
	persistence_enabled = not OS.get_cmdline_user_args().has("--test-mode")
	if persistence_enabled:
		load_progress()

func has_skill(id: String) -> bool:
	return unlocked_skills.has(id)

func rank(prefix: String) -> int:
	var result := 0
	for id in unlocked_skills:
		if id.begins_with(prefix + "_") and id.get_slice("_", 1).is_valid_int():
			result = maxi(result, int(id.get_slice("_", 1)))
	return result

func core_capacity() -> int:
	return 3 if has_skill("power_three") else (2 if has_skill("power_two") else 1)

func can_unlock_skill(id: String) -> bool:
	if not SKILLS.has(id) or has_skill(id):
		return false
	var skill: Dictionary = SKILLS[id]
	return has_skill(skill.requires) and xp >= skill.xp and special_items >= skill.item

func unlock_skill(id: String) -> bool:
	if not can_unlock_skill(id):
		return false
	xp -= SKILLS[id].xp
	special_items -= SKILLS[id].item
	unlocked_skills.append(id)
	save_progress()
	changed.emit()
	return true

func award(amount: int, items := 0) -> void:
	xp += maxi(0, amount)
	special_items += maxi(0, items)
	save_progress()
	changed.emit()

func save_progress(path := "") -> void:
	if path.is_empty():
		path = active_save_path
	if not persistence_enabled:
		return
	var config := ConfigFile.new()
	config.load(path)
	config.set_value("progress", "xp", xp)
	config.set_value("progress", "items", special_items)
	config.set_value("progress", "skills", unlocked_skills)
	var error := config.save(path)
	if error != OK:
		push_warning("Could not save skill tree: " + error_string(error))

func load_progress(path := SAVE_PATH) -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	xp = maxi(0, int(config.get_value("progress", "xp", 0)))
	special_items = maxi(0, int(config.get_value("progress", "items", 0)))
	unlocked_skills.assign(["root"])
	var saved = config.get_value("progress", "skills", [])
	if saved is Array or saved is PackedStringArray:
		# Preserve purchases of the replaced Perfect Fortune node.
		if "perfect_dodge" in saved and not "perfect_reprisal" in saved:
			saved.append("perfect_reprisal")
		for id in SKILLS:
			if id != "root" and id in saved and has_skill(SKILLS[id].requires):
				unlocked_skills.append(id)

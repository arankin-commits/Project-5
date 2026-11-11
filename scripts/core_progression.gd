extends Node

const CORE_NAMES := {
	"standard": "Standard Core",
	"core_02": "Core Slot II",
	"core_03": "Core Slot III"
}
const SKILLS := {
	"power_routing": {"name": "Power Routing", "description": "The starting circuit for the Standard Core.", "requires": ""},
	"drive_tuning": {"name": "Drive Tuning", "description": "A future movement upgrade branch.", "requires": "power_routing"},
	"capacitor_bank": {"name": "Capacitor Bank", "description": "A future energy upgrade branch.", "requires": "power_routing"},
	"armor_lattice": {"name": "Armor Lattice", "description": "A future defense upgrade branch.", "requires": "power_routing"}
}

var unlocked_cores: Array[String] = ["standard"]
var equipped_core := "standard"
var unlocked_skills: Array[String] = ["power_routing"]
var skill_points := 0

func equip_core(core_id: String) -> bool:
	if not unlocked_cores.has(core_id) or not CORE_NAMES.has(core_id):
		return false
	equipped_core = core_id
	return true

func can_unlock_skill(skill_id: String) -> bool:
	if not SKILLS.has(skill_id) or unlocked_skills.has(skill_id) or skill_points < 1:
		return false
	var prerequisite: String = SKILLS[skill_id]["requires"]
	return prerequisite == "" or unlocked_skills.has(prerequisite)

func unlock_skill(skill_id: String) -> bool:
	if not can_unlock_skill(skill_id):
		return false
	skill_points -= 1
	unlocked_skills.append(skill_id)
	return true

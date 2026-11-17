extends Node

var active_slot := 0
var directory := "user://"
var collected_cds: Array[String] = []

const CD_ALBUM_DIR := "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1"

const CD_TRACKS: Dictionary = {
	"01_Copper_Hearth": {
		"id": "01_Copper_Hearth",
		"number": 1,
		"title": "Copper Hearth",
		"biome": "maintenance",
		"path": "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1/Audio/01_Copper_Hearth/Quiet_Lobby_Loop.ogg"
	},
	"02_Scribes_of_the_Air": {
		"id": "02_Scribes_of_the_Air",
		"number": 2,
		"title": "Scribes of the Air",
		"biome": "maintenance",
		"path": "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1/Audio/02_Scribes_of_the_Air/Quiet_Lobby_Loop.ogg"
	},
	"03_Parlour_Above_the_Clouds": {
		"id": "03_Parlour_Above_the_Clouds",
		"number": 3,
		"title": "Parlour Above the Clouds",
		"biome": "maintenance",
		"path": "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1/Audio/03_Parlour_Above_the_Clouds/Quiet_Lobby_Loop.ogg"
	},
	"04_Captains_Quadrille": {
		"id": "04_Captains_Quadrille",
		"number": 4,
		"title": "Captain's Quadrille",
		"biome": "maintenance",
		"path": "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1/Audio/04_Captains_Quadrille/Quiet_Lobby_Loop.ogg"
	},
	"05_Clockwork_Pavane": {
		"id": "05_Clockwork_Pavane",
		"number": 5,
		"title": "Clockwork Pavane",
		"biome": "factory",
		"path": "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1/Audio/05_Clockwork_Pavane/Quiet_Lobby_Loop.ogg"
	},
	"06_Fathers_Photograph": {
		"id": "06_Fathers_Photograph",
		"number": 6,
		"title": "Father's Photograph",
		"biome": "factory",
		"path": "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1/Audio/06_Fathers_Photograph/Quiet_Lobby_Loop.ogg"
	},
	"07_Brass_and_Lace": {
		"id": "07_Brass_and_Lace",
		"number": 7,
		"title": "Brass and Lace",
		"biome": "factory",
		"path": "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1/Audio/07_Brass_and_Lace/Quiet_Lobby_Loop.ogg"
	},
	"08_Liberty_Overture": {
		"id": "08_Liberty_Overture",
		"number": 8,
		"title": "Liberty Overture",
		"biome": "factory",
		"path": "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1/Audio/08_Liberty_Overture/Quiet_Lobby_Loop.ogg"
	},
	"09_Glass_Horizon": {
		"id": "09_Glass_Horizon",
		"number": 9,
		"title": "Glass Horizon",
		"biome": "boiler",
		"path": "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1/Audio/09_Glass_Horizon/Quiet_Lobby_Loop.ogg"
	},
	"10_Aether_Lullaby": {
		"id": "10_Aether_Lullaby",
		"number": 10,
		"title": "Aether Lullaby",
		"biome": "boiler",
		"path": "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1/Audio/10_Aether_Lullaby/Quiet_Lobby_Loop.ogg"
	},
	"11_Time_Between_Gears": {
		"id": "11_Time_Between_Gears",
		"number": 11,
		"title": "Time Between Gears",
		"biome": "boiler",
		"path": "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1/Audio/11_Time_Between_Gears/Quiet_Lobby_Loop.ogg"
	},
	"12_Skylight_Chapel": {
		"id": "12_Skylight_Chapel",
		"number": 12,
		"title": "Skylight Chapel",
		"biome": "boiler",
		"path": "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1/Audio/12_Skylight_Chapel/Quiet_Lobby_Loop.ogg"
	},
	"13_Observatory_of_Dreams": {
		"id": "13_Observatory_of_Dreams",
		"number": 13,
		"title": "Observatory of Dreams",
		"biome": "toxin_refinery",
		"path": "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1/Audio/13_Observatory_of_Dreams/Quiet_Lobby_Loop.ogg"
	},
	"14_The_Unsent_Letter": {
		"id": "14_The_Unsent_Letter",
		"number": 14,
		"title": "The Unsent Letter",
		"biome": "toxin_refinery",
		"path": "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1/Audio/14_The_Unsent_Letter/Quiet_Lobby_Loop.ogg"
	},
	"15_Wings_Beyond_Tomorrow": {
		"id": "15_Wings_Beyond_Tomorrow",
		"number": 15,
		"title": "Wings Beyond Tomorrow",
		"biome": "toxin_refinery",
		"path": "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1/Audio/15_Wings_Beyond_Tomorrow/Quiet_Lobby_Loop.ogg"
	},
	"16_Homeward_Through_Mist": {
		"id": "16_Homeward_Through_Mist",
		"number": 16,
		"title": "Homeward Through Mist",
		"biome": "toxin_refinery",
		"path": "res://Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1/Flying_Liberty_Lobby_OST_16_v1/Audio/16_Homeward_Through_Mist/Quiet_Lobby_Loop.ogg"
	}
}

const BIOME_CDS: Dictionary = {
	"maintenance": ["01_Copper_Hearth", "02_Scribes_of_the_Air", "03_Parlour_Above_the_Clouds", "04_Captains_Quadrille"],
	"factory": ["05_Clockwork_Pavane", "06_Fathers_Photograph", "07_Brass_and_Lace", "08_Liberty_Overture"],
	"boiler": ["09_Glass_Horizon", "10_Aether_Lullaby", "11_Time_Between_Gears", "12_Skylight_Chapel"],
	"toxin_refinery": ["13_Observatory_of_Dreams", "14_The_Unsent_Letter", "15_Wings_Beyond_Tomorrow", "16_Homeward_Through_Mist"]
}

func is_cd_collected(track_id: String) -> bool:
	return collected_cds.has(track_id)

func collect_cd(track_id: String) -> bool:
	if not CD_TRACKS.has(track_id):
		return false
	if not collected_cds.has(track_id):
		collected_cds.append(track_id)
		save_current()
		return true
	return false

func get_collected_cds() -> Array[String]:
	return collected_cds.duplicate()

func get_uncollected_cds(biome_name: String) -> Array[String]:
	var uncollected: Array[String] = []
	var pool_tracks: Array = BIOME_CDS.get(biome_name, [])
	for track_id in pool_tracks:
		if not collected_cds.has(track_id):
			uncollected.append(track_id)
	return uncollected

func has_uncollected_cds(biome_name: String) -> bool:
	return not get_uncollected_cds(biome_name).is_empty()

func reset_collected_cds() -> void:
	collected_cds.clear()

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
		"returns": data.get_value("ship", "returns", 0),
		"cds": data.get_value("ship", "collected_cds", []).size()}

func is_slot_empty(slot: int) -> bool:
	var inf := info(slot)
	if not inf.exists:
		return true
	return inf.xp == 0 and inf.victories == 0 and inf.skills <= 1 and int(inf.get("returns", 0)) == 0 and int(inf.get("cds", 0)) == 0

func delete_slot(slot: int) -> Error:
	if slot < 1 or slot > 3:
		return ERR_INVALID_PARAMETER
	var slot_file := path(slot)
	if FileAccess.file_exists(slot_file):
		var err := DirAccess.remove_absolute(slot_file)
		if err != OK:
			return err
	if slot == 1:
		var legacy_file := directory.path_join("skill_tree.cfg")
		if FileAccess.file_exists(legacy_file):
			DirAccess.remove_absolute(legacy_file)
	if active_slot == slot:
		active_slot = 0
		collected_cds.clear()
		var progress = get_node_or_null("/root/CoreProgression")
		if progress != null:
			progress.xp = 0
			progress.special_items = 0
			progress.unlocked_skills.assign(["root"])
			progress.changed.emit()
		var config = get_node_or_null("/root/RunConfig")
		if config != null:
			config.best_room = 0
			config.victories = 0
			config.active = false
			config.sync_return_pending = false
			config.core_elements.clear()
		var crew = get_node_or_null("/root/ShipCrew")
		if crew != null:
			crew.return_count = 0
			if crew.COCKPIT_LAYOUTS.size() > 0:
				crew.cockpit_layout = crew.COCKPIT_LAYOUTS[0].duplicate()
	return OK

func select_slot(slot: int) -> Error:
	if slot < 1 or slot > 3:
		return ERR_INVALID_PARAMETER
	var progress = get_node("/root/CoreProgression")
	var config = get_node("/root/RunConfig")
	var crew = get_node("/root/ShipCrew")
	active_slot = slot
	collected_cds.clear()
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
	var saved_cds = data.get_value("ship", "collected_cds", [])
	if saved_cds is Array or saved_cds is PackedStringArray:
		for cd in saved_cds:
			collected_cds.append(str(cd))
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
	data.set_value("ship", "collected_cds", collected_cds)
	return data.save(path(active_slot))

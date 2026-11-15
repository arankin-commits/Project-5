extends RefCounted

static func select_rooms(data: Dictionary, rng: RandomNumberGenerator) -> Array:
	var available: Array = []
	var bosses: Array = []
	for room in data.rooms:
		if room.get("boss",false):
			bosses.append(room)
		else:
			available.append(room)
	var shared_boss_layout := data.has("boss_encounter")
	var required := 9 if shared_boss_layout else 8
	if available.size() < required or (not shared_boss_layout and bosses.is_empty()):
		push_error("Room pool needs enough unique layouts for eight rooms and a boss; repeats are not allowed.")
		return []
	var selected: Array = []
	for i in required:
		var pick := rng.randi_range(0,available.size()-1)
		selected.append(available[pick].duplicate(true))
		available.remove_at(pick)
	if shared_boss_layout:
		selected[8].merge(data.boss_encounter,true)
	else:
		selected.append(bosses[rng.randi_range(0,bosses.size()-1)].duplicate(true))
	return selected

class_name ElementalSystem
extends RefCounted

# ==============================================================================
# ELEMENTAL SYSTEM & RULES ENGINE
# Defines elemental damage colors, reactions, statuses, meters, and terrain rules.
# ==============================================================================

# 1. Damage Number Elemental Colors
const ELEMENT_COLORS: Dictionary = {
	"fire": Color("ff3b30"),
	"burn": Color("ff3b30"),
	"explosive": Color("ff3b30"),
	"earth": Color("a65e2e"),
	"lightning": Color("ffe600"),
	"electricity": Color("ffe600"),
	"water": Color("3399ff"),
	"rust": Color("3399ff"),
	"wind": Color("38d978"),
	"ice": Color("a8f0ff"),
	"frost": Color("a8f0ff"),
	"frozen_blue": Color("a8f0ff"),
	"frozen blue": Color("a8f0ff"),
	"regular": Color("cccccc"),
	"physical": Color("cccccc"),
	"default": Color("cccccc"),
	"grey": Color("cccccc"),
	"gray": Color("cccccc")
}

static func get_element_color(element: String) -> Color:
	var key := element.to_lower().strip_edges().replace(" ", "_")
	return ELEMENT_COLORS.get(key, Color("cccccc"))

# 2. Elemental Status State per Entity
class StatusState:
	var burn_timer: float = 0.0
	var burn_meter: float = 0.0
	var frost_timer: float = 0.0
	var frost_meter: float = 0.0
	var frozen_timer: float = 0.0
	var wet_timer: float = 0.0
	var mud_timer: float = 0.0
	var wind_fanned_timer: float = 0.0 # +25% burn tick damage for 3s
	var cc_resistance: float = 0.0     # Boss diminishing returns on hard CC
	var is_boss: bool = false
	var last_reaction: String = ""

	func is_burning() -> bool:
		return burn_timer > 0.0

	func is_frost() -> bool:
		return frost_timer > 0.0

	func is_frozen() -> bool:
		return frozen_timer > 0.0

	func is_wet() -> bool:
		return wet_timer > 0.0

	func is_muddy() -> bool:
		return mud_timer > 0.0

	func update(delta: float) -> void:
		burn_timer = maxf(0.0, burn_timer - delta)
		frost_timer = maxf(0.0, frost_timer - delta)
		frozen_timer = maxf(0.0, frozen_timer - delta)
		wet_timer = maxf(0.0, wet_timer - delta)
		mud_timer = maxf(0.0, mud_timer - delta)
		wind_fanned_timer = maxf(0.0, wind_fanned_timer - delta)
		if is_boss and cc_resistance > 0.0:
			cc_resistance = maxf(0.0, cc_resistance - delta * 0.1)
		
		# If burn ends, meter resets
		if burn_timer <= 0.0:
			burn_meter = 0.0
			wind_fanned_timer = 0.0
		# If frost ends and not frozen, frost meter resets
		if frost_timer <= 0.0 and frozen_timer <= 0.0:
			frost_meter = 0.0

# 3. Damage Calculation with Status Multipliers
static func calculate_elemental_damage(base_damage: float, element: String, state: StatusState) -> float:
	var elem := element.to_lower().strip_edges()
	var dmg := base_damage
	
	# Ice/Frost and Lightning/Electricity do 50% more damage if enemy is under Wet status
	if state.is_wet():
		if elem in ["ice", "frost", "lightning", "electricity"]:
			dmg *= 1.5
	
	# Earth and Burn damage do 50% damage to frozen enemies
	if state.is_frozen():
		if elem in ["earth", "burn", "fire"]:
			dmg *= 0.5
			
	return dmg

# 4. Burn Tick Calculation
static func calculate_burn_tick(base_tick: float, state: StatusState) -> float:
	# Wind increases Burn tick damage by 25% for 3 seconds
	if state.wind_fanned_timer > 0.0:
		return base_tick * 1.25
	return base_tick

# 5. Core Elemental Reactions & Status Application
static func apply_burn(state: StatusState, duration := 4.0, buildup := 25.0) -> Dictionary:
	# Enemies cannot be burned under Wet status
	if state.is_wet():
		return {"applied": false, "reason": "wet_immune", "reaction": "none"}
	
	# Applying Burn on top of Frost/Frozen cancels both and applies Wet status
	# Reset corresponding buildup meters to zero
	if state.is_frost() or state.is_frozen():
		state.frost_timer = 0.0
		state.frost_meter = 0.0
		state.frozen_timer = 0.0
		state.burn_timer = 0.0
		state.burn_meter = 0.0
		state.wet_timer = 4.0
		state.last_reaction = "vaporize_wet"
		return {"applied": true, "reaction": "vaporize_wet", "result": "wet"}
	
	# Reapplying Burn resets its duration instead of adding time
	state.burn_timer = duration
	
	# Burn meter can only increase while Burn is active
	state.burn_meter += buildup
	if state.burn_meter >= 100.0:
		# Explosion triggers: meter resets to zero, excess buildup discarded
		state.burn_meter = 0.0
		state.last_reaction = "burn_explosion"
		return {"applied": true, "reaction": "burn_explosion"}
	
	state.last_reaction = "burn"
	return {"applied": true, "reaction": "burn"}

static func apply_frost(state: StatusState, duration := 4.0, buildup := 25.0) -> Dictionary:
	# Applying Frost to a burning enemy cancels both statuses and applies Wet
	# Enemies cannot be under frost or frozen status while under burn
	if state.is_burning():
		state.burn_timer = 0.0
		state.burn_meter = 0.0
		state.wind_fanned_timer = 0.0
		state.frost_timer = 0.0
		state.frost_meter = 0.0
		state.frozen_timer = 0.0
		state.wet_timer = 4.0
		state.last_reaction = "melt_wet"
		return {"applied": true, "reaction": "melt_wet", "result": "wet"}
	
	# During Freeze duration, additional Frost hits deal normal damage but do not build another Freeze
	if state.is_frozen():
		return {"applied": false, "reason": "already_frozen", "reaction": "none"}
	
	# Frost meter attack gain is doubled under Wet status
	var effective_gain := buildup * (2.0 if state.is_wet() else 1.0)
	state.frost_meter = minf(100.0, state.frost_meter + effective_gain)
	
	# Freeze Meter cannot rise above 100. When freezing occurs, meter resets to zero
	if state.frost_meter >= 100.0:
		state.frost_meter = 0.0
		var freeze_dur := duration
		if state.is_boss:
			# Bosses cannot be permanently stunned, frozen, or trapped.
			# Repeated hard crowd control grants temporary resistance
			freeze_dur *= maxf(0.2, 1.0 - state.cc_resistance)
			state.cc_resistance = minf(0.8, state.cc_resistance + 0.3)
		state.frozen_timer = freeze_dur
		state.last_reaction = "freeze"
		return {"applied": true, "reaction": "freeze"}
	
	# Reapplying Frost resets duration
	state.frost_timer = duration
	state.last_reaction = "frost"
	return {"applied": true, "reaction": "frost"}

static func apply_wet(state: StatusState, duration := 4.0) -> Dictionary:
	# Applying Wet to a burning enemy extinguishes Burn and resets its Burn meter to zero
	if state.is_burning():
		state.burn_timer = 0.0
		state.burn_meter = 0.0
		state.wind_fanned_timer = 0.0
	
	# Reapplying Wet resets its duration instead of adding time
	state.wet_timer = duration
	state.last_reaction = "wet"
	return {"applied": true, "reaction": "wet"}

static func apply_wind(state: StatusState, duration := 3.0) -> Dictionary:
	# Wind increases Burn tick damage by 25% for 3 seconds.
	# Repeated Wind hits refresh the duration rather than stacking the bonus
	if state.is_burning():
		state.wind_fanned_timer = duration
		state.last_reaction = "wind_fanned_burn"
		return {"applied": true, "reaction": "wind_fanned_burn"}
	return {"applied": false, "reaction": "none"}

static func apply_earth(state: StatusState, duration := 2.0) -> Dictionary:
	# Earth attacks against Wet enemies apply Mud, slowing their movement by 20% for 2 seconds
	if state.is_wet():
		state.mud_timer = duration
		state.last_reaction = "mud"
		return {"applied": true, "reaction": "mud"}
	return {"applied": true, "reaction": "earth"}

static func apply_lightning(state: StatusState) -> Dictionary:
	# Lightning hitting a burning enemy triggers an immediate additional Burn tick, without reducing Burn duration
	if state.is_burning():
		state.last_reaction = "lightning_burn_tick"
		return {"applied": true, "reaction": "lightning_burn_tick", "extra_burn_tick": true}
	return {"applied": true, "reaction": "lightning"}

# 6. Wind Knockback Spread
# Knocking back a Burning enemy or Wet enemy spreads Wet to the first enemy it collides with if source was wind
static func check_wind_knockback_spread(source_state: StatusState, target_state: StatusState, knockback_source: String) -> bool:
	if knockback_source == "wind" and (source_state.is_burning() or source_state.is_wet()):
		apply_wet(target_state, 4.0)
		return true
	return false

# 7. Boss Knockback Rule
# Knockback effects are halved against bosses
static func get_effective_knockback(distance: float, is_boss: bool) -> float:
	return distance * 0.5 if is_boss else distance

# 8. Lightning Chain Target Selection
# Cannot hit the same enemy twice during the same chain; prioritizes closest unhit enemy
static func pick_next_chain_target(origin: Vector2, candidate_nodes: Array, hit_targets: Array) -> Node2D:
	var closest: Node2D = null
	var min_dist := INF
	for node in candidate_nodes:
		if not is_instance_valid(node) or node in hit_targets or node.get("health", 0.0) <= 0.0:
			continue
		var dist: float = origin.distance_to(node.global_position)
		if dist < min_dist:
			min_dist = dist
			closest = node
	return closest

# 9. Terrain & Construct Interactions
class TerrainInteractions:
	# Water puddle interactions:
	# - Ice freezes puddle into temporary slippery surface
	# - Fire evaporates water puddle into steam cloud obscuring vision without applying Burn
	# - Lightning electrifies water puddle briefly, damaging grounded enemies inside
	static func interact_puddle(puddle: Dictionary, element: String) -> String:
		match element.to_lower():
			"ice", "frost":
				puddle["state"] = "frozen_slippery"
				return "frozen_slippery"
			"fire", "burn":
				puddle["state"] = "steam_cloud"
				return "steam_cloud"
			"lightning", "electricity":
				puddle["state"] = "electrified"
				return "electrified"
		return puddle.get("state", "water")

	# Earth construct interactions:
	# - Fire attacks heat rock construct for 5 seconds (enemies colliding receive Burn)
	# - Ice attacks freeze Earth constructs (touching enemies accumulate Frost meter)
	static func interact_earth_construct(construct: Dictionary, element: String) -> String:
		match element.to_lower():
			"fire", "burn":
				construct["heated_timer"] = 5.0
				return "heated"
			"ice", "frost":
				construct["frozen_timer"] = 5.0
				return "frozen"
		return "neutral"

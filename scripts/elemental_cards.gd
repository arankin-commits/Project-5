class_name ElementalCards
extends RefCounted

# ==============================================================================
# ELEMENTAL CARDS SYSTEM
# Defines cards across 6 elements (Lightning, Fire, Water, Wind, Ice, Earth),
# base core effects, card drafting (3 choices, rarity weights, prerequisites).
# ==============================================================================

# Rarity Weights (Commons appear more often than Rares, Rares more than Epics, etc.)
# Default: Common ~58%, Rare ~26%, Epic ~12%, Legendary ~4%
const RARITY_WEIGHTS: Dictionary = {
	"common": 58,
	"rare": 26,
	"epic": 12,
	"legendary": 4
}

# When trap buff is active ("Upgrade rarity increased for future rewards")
const TRAP_BUFF_RARITY_WEIGHTS: Dictionary = {
	"common": 38,
	"rare": 34,
	"epic": 20,
	"legendary": 8
}

# Base Core Effects per Element
const BASE_CORE_EFFECTS: Dictionary = {
	"lightning": {
		"focus": "Burst damage, speed, chaining, multiple enemies",
		"spread_chance": 0.35,
		"secondary_damage_ratio": 0.50,
		"description": "Lightning has a 35% chance to spread to the closest enemy within range. Secondary strikes deal 50% damage."
	},
	"fire": {
		"focus": "Damage over time, rapid attacks, explosive damage",
		"burn_dps": 6.0,
		"burn_duration": 3.0,
		"total_burn_damage": 18.0,
		"burn_meter_gain_on_explosion": 10.0,
		"wind_burn_dps": 9.0,
		"wind_burn_bonus": 0.50,
		"description": "Burn deals 6 damage/sec for 3s (18 total). Wind increases to 9/sec. Burn meter gains 10 per qualifying hit once Explosion unlocked."
	},
	"water": {
		"focus": "Weakening enemies, rust damage, armor reduction, elemental synergy",
		"wet_damage_reduction": 0.20,
		"wet_duration": 3.0,
		"lightning_ice_damage_mult": 1.50,
		"rust_damage_active": false,
		"description": "Wet reduces enemy damage by 20% for 3s. Lightning and Ice deal 50% more elemental damage against Wet enemies."
	},
	"wind": {
		"focus": "Knockback, collision damage, movement, stuns",
		"knockback_distance_bonus": 0.25,
		"wall_collision_damage": 16.0,
		"enemy_collision_damage_with_pinball": 8.0,
		"wall_collision_stun": 0.5,
		"description": "Knockback distance +25%. Wall collisions deal 16 Wind damage and stun for 0.5s. Enemy collisions deal 8 Wind damage when Pinball unlocked."
	},
	"ice": {
		"focus": "Crowd control, slowing, freezing, trapping, execution",
		"frost_slow": 0.25,
		"frost_duration": 3.0,
		"freeze_meter_gain_on_freeze": 10.0,
		"freeze_duration": 2.0,
		"wet_freeze_meter_gain": 20.0,
		"boss_freeze_damage": 80.0,
		"description": "Frost slows enemy movement by 25% for 3s. Freeze meter gains 10 per hit (20 if Wet) once Freeze unlocked. Bosses take 80 Ice damage instead of freezing."
	},
	"earth": {
		"focus": "Heavy damage, defense, constructs, projectile deflection",
		"max_stationary_constructs": 3,
		"max_orbiting_rocks": 3,
		"rock_existence_counter": 3,
		"construct_existence_counter": 5,
		"orbiting_rock_contact_damage": 16.0,
		"orbiting_rock_launch_damage": 32.0,
		"description": "Max 3 orbiting rocks (16 contact / 32 launch damage, 3 existence) and 3 stationary constructs (5 existence). Rocks block/deflect projectiles."
	}
}

# Complete Card Database (66 cards: 11 per element)
const CARDS: Dictionary = {
	# ==========================================================================
	# 1. LIGHTNING CARDS
	# ==========================================================================
	"lightning_attack": {
		"id": "lightning_attack",
		"element": "lightning",
		"rarity": "common",
		"name": "Lightning Attack",
		"damage": "8 / 8 / 12",
		"effect": "8 / 8 / 12 per combo hit",
		"description": "Combo strikes deal 8 / 8 / 12 elemental Lightning damage.",
		"prerequisite": ""
	},
	"lightning_special": {
		"id": "lightning_special",
		"element": "lightning",
		"rarity": "common",
		"name": "Lightning Special",
		"damage": "20",
		"effect": "20 to each enemy hit",
		"description": "Special attack deals 20 elemental Lightning damage to each enemy struck.",
		"prerequisite": ""
	},
	"lightning_armor": {
		"id": "lightning_armor",
		"element": "lightning",
		"rarity": "common",
		"name": "Lightning Armor",
		"damage": "16",
		"effect": "16 to the enemy that attacks you. Getting hit while charging energy does lightning damage",
		"description": "Retaliates with 16 Lightning damage to attacking melee enemies. Getting hit while charging energy deals Lightning damage.",
		"prerequisite": ""
	},
	"lightning_dash": {
		"id": "lightning_dash",
		"element": "lightning",
		"rarity": "common",
		"name": "Lightning Dash",
		"damage": "18",
		"effect": "18 to each enemy dashed through. Dashing through an enemy causes lightning to strike down on them",
		"description": "Dashing through an enemy causes lightning to strike down on them for 18 damage.",
		"prerequisite": ""
	},
	"lightning_slam": {
		"id": "lightning_slam",
		"element": "lightning",
		"rarity": "rare",
		"name": "Lightning Slam",
		"damage": "40",
		"effect": "Ground Slam will electrify the ground, and after a second, a massive delayed lightning strike deals 40 damage to enemies inside the Ground Slam AoE.",
		"description": "Ground Slam electrifies the ground. After 1 second, a massive delayed lightning strike deals 40 damage to enemies inside the AoE.",
		"prerequisite": ""
	},
	"electric_energy": {
		"id": "electric_energy",
		"element": "lightning",
		"rarity": "rare",
		"name": "Electric Energy",
		"damage": "-",
		"effect": "Energy charging speed increased by 200%. Cannot move while charging.",
		"description": "Energy charging speed increased by 200%. Cannot move while charging.",
		"prerequisite": ""
	},
	"stronger_lightning": {
		"id": "stronger_lightning",
		"element": "lightning",
		"rarity": "rare",
		"name": "Stronger Lightning",
		"damage": "50%",
		"effect": "Lightning can spread to two additional enemies, dealing 50% damage to each.",
		"description": "Lightning spreads to two additional enemies, dealing 50% of the original strike to each.",
		"prerequisite": ""
	},
	"raging_tempest": {
		"id": "raging_tempest",
		"element": "lightning",
		"rarity": "epic",
		"name": "Raging Tempest",
		"damage": "18",
		"effect": "Every 30 energy gained while charging triggers lightning strikes dealing 18 damage each to up to three nearby enemies.",
		"description": "Every 30 energy gained while charging triggers lightning strikes dealing 18 damage each to up to three nearby enemies.",
		"prerequisite": ""
	},
	"chain_lightning": {
		"id": "chain_lightning",
		"element": "lightning",
		"rarity": "epic",
		"name": "Chain Lightning",
		"damage": "50%",
		"effect": "Lightning can chain through up to four additional enemies. Each chain hit deals 50% of the original strike.",
		"description": "Lightning can chain through up to 4 additional enemies. Each chain hit deals 50% of the original strike.",
		"prerequisite": ""
	},
	"light_speed": {
		"id": "light_speed",
		"element": "lightning",
		"rarity": "epic",
		"name": "Light Speed",
		"damage": "-",
		"effect": "Dash becomes an instant teleport. Lightning Dash still affects enemies between the starting and ending locations.",
		"description": "Dash becomes an instant teleport. Lightning Dash still strikes enemies along the teleport path.",
		"prerequisite": ""
	},
	"lightning_overload": {
		"id": "lightning_overload",
		"element": "lightning",
		"rarity": "legendary",
		"name": "Lightning Overload",
		"damage": "60%",
		"effect": "Lightning strikes deal 60% of their damage to all other enemies within a small radius. This replaces ordinary lightning spreading.",
		"description": "Lightning strikes deal 60% of their damage to all enemies within a small radius. Replaces ordinary lightning spreading.",
		"prerequisite": ""
	},

	# ==========================================================================
	# 2. FIRE CARDS
	# ==========================================================================
	"fire_attack": {
		"id": "fire_attack",
		"element": "fire",
		"rarity": "common",
		"name": "Fire Attack",
		"damage": "6/s",
		"effect": "Applies Burn: 6 per second",
		"description": "Normal strikes apply Burn dealing 6 Fire damage per second for 3 seconds.",
		"prerequisite": ""
	},
	"fire_special": {
		"id": "fire_special",
		"element": "fire",
		"rarity": "common",
		"name": "Fire Special",
		"damage": "6/s",
		"effect": "Applies Burn: 6 per second",
		"description": "Special attack applies Burn dealing 6 Fire damage per second to all enemies hit.",
		"prerequisite": ""
	},
	"fire_armor": {
		"id": "fire_armor",
		"element": "fire",
		"rarity": "common",
		"name": "Fire Armor",
		"damage": "6/s",
		"effect": "Applies Burn: 6 per second to the attacker. Being attacked while charging energy applies Burn to enemies",
		"description": "Applies Burn (6 dmg/sec) to the attacker. Being attacked while charging energy applies Burn to surrounding enemies.",
		"prerequisite": ""
	},
	"fire_dash": {
		"id": "fire_dash",
		"element": "fire",
		"rarity": "common",
		"name": "Fire Dash",
		"damage": "6/s",
		"effect": "Applies Burn: 6 per second",
		"description": "Dashing through enemies applies Burn dealing 6 Fire damage per second.",
		"prerequisite": ""
	},
	"fire_trail": {
		"id": "fire_trail",
		"element": "fire",
		"rarity": "rare",
		"name": "Fire Trail",
		"damage": "6/s",
		"effect": "Leaves a trail lasting 3 seconds. Applies and refreshes Burn on grounded enemies.",
		"description": "Dash leaves a blazing trail for 3 seconds that applies and refreshes Burn on grounded enemies.",
		"prerequisite": ""
	},
	"fire_spread": {
		"id": "fire_spread",
		"element": "fire",
		"rarity": "rare",
		"name": "Fire Spread",
		"damage": "6/s",
		"effect": "Killing a burning enemy applies a fresh Burn to the closest enemy.",
		"description": "Killing a burning enemy spreads a fresh Burn to the nearest enemy.",
		"prerequisite": ""
	},
	"fire_slam": {
		"id": "fire_slam",
		"element": "fire",
		"rarity": "rare",
		"name": "Fire Slam",
		"damage": "18",
		"effect": "Ground Slam produces a ring of fire that expands outwards and burns enemies it passes through. The expanding ring of fire deals 18 Fire damage and applies Burn.",
		"description": "Ground Slam produces an expanding ring of fire dealing 18 Fire damage and applying Burn.",
		"prerequisite": ""
	},
	"explosion": {
		"id": "explosion",
		"element": "fire",
		"rarity": "epic",
		"name": "Explosion",
		"damage": "100",
		"effect": "Reaching 100 Burn meter causes 100 explosive damage. Resets the meter to zero.",
		"description": "Unlocks Burn meter (10 gain/hit). Reaching 100 Burn meter causes 100 explosive damage and resets meter to zero.",
		"prerequisite": ""
	},
	"scorching_end": {
		"id": "scorching_end",
		"element": "fire",
		"rarity": "epic",
		"name": "Scorching End",
		"damage": "8/s",
		"effect": "Enemies killed by explosions leave burning ground for 3 seconds. Deals 8 Fire damage per second to grounded enemies inside it.",
		"description": "Enemies killed by explosions leave burning ground for 3s dealing 8 Fire damage per second.",
		"prerequisite": ""
	},
	"lasting_fire": {
		"id": "lasting_fire",
		"element": "fire",
		"rarity": "epic",
		"name": "Lasting Fire",
		"damage": "30 total",
		"effect": "Increases Burn duration to 5 seconds, for 30 total Burn damage.",
		"description": "Increases Burn duration to 5 seconds, dealing 30 total Burn damage.",
		"prerequisite": ""
	},
	"explosive_fury": {
		"id": "explosive_fury",
		"element": "fire",
		"rarity": "legendary",
		"name": "Explosive Fury",
		"damage": "60 / 100",
		"effect": "Explosions deal 60 explosive damage to surrounding enemies. Enemies with at least 70 Burn meter immediately trigger their own 100-damage explosion.",
		"description": "Explosions deal 60 explosive damage to surrounding enemies. Enemies with at least 70 Burn meter immediately trigger their own 100-damage explosion.",
		"prerequisite": "explosion"
	},

	# ==========================================================================
	# 3. WATER CARDS
	# ==========================================================================
	"water_attack": {
		"id": "water_attack",
		"element": "water",
		"rarity": "common",
		"name": "Water Attack",
		"damage": "-",
		"effect": "Applies Wet for 3 seconds.",
		"description": "Normal attacks apply Wet for 3 seconds, reducing enemy damage by 20%.",
		"prerequisite": ""
	},
	"water_special": {
		"id": "water_special",
		"element": "water",
		"rarity": "common",
		"name": "Water Special",
		"damage": "-",
		"effect": "Applies Wet to all enemies hit.",
		"description": "Special attack applies Wet for 3 seconds to all enemies hit.",
		"prerequisite": ""
	},
	"water_armor": {
		"id": "water_armor",
		"element": "water",
		"rarity": "common",
		"name": "Water Armor",
		"damage": "-",
		"effect": "Applies Wet to the attacker. Being attacked while charging energy applies Wet",
		"description": "Applies Wet to attacking enemies. Being attacked while charging energy applies Wet to surrounding enemies.",
		"prerequisite": ""
	},
	"water_dash": {
		"id": "water_dash",
		"element": "water",
		"rarity": "common",
		"name": "Water Dash",
		"damage": "-",
		"effect": "Applies Wet to enemies dashed through.",
		"description": "Dashing through enemies applies Wet for 3 seconds.",
		"prerequisite": ""
	},
	"tidal_slam": {
		"id": "tidal_slam",
		"element": "water",
		"rarity": "rare",
		"name": "Tidal Slam",
		"damage": "16",
		"effect": "Ground Slam releases an expanding wave that deals 16 Water damage, pushes enemies away, and applies Wet.",
		"description": "Ground Slam releases an expanding tidal wave that deals 16 Water damage, pushes enemies away, and applies Wet.",
		"prerequisite": ""
	},
	"water_damage": {
		"id": "water_damage",
		"element": "water",
		"rarity": "rare",
		"name": "Water Damage",
		"damage": "-",
		"effect": "Wet now reduces enemy damage by 35%",
		"description": "Wet now reduces enemy damage by 35% (up from 20%).",
		"prerequisite": ""
	},
	"erosion": {
		"id": "erosion",
		"element": "water",
		"rarity": "rare",
		"name": "Erosion",
		"damage": "+5%/s (max +25%)",
		"effect": "Wet enemies take an additional 5% regular damage for each second they remain Wet, capped at 25%.",
		"description": "Wet enemies take +5% additional regular damage per second they remain Wet, up to a maximum of 25%.",
		"prerequisite": ""
	},
	"drenched": {
		"id": "drenched",
		"element": "water",
		"rarity": "epic",
		"name": "Drenched",
		"damage": "-",
		"effect": "Wet duration increased to 5 seconds.",
		"description": "Increases Wet duration to 5 seconds.",
		"prerequisite": ""
	},
	"whirlpool": {
		"id": "whirlpool",
		"element": "water",
		"rarity": "epic",
		"name": "Whirlpool",
		"damage": "8/s (max 24)",
		"effect": "Creates a whirlpool for 3 seconds, dealing 8 Water damage per second and continuously applying Wet. Maximum base damage: 24.",
		"description": "Creates a whirlpool for 3s dealing 8 Water damage/sec (24 max) and continuously applying Wet.",
		"prerequisite": ""
	},
	"rust": {
		"id": "rust",
		"element": "water",
		"rarity": "epic",
		"name": "Rust",
		"damage": "8/s (24 total)",
		"effect": "Wet now deals 8 Rust damage per second. A full three-second Wet duration deals 24 damage.",
		"description": "Wet now deals 8 Rust damage per second (24 damage across a standard 3-second Wet duration).",
		"prerequisite": ""
	},
	"wear_and_tear": {
		"id": "wear_and_tear",
		"element": "water",
		"rarity": "legendary",
		"name": "Wear and Tear",
		"damage": "+3/tick (max 32)",
		"effect": "Each consecutive Rust tick increases the next tick's damage by 3, up to a maximum of 32 damage per tick.",
		"description": "Each consecutive Rust tick increases the next tick's damage by 3, up to a maximum of 32 damage per tick.",
		"prerequisite": "rust"
	},

	# ==========================================================================
	# 4. WIND CARDS
	# ==========================================================================
	"wind_attack": {
		"id": "wind_attack",
		"element": "wind",
		"rarity": "common",
		"name": "Wind Attack",
		"damage": "5 / 5 / 8",
		"effect": "5 / 5 / 8 plus knockback",
		"description": "Normal strikes deal 5 / 5 / 8 Wind damage plus increased knockback.",
		"prerequisite": ""
	},
	"wind_special": {
		"id": "wind_special",
		"element": "wind",
		"rarity": "common",
		"name": "Wind Special",
		"damage": "14",
		"effect": "14 plus knockback",
		"description": "Special attack deals 14 Wind damage plus heavy knockback to all enemies hit.",
		"prerequisite": ""
	},
	"wind_armor": {
		"id": "wind_armor",
		"element": "wind",
		"rarity": "common",
		"name": "Wind Armor",
		"damage": "10",
		"effect": "10 to nearby enemies plus knockback. Being attacked while charging energy does wind damage and knockback to the attacker",
		"description": "Deals 10 Wind damage and knocks back nearby enemies. Being attacked while charging energy retaliates with Wind damage and knockback.",
		"prerequisite": ""
	},
	"wind_dash": {
		"id": "wind_dash",
		"element": "wind",
		"rarity": "common",
		"name": "Wind Dash",
		"damage": "8",
		"effect": "8 to enemies dashed through, pulling them behind the player",
		"description": "Deals 8 Wind damage to enemies dashed through, vortexing them behind the player.",
		"prerequisite": ""
	},
	"pinball": {
		"id": "pinball",
		"element": "wind",
		"rarity": "rare",
		"name": "Pinball",
		"damage": "8",
		"effect": "Enemy-to-enemy collisions deal 8 damage to both enemies and transfer momentum.",
		"description": "Enemy-to-enemy collisions deal 8 Wind damage to both enemies and transfer momentum.",
		"prerequisite": ""
	},
	"fleet_foot": {
		"id": "fleet_foot",
		"element": "wind",
		"rarity": "rare",
		"name": "Fleet Foot",
		"damage": "+25% speed",
		"effect": "Dashing through an enemy increases movement speed by 25% for 2 seconds.",
		"description": "Dashing through an enemy increases player movement speed by 25% for 2 seconds.",
		"prerequisite": ""
	},
	"gust": {
		"id": "gust",
		"element": "wind",
		"rarity": "rare",
		"name": "Gust",
		"damage": "+30% knockback",
		"effect": "All knockback distances are increased by another 30%.",
		"description": "All knockback distances are increased by another 30%.",
		"prerequisite": ""
	},
	"vortex": {
		"id": "vortex",
		"element": "wind",
		"rarity": "epic",
		"name": "Vortex",
		"damage": "5 / 5 / 8",
		"effect": "Normal attacks pull enemies toward the player instead of pushing them away. Damage remains 5 / 5 / 8.",
		"description": "Normal attacks pull enemies toward the player instead of pushing them away (5 / 5 / 8 damage).",
		"prerequisite": ""
	},
	"come_hither": {
		"id": "come_hither",
		"element": "wind",
		"rarity": "epic",
		"name": "Come Hither",
		"damage": "12",
		"effect": "Enemies that collide with a wall or construct are pushed back off it, dealing 12 additional Wind damage.",
		"description": "Enemies that collide with a wall or construct rebound, taking 12 additional Wind damage.",
		"prerequisite": ""
	},
	"wind_bomb": {
		"id": "wind_bomb",
		"element": "wind",
		"rarity": "legendary",
		"name": "Wind Bomb",
		"damage": "24",
		"effect": "Enemy collisions create a shockwave dealing 24 Wind damage and knocking back nearby enemies.",
		"description": "Enemy collisions trigger a shockwave dealing 24 Wind damage and knocking back nearby enemies.",
		"prerequisite": ""
	},

	# ==========================================================================
	# 5. ICE CARDS
	# ==========================================================================
	"ice_attack": {
		"id": "ice_attack",
		"element": "ice",
		"rarity": "common",
		"name": "Ice Attack",
		"damage": "5 / 5 / 8",
		"effect": "5 / 5 / 8 and applies Frost",
		"description": "Normal strikes deal 5 / 5 / 8 Ice damage and apply Frost (25% slow for 3s).",
		"prerequisite": ""
	},
	"ice_special": {
		"id": "ice_special",
		"element": "ice",
		"rarity": "common",
		"name": "Ice Special",
		"damage": "14",
		"effect": "14 and applies Frost",
		"description": "Special attack deals 14 Ice damage and applies Frost to each enemy hit.",
		"prerequisite": ""
	},
	"ice_armor": {
		"id": "ice_armor",
		"element": "ice",
		"rarity": "common",
		"name": "Ice Armor",
		"damage": "12",
		"effect": "12 to the attacker and applies Frost. While charging, energy does Ice damage to attacking enemies",
		"description": "Deals 12 Ice damage and applies Frost to attackers. Energy charging damages attacking enemies with Ice.",
		"prerequisite": ""
	},
	"ice_dash": {
		"id": "ice_dash",
		"element": "ice",
		"rarity": "common",
		"name": "Ice Dash",
		"damage": "10",
		"effect": "10 and applies Frost",
		"description": "Dashing through enemies deals 10 Ice damage and applies Frost.",
		"prerequisite": ""
	},
	"ice_slam": {
		"id": "ice_slam",
		"element": "ice",
		"rarity": "rare",
		"name": "Ice Slam",
		"damage": "22",
		"effect": "Ground Slam creates ice pillars around enemies caught in its area. Ice pillars deal 22 Ice damage and trap eligible enemies for 2 seconds.",
		"description": "Ground Slam creates ice pillars dealing 22 Ice damage and trapping eligible enemies for 2 seconds.",
		"prerequisite": ""
	},
	"frost_recharge": {
		"id": "frost_recharge",
		"element": "ice",
		"rarity": "rare",
		"name": "Frost Recharge",
		"damage": "3-hit barrier",
		"effect": "Encase yourself in ice to charge energy. Protects the player from three hits while charging. Cannot move or cancel until fully charged.",
		"description": "Encase yourself in ice while charging energy. Protects from 3 hits. Cannot move or cancel until fully charged.",
		"prerequisite": ""
	},
	"snow_down": {
		"id": "snow_down",
		"element": "ice",
		"rarity": "rare",
		"name": "Snow Down",
		"damage": "40% slow",
		"effect": "Increases Frost movement slow from 25% to 40%.",
		"description": "Increases Frost movement slow from 25% to 40%.",
		"prerequisite": ""
	},
	"freeze": {
		"id": "freeze",
		"element": "ice",
		"rarity": "epic",
		"name": "Freeze",
		"damage": "80 (Boss)",
		"effect": "Freezes non-boss enemies for 2 seconds when their Freeze meter reaches 100. Bosses take 80 Ice damage instead.",
		"description": "Unlocks Freeze meter (10 gain/hit, 20 if Wet). Freezes enemies for 2s at 100 meter. Bosses take 80 Ice damage instead.",
		"prerequisite": ""
	},
	"everlasting_winter": {
		"id": "everlasting_winter",
		"element": "ice",
		"rarity": "epic",
		"name": "Everlasting Winter",
		"damage": "-",
		"effect": "Frost duration increased to 5 seconds.",
		"description": "Increases Frost duration from 3 seconds to 5 seconds.",
		"prerequisite": ""
	},
	"cold_spirit": {
		"id": "cold_spirit",
		"element": "ice",
		"rarity": "epic",
		"name": "Cold Spirit",
		"damage": "-25% attack speed",
		"effect": "Frost reduces enemy attack speed by 25%.",
		"description": "Frost reduces enemy attack speed by 25%.",
		"prerequisite": ""
	},
	"flash_freeze": {
		"id": "flash_freeze",
		"element": "ice",
		"rarity": "legendary",
		"name": "Flash Freeze",
		"damage": "Execute / 160-240",
		"effect": "Frozen non-boss enemies below 15% maximum health immediately shatter and die. Boss Freeze burst damage increases from 80 to 160.",
		"description": "Frozen non-boss enemies below 15% max health shatter and die. Boss Freeze damage increases to 160 (240 if Wet).",
		"prerequisite": "freeze"
	},

	# ==========================================================================
	# 6. EARTH CARDS
	# ==========================================================================
	"earthen_attack": {
		"id": "earthen_attack",
		"element": "earth",
		"rarity": "common",
		"name": "Earthen Attack",
		"damage": "10 / 10 / 14",
		"effect": "10 / 10 / 14",
		"description": "Normal strikes deal 10 / 10 / 14 elemental Earth damage.",
		"prerequisite": ""
	},
	"earthen_special": {
		"id": "earthen_special",
		"element": "earth",
		"rarity": "common",
		"name": "Earthen Special",
		"damage": "24",
		"effect": "24 to each enemy hit",
		"description": "Special attack deals 24 Earth damage to each enemy hit.",
		"prerequisite": ""
	},
	"earthen_armor": {
		"id": "earthen_armor",
		"element": "earth",
		"rarity": "common",
		"name": "Earthen Armor: Orbiting Wall",
		"damage": "16 contact",
		"effect": "Creates a rock every 45 energy. Rocks deal 16 damage on contact. Rocks also block projectiles.",
		"description": "Creates an orbiting rock every 45 energy. Rocks deal 16 damage on contact and block projectiles.",
		"prerequisite": ""
	},
	"earthen_dash": {
		"id": "earthen_dash",
		"element": "earth",
		"rarity": "common",
		"name": "Earthen Dash: Stone Creation",
		"damage": "-",
		"effect": "Creates a stationary construct at the dash starting location. Deals no initial damage.",
		"description": "Creates a stationary construct (5 existence) at dash start. Deals no initial damage.",
		"prerequisite": ""
	},
	"earthen_slam": {
		"id": "earthen_slam",
		"element": "earth",
		"rarity": "rare",
		"name": "Earthen Slam",
		"damage": "28",
		"effect": "Ground Slam releases earth spikes, dealing 28 Earth damage to grounded enemies.",
		"description": "Ground Slam releases earth spikes dealing 28 Earth damage to grounded enemies.",
		"prerequisite": ""
	},
	"earth_arsenal": {
		"id": "earth_arsenal",
		"element": "earth",
		"rarity": "rare",
		"name": "Earth Arsenal",
		"damage": "5 max rocks",
		"effect": "Maximum orbiting rocks increased from 3 to 5.",
		"description": "Increases maximum orbiting rocks from 3 to 5.",
		"prerequisite": ""
	},
	"orbiting_fortress": {
		"id": "orbiting_fortress",
		"element": "earth",
		"rarity": "rare",
		"name": "Orbiting Fortress",
		"damage": "Deflect",
		"effect": "Rocks now deflect projectiles.",
		"description": "Orbiting rocks now deflect enemy projectiles back instead of merely blocking them.",
		"prerequisite": ""
	},
	"rock_shot": {
		"id": "rock_shot",
		"element": "earth",
		"rarity": "epic",
		"name": "Rock Shot",
		"damage": "32 per rock",
		"effect": "Allows the player to launch orbiting rocks at enemies, dealing 32 Earth damage per rock.",
		"description": "Allows launching orbiting rocks at enemies, dealing 32 Earth damage per rock.",
		"prerequisite": ""
	},
	"rocksplosion": {
		"id": "rocksplosion",
		"element": "earth",
		"rarity": "epic",
		"name": "Rocksplosion",
		"damage": "36",
		"effect": "Rocks that reach zero existence explode, dealing 36 Earth damage to nearby enemies and staggering them for 0.5 seconds.",
		"description": "Rocks reaching zero existence explode for 36 Earth damage and stagger enemies for 0.5s.",
		"prerequisite": ""
	},
	"earth_bender": {
		"id": "earth_bender",
		"element": "earth",
		"rarity": "epic",
		"name": "Earth Bender",
		"damage": "32 return",
		"effect": "Launched rocks return after hitting an enemy if they have remaining existence. Launch damage remains 32.",
		"description": "Launched rocks return to orbit after hitting an enemy if they have remaining existence (32 damage).",
		"prerequisite": "rock_shot"
	},
	"shotgun": {
		"id": "shotgun",
		"element": "earth",
		"rarity": "legendary",
		"name": "Shotgun",
		"damage": "12 x 3",
		"effect": "A launched rock splits into three smaller rocks after its first impact. Each fragment deals 12 Earth damage to a different enemy.",
		"description": "Launched rocks split into 3 fragments on first impact, each dealing 12 Earth damage to different enemies.",
		"prerequisite": "rock_shot"
	}
}

# ==============================================================================
# CARD QUERY METHODS
# ==============================================================================

static func get_card(card_id: String) -> Dictionary:
	return CARDS.get(card_id, {})

static func has_card(card_id: String) -> bool:
	return CARDS.has(card_id)

static func get_element_cards(element: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var elem := element.to_lower().strip_edges()
	for card_id in CARDS:
		var c: Dictionary = CARDS[card_id]
		if c.get("element", "") == elem:
			result.append(c)
	return result

static func get_cards_by_rarity(element: String, rarity: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var elem := element.to_lower().strip_edges()
	var rar := rarity.to_lower().strip_edges()
	for card_id in CARDS:
		var c: Dictionary = CARDS[card_id]
		if c.get("element", "") == elem and c.get("rarity", "") == rar:
			result.append(c)
	return result

static func can_offer_card(card_id: String, owned_cards: Array) -> bool:
	if not CARDS.has(card_id):
		return false
	var card: Dictionary = CARDS[card_id]
	# Cannot show if already owned
	if owned_cards.has(card_id):
		return false
	# Check prerequisite requirement
	var prereq: String = card.get("prerequisite", "")
	if not prereq.is_empty():
		if not owned_cards.has(prereq):
			return false
	return true

# ==============================================================================
# CARD DRAFTING ALGORITHM
# Generates exactly 3 distinct card choices for an element:
# - Commons appear more often than Rares, Rares more than Epics, Epics more than Legendaries
# - Cards with prerequisites cannot show up if prerequisite is not owned
# - Unowned cards are offered first
# ==============================================================================

static func roll_elemental_cards(element: String, owned_cards: Array, trap_buff := false, rng: RandomNumberGenerator = null) -> Array[Dictionary]:
	var elem := element.to_lower().strip_edges()
	var available_cards := get_element_cards(elem)
	if available_cards.is_empty():
		return []

	# Filter by unowned and prerequisite satisfied
	var eligible: Array[Dictionary] = []
	for card in available_cards:
		var cid: String = card["id"]
		if can_offer_card(cid, owned_cards):
			eligible.append(card)

	# If all cards are owned or eligible pool is small:
	# Fallback to any cards whose prerequisite is met
	if eligible.size() < 3:
		for card in available_cards:
			var cid: String = card["id"]
			var prereq: String = card.get("prerequisite", "")
			var prereq_ok := prereq.is_empty() or owned_cards.has(prereq)
			if prereq_ok and not eligible.has(card):
				eligible.append(card)

	# If total available is 3 or less, return all
	if eligible.size() <= 3:
		return eligible.duplicate()

	# Use active weights
	var weights_map: Dictionary = TRAP_BUFF_RARITY_WEIGHTS if trap_buff else RARITY_WEIGHTS

	var chosen: Array[Dictionary] = []
	var pool: Array[Dictionary] = eligible.duplicate()

	var local_rng := rng
	if local_rng == null:
		local_rng = RandomNumberGenerator.new()
		local_rng.randomize()

	# Pick 3 distinct cards using rarity-weighted sampling
	while chosen.size() < 3 and not pool.is_empty():
		# Calculate total weight of remaining pool
		var total_weight := 0
		for card in pool:
			var r: String = card.get("rarity", "common")
			total_weight += int(weights_map.get(r, 10))

		if total_weight <= 0:
			# Fallback to uniform pick
			var idx := local_rng.randi_range(0, pool.size() - 1)
			chosen.append(pool[idx])
			pool.remove_at(idx)
			continue

		var roll := local_rng.randi_range(1, total_weight)
		var cumulative := 0
		var picked_idx := -1
		for i in pool.size():
			var card: Dictionary = pool[i]
			var r: String = card.get("rarity", "common")
			cumulative += int(weights_map.get(r, 10))
			if roll <= cumulative:
				picked_idx = i
				break

		if picked_idx >= 0 and picked_idx < pool.size():
			chosen.append(pool[picked_idx])
			pool.remove_at(picked_idx)
		else:
			var idx := local_rng.randi_range(0, pool.size() - 1)
			chosen.append(pool[idx])
			pool.remove_at(idx)

	return chosen

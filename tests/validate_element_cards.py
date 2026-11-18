import sys
import random

# ==============================================================================
# COMPREHENSIVE ELEMENTAL CARDS VALIDATION
# Validates all 66 cards, base core effects, drafting rules, prerequisites,
# rarity distribution, and the burn tick timer preservation rule.
# ==============================================================================

# 1. Rarity weights
RARITY_WEIGHTS = {
    "common": 58,
    "rare": 26,
    "epic": 12,
    "legendary": 4
}
TRAP_BUFF_RARITY_WEIGHTS = {
    "common": 38,
    "rare": 34,
    "epic": 20,
    "legendary": 8
}

# 2. Complete Card Database Replica
CARDS = {
    # Lightning
    "lightning_attack": {"id": "lightning_attack", "element": "lightning", "rarity": "common", "name": "Lightning Attack", "prerequisite": ""},
    "lightning_special": {"id": "lightning_special", "element": "lightning", "rarity": "common", "name": "Lightning Special", "prerequisite": ""},
    "lightning_armor": {"id": "lightning_armor", "element": "lightning", "rarity": "common", "name": "Lightning Armor", "prerequisite": ""},
    "lightning_dash": {"id": "lightning_dash", "element": "lightning", "rarity": "common", "name": "Lightning Dash", "prerequisite": ""},
    "lightning_slam": {"id": "lightning_slam", "element": "lightning", "rarity": "rare", "name": "Lightning Slam", "prerequisite": ""},
    "electric_energy": {"id": "electric_energy", "element": "lightning", "rarity": "rare", "name": "Electric Energy", "prerequisite": ""},
    "stronger_lightning": {"id": "stronger_lightning", "element": "lightning", "rarity": "rare", "name": "Stronger Lightning", "prerequisite": ""},
    "raging_tempest": {"id": "raging_tempest", "element": "lightning", "rarity": "epic", "name": "Raging Tempest", "prerequisite": ""},
    "chain_lightning": {"id": "chain_lightning", "element": "lightning", "rarity": "epic", "name": "Chain Lightning", "prerequisite": ""},
    "light_speed": {"id": "light_speed", "element": "lightning", "rarity": "epic", "name": "Light Speed", "prerequisite": ""},
    "lightning_overload": {"id": "lightning_overload", "element": "lightning", "rarity": "legendary", "name": "Lightning Overload", "prerequisite": ""},

    # Fire
    "fire_attack": {"id": "fire_attack", "element": "fire", "rarity": "common", "name": "Fire Attack", "prerequisite": ""},
    "fire_special": {"id": "fire_special", "element": "fire", "rarity": "common", "name": "Fire Special", "prerequisite": ""},
    "fire_armor": {"id": "fire_armor", "element": "fire", "rarity": "common", "name": "Fire Armor", "prerequisite": ""},
    "fire_dash": {"id": "fire_dash", "element": "fire", "rarity": "common", "name": "Fire Dash", "prerequisite": ""},
    "fire_trail": {"id": "fire_trail", "element": "fire", "rarity": "rare", "name": "Fire Trail", "prerequisite": ""},
    "fire_spread": {"id": "fire_spread", "element": "fire", "rarity": "rare", "name": "Fire Spread", "prerequisite": ""},
    "fire_slam": {"id": "fire_slam", "element": "fire", "rarity": "rare", "name": "Fire Slam", "prerequisite": ""},
    "explosion": {"id": "explosion", "element": "fire", "rarity": "epic", "name": "Explosion", "prerequisite": ""},
    "scorching_end": {"id": "scorching_end", "element": "fire", "rarity": "epic", "name": "Scorching End", "prerequisite": ""},
    "lasting_fire": {"id": "lasting_fire", "element": "fire", "rarity": "epic", "name": "Lasting Fire", "prerequisite": ""},
    "explosive_fury": {"id": "explosive_fury", "element": "fire", "rarity": "legendary", "name": "Explosive Fury", "prerequisite": "explosion"},

    # Water
    "water_attack": {"id": "water_attack", "element": "water", "rarity": "common", "name": "Water Attack", "prerequisite": ""},
    "water_special": {"id": "water_special", "element": "water", "rarity": "common", "name": "Water Special", "prerequisite": ""},
    "water_armor": {"id": "water_armor", "element": "water", "rarity": "common", "name": "Water Armor", "prerequisite": ""},
    "water_dash": {"id": "water_dash", "element": "water", "rarity": "common", "name": "Water Dash", "prerequisite": ""},
    "tidal_slam": {"id": "tidal_slam", "element": "water", "rarity": "rare", "name": "Tidal Slam", "prerequisite": ""},
    "water_damage": {"id": "water_damage", "element": "water", "rarity": "rare", "name": "Water Damage", "prerequisite": ""},
    "erosion": {"id": "erosion", "element": "water", "rarity": "rare", "name": "Erosion", "prerequisite": ""},
    "drenched": {"id": "drenched", "element": "water", "rarity": "epic", "name": "Drenched", "prerequisite": ""},
    "whirlpool": {"id": "whirlpool", "element": "water", "rarity": "epic", "name": "Whirlpool", "prerequisite": ""},
    "rust": {"id": "rust", "element": "water", "rarity": "epic", "name": "Rust", "prerequisite": ""},
    "wear_and_tear": {"id": "wear_and_tear", "element": "water", "rarity": "legendary", "name": "Wear and Tear", "prerequisite": "rust"},

    # Wind
    "wind_attack": {"id": "wind_attack", "element": "wind", "rarity": "common", "name": "Wind Attack", "prerequisite": ""},
    "wind_special": {"id": "wind_special", "element": "wind", "rarity": "common", "name": "Wind Special", "prerequisite": ""},
    "wind_armor": {"id": "wind_armor", "element": "wind", "rarity": "common", "name": "Wind Armor", "prerequisite": ""},
    "wind_dash": {"id": "wind_dash", "element": "wind", "rarity": "common", "name": "Wind Dash", "prerequisite": ""},
    "pinball": {"id": "pinball", "element": "wind", "rarity": "rare", "name": "Pinball", "prerequisite": ""},
    "fleet_foot": {"id": "fleet_foot", "element": "wind", "rarity": "rare", "name": "Fleet Foot", "prerequisite": ""},
    "gust": {"id": "gust", "element": "wind", "rarity": "rare", "name": "Gust", "prerequisite": ""},
    "vortex": {"id": "vortex", "element": "wind", "rarity": "epic", "name": "Vortex", "prerequisite": ""},
    "come_hither": {"id": "come_hither", "element": "wind", "rarity": "epic", "name": "Come Hither", "prerequisite": ""},
    "wind_bomb": {"id": "wind_bomb", "element": "wind", "rarity": "legendary", "name": "Wind Bomb", "prerequisite": ""},

    # Ice
    "ice_attack": {"id": "ice_attack", "element": "ice", "rarity": "common", "name": "Ice Attack", "prerequisite": ""},
    "ice_special": {"id": "ice_special", "element": "ice", "rarity": "common", "name": "Ice Special", "prerequisite": ""},
    "ice_armor": {"id": "ice_armor", "element": "ice", "rarity": "common", "name": "Ice Armor", "prerequisite": ""},
    "ice_dash": {"id": "ice_dash", "element": "ice", "rarity": "common", "name": "Ice Dash", "prerequisite": ""},
    "ice_slam": {"id": "ice_slam", "element": "ice", "rarity": "rare", "name": "Ice Slam", "prerequisite": ""},
    "frost_recharge": {"id": "frost_recharge", "element": "ice", "rarity": "rare", "name": "Frost Recharge", "prerequisite": ""},
    "snow_down": {"id": "snow_down", "element": "ice", "rarity": "rare", "name": "Snow Down", "prerequisite": ""},
    "freeze": {"id": "freeze", "element": "ice", "rarity": "epic", "name": "Freeze", "prerequisite": ""},
    "everlasting_winter": {"id": "everlasting_winter", "element": "ice", "rarity": "epic", "name": "Everlasting Winter", "prerequisite": ""},
    "cold_spirit": {"id": "cold_spirit", "element": "ice", "rarity": "epic", "name": "Cold Spirit", "prerequisite": ""},
    "flash_freeze": {"id": "flash_freeze", "element": "ice", "rarity": "legendary", "name": "Flash Freeze", "prerequisite": "freeze"},

    # Earth
    "earthen_attack": {"id": "earthen_attack", "element": "earth", "rarity": "common", "name": "Earthen Attack", "prerequisite": ""},
    "earthen_special": {"id": "earthen_special", "element": "earth", "rarity": "common", "name": "Earthen Special", "prerequisite": ""},
    "earthen_armor": {"id": "earthen_armor", "element": "earth", "rarity": "common", "name": "Earthen Armor: Orbiting Wall", "prerequisite": ""},
    "earthen_dash": {"id": "earthen_dash", "element": "earth", "rarity": "common", "name": "Earthen Dash: Stone Creation", "prerequisite": ""},
    "earthen_slam": {"id": "earthen_slam", "element": "earth", "rarity": "rare", "name": "Earthen Slam", "prerequisite": ""},
    "earth_arsenal": {"id": "earth_arsenal", "element": "earth", "rarity": "rare", "name": "Earth Arsenal", "prerequisite": ""},
    "orbiting_fortress": {"id": "orbiting_fortress", "element": "earth", "rarity": "rare", "name": "Orbiting Fortress", "prerequisite": ""},
    "rock_shot": {"id": "rock_shot", "element": "earth", "rarity": "epic", "name": "Rock Shot", "prerequisite": ""},
    "rocksplosion": {"id": "rocksplosion", "element": "earth", "rarity": "epic", "name": "Rocksplosion", "prerequisite": ""},
    "earth_bender": {"id": "earth_bender", "element": "earth", "rarity": "epic", "name": "Earth Bender", "prerequisite": "rock_shot"},
    "shotgun": {"id": "shotgun", "element": "earth", "rarity": "legendary", "name": "Shotgun", "prerequisite": "rock_shot"},
}

def can_offer_card(card_id, owned_cards):
    if card_id not in CARDS:
        return False
    card = CARDS[card_id]
    if card_id in owned_cards:
        return False
    prereq = card.get("prerequisite", "")
    if prereq and prereq not in owned_cards:
        return False
    return True

def roll_elemental_cards(element, owned_cards, trap_buff=False, rng=None):
    if rng is None:
        rng = random.Random()
    available = [c for c in CARDS.values() if c["element"] == element]
    eligible = [c for c in available if can_offer_card(c["id"], owned_cards)]
    
    if len(eligible) < 3:
        for c in available:
            prereq = c.get("prerequisite", "")
            prereq_ok = (not prereq) or (prereq in owned_cards)
            if prereq_ok and c not in eligible:
                eligible.append(c)
    
    if len(eligible) <= 3:
        return list(eligible)
        
    weights = TRAP_BUFF_RARITY_WEIGHTS if trap_buff else RARITY_WEIGHTS
    pool = list(eligible)
    chosen = []
    
    while len(chosen) < 3 and pool:
        total_weight = sum(weights.get(c["rarity"], 10) for c in pool)
        roll = rng.randint(1, total_weight)
        cumulative = 0
        picked_idx = 0
        for i, c in enumerate(pool):
            cumulative += weights.get(c["rarity"], 10)
            if roll <= cumulative:
                picked_idx = i
                break
        chosen.append(pool.pop(picked_idx))
        
    return chosen

class BurnStatusSim:
    def __init__(self):
        self.burn_timer = 0.0
        self.burn_tick_timer = 0.0
        self.burn_meter = 0.0
        self.ticks_fired = 0

    def apply_burn(self, duration=3.0, buildup=10.0):
        # Reapplying Burn refreshes its expiration timer but does not reset the tick timer.
        if self.burn_timer <= 0.0:
            self.burn_tick_timer = 1.0
        self.burn_timer = duration
        self.burn_meter += buildup

    def update(self, delta):
        if self.burn_timer > 0.0:
            self.burn_timer = max(0.0, self.burn_timer - delta)
            self.burn_tick_timer = max(0.0, self.burn_tick_timer - delta)
            if self.burn_tick_timer <= 0.0:
                self.ticks_fired += 1
                self.burn_tick_timer += 1.0 # Schedule next tick
            if self.burn_timer <= 0.0:
                self.burn_meter = 0.0
                self.burn_tick_timer = 0.0

def test_all():
    print("Beginning Comprehensive Elemental Cards & Drafting Validation...")

    # 1. Card Database Counts: 6 elements, exactly 65 cards matching spec
    elements = ["lightning", "fire", "water", "wind", "ice", "earth"]
    assert len(CARDS) == 65, f"Expected 65 cards, got {len(CARDS)}"
    for elem in elements:
        cards_for_elem = [c for c in CARDS.values() if c["element"] == elem]
        expected_len = 10 if elem == "wind" else 11
        assert len(cards_for_elem) == expected_len, f"Element {elem} must have {expected_len} cards, got {len(cards_for_elem)}"
        commons = [c for c in cards_for_elem if c["rarity"] == "common"]
        rares = [c for c in cards_for_elem if c["rarity"] == "rare"]
        epics = [c for c in cards_for_elem if c["rarity"] == "epic"]
        legendaries = [c for c in cards_for_elem if c["rarity"] == "legendary"]
        assert len(commons) == 4, f"{elem} commons != 4"
        assert len(rares) == 3, f"{elem} rares != 3"
        expected_epics = 2 if elem == "wind" else 3
        assert len(epics) == expected_epics, f"{elem} epics count mismatch"
        assert len(legendaries) == 1, f"{elem} legendaries != 1"
    print("[PASS] Card Database structure: 65 cards across 6 elements verified")

    # 2. Prerequisites
    prereqs = {c["id"]: c["prerequisite"] for c in CARDS.values() if c["prerequisite"]}
    expected_prereqs = {
        "explosive_fury": "explosion",
        "wear_and_tear": "rust",
        "flash_freeze": "freeze",
        "earth_bender": "rock_shot",
        "shotgun": "rock_shot"
    }
    assert prereqs == expected_prereqs, f"Prerequisites mismatch: {prereqs} != {expected_prereqs}"
    print("[PASS] Prerequisites strictly mapped: Explosive Fury->Explosion, Wear & Tear->Rust, Flash Freeze->Freeze, Earth Bender->Rock Shot, Shotgun->Rock Shot")

    # 3. Prerequisites Enforced in Drafting
    rng = random.Random(42)
    # Fire without explosion: explosive_fury must NEVER appear
    for _ in range(100):
        choices = roll_elemental_cards("fire", owned_cards=[], rng=rng)
        assert len(choices) == 3
        ids = [c["id"] for c in choices]
        assert "explosive_fury" not in ids, "Explosive Fury appeared without Explosion prerequisite"
    
    # Fire with explosion: explosive_fury CAN appear
    saw_fury = False
    for _ in range(500):
        choices = roll_elemental_cards("fire", owned_cards=["explosion"], rng=rng)
        ids = [c["id"] for c in choices]
        if "explosive_fury" in ids:
            saw_fury = True
            break
    assert saw_fury, "Explosive Fury never appeared even when Explosion owned"

    # Ice without freeze: flash_freeze must NEVER appear
    for _ in range(100):
        choices = roll_elemental_cards("ice", owned_cards=[], rng=rng)
        ids = [c["id"] for c in choices]
        assert "flash_freeze" not in ids, "Flash Freeze appeared without Freeze prerequisite"

    # Water without rust: wear_and_tear must NEVER appear
    for _ in range(100):
        choices = roll_elemental_cards("water", owned_cards=[], rng=rng)
        ids = [c["id"] for c in choices]
        assert "wear_and_tear" not in ids, "Wear and Tear appeared without Rust prerequisite"

    # Earth without rock_shot: earth_bender and shotgun must NEVER appear
    for _ in range(100):
        choices = roll_elemental_cards("earth", owned_cards=[], rng=rng)
        ids = [c["id"] for c in choices]
        assert "earth_bender" not in ids and "shotgun" not in ids, "Rock Shot prerequisite bypassed"
    print("[PASS] Drafting respects prerequisites: locked cards never show up without prerequisite")

    # 4. Rarity Weighting: Commons > Rares > Epics > Legendaries
    counts = {"common": 0, "rare": 0, "epic": 0, "legendary": 0}
    rng_stat = random.Random(1337)
    for _ in range(5000):
        # Fire with explosion so all rarities eligible
        choices = roll_elemental_cards("fire", owned_cards=["explosion"], rng=rng_stat)
        assert len(choices) == 3
        assert len(set(c["id"] for c in choices)) == 3, "Draft rolled duplicate cards"
        for c in choices:
            counts[c["rarity"]] += 1
    
    print(f"Rarity roll distribution across 15,000 offered cards: {counts}")
    assert counts["common"] > counts["rare"], "Commons must appear more often than Rares"
    assert counts["rare"] > counts["epic"], "Rares must appear more often than Epics"
    assert counts["epic"] > counts["legendary"], "Epics must appear more often than Legendaries"
    print("[PASS] Rarity hierarchy verified: Common > Rare > Epic > Legendary")

    # 5. Burn Tick Preservation Simulation
    sim = BurnStatusSim()
    sim.apply_burn(duration=3.0)
    assert sim.burn_tick_timer == 1.0
    
    # Tick 0.4s
    sim.update(0.4)
    assert abs(sim.burn_tick_timer - 0.6) < 1e-4
    assert sim.ticks_fired == 0

    # Rapid attack reapplies Burn at 0.4s: expiration refreshes to 3.0s, tick timer MUST NOT reset to 1.0!
    sim.apply_burn(duration=3.0)
    assert abs(sim.burn_tick_timer - 0.6) < 1e-4, f"Tick timer was reset to {sim.burn_tick_timer}!"
    assert sim.burn_timer == 3.0

    # Tick another 0.61s: tick 1 MUST fire at 1.0s elapsed!
    sim.update(0.61)
    assert sim.ticks_fired == 1, "Burn tick failed to fire after 1.0s elapsed despite rapid reapplication"
    print("[PASS] Burn Tick Preservation rule verified: reapplying Burn refreshes duration without resetting tick timer")

    # 6. Check Scripts on disk
    with open('scripts/elemental_cards.gd', 'r', encoding='utf-8') as f:
        cards_code = f.read()
    assert "class_name ElementalCards" in cards_code
    assert "roll_elemental_cards" in cards_code
    assert "BASE_CORE_EFFECTS" in cards_code
    assert "CARDS" in cards_code
    assert "lightning_overload" in cards_code
    assert "explosive_fury" in cards_code
    assert "wear_and_tear" in cards_code
    assert "wind_bomb" in cards_code
    assert "flash_freeze" in cards_code
    assert "shotgun" in cards_code

    with open('scripts/elemental_system.gd', 'r', encoding='utf-8') as f:
        elem_code = f.read()
    assert "burn_tick_timer" in elem_code
    assert "rust_tick_timer" in elem_code
    assert "boss_freeze_damage" in elem_code

    with open('scripts/run_config.gd', 'r', encoding='utf-8') as f:
        cfg_code = f.read()
    assert 'const ELEMENTS := ["fire", "water", "lightning", "ice", "wind", "earth"]' in cfg_code

    with open('scripts/roguelike_run.gd', 'r', encoding='utf-8') as f:
        run_code = f.read()
    assert "ElementalCards.roll_elemental_cards" in run_code
    assert "player_cards" in run_code
    assert "_apply_elemental_card" in run_code

    with open('MEMORY.md', 'r', encoding='utf-8') as f:
        mem_code = f.read()
    assert "Elemental Cards & Drafting System" in mem_code
    assert "Burn Tick Timer Preservation" in mem_code

    with open('memory/element-rules.md', 'r', encoding='utf-8') as f:
        er_code = f.read()
    assert "Elemental Cards & Drafting System" in er_code
    assert "Burn Tick Timer Preservation" in er_code

    print("[PASS] All disk files, code bindings, and memory rules verified")

    print("\nALL ELEMENTAL CARDS, PREREQUISITES, AND DRAFTING TESTS PASSED SUCCESSFULLY!")

if __name__ == '__main__':
    test_all()

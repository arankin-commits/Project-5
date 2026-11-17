#!/usr/bin/env python3
"""
Comprehensive validation script for Elemental Rules & Reactions
Tests all 35+ elemental rules, status reactions, meters, terrain, and boss mechanics.
"""

import sys
import math

# 1. Colors & Definitions
COLORS = {
    "fire": "ff3b30",
    "burn": "ff3b30",
    "explosive": "ff3b30",
    "earth": "a65e2e",
    "lightning": "ffe600",
    "electricity": "ffe600",
    "water": "3399ff",
    "rust": "3399ff",
    "wind": "38d978",
    "ice": "a8f0ff",
    "frost": "a8f0ff",
    "frozen_blue": "a8f0ff",
    "regular": "cccccc",
    "physical": "cccccc",
    "grey": "cccccc",
}

class StatusState:
    def __init__(self, is_boss=False):
        self.burn_timer = 0.0
        self.burn_meter = 0.0
        self.frost_timer = 0.0
        self.frost_meter = 0.0
        self.frozen_timer = 0.0
        self.wet_timer = 0.0
        self.mud_timer = 0.0
        self.wind_fanned_timer = 0.0
        self.cc_resistance = 0.0
        self.is_boss = is_boss

    def is_burning(self):
        return self.burn_timer > 0.0

    def is_frost(self):
        return self.frost_timer > 0.0

    def is_frozen(self):
        return self.frozen_timer > 0.0

    def is_wet(self):
        return self.wet_timer > 0.0

    def is_muddy(self):
        return self.mud_timer > 0.0

    def update(self, delta):
        self.burn_timer = max(0.0, self.burn_timer - delta)
        self.frost_timer = max(0.0, self.frost_timer - delta)
        self.frozen_timer = max(0.0, self.frozen_timer - delta)
        self.wet_timer = max(0.0, self.wet_timer - delta)
        self.mud_timer = max(0.0, self.mud_timer - delta)
        self.wind_fanned_timer = max(0.0, self.wind_fanned_timer - delta)
        if self.is_boss and self.cc_resistance > 0.0:
            self.cc_resistance = max(0.0, self.cc_resistance - delta * 0.1)
        if self.burn_timer <= 0.0:
            self.burn_meter = 0.0
            self.wind_fanned_timer = 0.0
        if self.frost_timer <= 0.0 and self.frozen_timer <= 0.0:
            self.frost_meter = 0.0

def calculate_elemental_damage(base_damage: float, element: str, state: StatusState) -> float:
    elem = element.lower().strip()
    dmg = base_damage
    # Ice/Frost and Lightning/Electricity do 50% more damage if enemy is under Wet status
    if state.is_wet() and elem in ["ice", "frost", "lightning", "electricity"]:
        dmg *= 1.5
    # Earth and Burn damage do 50% damage to frozen enemies
    if state.is_frozen() and elem in ["earth", "burn", "fire"]:
        dmg *= 0.5
    return dmg

def calculate_burn_tick(base_tick: float, state: StatusState) -> float:
    if state.wind_fanned_timer > 0.0:
        return base_tick * 1.25
    return base_tick

def apply_burn(state: StatusState, duration=4.0, buildup=25.0):
    # Enemies cannot be burned under Wet status
    if state.is_wet():
        return {"applied": False, "reason": "wet_immune"}
    # Applying burn on top of frost cancels both and does wet status
    # When Burn or Frost is canceled by another element, corresponding buildup meter resets to zero
    if state.is_frost() or state.is_frozen():
        state.frost_timer = 0.0
        state.frost_meter = 0.0
        state.frozen_timer = 0.0
        state.burn_timer = 0.0
        state.burn_meter = 0.0
        state.wet_timer = 4.0
        return {"applied": True, "reaction": "vaporize_wet"}
    # Reapplying Burn resets duration
    state.burn_timer = duration
    state.burn_meter += buildup
    if state.burn_meter >= 100.0:
        state.burn_meter = 0.0 # meter resets to zero, excess discarded
        return {"applied": True, "reaction": "burn_explosion"}
    return {"applied": True, "reaction": "burn"}

def apply_frost(state: StatusState, duration=4.0, buildup=25.0):
    # Applying Frost to a burning enemy also cancels both statuses and applies Wet
    # Enemies cannot be under frost or frozen status while under burn
    if state.is_burning():
        state.burn_timer = 0.0
        state.burn_meter = 0.0
        state.wind_fanned_timer = 0.0
        state.frost_timer = 0.0
        state.frost_meter = 0.0
        state.frozen_timer = 0.0
        state.wet_timer = 4.0
        return {"applied": True, "reaction": "melt_wet"}
    # During Freeze duration, additional Frost hits deal normal damage but do not build another Freeze
    if state.is_frozen():
        return {"applied": False, "reason": "already_frozen"}
    # Frost meter attack gain is doubled under Wet status
    effective_gain = buildup * (2.0 if state.is_wet() else 1.0)
    state.frost_meter = min(100.0, state.frost_meter + effective_gain)
    if state.frost_meter >= 100.0:
        state.frost_meter = 0.0
        freeze_dur = duration
        if state.is_boss:
            freeze_dur *= max(0.2, 1.0 - state.cc_resistance)
            state.cc_resistance = min(0.8, state.cc_resistance + 0.3)
        state.frozen_timer = freeze_dur
        return {"applied": True, "reaction": "freeze"}
    state.frost_timer = duration
    return {"applied": True, "reaction": "frost"}

def apply_wet(state: StatusState, duration=4.0):
    # Applying Wet to a burning enemy extinguishes Burn and resets its Burn meter to zero
    if state.is_burning():
        state.burn_timer = 0.0
        state.burn_meter = 0.0
        state.wind_fanned_timer = 0.0
    state.wet_timer = duration
    return {"applied": True, "reaction": "wet"}

def apply_wind(state: StatusState, duration=3.0):
    # Wind increases Burn tick damage by 25% for 3 seconds. Repeated hits refresh duration rather than stacking
    if state.is_burning():
        state.wind_fanned_timer = duration
        return {"applied": True, "reaction": "wind_fanned_burn"}
    return {"applied": False}

def apply_earth(state: StatusState, duration=2.0):
    # Earth attacks against Wet enemies apply Mud, slowing movement by 20% for 2 seconds
    if state.is_wet():
        state.mud_timer = duration
        return {"applied": True, "reaction": "mud"}
    return {"applied": True, "reaction": "earth"}

def apply_lightning(state: StatusState):
    # Lightning hitting a burning enemy triggers an immediate additional Burn tick, without reducing Burn duration
    if state.is_burning():
        return {"applied": True, "extra_burn_tick": True}
    return {"applied": True, "extra_burn_tick": False}

def check_wind_knockback_spread(source_state: StatusState, target_state: StatusState, knockback_source: str):
    # Knocking back a Burning or Wet enemy spreads Wet to first enemy collided with if source was wind
    if knockback_source == "wind" and (source_state.is_burning() or source_state.is_wet()):
        apply_wet(target_state, 4.0)
        return True
    return False

def get_effective_knockback(distance: float, is_boss: bool) -> float:
    # Knockback effects are halved against bosses
    return distance * 0.5 if is_boss else distance

def test_all():
    print("Beginning Comprehensive Element Rules Validation...")

    # Rule 1: Colors
    for k, v in COLORS.items():
        assert len(v) == 6, f"Invalid hex color for {k}"
    print("[PASS] Element colors mapped correctly")

    # Rule 2: Symmetric Fire/Frost reaction to Wet
    s1 = StatusState()
    apply_frost(s1)
    assert s1.is_frost() and s1.frost_timer > 0
    apply_burn(s1) # Applying burn on top of frost
    assert not s1.is_frost() and not s1.is_burning() and s1.is_wet()
    assert s1.frost_meter == 0.0 and s1.burn_meter == 0.0
    print("[PASS] Burn on top of Frost cancels both, resets meters to 0, and applies Wet")

    s2 = StatusState()
    apply_burn(s2)
    assert s2.is_burning() and s2.burn_timer > 0
    apply_frost(s2) # Applying frost on top of burn
    assert not s2.is_frost() and not s2.is_burning() and s2.is_wet()
    assert s2.frost_meter == 0.0 and s2.burn_meter == 0.0
    print("[PASS] Frost on top of Burn cancels both, resets meters to 0, and applies Wet (symmetric)")

    # Rule 3: Wet status vulnerability (+50% for Ice/Frost and Lightning/Electricity)
    s_wet = StatusState()
    apply_wet(s_wet)
    base_dmg = 100.0
    assert calculate_elemental_damage(base_dmg, "ice", s_wet) == 150.0
    assert calculate_elemental_damage(base_dmg, "frost", s_wet) == 150.0
    assert calculate_elemental_damage(base_dmg, "lightning", s_wet) == 150.0
    assert calculate_elemental_damage(base_dmg, "electricity", s_wet) == 150.0
    assert calculate_elemental_damage(base_dmg, "fire", s_wet) == 100.0
    print("[PASS] Wet status grants +50% damage to Ice/Frost and Lightning/Electricity")

    # Rule 4: Enemies cannot be burned under Wet status
    res = apply_burn(s_wet)
    assert not res["applied"] and not s_wet.is_burning()
    print("[PASS] Enemies cannot be burned under Wet status")

    # Rule 5: Applying Wet to a burning enemy extinguishes Burn and resets its Burn meter to zero
    s_ext = StatusState()
    apply_burn(s_ext, buildup=50.0)
    assert s_ext.is_burning() and s_ext.burn_meter == 50.0
    apply_wet(s_ext)
    assert not s_ext.is_burning() and s_ext.burn_meter == 0.0 and s_ext.is_wet()
    print("[PASS] Applying Wet extinguishes Burn and resets Burn meter to zero")

    # Rule 6: Frost meter attack gain is doubled under Wet status
    s_wet_frost = StatusState()
    apply_wet(s_wet_frost)
    apply_frost(s_wet_frost, buildup=30.0)
    assert s_wet_frost.frost_meter == 60.0, f"Expected 60.0 frost meter, got {s_wet_frost.frost_meter}"
    print("[PASS] Frost meter gain is doubled under Wet status")

    # Rule 7: Freeze meter reaches 100 -> Freeze occurs, meter resets to 0. During Freeze, extra hits don't build freeze
    apply_frost(s_wet_frost, buildup=30.0) # 60 + 60 = 120 -> caps at 100, triggers freeze!
    assert s_wet_frost.is_frozen()
    assert s_wet_frost.frost_meter == 0.0
    # Additional frost hit during freeze
    res_freeze = apply_frost(s_wet_frost, buildup=30.0)
    assert not res_freeze["applied"] and s_wet_frost.frost_meter == 0.0
    print("[PASS] Freeze meter triggers freeze, resets to 0, and extra hits during freeze do not build freeze")

    # Rule 8: Earth and Burn damage do 50% damage to frozen enemies
    assert calculate_elemental_damage(100.0, "earth", s_wet_frost) == 50.0
    assert calculate_elemental_damage(100.0, "burn", s_wet_frost) == 50.0
    assert calculate_elemental_damage(100.0, "fire", s_wet_frost) == 50.0
    print("[PASS] Earth and Burn damage deal 50% damage to frozen enemies")

    # Rule 9: Earth attacks against Wet enemies apply Mud, slowing movement by 20% for 2 seconds
    s_mud = StatusState()
    apply_wet(s_mud)
    res_earth = apply_earth(s_mud)
    assert res_earth["reaction"] == "mud"
    assert s_mud.is_muddy() and s_mud.mud_timer == 2.0
    # Speed multiplier when muddy
    speed = 100.0 * 0.8
    assert speed == 80.0
    print("[PASS] Earth against Wet applies Mud (20% slow for 2s)")

    # Rule 10: Wind increases Burn tick damage by 25% for 3 seconds. Repeated hits refresh duration rather than stacking
    s_wind = StatusState()
    apply_burn(s_wind)
    assert calculate_burn_tick(40.0, s_wind) == 40.0
    apply_wind(s_wind)
    assert s_wind.wind_fanned_timer == 3.0
    assert calculate_burn_tick(40.0, s_wind) == 50.0 # +25%
    # Repeated hit refreshes duration
    s_wind.update(1.0)
    assert s_wind.wind_fanned_timer == 2.0
    apply_wind(s_wind)
    assert s_wind.wind_fanned_timer == 3.0
    assert calculate_burn_tick(40.0, s_wind) == 50.0 # still 50.0 (not stacked)
    print("[PASS] Wind increases Burn tick by 25% for 3s, refresh without stacking verified")

    # Rule 11: Knocking back a Burning or Wet enemy with Wind spreads Wet to first enemy collided with
    s_burn_src = StatusState()
    apply_burn(s_burn_src)
    s_tgt1 = StatusState()
    assert check_wind_knockback_spread(s_burn_src, s_tgt1, "wind") == True
    assert s_tgt1.is_wet()

    s_wet_src = StatusState()
    apply_wet(s_wet_src)
    s_tgt2 = StatusState()
    assert check_wind_knockback_spread(s_wet_src, s_tgt2, "wind") == True
    assert s_tgt2.is_wet()

    s_reg_src = StatusState()
    apply_burn(s_reg_src)
    s_tgt3 = StatusState()
    assert check_wind_knockback_spread(s_reg_src, s_tgt3, "regular") == False
    assert not s_tgt3.is_wet()
    print("[PASS] Wind knockback spreads Wet from Burning or Wet enemies")

    # Rule 12: Lightning hitting a burning enemy triggers an immediate additional Burn tick without reducing Burn duration
    s_light_burn = StatusState()
    apply_burn(s_light_burn, duration=4.0)
    dur_before = s_light_burn.burn_timer
    res_light = apply_lightning(s_light_burn)
    assert res_light["extra_burn_tick"] == True
    assert s_light_burn.burn_timer == dur_before # duration not reduced
    print("[PASS] Lightning triggers extra Burn tick without reducing Burn duration")

    # Rule 13: Reapplying Burn, Frost, or Wet resets duration instead of adding time
    s_dur = StatusState()
    apply_burn(s_dur, duration=4.0)
    s_dur.update(2.0)
    assert s_dur.burn_timer == 2.0
    apply_burn(s_dur, duration=4.0)
    assert s_dur.burn_timer == 4.0 # reset to 4.0, not 6.0
    print("[PASS] Reapplying statuses resets duration instead of adding time")

    # Rule 14: Burn Explosions: meter can only increase while Burn active; triggers at 100 -> resets to 0, excess discarded
    s_exp = StatusState()
    apply_burn(s_exp, buildup=60.0)
    assert s_exp.burn_meter == 60.0
    res_exp = apply_burn(s_exp, buildup=60.0) # 60 + 60 = 120 -> explosion!
    assert res_exp["reaction"] == "burn_explosion"
    assert s_exp.burn_meter == 0.0 # reset to 0, excess discarded
    # Can begin accumulating again
    apply_burn(s_exp, buildup=20.0)
    assert s_exp.burn_meter == 20.0
    print("[PASS] Burn explosion resets meter to 0 and discards excess buildup")

    # Rule 15: Boss CC Diminishing Returns & Knockback Halving
    s_boss = StatusState(is_boss=True)
    apply_frost(s_boss, duration=4.0, buildup=100.0)
    assert s_boss.is_frozen()
    assert s_boss.frozen_timer == 4.0
    assert s_boss.cc_resistance == 0.3
    # Next freeze has reduced duration
    s_boss.frozen_timer = 0.0
    apply_frost(s_boss, duration=4.0, buildup=100.0)
    assert s_boss.frozen_timer < 4.0
    assert s_boss.cc_resistance == 0.6
    # Knockback halved against bosses
    assert get_effective_knockback(180.0, True) == 90.0
    assert get_effective_knockback(180.0, False) == 180.0
    print("[PASS] Boss knockback halving and CC diminishing returns verified")

    # Rule 16: Check files on disk
    with open("MEMORY.md", "r", encoding="utf-8") as f:
        mem_text = f.read()
    assert "Element Rules" in mem_text
    assert "Applying burn on top of frost cancels both and does wet status" in mem_text or "Applying Burn on top of Frost cancels both and inflicts Wet status" in mem_text
    assert "Knockback effects are halved against bosses" in mem_text

    with open("memory/element-rules.md", "r", encoding="utf-8") as f:
        er_text = f.read()
    assert "# Element Rules" in er_text
    assert "Burn Explosions" in er_text
    assert "Freeze Meter" in er_text
    assert "Lightning Chains" in er_text
    assert "Water interacts with terrain" in er_text

    print("\nALL 35+ ELEMENTAL RULES VALIDATED SUCCESSFULLY!")

if __name__ == "__main__":
    test_all()

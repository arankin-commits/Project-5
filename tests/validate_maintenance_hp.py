#!/usr/bin/env python3
"""
Validation script for Maintenance Enemy Health (3x HP)
"""
import json
import re

def test_maintenance_hp():
    print("Testing Maintenance Enemy Health (3x HP)...")
    with open("data/enemies/industrial.json", "r", encoding="utf-8") as f:
        catalog = json.load(f)

    # Base HP before tripling:
    original_maint_hp = {
        "industrial_00": 35,
        "industrial_01": 12,
        "industrial_02": 110,
        "industrial_03": 90,
        "industrial_04": 130,
        "industrial_05": 80,
        "industrial_06": 80,
        "industrial_07": 60,
    }

    for key, orig_hp in original_maint_hp.items():
        expected_hp = orig_hp * 3
        actual_hp = catalog[key]["hp"]
        assert actual_hp == expected_hp, f"Expected {expected_hp} HP for {key} ({catalog[key]['name']}), got {actual_hp}"
        assert catalog[key]["biome_key"] == "maintenance"
        print(f"  [PASS] {key} ({catalog[key]['name']}): {orig_hp} -> {actual_hp} HP (3x)")

    # Verify other biomes were NOT modified
    expected_other_samples = {
        "industrial_08": 90,  # factory Conveyor Hound
        "industrial_12": 160, # factory Presswall Worker
        "industrial_16": 55,  # boiler Cinder Kettle
        "industrial_21": 155, # boiler Grate Mauler
        "industrial_25": 95,  # toxin_refinery Corrosion Eel
        "industrial_31": 170  # toxin_refinery Corrosion Shellback
    }
    for key, expected in expected_other_samples.items():
        assert catalog[key]["hp"] == expected, f"{key} in {catalog[key]['biome_key']} was altered: got {catalog[key]['hp']}, expected {expected}"
    print("  [PASS] Factory, Boiler, and Toxin Refinery enemy HPs are unmodified.")

    # Check roguelike_run.gd
    with open("scripts/roguelike_run.gd", "r", encoding="utf-8") as f:
        run_code = f.read()
    assert "enemy.health *= 3.0" in run_code, "roguelike_run.gd must scale non-industrial enemy health in maintenance by 3.0"
    print("  [PASS] roguelike_run.gd scales non-industrial maintenance spawns by 3x")

    # Check MEMORY.md and memory/biome-enemies.md
    with open("MEMORY.md", "r", encoding="utf-8") as f:
        mem_text = f.read()
    assert "Maintenance Enemy Health (3x)" in mem_text

    with open("memory/biome-enemies.md", "r", encoding="utf-8") as f:
        biome_text = f.read()
    assert "3x HP" in biome_text or "triple their base health" in biome_text

    # Check tests/test_memory_rules.gd
    with open("tests/test_memory_rules.gd", "r", encoding="utf-8") as f:
        test_text = f.read()
    assert "RULE 20: Maintenance Enemy Health (3x HP)" in test_text

    print("\nALL MAINTENANCE ENEMY HEALTH VALIDATION CHECKS PASSED!")

if __name__ == "__main__":
    test_maintenance_hp()

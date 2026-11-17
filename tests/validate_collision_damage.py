#!/usr/bin/env python3
"""
Validation script for Enemy Collision Damage & Knockback Scaling
"""
import re
import sys
import math

def calculate_collision_damage(knockback_power: float) -> float:
    if knockback_power <= 0.0:
        return 0.0
    return max(1.0, float(math.floor(knockback_power * 0.5 + 0.5)))

def test_damage_scaling():
    print("Testing collision damage scaling...")
    p12 = calculate_collision_damage(12.0)
    p65 = calculate_collision_damage(65.0)
    p90 = calculate_collision_damage(90.0)
    p180 = calculate_collision_damage(180.0)
    p0 = calculate_collision_damage(0.0)

    assert p12 == 6.0, f"Expected 6.0 for power 12.0, got {p12}"
    assert p65 == 33.0, f"Expected 33.0 for power 65.0, got {p65}"
    assert p90 == 45.0, f"Expected 45.0 for power 90.0, got {p90}"
    assert p180 == 90.0, f"Expected 90.0 for power 180.0, got {p180}"
    assert p0 == 0.0, f"Expected 0.0 for power 0.0, got {p0}"
    assert p180 > p90 > p65 > p12, "Damage scaling must be strictly increasing with knockback power"
    print("Collision damage scaling verified!")

def test_run_enemy_script():
    print("Checking scripts/run_enemy.gd...")
    with open("scripts/run_enemy.gd", "r", encoding="utf-8") as f:
        code = f.read()

    assert "func calculate_collision_damage(knockback_power: float) -> float:" in code
    assert "collision_mask |= 4" in code
    assert "calculate_collision_damage(" in code
    assert "wall_stun_timer = 0.3" in code
    assert "is_in_knockback" in code
    assert "func _die() -> void:" in code
    assert "take_damage(col_damage, Vector2.ZERO, 0.0, \"regular\")" in code
    assert "collider.call(\"take_damage\", col_damage, Vector2.ZERO, 0.0, \"regular\")" in code
    assert "collision_layer = 4" in code
    assert "collision_mask = 9" in code
    print("scripts/run_enemy.gd implementation verified!")

def test_industrial_enemy_script():
    print("Checking scripts/industrial_enemy.gd...")
    with open("scripts/industrial_enemy.gd", "r", encoding="utf-8") as f:
        code = f.read()

    assert "func _die() -> void:" in code
    assert "super.take_damage(amount, knockback, push_distance, element" in code
    assert "dying = true" in code
    print("scripts/industrial_enemy.gd implementation verified!")

def test_memory_md():
    print("Checking MEMORY.md documentation...")
    with open("MEMORY.md", "r", encoding="utf-8") as f:
        mem = f.read()

    assert "Enemy Collision Damage & Knockback Scaling" in mem
    assert "Enemy-Enemy Collision" in mem
    assert "Wall & Construct Collision" in mem
    assert "Knockback Power Damage Scaling" in mem
    print("MEMORY.md verified!")

def test_memory_rules_test():
    print("Checking tests/test_memory_rules.gd...")
    with open("tests/test_memory_rules.gd", "r", encoding="utf-8") as f:
        test_code = f.read()

    assert "RULE 19: Enemy Collision Damage & Knockback Scaling" in test_code
    assert "calculate_collision_damage" in test_code
    assert "apply_knockback(Vector2.RIGHT, 65.0)" in test_code
    assert "apply_knockback(Vector2.LEFT, 180.0)" in test_code
    print("tests/test_memory_rules.gd verified!")

class MockEnemy:
    def __init__(self, name, hp=100.0, kind="crawler"):
        self.name = name
        self.health = hp
        self.max_health = hp
        self.kind = kind
        self.active = True
        self.wall_stun_timer = 0.0
        self.state = "chase"
        self.cooldown = 1.0
        self.collision_layer = 4
        self.collision_mask = 9
        self.is_in_knockback = False
        self.defeated_count = 0
        self.damaged_events = []

    def calculate_collision_damage(self, power: float) -> float:
        return calculate_collision_damage(power)

    def damaged_emit(self, amount, knockback, element):
        self.damaged_events.append((amount, knockback, element))

    def defeated_emit(self):
        self.defeated_count += 1

    def _die(self):
        if not self.active and self.health <= 0:
            return
        self.active = False
        self.defeated_emit()

    def take_damage(self, amount: float, knockback=(0, 0), push_distance=12.0, element="regular", collider=None):
        if self.health <= 0 or not self.active:
            return
        self.health = max(0.0, self.health - amount)
        self.damaged_emit(amount, knockback, element)
        if self.health <= 0:
            self._die()
            return
        if self.kind != "boss" and (knockback[0] != 0 or knockback[1] != 0):
            self.apply_knockback(knockback, push_distance, collider)

    def apply_knockback(self, direction, distance, collider=None):
        if self.kind == "boss" or self.health <= 0 or self.is_in_knockback:
            return
        self.is_in_knockback = True
        old_mask = self.collision_mask
        self.collision_mask |= 4
        
        # Simulated collision
        if collider is not None:
            col_damage = self.calculate_collision_damage(distance)
            self.wall_stun_timer = 0.3
            self.state = "chase"
            self.cooldown = 1.0
            if isinstance(collider, MockEnemy):
                collider.take_damage(col_damage, (0, 0), 0.0, "regular")
                if collider.kind != "boss":
                    collider.wall_stun_timer = 0.3
                    collider.state = "chase"
                    collider.cooldown = max(collider.cooldown, 1.0)
                self.take_damage(col_damage, (0, 0), 0.0, "regular")
            else:
                # Wall or construct
                self.take_damage(col_damage, (0, 0), 0.0, "regular")
        self.collision_mask = old_mask
        self.is_in_knockback = False

def test_full_collision_simulation():
    print("Simulating enemy collision dynamics...")
    # 1. Enemy knocked into another enemy
    e1 = MockEnemy("crawler1", 100.0)
    e2 = MockEnemy("crawler2", 100.0)
    # Knock e1 into e2 with heavy strike (65.0)
    e1.take_damage(20.0, knockback=(1, 0), push_distance=65.0, element="regular", collider=e2)
    assert e1.health == 100.0 - 20.0 - 33.0, f"e1 health should be 47.0, got {e1.health}"
    assert e2.health == 100.0 - 33.0, f"e2 health should be 67.0, got {e2.health}"
    assert e1.wall_stun_timer == 0.3
    assert e2.wall_stun_timer == 0.3
    assert len(e1.damaged_events) == 2 # strike + collision
    assert len(e2.damaged_events) == 1 # collision
    assert e1.damaged_events[1][2] == "regular" # regular grey damage
    assert e2.damaged_events[0][2] == "regular"
    print("Enemy-enemy collision simulation passed!")

    # 2. Enemy knocked into wall with charged strike (180.0 -> 90.0 damage)
    e3 = MockEnemy("crawler3", 100.0)
    e3.take_damage(5.0, knockback=(-1, 0), push_distance=180.0, element="fire", collider="wall")
    assert e3.health == 100.0 - 5.0 - 90.0, f"e3 health should be 5.0, got {e3.health}"
    assert e3.wall_stun_timer == 0.3
    assert e3.damaged_events[0] == (5.0, (-1, 0), "fire")
    assert e3.damaged_events[1] == (90.0, (0, 0), "regular")
    print("Wall collision simulation passed!")

    # 3. Lethal collision damage defeats enemy exactly once
    e4 = MockEnemy("crawler4", 30.0)
    e4.take_damage(10.0, knockback=(1, 0), push_distance=65.0, element="regular", collider="wall")
    # Initial 10 dmg leaves 20 hp. Wall collision deals 33 dmg -> lethal!
    assert e4.health == 0.0
    assert e4.active == False
    assert e4.defeated_count == 1, f"Defeated count must be exactly 1, got {e4.defeated_count}"
    print("Lethal collision single-defeat simulation passed!")

    # 4. Open space knockback (no collision)
    e5 = MockEnemy("crawler5", 100.0)
    e5.take_damage(20.0, knockback=(1, 0), push_distance=65.0, element="regular", collider=None)
    assert e5.health == 80.0
    assert e5.wall_stun_timer == 0.0
    assert len(e5.damaged_events) == 1
    print("Open space knockback simulation passed!")

if __name__ == "__main__":
    test_damage_scaling()
    test_run_enemy_script()
    test_industrial_enemy_script()
    test_memory_md()
    test_memory_rules_test()
    test_full_collision_simulation()
    print("\nALL COLLISION DAMAGE VALIDATION CHECKS PASSED SUCCESSFULLY!")

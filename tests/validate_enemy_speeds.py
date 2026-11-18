import json
import math

BASE_MEDIUM_ROBOT_SPEED = 265.0
HEAVY_ROBOT_SPEED = 265.0 * 0.7  # 185.5

EXPECTED_BASE_SPEEDS = {
    "Tiny": BASE_MEDIUM_ROBOT_SPEED * 1.25,   # 331.25
    "Small": BASE_MEDIUM_ROBOT_SPEED * 1.15,  # 304.75
    "Medium": BASE_MEDIUM_ROBOT_SPEED,        # 265.0
    "Large": HEAVY_ROBOT_SPEED                # 185.5
}

def validate():
    with open("data/enemies/industrial.json", "r", encoding="utf-8") as f:
        catalog = json.load(f)

    assert len(catalog) == 33, f"Expected 33 enemies, got {len(catalog)}"

    counts = {"Tiny": 0, "Small": 0, "Medium": 0, "Large": 0}

    for enemy_id, data in catalog.items():
        size = data.get("size")
        assert size in EXPECTED_BASE_SPEEDS, f"Enemy {enemy_id} has invalid size: {size}"
        counts[size] += 1

        speed_units = float(data.get("speed"))
        pixel_speed = speed_units * 26.0
        expected_speed = EXPECTED_BASE_SPEEDS[size]

        assert math.isclose(pixel_speed, expected_speed, rel_tol=1e-4), (
            f"Enemy {enemy_id} ({size}) speed mismatch: "
            f"units={speed_units}, pixel_speed={pixel_speed}, expected={expected_speed}"
        )

    print("Enemy speed validation passed!")
    print(f"Validated size distributions: {counts}")
    for size, expected in EXPECTED_BASE_SPEEDS.items():
        print(f"  {size}: {expected:.2f} px/s ({expected/26.0:.6f} movement units)")

if __name__ == "__main__":
    validate()

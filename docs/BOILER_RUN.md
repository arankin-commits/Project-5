# The Boiler Below

Launch Godot 4.7.2, open `scenes/RoguelikeRun.tscn`, and press F6. The normal route remains Main Hall -> first top door -> Sync Pod -> E -> Start Roguelike Run. Medium is the only unlocked frame. The ship, core terminal, cockpit, and existing transitions are unchanged by this remake.

WASD moves at normalized speed. LMB attacks toward the cursor; J attacks in the facing direction. The third consecutive strike is stronger. RMB/K performs a radial heavy strike with a cooldown. Space dashes in the movement direction (or facing while standing), respects solid geometry, and grants brief invulnerability. E advances only near the teal lift marker after all waves are defeated and a salvage reward has been selected. Esc pauses; F3 shows room and furniture collision boundaries. No extra door artwork was added.

| Room | Encounter | Environment |
| --- | --- | --- |
| 1. Cinder Vestibule | Crawler introduction | Boiler house |
| 2. Coal Exchange | Crawlers and cannon sentry, coal cover | Coal handling |
| 3. Condensate Crossing | Sentries across condenser cover | Condenser hall |
| 4. Furnace Gallery | Two waves through furnace machinery | Boiler house |
| 5. Piston Works | Armored brute with support | Coal handling |
| 6. Steam Junction | Two waves and staggered steam vents | Condenser hall |
| 7. Pressure Lock | Two waves of mixed defenses | Boiler house |
| 8. Heart of the Boiler | Furnace Warden | Dedicated boss arena |

The Warden alternates telegraphed volleys, charges, and ground slams. Below half hull it enters Overpressure: faster attacks, larger slams, and denser volleys. Defeating it completes the district. Defeat and victory both offer a new run or a return to the Sync Chamber.

Rooms 1-7 repair 12 hull and offer three randomly selected upgrades. Damage, maximum hull, dash recharge, movement speed, and healing rewards are functional. Run-only upgrades reset on retry; the original core unlock system remains separate. Overclock increases enemy speed by 25%; Reinforcements adds two crawlers per chamber; Fragile Frame reduces starting/maximum hull from 100 to 70.

## Mapping and organization

Everything is Godot 2D. `scripts/boiler_space.gd` maps a 1000 x 1000 logical deck to native 1536 x 1024 painted pixels using `origin=(768,272)`, `axis_x=(0.724,0.337)`, and `axis_y=(-0.724,0.337)`. Artwork is never skewed or stretched to fake perspective. Foot collision shapes live in rendered coordinates; machinery footprints and AStarGrid2D navigation are generated from the same logical rectangles. The room boundary is inset to logical 55..945. Actors, enemies, and freestanding machinery share Y sorting; floor art and ground signals use fixed background layers. Camera2D smoothly follows within the room composition.

`data/boiler/rooms.json` defines the eight fixed layouts, scenery, vents, and waves. The four illustrated architectural shells are shared across these eight distinct obstacle/encounter layouts. Spawns and salvage choices use a run seed; the overall room sequence is fixed, not a procedural branching map.

The Medium artwork lives in `art/characters/medium_v2/`: eight directions each for idle, stride, and strike. The controller uses a two-pose gait with procedural bob/lean and an attack pose; this is not a full frame-by-frame animation set. Enemies have distinct crawler, cannon, brute, and boss behavior; the brute reuses the crawler illustration at a larger scale. Painted artwork uses linear filtering and PNG transparency. Original ship art is preserved.

`roguelike_run.gd` coordinates the run; `medium_robot.gd` owns combat movement; `run_enemy.gd` owns enemy AI and boss states; `boiler_room.gd` builds art/collision/navigation; `run_projectile.gd`, `run_effect.gd`, `run_audio.gd`, and `run_hud.gd` handle projectiles, effects, synthesized cues, and UI. Built-in imagegen prompts and asset provenance are stored beside the artwork in `art/boiler/GENERATION.md`, `VARIANT_PROMPTS.md`, and `art/characters/medium_v2/ACTION_PROMPTS.md`.

## Verification

Run from the project folder with the installed Godot console executable:

```text
Godot --headless --path . --editor --import --quit
Godot --headless --path . --script res://tests/test_cockpit.gd
Godot --headless --path . --script res://tests/test_run_setup.gd
Godot --headless --path . --script res://tests/test_live_combat.gd
Godot --rendering-method gl_compatibility --resolution 1280x720 --path . --script res://tests/capture_run.gd
```

The progression test exercises the actual damage/death callbacks to clear waves, then checks all eight room transitions. It separately checks directional melee, cooldowns, cover blocking, dash invulnerability, walls, machinery, normalized movement, robot views, spawn/path validity, boss attack states, rewards, pause, retry, death, and hub return. The live combat smoke test drives movement and attack controls against unmodified first-room enemies. These automated checks do not establish final difficulty balance or constitute a complete manual combat playthrough.

Rendered screenshots: `reviews/boiler_room_01.png` through `boiler_room_08.png`, `boiler_boss_telegraph.png`, `boiler_robot_strike.png`, and `boiler_rewards.png`. The sandbox reports unrelated user-log/editor-settings permission and certificate-store warnings. Validation should distinguish those from game parser/runtime errors.

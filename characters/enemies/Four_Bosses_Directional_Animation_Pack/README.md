# Four-Boss Isometric Directional Animation Lab

A self-contained browser-based graybox prototype for four original industrial-skyscraper bosses, using the combat identities previously specified for Maintenance, Factory, Boiler Room, and Toxin Refinery.

## Run it

Open `Four_Boss_Directional_Animation_Lab.html` in Chrome or Firefox. The HTML is self-contained and does not require an internet connection or a development server.

**Keyboard:** WASD / arrow keys move; 1–4 play signature attacks; T plays the eight-direction tour; B plays all moves automatically; K shows the death animation; R resets the boss.

**Side panel:** Select bosses, toggle 8/16/32-direction facing, click any attack, inspect eight-angle turnarounds, and adjust the boss-health percentage to view suggested phase scaling. Health is an animation test control, not a fully playable damage system.

## Included bosses and attacks

### Maintenance — Overseer Seraph
- Evasive Retreat
- Summon Maintenance Units
- Convert to Elite
- Six-Hand Barrage

### Factory — Foundry Tyrant
- Gear Burst
- Saw Spiral
- Conveyor Mines
- Forge Beam

### Boiler Room — Magma Colossus
- Spew Lava: lava pools are modeled with a five-second lifetime
- Jump and Slam
- Explosive Barrel Throw
- Rolling Furnace: transformation into a rolling ball

### Toxin Refinery — Venom Coil Leviathan
- Lunging Bite + Grab
- Poison Spit
- Tail Smack
- Stadium Rush: 3–5 repetitions depending on phase

## Exported assets

- `models_obj/` — one `.obj` and `.mtl` per boss, static reference geometry at idle pose
- `sprite_atlases/` — one 32-direction idle atlas and one 8-direction x four-attack pose atlas per boss (rows = moves in their listed order)
- `animation_gifs/` — one gameplay-scale movement and attack GIF for each boss; direction tour followed by four move key-pose sequences
- `gameplay_previews/` — isometric screenshots for each boss

All images are generated from the same procedural models as the HTML viewer. The animation GIFs use posed snapshots; the HTML plays windup, active and recovery in real time and is the authoritative motion preview.

## Production status and limitations

**This is a graybox animation prototype.** The OBJ files are static, unrigged meshes. Attack and locomotion pose changes are procedural inside the HTML. The atlas images are sampled pose views rather than complete production-ready animated sprite sheets with per-animation frame counts. The prototype has attack telegraphs and visual effects but does not have complete collision, hit confirmation, navigation, boss AI, character combat or final rigged Blender animations. Visual effects are geometric placeholders, and boss health phases are illustrative rather than a full designed encounter.

The camera is fixed in a three-quarter isometric view. Its facing-direction system rounds the actor's yaw to a selectable 8, 16, or 32 slices, in the spirit of the pre-rendered directional character pipeline used by Hades.

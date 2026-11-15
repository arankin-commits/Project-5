# Four Biomes — 120 Unique Gameplay Blockouts

A gameplay-first blockout collection, inspired by the chamber design principles of Hades, but with original geometry. These are not copied Hades rooms.

## Files and dimensions

- 4 biomes × (6 small + 14 medium + 10 large) = 120 individual PNG room blockouts.
- Small: 1280 × 720 px. Medium: 2688 × 1512 px (4.41× pixel area). Large: 3200 × 1800 px (6.25× pixel area).
- Each biome folder contains `small`, `medium`, and `large` image folders and 3 overview contact sheets.
- `all_room_geometry.json` includes all room polygons, solid obstacles, half cover, gaps, hazards, and identical entrance/exit door styles.
- `room_index.csv` includes names, counts, dimensions, and hazard inventory.
- `generation_source.py` is included to reproduce the set.

## Gameplay analysis before decoration

Hades-style chamber design works because the combat arena is authored as a tactical space: floor and walls establish positioning, cover determines projectile interactions, and traps create movement choices. This set uses independent silhouettes and encounter motifs rather than re-skinning one layout. All floors are single-elevation and no platforms are walkable.

### Shared collision vocabulary

| Element | Gameplay blockout behavior |
|---|---|
| Solid wall | Blocks movement and projectiles; defines the chamber edge |
| Half cover | Blocks movement but allows most projectiles to pass overhead |
| Full obstacle | Blocks movement and projectiles; cannot be climbed |
| Floor gap | Non-walkable void; fixed black floor cutout |
| Hazard | A damaging/time-sensitive mechanic; specific to the biome |
| Exit | Reused identical mechanism per biome, always on straight walls |

### Hazard analysis by biome

#### Maintenance
- Projectile-shooting turrets set exposed firing lanes. Place them opposite useful cover, not at spawn.
- Blower fans change player position and exert force toward/away from obstacles, making movement choices meaningful.
- Open wires punish predictable crossing paths. Avoid forcing a player to cross an unavoidable hazard and projectile simultaneously.
- Spinning-vent entrances/exits use the same mechanically framed six-blade model at every portal.

#### Factory
- Sawblades travel back and forth along floor-level strips. Their travel direction is shown by a rail arrow and blade icon.
- Tesla machines create pulsing circular danger fields; their ring is an attack indication, not a raised floor.
- Breakable ceiling traps telegraph a crush zone and then descend. Ceiling slabs are non-walkable suspended objects, not platforms.
- Roll-up exits use the same horizontal shutter slats at every portal.

#### Boiler Room
- Fire spinners project rotating fire arms; place them to create alternating safe sectors.
- Fire spitters control directed lanes. Furnace/oven spitters use a heavier frontal flame attack.
- Floor fire vents create intermittent danger at specific spots.
- Explosive cans provide risk/reward chain reactions, ideally not in unavoidable entrance positions.
- Steam-duct exits use identical framed ribbed portals on straight walls.

#### Toxin Refinery
- Acid spitters create ranged toxic lanes; use cover and alternative approaches for counterplay.
- Spike traps threaten selected floor strips or intersections; floor elsewhere remains navigable.
- Exploding barrels provide an opportunity to damage enemies but increase risk near cover.
- The requested high-speed control buses are interpreted as high-speed electrical data-bus portals with uniform illuminated parallel signal rails.

## Perspective
The elevated orthographic three-quarter projection gives every wall and non-walkable obstacle visible thickness and height. Ground features remain on one planar floor. Rooms are not flat overhead schematics.

## Uniqueness and verification
- 120 distinct room names and 120 distinct exact outer-footprint signatures.
- Unique chamber-edge silhouettes are combined with different encounter motifs, hazard counts, and obstruction placements.
- Geometry placement validation confirmed that all door approaches are in the same traversable static floor component.
- This validation does not simulate real-time hazard timings, enemy AI, or movement ability clearance; playtesting is still necessary.
- Higher-resolution images are intentionally separate, not squeezed into one overview image.
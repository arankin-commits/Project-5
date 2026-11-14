# Flying Liberty — Toxin Refinery (15 Room Pack)

## What is in this pack

- 1 original isometric concept sheet showing four mirrored high-speed Control Bus stop modules (top-left/top-right exits; bottom-left/bottom-right arrivals)
- 1 original concept board depicting three small, seven medium, five large toxin-refinery rooms
- 15 individual **measured** polygonal room plans with bus-stop positions
- 15 individual room JSON files plus `JSON/all_rooms.json`
- separate small, medium, and large plan atlases

## Important distinction

The concept illustrations provide the look and mood and do NOT precisely trace the measured JSON footprints. For implementation in ChamberForge or Godot, treat each JSON outline polygon and the stop coordinates as the source of truth. The plans are schematic overhead floor-layout diagrams, not polished game sprites.

## Biome palette
- Shadow #283930
- Base #71806C
- Brass #A7793E
- Highlight #B0BAA0
- Rare toxin glow #9ADD56

## Area scaling (actual outline area after corner cuts / notches)
Reference small room S01: 126.74 tile².
Small (3): 118.95–129.21 tile².
Medium (7): 3.15–3.32× S01.
Large (5): 6.37–6.51× S01.

## How the bus stops work

Exit bus stops live on straight *exposed platform edges* toward the top, not walls. Entrance bus stops live on the opposite straight side. Crossing takes place in a high-speed bus above the toxin lake. The image shows buses as environment concepts; these are NOT animated vehicles or playable scenes. Each exit JSON marker includes a sample reward preview to be replaced at runtime.

## Constraint checks
- 15 distinct and valid polygons
- No circular outer walls
- Every stop on a straight segment of the outer platform boundary
- No enclosed perimeter walls; rails and small barrier details optional
- Preserve separate entry and exit markers
- All artwork remains concept art, not fully implemented in Godot

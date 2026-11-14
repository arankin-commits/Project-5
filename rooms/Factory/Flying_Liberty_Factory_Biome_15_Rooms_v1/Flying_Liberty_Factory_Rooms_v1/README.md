# Flying Liberty — Factory Biome Rooms (V1)

## Art direction
Factory palette: #292F33 (shadows), #62696C (worn metal), #A7793E (brass), #A7A6A0 (steel highlights), #EEAE52 (rare warning accent).

## Four reusable door modules
Concepts/RollUp_Door_Modules.png has one closed top-left roll-up EXIT mirrored into top-right and one open bottom-left roll-up ENTRANCE mirrored into bottom-right. Doors are embedded in straight wall sections and never placed on floor tiles. Preserve the same physical model and mirror horizontally for left/right versions.

## Room groups
Three small rooms (player should see all from middle), seven medium rooms (3–4x the small group average in floor area), five large rooms (6–7x that average).

The illustrated art sheets are environmental DESIGN REFERENCES, *not* exact footprint layouts. The coordinate-accurate, implementation-oriented polygon boundaries and door locators are in Factory_Room_Layouts.json and Footprints/*.png. When you build the game, treat JSON as authoritative; do not move any walls or doors to conform to a concept illustration.

## Implementation notes
- Logical tile coordinates use X to the right and Y down. Vertices are given along each exterior polygon, with no curved segments.
- No tilemap size is assumed. Decide tile-to-world scale in your Godot scene.
- Exit doors start closed; unlock after clearing enemies and claiming the room reward; leaving is one-way.
- Entrance doors are partially raised when arriving; reward signs may be instanced above the exit doors.
- World-space cameras should display small full rooms at player center, but not reveal medium/large full rooms at gameplay zoom; calculate viewport zoom from small-room size in-game.
- The paintings are not Godot-ready layered art. Separate floor, wall, doors, and props during art pass.

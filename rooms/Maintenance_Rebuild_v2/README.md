# Flying Liberty — Maintenance biome v2 (measured standalone rooms)

Includes 15 separate PNG room images, full-size world geometry JSON, 4 transparent modular vent components, an illustrated vent reference, and a compact contact sheet to browse the designs. Contact sheet is NOT a replacement for individual room images.

**World/canvas dimensions** (actual PNG size):

- Small: 1280 × 720 pixels (921,600 pixels); 3 rooms.
- Medium: 2560 × 1620 pixels (4,147,200 pixels = 4.5× a small room canvas); 7 rooms.
- Large: 3200 × 1920 pixels (6,144,000 pixels = 6.6667× a small room canvas); 5 rooms.

Actual irregular playable floor polygon areas are separately measured in `room_sizes.csv` and `manifest.json`. The world polygon is the ground-plane source of truth; the oblique image is the corresponding environment reference.

The artwork uses an elevated oblique/isometric projection and straight-edged, polygonal footprints. All exits (one or two depending on chamber) attach to specific straight, upper wall segments, stored in per-room JSON with their segment endpoints. Entrances are **not** placed into any room; four isolated fan-vent modules include two entrance variants solely as design assets.

Maintenance colors: `#3B4145` shadow, `#929799` base, `#A7793E` brass, `#DDDCD5` light, `#85C9D0` rare cyan accent. Fans have 8 thin spokes and large openings so the powered-down fan passage can be traversed in the game. Collision remains a Godot implementation task, with stopping animations and movement needed.

For a high-detail painted treatment, use the `modules/fan_vent_painted_concept_reference.png` and `previews/maintenance_art_direction_moodboard.png` as stylistic references, and **preserve the measured JSON geometry** rather than repainting arbitrary new positions. These PNG room renderings are stylized geometry-first environment illustrations, not individually hand-painted game-ready layer separations. They are not animated and are not implemented in Godot.

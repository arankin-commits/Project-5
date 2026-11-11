# Flying Liberty Cockpit

Open `project.godot` with Godot 4.7.2 (Godot 4.x compatible), then press **F5** to start in the Main Hall. The cockpit can also be run directly by opening `scenes/FlyingLibertyCockpit.tscn` and pressing **F6**.

Move with **WASD**, interact with **E**, and toggle cockpit collision outlines plus mapped ChamberForge markers with **F3**. The cockpit exit at the bottom center enters the Main Hall. The first top door enters the Sync Chamber, and the second top door enters the cockpit. Each room's exit returns the player to its matching Main Hall doorway. The pilot stands by the left pilot seat.

The painting is assembled at its native **1672 × 941** size from the provided OpenRaster layers and cropped sprites. Gameplay locations from the **1280 × 800** ChamberForge layout use the adjustable mapping in `data/cockpit_mapping.json`. Collision footprints are calibrated separately in `scripts/cockpit_room.gd`.

The Main Hall uses the supplied `rooms/Steampunk Victorian Hall Without Labels.png`. Since that image is flattened, its furniture collision is fitted by hand and character occlusion by furniture is limited.

The Sync Chamber uses the supplied `rooms/Empty Sync Chamber Steampunk Lab.png`. Its central machine, tanks, console, and crates have calibrated blocking footprints.

The upper-right bedroom corridor continues from the hall's right passage using wall, carpet, trim, and doorway regions from that same painting. It has six interactable bedroom doors. Their destination scenes are placeholders until bedroom rooms are added.

`tests/capture_cockpit.gd` saves game and native art screenshots in `reviews/`. `tests/test_cockpit.gd` checks movement, seat and wall collisions, Pilot dialogue, and travel in both directions between the cockpit and hall.

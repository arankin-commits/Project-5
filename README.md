# Flying Liberty Cockpit

Open `project.godot` with Godot 4.7.2 (Godot 4.x compatible), then press **F5** to start in the Main Hall. The cockpit can also be run directly by opening `scenes/FlyingLibertyCockpit.tscn` and pressing **F6**.

Move with **WASD**, interact with **E**, and toggle cockpit collision outlines plus mapped ChamberForge markers with **F3**. The cockpit exit at the bottom center enters the Main Hall. The first top door enters the Sync Chamber, and the second top door enters the cockpit. Each room's exit returns the player to its matching Main Hall doorway. The pilot stands by the left pilot seat.

The painting is assembled at its native **1672 × 941** size from the provided OpenRaster layers and cropped sprites. Gameplay locations from the **1280 × 800** ChamberForge layout use the adjustable mapping in `data/cockpit_mapping.json`. Collision footprints are calibrated separately in `scripts/cockpit_room.gd`.

The Main Hall uses the supplied `rooms/Steampunk Victorian Hall Without Labels.png`. Since that image is flattened, its furniture collision is fitted by hand and character occlusion by furniture is limited.

The Sync Chamber uses the supplied `rooms/Empty Sync Chamber Steampunk Lab.png`. Its central machine, tanks, console, and crates have calibrated blocking footprints.

The Engineering Workshop uses the supplied `rooms/Steampunk Automaton Engineering Workshop.png`. Walk through the far-left end of the hall's left corridor to enter; walk through the workshop's existing right-side opening to return. No extra door artwork is placed in the hall. Major robots, machinery, and benches have blocking footprints.

Approach the workshop's central power core and press **E** to open the Core Interface. It shows the Standard Core's skill tree and core selection. Only the Standard Core is unlocked at present; the other two slots are locked. Press **E** or the Close button to return to movement.

The ship character and Pilot use cutouts from `characters/Hades-Style Character and Robot Sprite Sheet.png`. The run now uses a remade, eight-direction Medium robot with illustrated idle, stride, and punch poses. At the Sync Pod, press **E**, select modifiers, and press **Start Roguelike Run** to enter **The Boiler Below**. Clear seven combat chambers, select salvage upgrades between encounters, and defeat the two-phase **Furnace Warden** in chamber eight. The three difficulty options change enemy speed, reinforcements, and maximum hull.

Run controls: **WASD** moves; **left mouse / J** strikes (three-hit combo); **right mouse / K** performs a heavy strike; **Space** dashes with brief invulnerability; **E** advances at the teal lift marker after clearing the room and choosing an upgrade; **Esc** pauses; **F3** displays collision footprints. Mouse attacks aim toward the cursor; keyboard attacks use the robot's facing. Open `scenes/RoguelikeRun.tscn` and press **F6** to test the run directly. See [the boiler run notes](docs/BOILER_RUN.md) for room data, projection, and validation details.

The upper-right bedroom corridor continues from the hall's right passage using wall, carpet, trim, and doorway regions from that same painting. It has six interactable bedroom doors. Their destination scenes are placeholders until bedroom rooms are added.

Capture scripts in `tests/` save rendered screenshots in `reviews/`. `tests/test_cockpit.gd` checks ship travel and interactions. `tests/test_run_setup.gd` checks the Sync Pod, all eight chambers, combat rules, modifiers, boss phases, victory, death, retry, and return. `tests/test_live_combat.gd` drives ordinary movement and combat controls against live enemies in the first chamber.

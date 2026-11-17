# Map Rules

## Fact or rule

- **Room Generation.** The game stitches together pre-designed room layouts and modular tiles, varying the sequence, rotations, and obstacle placements.
- **Room Sizes.** Small rooms are at least 1280 x 720 pixels (921,600 pixels total). Medium rooms contain 4-5 times the total pixel area of a small room. Large rooms contain 6-7 times the total pixel area of a small room. These multipliers describe area, not a multiplier applied to both width and height.
- **Underground Room Source.** Use `rooms/ALL_4_BIOMES_120_UNIQUE_BLOCKOUTS` for Maintenance, Factory, Boiler, and Toxin Refinery. Each biome has 30 unique layouts (6 small, 14 medium, 10 large), with geometry from `all_room_geometry.json`. This supersedes the earlier fifteen-room Maintenance sets and old Boiler pool. Preserve random selection without repeats.
- **Room Pool and No Repeats.** Rooms must never repeat during a run. All available layouts in the current biome, regardless of size, belong in one pool and are selected randomly without replacement, including the first room. A boss remains encounter nine and must not reuse an earlier room layout. Larger rooms must have larger playable space, rather than being scaled down to the size of small rooms.
- **Reward Previews.** Every exit displays a symbol showing the exact reward or encounter waiting in the next room. Standard rooms offer up to four exits to choose from. [1, 2]
- **Distinct Door Icons.** If a room has multiple exit doors, every door must display a different reward or encounter icon. No two doors in the same room may share an icon. Each icon must still accurately represent what waits through that door.
- **Combat Requirements.** Exits remain locked until you defeat every enemy in the current room and claim the room's reward. Once you step through an exit, you cannot return to the previous chamber. [1]
- **Mid-Room Locks.** The Quit option locks and grays out as soon as you take damage, collect a reward, talk to an NPC, or buy an item from Charon's shop. You must clear the room and step through the next entrance before you can quit without losing your current run.
- **Entering a Room.** The game auto-saves the moment you enter a new chamber, allowing you to safely select Quit from the pause menu and resume there later.
- **Isometric Sightlines.** Exits are almost always positioned along the upper-left, upper-right, or far-top walls of an arena so reward previews remain clearly visible to the player. Entrances generally sit at the bottom-left or bottom-right edges.
- **Room Connection.** The player should enter from the room wall opposite the wall they exited from in the previous room. The player always comes in from the bottom left in the first room of a new biome.
- **Hazards and Enemy Placement.** Hazards and enemies are placed on top afterwards.
- **Asymmetric Trap Damage.** Environmental hazards damage both Zagreus and foes, but traps deal significantly more damage to enemies than to you. Enemies don't trigger traps, but can still be harmed by them. You can use knockback effects to knock enemies into active traps or trigger traps yourself to catch enemies in the hazard.
- **Fixed Biome Hazards.** Each region features signature environmental traps built directly into the room's floor plan. These include pressure-activated Spike Pits and explosive urns in Tartarus, rivers of magma in Asphodel, and poison pools alongside curing mandragora stations in the Temple of Styx.
- **Wave-Based Spawning.** Standard combat rooms do not spawn every enemy at once. Instead, enemies appear in sequential waves, with the next group spawning once the active wave is cleared or reduced below a set threshold - 50%, 70%, or 90%.
- **Proximity Spawn Manipulation.** Each chamber has predefined spawn points, and the game prioritizes spawning new waves at nodes near Zagreus's current location. Speedrunners use "spawn manipulation" by standing near specific landmarks or exit doors right as a wave dies to force the next group to cluster together.
- **Special Encounter Overrides.** Certain encounters alter standard wave rules.

## Why

The user supplied these durable map design rules to guide room layout and encounter behavior across sessions. They describe intended design, not verified implementation.

The user corrected repeated rooms and missing large rooms after the initial Maintenance implementation sampled only three layouts with replacement. Do not restrict the pool to that initial subset or force a small starting room.

The user specified minimum room dimensions and size ratios so room categories have meaningful size differences.

The user specified distinct icons for multiple doors in one room so the available choices are visually distinguishable.

The user corrected the Maintenance integration: the `art pass` rooms themselves must appear in game, rather than gray measured layouts decorated with painted fan props.

## How to apply

Consult these rules before changing room generation, entrances and exits, reward previews, saving and quitting, hazards, or enemy waves. Preserve the supplied reference names and citation markers; their source links and project-specific equivalents have not been provided.

When assigning door previews, enforce icon uniqueness within each room and keep each preview consistent with its destination reward or encounter.


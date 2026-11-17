# Project Memory

## Map Rules

- **Reward Previews.** Every exit displays a symbol showing the exact reward or encounter waiting in the next room. Standard rooms offer up to four exits to choose from. [1, 2]
- **Unique Door Icons.** There cannot be multiple doors with the same icon in the same room; all exit preview icons in a single room must be distinct.
- **Combat Requirements.** Exits remain locked until you defeat every enemy in the current room. Once you step through an exit, you cannot return to the previous chamber. [1]
- **Mid-Room Locks.** The Quit option locks and grays out as soon as you take damage, collect a reward, talk to an NPC, or buy an item from Charon's shop. You must clear the room and step through the next entrance before you can quit without losing your current run.
- **Entering a Room.** The game auto-saves the moment you enter a new chamber, allowing you to safely select Quit from the pause menu and resume there later.
- **Isometric Sightlines.** Exits are almost always positioned along the upper-left, upper-right, or far-top walls of an arena so reward previews remain clearly visible to the player. Entrances generally sit at the bottom-left or bottom-right edges.
- **Room Connection.** The player should enter from the room wall opposite the wall they exited from in the previous room. The player always comes in from the bottom left in the first room of a new biome.
- **Hazards and Enemy Placement.** Hazards and enemies are placed on top afterwards.
- **Asymmetric Trap Damage.** Environmental hazards damage both the player and foes, but traps deal significantly more damage to enemies than to you. Enemies don't trigger traps, but can still be harmed by them. You can use knockback effects to knock enemies into active traps or trigger traps yourself to catch enemies in the hazard.
- **Fixed Biome Hazards.** Each region features signature environmental traps built directly into the room's floor plan. These include pressure-activated Spike Pits and explosive urns in Tartarus, rivers of magma in Asphodel, and poison pools alongside curing mandragora stations in the Temple of Styx.
- **Wave-Based Spawning.** Standard combat rooms do not spawn every enemy at once. Instead, enemies appear in sequential waves, with the next group spawning once the active wave is cleared or reduced below a set threshold - 50%, 70%, or 90%.
- **Proximity Spawn Manipulation.** Each chamber has predefined spawn points, and the game prioritizes spawning new waves at nodes near the player's current location.
- **Special Encounter Overrides.** Certain encounters alter standard wave rules.

## Reward Item Spawning & Exit Interaction

- **Spawn Location:** The reward item spawns next to the player, guaranteed within bounds (never out of bounds).
- **Interaction Activation:** The reward item only activates once the player interacts with it by pressing `E`.
- **Leaving Unclaimed Rewards:** If the player attempts to exit through a door without collecting the reward item, the player character states that they should collect the reward item first. If the player interacts with the door a second time, they are allowed to leave the reward behind and exit.

## Steampunk Reward Icon Atlas

Indexed from left to right, top to bottom:
1. Aether Cores
2. Core XP
3. Permanent Info *(Do not show - info not yet used)*
4. CDs
5. Fire
6. Ice
7. Wind
8. Earth
9. Lightning
10. Water
11. Temporary Info *(Do not show - info not yet used)*
12. Fire Upgrade
13. Ice Upgrade
14. Wind Upgrade
15. Earth Upgrade
16. Lightning Upgrade
17. Water Upgrade
18. Max HP Increase
19. Shop Room *(Do not show - not yet implemented)*
20. Trap Room
21. Secret Room *(Do not show - no secret rooms)*

## Reward & Room Eligibility Rules

- **Excluded Icons (Do Not Show):**
  - **Secret Rooms:** There are no secret rooms, so the secret room icon must not show up.
  - **Shop Rooms:** There are no shop rooms implemented yet, so the shop icon must not show up.
  - **Information:** There is no current use for information, so information icons (both permanent info and temporary info) must not show up.
  - **Weapons & Weapon Upgrades:** No weapon or weapon upgrade icons exist yet; do not add them yet.
- **Elemental Cores & Core Upgrades:**
  - **Skill Tree Alignment:** Elemental cores appearing as rewards must align with the skill tree rules (power of 2 and power of 3).
  - **Owned Core Prerequisite:** Elemental core upgrades can only show up if the player currently owns that selected core.
- **Weapons & Weapon Rooms (Future Implementation):**
  - **Weapon Upgrade Alignment:** Weapon upgrade rewards must align with the weapon the player currently has; if they have no weapon, weapon upgrades cannot appear.
  - **Weapon Rooms:** Feature a mini-boss wielding the designated weapon; defeating the mini-boss permanently unlocks the weapon (not yet implemented; do not add yet).

## Special Room Types

- **Trap Rooms:**
  - **Win Conditions:** The player must either survive for a set time between 45 seconds and 1 minute 30 seconds (45s - 90s) OR survive against a set sequence of 10 to 15 enemy waves.
  - **Reward Benefit:** Clearing a trap room increases the probability of receiving higher rarity selections when choosing between the 3 options during weapon or core upgrades.
- **Shop Rooms (Design Specifications):**
  - Allows the player to choose from 3 rewards for their selected gear price.
  - Hard limit of 2 shop rewards per run.
  - *(Currently not implemented; do not show shop room icons).*

## Workshop & Skill Tree Interface

- **All-Sides Interaction:** The power core machine in the Engineering Workshop (`PowerCoreTerminal`) used to interact with and view the elemental skill tree is interactable on all sides (top/north, bottom/south, left/west, right/east, and corners).
- **Exit Arch Dimensions:** The return passage back to the Main Hall (`MainHallReturn` in `scripts/workshop.gd`) matches the visual opening of the painted archway on the right wall: `position = Vector2(1500, 510)` and `half_extent = Vector2(35, 120)` (spanning $X \in [1465, 1535]$ and $Y \in [390, 630]$, full size $70 \times 240$ px).

## Flying Liberty Controls & Movement

- **Running on the Flying Liberty:** Holding Space while moving on the Flying Liberty (Cockpit, Main Hall, Sync Chamber, Engineering Workshop) engages running at increased speed (360 px/s vs standard 220 px/s walk) and plays the character running animation (`MC_RUN`).

## Combat & Enemy Mechanics

- **Wall & Construct Knockback Stun:** Enemies knocked back into walls or constructs/obstacles are stunned for 0.3 seconds (`wall_stun_timer = 0.3`). While stunned, enemy movement and attacks are paused, a stun halo is drawn overhead, the recovery/reeling animation plays, and attacks against the enemy gain the wall-stun damage bonus.
- **Enemy Collision Damage & Knockback Scaling:**
  - **Enemy-Enemy Collision:** Enemies knocked into other enemies deal collision damage to both targets (`collider.take_damage(dmg, Vector2.ZERO, 0.0, "regular")` and `self.take_damage(dmg, Vector2.ZERO, 0.0, "regular")`). Non-boss enemies hit are stunned for 0.3 seconds (`wall_stun_timer = 0.3`).
  - **Wall & Construct Collision:** Enemies knocked into walls or constructs (such as pillars, pipes, cover, or arena borders) deal collision damage to the knocked enemy (`self.take_damage(dmg, Vector2.ZERO, 0.0, "regular")`) in addition to triggering wall stun.
  - **Knockback Power Damage Scaling:** Collision damage is directly proportional to knockback power (`push_distance`): `calculate_collision_damage(knockback_power)` calculates `maxf(1.0, roundf(knockback_power * 0.5))`. A normal strike (12.0 distance) deals 6 damage, a heavy strike (65.0 distance) deals 33 damage, core abilities (90.0 distance) deal 45 damage, and charged strikes (180.0 distance) deal 90 damage.
  - **Knockback Without Collision:** If an enemy is knocked back in open space and collides with neither a wall/construct nor another enemy, 0 collision damage is dealt and no stun is applied.
- **Damage Numbers Beside Foes:** When an enemy takes damage, damage numbers show up next to the enemy hit (horizontally offset beside the enemy's torso on the side of the impact, rather than directly overhead) to keep the enemy body, overhead stun halos, and health bars unobstructed. Damage numbers reflect the actual damage taken after reductions (such as shield guarding) and apply to all damage sources including player strikes, core powers, and environmental traps/hazards.
- **Enemies and Traps:** Enemies do not trigger traps or pressure plates (`can_trigger_trap(enemy) == false`). However, enemies can still be harmed by traps (`take_damage` from active/triggered hazards) when knocked into them or when caught inside hazards triggered by the player or environmental cycles.
- **Maintenance Enemy Health (3x):** All enemies in the Maintenance biome have triple their base health (all 8 Maintenance industrial enemies: Inspection Wasp 105 HP, Dust Mites 36 HP, Pressure Purger 330 HP, Spanner Guard 270 HP, Foreman Node 390 HP, Cable Snare Unit 240 HP, Phase Custodian 240 HP, Signal Scrambler 180 HP; summons; regular wave spawns; and Maintenance Guardian boss 3750 HP).

## Element Rules

- **Damage Number Elemental Colors:** Damage numbers floating beside hit enemies use distinct colors corresponding to their damage element / type:
  - **Fire / Burn / Explosive:** Red (`Color("ff3b30")`)
  - **Earth:** Brown (`Color("a65e2e")`)
  - **Lightning / Electricity:** Yellow (`Color("ffe600")`)
  - **Water / Rust:** Blue (`Color("3399ff")`)
  - **Wind:** Green (`Color("38d978")`)
  - **Ice / Frost:** Frozen Blue (`Color("a8f0ff")`)
  - **Regular / Physical / Default:** Grey (`Color("cccccc")`)
  - **Separate Numbers:** If an attack deals regular and elemental damage, both appear separately using their respective colors.
  - **Type Retention:** Elemental damage retains its original type. If a normal attack activates both Fire and Lightning, its Burn damage remains red, and its Lightning damage remains yellow. Neither replaces the other.
- **Fire & Ice Reaction (Wet Generation):**
  - Applying Burn on top of Frost cancels both and inflicts Wet status.
  - Applying Frost to a burning enemy also cancels both statuses and applies Wet, making the reaction work symmetrically in either direction.
  - Any Fire/Frost reaction creates Wet, regardless of application order. This gives multi-element builds a predictable way to produce Wet and then exploit its Lightning and Ice bonuses.
  - All applicable elemental effects activate, except when reactions cancel them. An attack that applies both Fire and Ice resolves the interaction and applies Wet instead of leaving both Burn and Frost active.
  - When Burn or Frost is canceled by another element, its corresponding buildup meter resets to zero.
- **Wet Status Vulnerabilities & Resistances:**
  - **Vulnerability Bonus:** Wet multiplies Ice and Lightning damage by 1.5. It does not increase the regular attack component.
  - **Burn Immunity Under Wet:** Enemies cannot be burned under Wet status.
  - **Extinguishing Burn:** Applying Wet to a burning enemy extinguishes Burn and resets its Burn meter to zero.
  - **Accelerated Freezing:** Frost meter attack gain is doubled under Wet status.
  - **Mud Formation:** Earth attacks against Wet enemies apply Mud, slowing their movement by 20% for 2 seconds.
- **Burn & Frost Mutual Exclusivity:**
  - Enemies cannot be under Frost or Frozen status while under Burn.
- **Wind Interactions:**
  - **Fanning the Flames:** Wind's 50% Burn damage bonus does not stack. Repeated Wind attacks refresh it.
  - **Wind Knockback Spread:** Knocking back a Burning enemy spreads Wet to the first enemy it collides with if the source of the knockback was Wind. Knocking back a Wet enemy also spreads Wet to the first enemy it collides with if the source of the knockback was Wind.
- **Secondary Effects & Recursion Control:**
  - Secondary effects cannot trigger themselves. Lightning splash damage cannot create another splash. Wind Bomb cannot endlessly create more Wind Bombs.
- **Lightning Reactions:**
  - **Burn Acceleration:** Lightning hitting a burning enemy triggers an immediate additional Burn tick, without reducing Burn duration.
  - **Chain Targeting:** A Lightning chain cannot hit the same enemy twice during the same chain unless a card explicitly permits it. Chains prioritize the closest enemy that has not already been struck.
- **Frozen Enemy Resistances:**
  - **Brittle Resistance:** Earth and Burn damage deal 50% damage to frozen enemies.
- **Duration Resetting & Simultaneous Statuses:**
  - **Duration Refresh:** Reapplying Burn, Frost, or Wet resets its duration instead of adding time.
  - **Multiple Statuses:** Enemies can have multiple elemental statuses simultaneously unless a specific reaction cancels them.
  - **Hit Frequency Limiting:** Elemental reactions occur once per qualifying hit. This prevents rapid attacks from triggering unlimited reactions from the same damage event.
- **Buildup vs Direct Damage:**
  - Elemental status buildup and direct elemental damage are separate. This keeps different elements useful even when an enemy resists or is immune to a particular status.
- **Elemental Meters & Explosions:**
  - **Qualifying Buildup Applications:** Burn and Freeze meters only increase from qualifying elemental applications. DoT ticks and secondary chain damage do not automatically increase buildup.
  - **Multi-Hit Controlled Buildup:** Multi-hit abilities should have controlled buildup. Each enemy receives a maximum of one meter increase per application or defined attack interval.
  - **Burn Explosions:** Burn meter can only increase while Burn is active. When an explosion triggers, the meter resets to zero, and excess buildup from the triggering hit is discarded. The enemy can begin accumulating buildup again on the next hit.
  - **Freeze Meter:** Freeze Meter cannot rise above 100. When freezing occurs, the meter resets to zero. During the Freeze duration, additional Frost hits deal their normal elemental damage but do not build another Freeze.
  - **Lightning Chains:** A Lightning chain cannot hit the same enemy twice during the same chain unless a card explicitly permits it. Chains prioritize the closest enemy that has not already been struck.
- **Boss & Enemy Rules:**
  - **Boss Crowd Control Diminishing Returns:** Bosses cannot be permanently stunned, frozen, or trapped. Repeated hard crowd control grants temporary resistance.
  - **Boss Knockback Halving:** Knockback effects are halved against bosses.
  - **Explicit Resistances:** Enemies are not automatically resistant to their own element. Resistances must be explicitly defined per enemy.
- **Terrain, Puddles & Construct Interactions:**
  - **Water Puddle Terrain Interaction:** Water interacts with terrain. Puddles can be electrified, frozen, or evaporated, allowing players to create combinations through positioning:
    - **Freezing:** Ice freezes a puddle, turning it into a temporary slippery surface for grounded enemies.
    - **Evaporation:** Fire attacks evaporate a water puddle, creating a short-lived steam cloud that obscures enemy vision without applying Burn.
    - **Electrification:** Lightning hitting a water puddle electrifies it briefly, damaging grounded enemies inside it.
  - **Earth Construct Interactions:**
    - **Heated Constructs:** Fire attacks can heat a rock construct for 5 seconds. Enemies colliding with it receive Burn.
    - **Frozen Constructs:** Ice attacks can freeze Earth constructs, causing enemies that touch them to accumulate Frost meter.
    - **Separate Construct Capacity Limits:** Orbiting rocks and stationary constructs have separate capacity limits.
    - **Rock Fragment Trigger Inheritance Prevention:** Rock fragments do not inherit Rock Shot triggers. This prevents Shotgun fragments from continuously splitting or returning to the player.
- **Combat Build & Player Safety Rules:**
  - **Player Damage Immunity:** Elemental attacks and hazards created by the player cannot damage the player unless a specific mechanic states otherwise.
  - **Multi-Core Attack Damage Separation:** Three-core builds should not automatically deal triple regular attack damage. Additional cores provide extra elemental effects and possible synergies, but regular attack damage remains separate.
  - **Armor Retaliation Cooldown:** Armor retaliation has a 0.5-second cooldown to prevent enemies with rapid attacks from triggering excessive damage.

## Run Setup & Robot Deployment

- **Medium Robot Only Available:** Only the Medium robot is implemented in the game. Players cannot start a run with the Light or Heavy robot selected. Selecting Light or Heavy in the Sync Pod Run Setup disables the Start Run button (`start_button.disabled = true`), displays `"[Robot] robot is not yet available."` in the route note, and blocks run initiation. Only the Medium robot (with Below Ground route) allows starting a run.

## Performance & Scene Transitions

- **Reward Tween Binding:** Looping tweens (such as `_spawn_reward_item()` floating animation) must be bound to the spawned node (`reward_item.create_tween()`) and configure `set_loops()` only after adding tween properties. This ensures the tween is automatically freed when the item is destroyed, preventing 0-duration infinite tween loops and `ERROR: Infinite loop detected` freezes.
- **Precompiled Shaders:** Shaders used for canvas items (`clean_walk.gdshader`, `key_black.gdshader`, `jukebox_cutout.gdshader`) are stored in `scripts/` as precompiled `.gdshader` files and loaded via `preload()` rather than compiled at runtime from dynamic strings, avoiding synchronous OpenGL shader compilation hitches.
- **Safe Spawn Coarse-to-Fine Search:** `_safe_source_point()` uses coarse-to-fine step sampling (16px coarse pass followed by local 2px refinement) rather than brute-forcing full 2px grids over the entire room canvas.
- **Player Idle Visual Updates:** In `_face_idle()`, only assign `visual.frame` when `visual.frame != target_frame` to prevent redundant frame-changed signal dispatches and uniform buffer re-uploads every physics frame.

## Save File Management

- **Save Deletion:** Non-empty save slots display a "Delete" button styled in crimson warning colors alongside the "Continue" button on the Save Selection screen.
- **Delete Confirmation:** Clicking "Delete" opens a modal confirmation dialog explaining that all progress, skills, XP, and stats will be permanently erased. Players can click "Cancel" (or press Esc) to dismiss, or "Delete File" to confirm.
- **Save Slot Reset:** Confirming deletion calls SaveSlots.delete_slot(slot), which removes slot_{id}.cfg (and legacy skill_tree.cfg if slot 1), resets active progression/crew/run state if currently active, and refreshes the slots view to show the slot as empty ("Create").

## In-Game Menu & Navigation

- **Quit to Main Menu:** Selecting "Quit" from the in-game menu (both in roguelike runs via the pause menu and aboard the Flying Liberty via ShipMenu) saves current game progress (`SaveSlots.save_current()`), resets active run flags, unpauses the game tree (`get_tree().paused = false`), and returns the player to the main menu (`res://scenes/ui/StartScreen.tscn`) rather than terminating the application.

## CD Track Rewards & Biome Distribution

- **16 Collectible Lobby Themes:** 16 full-production lobby theme tracks located in `Music/Flying_Liberty_16_Lobby_Themes_Full_Production_v1` can be acquired as room CD rewards (`"cds"`):
  - **Tracks 1–4 (Maintenance):** 01 Copper Hearth, 02 Scribes of the Air, 03 Parlour Above the Clouds, 04 Captain's Quadrille.
  - **Tracks 5–8 (Factory):** 05 Clockwork Pavane, 06 Father's Photograph, 07 Brass and Lace, 08 Liberty Overture.
  - **Tracks 9–12 (Boiler):** 09 Glass Horizon, 10 Aether Lullaby, 11 Time Between Gears, 12 Skylight Chapel.
  - **Tracks 13–16 (Toxin Refinery):** 13 Observatory of Dreams, 14 The Unsent Letter, 15 Wings Beyond Tomorrow, 16 Homeward Through Mist.
- **Random Selection Without Replacement:** Entering a chamber with `"cds"` as the promised reward randomly assigns one of the remaining uncollected tracks for the current biome. Once a track has been collected, it is permanently removed from the reward pool and cannot be awarded again.
- **Biome Cleared Exclusion:** Once all 4 tracks for a biome have been acquired, the `"cds"` reward is removed from the reward candidate pool and will no longer show up as a door reward or exit option in that biome.
- **3x Rarity:** The `"cds"` reward is 3 times as rare to find as standard exit rewards. When candidate exit pools are generated, `"cds"` only enters the available selection pool 1 out of 3 times (`exit_rng.randi_range(0, 2) == 0`).
- **Save File Persistence:** Collected CD track IDs are saved persistently per save slot under `[ship] collected_cds` and loaded automatically via `SaveSlots`.
- **Tracklist Import Keep:** `Tracklist.csv` metadata file in the music directory is marked with `importer="keep"` in `Tracklist.csv.import` and uses `Key_Mode` instead of `Key/Mode` to prevent Godot's translation importer from attempting to create invalid `.translation` files.

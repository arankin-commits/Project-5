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
- **Asymmetric Trap Damage.** Environmental hazards damage both the player and foes, but traps deal significantly more damage to enemies than to you. You can use knockback effects or bait enemies into walking over triggers to clear waves safely.
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

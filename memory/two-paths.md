# Two Paths

## Fact or rule

The game has two paths with different objectives:

- **Going up — Above-ground route:** Confront the top brass.
- **Going down — Underground route:** Investigate tech.

Above-ground progression, from start to end:

1. Storage (Start)
2. Flying Ship gallery
3. Executive
4. Summit Chambers (End)

Underground progression, from start to end:

1. Maintenance (Start)
2. Factory
3. Boiler
4. Toxin Refinery (End)

## Why

The user established these two routes, their objectives, and their area order as durable project decisions. They corrected the biome dropdown: players select a route, not an individual biome.

## How to apply

Use these objectives and start-to-end sequences when planning or changing route selection, area progression, maps, or story content.

Each biome contains eight regular maps followed by a boss in the ninth room. Defeating the boss and claiming its reward advances the same run: Maintenance boss → Factory; Factory boss → Boiler; Boiler boss → Toxin Refinery. Defeating the Toxin Refinery boss completes the underground route. Preserve the player's run upgrades and progress between biomes.

The route dropdown shows only the two directions and their objectives. Do not display the ordered biome lists in the dropdown or accompanying route-selection UI; the order is internal progression information.

All four underground biomes use the thirty-room pools from `rooms/ALL_4_BIOMES_120_UNIQUE_BLOCKOUTS`. No above-ground biome exists yet; above ground remains unavailable until Storage exists.

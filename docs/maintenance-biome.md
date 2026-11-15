# Active underground integration

The active four-biome pack supersedes the historical Maintenance integrations below. See [Four-biome route](four-biome-route.md) for current sources, progression, collision, and validation.

# Current room source

Maintenance now uses all fifteen standalone images in `rooms/Maintenance_Rebuild_v2/rooms` and their measured metadata. The painted-sheet background integration described below is historical and superseded. Collision footprints use the source generator's half-extents. Random selection, size categories, and nine-room progression are preserved.

# Maintenance biome and route progression

In the Flying Liberty Sync Chamber, open a Sync Pod and select **Below ground | Investigate tech**. The dropdown offers routes, not individual biomes, and does not reveal the ordered biome list. **Above ground | Confront the upper brass** can be selected, but Start is disabled because its first biome is not implemented.

Maintenance draws nine different layouts from all fifteen painted rooms in `rooms/Maintenance_Rebuild_v2/art pass/Flying Liberty Maintenance Room Set-2.png`: eight regular encounters followed by the boss. Every size shares the same pool, with an equal chance on each draw; selected layouts are removed from the pool, including the boss layout. The first room is random too. Small canvases are 1280 x 720, medium 2560 x 1620, and large 3200 x 1920. Each painted room fits its canvas at a uniform scale, retaining its aspect ratio. Navigation expands to cover large rooms, and the camera scrolls at a fixed zoom instead of shrinking large floors. The Maintenance Guardian currently reuses the existing boss art and mechanics.

The painted sheet supplies the actual room backgrounds, not just surface styling. `data/maintenance/painted_layouts.json` traces each room's artwork outline, walkable floor, pits, machinery, entrance, exits, and hazard positions in sheet pixels. Textured polygons exclude the board's headings and neighboring rooms. Floor collision and navigation use these painted traces instead of the previous gray-room geometry. The central platform in L01 remains accessible between the surrounding pit sections. Fan exit props come from the other `art pass` image. Original source images remain unchanged; the older gray-room textures and surface shader are no longer used by Maintenance.

`tools/integrate_maintenance_v2.py` refreshes the room catalog's links to these painted layouts while retaining encounter definitions. Individual rooms occupy only a small part of the 1536 x 1024 source sheet, so their enlarged backgrounds contain less detail than the separate character and prop sprites. Both biome backgrounds use `scripts/map_texture.gdshader` for sharper cubic sampling and restrained detail enhancement when enlarged. Local color bounds limit sharpening halos, and native-size/minified textures use their ordinary sampling. This reduces filtering blur but does not increase the source images' resolution or reconstruct missing painted detail.

Electrical floor hazards use the lower-left and lower-right pieces of `rooms/Hazards/Maintenance.png`. They warn before pulsing, deal 8 hull damage to the player and 32 to enemies, and stop when combat ends. The crossed-out fan is excluded. The `.png.import` file is Godot metadata, not the texture itself.

Two exit positions per standard chamber show the heart icon from `rooms/Room Exit Icons/Steampunk Reward Icon Atlas.png`, plus the next room name and exact hull reward. Interaction selects the nearest exit. Both exits currently lead to the same next encounter; this does not add branching routes. Sequential enemy waves must be defeated and the room reward claimed before the exits unlock. After the ninth-room boss and reward, progression checks the next biome in the route. Missing biomes are never skipped: Maintenance currently returns to the ship with a Factory-unavailable message. A partial route does not count as a full-route victory.

The route order is recorded internally in `RunConfig.ROUTES`. `BIOME_DATA` contains only implemented biomes. Boiler shuffles eight distinct regular configurations, including Return Manifold, before its separate ninth-room boss; it no longer repeats a regular room to fill the run. Boiler remains accessible for development with `-- --boiler-preview`, but is not offered as a separate player route. When a next biome is implemented and registered, progression loads it without resetting health, run upgrades, core selections, or accumulated run rewards.

## Scope still outstanding

- All fifteen painted Maintenance layouts and painted fan exit modules are integrated. Painted entrance modules and fan animations are not integrated yet.
- Turret and upright fan hazards are not implemented; existing combat enemies are reused.
- Modular tile assembly, room rotations, variable obstacle placement, and branching exits remain future work.
- Room-entry autosaves, safe-quit locks, and resumable runs remain unimplemented in the shared run system. Quit still has the existing behavior; do not assume a run will resume.
- Factory and Toxin Refinery are not implemented; no above-ground biomes are implemented. Full multi-biome progression remains untested with real biome content.
- Flattened artwork cannot occlude characters behind furniture; collisions keep actors out of fitted machinery footprints.

## Validation

`tests/test_room_pool.gd` checks 500 seeds for unique draws, reproducibility, and coverage of every layout, including as the first room. It loads all fifteen Maintenance layouts and checks the painted texture source, entrances, exits, navigation, physical pit/machinery collision, hazard placement, spawn capacity, and size differences. `tests/test_maintenance.gd` exercises the complete run through the Sync Pod. `tests/capture_maintenance.gd` captures all fifteen layouts with the real renderer, plus full-room overview images for artwork review. The overview zoom is only used by that capture script. `tests/test_run_setup.gd` covers Boiler with `--boiler-preview`; its geometry-specific checks explicitly choose a seed with the Cinder room first.

`tests/capture_map_sampling.gd` compares ordinary and sharpened rendering for Maintenance and Boiler at camera zoom 0.4, 0.82, and 1.5. It captures both versions and verifies that enlarged maps change while minified Boiler backgrounds remain unchanged. Visual inspection is still necessary; changed pixels alone do not establish better image quality.

API references checked against the Godot 4.7 documentation:

- [AtlasTexture](https://docs.godotengine.org/en/4.7/classes/class_atlastexture.html)
- [Geometry2D](https://docs.godotengine.org/en/4.7/classes/class_geometry2d.html)
- [CanvasItem shaders](https://docs.godotengine.org/en/4.7/tutorials/shaders/shader_reference/canvas_item_shader.html)

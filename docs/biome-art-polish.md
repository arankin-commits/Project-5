# Underground biome art pass

Implemented in route order: Maintenance, Factory, Boiler, Toxin Refinery.

The flat vector room pass has been replaced in all 120 layouts by painted
modular environments. `scripts/painted_biome_room.gd` fits textured steel
floors, thick walls, doorways, crates, machinery and platform edges to the
original geometry. Plate size stays consistent across source canvas sizes.
Maintenance has cyan machinery and fan portals; Factory has conveyors and
rolling shutters; Boiler has copper pressure vessels and pipe doorways.
Toxin Refinery is an open platform over animated lime liquid, with cyan
transit gates and capsule trams, rather than an enclosed green room.

References are `maintenance reference.png`, `factory reference.png`,
`boiler reference.png`, and `toxin factory reference.png` in `rooms/references`,
the biome room sheets,
the four `rooms/Hazards` atlases, and the four enemy art-pass sheets in
`characters/enemies/references`. Four new painted environment atlases were
generated with the built-in image-generation tool using those scenes as
references. The assets and prompt set are in `art/painted_biomes/`.
Enemy artwork remains from the earlier vector material pass; the room
correction does not modify enemies or combat.
The trap artwork uses the supplied painted atlases directly. The crossed-out
maintenance floor fan is excluded. Interlocking saw and oven atlas assets use
polygon masks instead of rectangular crops.

All 33 regular enemy atlases retain eight directions and sixteen animation
poses, with biome finishes, bright powered lenses, inset armor seams, rivets,
edge highlights, and striped warning materials. Source models, enemy stats,
abilities, collision geometry, wave definitions, and room navigation remain
unchanged. Boss art is retained.

Ground-trap warnings retain the actual 65-by-32.5 world-pixel damage footprint.
The warning ring fills before activation; electrical arcs, ember streaks, and
chemical bubbles distinguish biomes. Refinery spikes change between the three
supplied poses with the existing timer. Duplicate trap types have unique node
names so every spike in a room updates. Existing nonfunctional machinery
(saws, presses, fans, turrets, flame machines, acid dispensers and barrels)
remains decorative; this pass does not add new damage mechanics.

The old `tools/polish_biomes.py` output is retained as a legacy fallback;
it is hidden in the runtime room renderer. Current painted art is assembled
by `painted_biome_room.gd` from the four PNG atlases, with `painted_floor.gdshader`
handling material tiling and refinery liquid flow.
Regenerate enemies with `node tools/export_industrial_enemies.cjs` (or one
biome argument). The enemy exporter preserves the current gameplay catalog;
the room integration tool retains polished art when regenerating catalogs.

Three newly used hazard sheets were removed from the Web export exclusion
list. The existing root Web build has not been rebuilt or published.

Validation artifacts for the correction: `reviews/painted_*` screenshots,
`painted-layout-tests.log`, and `polish-all-visual.log`. The capture script
renders three room sizes per biome and four whole-room overview images.
Enemy gallery capture is opt-in with `--enemy-gallery`.
Automated captures are not a manual full-run playtest. Godot also reports
existing duplicate source UIDs and shutdown resource leaks; sandboxed runs
report a certificate-store warning.

Correction validation: 16,928 room/navigation/trap checks passed. Catalogs,
collision geometry, wave definitions and enemy statistics are unchanged by
this correction. Images were inspected in the actual compatibility renderer.

Room previews: [Maintenance](../reviews/painted_maintenance_overview.png),
[Factory](../reviews/painted_factory_overview.png),
[Boiler](../reviews/painted_boiler_overview.png),
[Toxin Refinery](../reviews/painted_toxin_refinery_overview.png).

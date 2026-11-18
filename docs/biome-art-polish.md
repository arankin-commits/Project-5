# Underground biome art pass

Implemented in route order: Maintenance, Factory, Boiler, Toxin Refinery.

All 120 room images now use fitted vector artwork: individual steel plates,
fasteners, seams, wear, recessed entrances, service pipes, illuminated wall
panels, underfloor edges, and machinery on the original obstacle footprints.
Maintenance uses slate/cyan/brass; Factory uses warm steel/red/ochre;
Boiler uses copper/ember; Toxin Refinery uses oxidized green/lime.

References are the four scenes in `rooms/references`, the biome room sheets,
the four `rooms/Hazards` atlases, and the four enemy art-pass sheets in
`characters/enemies/references`. Room and enemy artwork is a vector adaptation
of the materials and colors, not a painted reproduction of those sheets.
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

Regenerate rooms with `python tools/polish_biomes.py` (or one biome argument).
Regenerate enemies with `node tools/export_industrial_enemies.cjs` (or one
biome argument). The enemy exporter preserves the current gameplay catalog;
the room integration tool retains polished art when regenerating catalogs.

Three newly used hazard sheets were removed from the Web export exclusion
list. The existing root Web build has not been rebuilt or published.

Validation artifacts: `reviews/polish_*` screenshots, `polish-final-tests.log`,
`polish-enemy-tests.log`, and `polish-all-visual.log`. The capture script renders
three room sizes per biome plus walk, windup, attack and death enemy galleries.
Automated captures are not a manual full-run playtest. Godot also reports
existing duplicate source UIDs and shutdown resource leaks; sandboxed runs
report a certificate-store warning.

Final results: 16,928 room/navigation/trap checks passed; 849 enemy checks
passed. All 120 catalog entries differ only in their artwork path, and the
enemy statistics catalog has no changes. The final rendered capture produced
12 room screenshots and 16 enemy-state screenshots without script errors.

Room previews: [Maintenance](../reviews/polish_maintenance_00.png),
[Factory](../reviews/polish_factory_00.png),
[Boiler](../reviews/polish_boiler_00.png),
[Toxin Refinery](../reviews/polish_toxin_refinery_00.png).

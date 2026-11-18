# Painted environment atlas prompts

Generated using the built-in image-generation tool, with genuine alpha
transparency requested. The four named images in `rooms/references` are the
style/content inputs. `maintenance-atlas.png` is the layout reference for the
other three sheets. Final outputs are the four sibling `*-atlas.png` files.

Shared prompt specification: production painted game environment texture and
sprite atlas, 1536x1024, exact 3x2 grid of 512x512 cells. Dense weathered
materials, volume and local soft shadows matching the reference. No vector,
low-poly or pixel-art appearance; no labels, UI, characters or checkerboard.
Transparent gutters, no overlapping assets. Floor and wall materials are
orthographic so they can be mapped to the actual room geometry. Props use
the reference's isometric camera. Bottom-row bases sit near y970.

Cell layout:

1. Upper-left, x52..476/y45..474: square top-down four-by-four riveted steel
   plate patch; scratches, oil stains, wear; no objects or perspective.
2. Upper-middle, x550..985/y42..472: rectangular front-elevation wall panel,
   heavy steel slabs, pipes, caged lamp and biome utility details. Refinery
   replaces this cell with top-down lime liquid, swirling reflections and foam.
3. Upper-right, x1041..1510/y40..474: front-elevation biome doorway; thick
   frame, warning threshold, header illumination, transparent outside.
4. Bottom-left: isolated low isometric cargo-crate cluster with metal latches,
   worn yellow-black base and attached biome barrel/canister.
5. Bottom-middle: isolated isometric landmark machine on a compact foundation.
6. Bottom-right: wide isometric service-wall machinery assembly. Refinery uses
   a capsule tram and elevated rails instead of a wall assembly.

Maintenance prompt: match the maintenance scene's richly painted charcoal
steel, chipped bevels, grime, copper pipes, muted ochre hazard stripes, cyan
utility lights and amber lamps. Circular maintenance fan portal with cyan
sides and amber header. Orange drum on crates. Landmark cabinet with twin
cyan cylinders, duct elbow and copper services. Wide service assembly with
large ventilation fan, elbow ducts, wires and a lamp; no floor platform.

Factory prompt: match the factory scene's dark worn steel, brass gears,
hazard stripes, warm amber lamps and red underglow. Oily gray floor with
subtle rust. Wall has copper conduits and red indicator. Rolling shutter
portal with small gear/factory emblem, cyan side strips and ochre threshold.
Red oil drum. Landmark machine has geared conveyor feed, forging rollers,
mechanical arm and internal orange light. Wide wall assembly has overhead
crane, motor, hanging hook and gear conveyor. No room composition.

Boiler prompt: match the boiler scene's copper pressure vessels, rivets,
soot-stained dark steel, large pipes, furnace orange light and amber lamps.
Gray-brown steel floor with oily mottling and restrained orange reflections.
Wall has copper pipes and glowing furnace vent. Giant circular steam-pipe
doorway with flange, dark interior and faint steam. Red pressure canister.
Landmark boiler has domed copper top, prominent cream dial, elbow pipes and
orange windows. Wide furnace wall has copper ducts, pressure gauges and small
smoking stack. No flames extending outside cells.

Refinery prompt: match the open steel platform over luminous lime acid,
cyan transit gates and corroded machinery. Gray-brown floor with subtle green
corrosion; upper-middle is LIQUID NOT WALL, bright organic ripples without
a container or border. Rectangular transit portal with scuffed pale metal
frame, brilliant cyan inner frame and dark cyan interior with rails, no fan
or shutter. Red chemical drum with biohazard marking. Landmark chemical vat
has bronze/corroded steel, glass lime-liquid tanks, pipes and valves. Wide
bottom-right asset is a gray capsule tram on twin rails, cyan lights and
support pillars. No room scene.

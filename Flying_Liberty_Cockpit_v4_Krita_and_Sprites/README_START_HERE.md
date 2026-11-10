# Flying Liberty Cockpit — Corrected Production Separation v4

This pack addresses both problems in the v2/v3 attempt: moved asset placement and baked-in duplicate props.

## What is actually in it
- **Cockpit_v4_Genuine_Editable_Layers.ora**: independently toggleable, full-canvas Krita-compatible layers.
- **Full_Canvas_Layers**: 19 separate aligned PNG layers, each the same 1672x941 size.
- **Sprites_Cropped**: 17 transparent cropped sprites plus exact original top-left pixel placement in manifest_v4.json.
- **Previews/01_Exact_Assembly.png**: assembled from the separated layers.
- **Previews/02_Empty_Background_No_Props.png**: what the repainted/inpainted shell and floor look like with props hidden.
- **Previews/03_Seats_and_Helm_Hidden.png**: a check that chairs and wheel are NOT still painted into the background.
- **References/ChamberForge_Cockpit.json**: unchanged gameplay layout; art position does not redefine collision positions.

## Quality check
- Pixels exactly matching the no-character Illustrated Art Pass: 100.00%.
- Mean absolute RGB pixel difference: 0.00 / 255.
- No rescaling or arbitrary repositioning was used for asset assembly.
- Built-in central console and emblem remain part of the floor/wall background by design; no second sprite is layered over either.
- Every visible pixel was assigned to one sprite or a non-overlapping architecture/floor layer.

## Real limitations
- The source is a single flattened illustration, so the areas formerly hidden behind large objects cannot be recovered exactly. The room shell uses inpainting; those newly exposed patches are approximate and should be repainted in Krita before moving the objects far from their original locations.
- Sprite silhouettes are traced polygons, not high-end hand-painted edge mattes. Some transparent edges and shadows require manual retouching for individual sprite animation.
- The cockpit image's prop positioning follows the Illustrated Art Pass. The ChamberForge JSON remains the authority for collision/gameplay, including the pilot's position.

## How to edit in Krita
1. Open `.ora`. All layers should align without movement.
2. Hide `Pilot Seat Left`, `Pilot Seat Right`, or `Helm Wheel`; the item should not remain in the background.
3. For a finished art pass, clean sprite silhouettes and paint occluded deck sections using the visible underpaint layer.
4. Save as `.kra` and export individual sprites or import `Sprites_Cropped` into Godot.

## Practical inspection
Open `Open_Layer_Inspector.html` after extracting the folder. Hide a single seat or desk; it will not appear twice. The source comparison button can verify positions.

## Note on background repair
The **assembled room** matches the original exactly; the **uncovered areas behind removed furniture** are newly painted approximate plank/grate fills and can look visibly patched. Their details were never in the original flat image, so for a polished movable asset production release these specific areas still need an artist to hand-paint consistent perspective, shadows, and trim.

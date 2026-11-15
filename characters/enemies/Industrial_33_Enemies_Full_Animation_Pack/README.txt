INDUSTRIAL SKYSCRAPER — 33 ENEMY ISOMETRIC DIRECTIONAL ANIMATION LAB
=====================================================================

CONTENTS
- Industrial_33_Enemy_Directional_Lab.html : single-file playable movement + attack viewer
- enemy_design_data.json                  : data for exactly 33 enemies and their 99 named moves
- models.js / app.js                       : editable source for procedural 3D grayboxes, projection,
                                            runtime directional selection and combat demonstrations
- obj_grayboxes/                           : 33 static 3D OBJ graybox meshes + a shared .MTL
- turnarounds/                             : 33 eight-direction graybox sprite sheets
- turnarounds_32_idle/                     : 33 idle/locomotion 32-direction sprite sheets
- animation_previews/                      : 33 GIFs showing 8-direction movement and 3 attack states
- *_Enemy_Preview.png                      : four biome galleries
- Original_Enemy_Designs_33.md            : the supplied moveset design source
- Original_Enemy_Stats_33.csv             : the supplied stat table

OPEN THE PLAYABLE DEMO
1. Unzip to any folder (no installation needed).
2. Double-click Industrial_33_Enemy_Directional_Lab.html; open in Chrome/Firefox.
3. Choose any enemy in the right-hand selector, or pick a biome.
4. Press WASD to move it through the room. Use 1/2/3 to try each named move.
5. Use "8-way tour" to watch all directions or "All moves" for a scripted demonstration.
6. Switch between 8 / 16 / 32 facing-angle quantization while running.
7. Use K for a generic physical death/fall test, R to reset, and check the Elite marker.

BACKGROUND
The neutral arena uses the user's supplied maintenance room reference S03_Filter_Intake(2).png.
All 33 models use the same fixed isometric camera for consistent comparison.

TECHNICAL DETAILS
The blockouts are made of 3D geometric solids and projected from the fixed viewpoint.
The HTML rasterizes generated graybox geometry on demand and quantizes yaw to the
selected number of angles. It is deliberately not a static billboard sheet for each
model, nor is it a fully rigged 3D character system.

CAVEATS / NOT YET COMPLETE
- The 33 models are prototype blockouts, not final textured models.
- Motion is generated through scripted geometric poses, direction/lean, and combat FX;
  these are not professionally authored keyframed or skeletal animation clips.
- The exported OBJ geometry is static and has no armature, skinning, or animation data.
- The test target is a dummy; the game is not a complete enemy-AI combat simulation.
- Each elite toggle adds an inspection marker, not the finalized unique elite mesh.
- Attack warnings and mock damage are illustrative, not production hitbox data.

ATTRIBUTION
All procedural geometry, rendering code, and new preview exports were authored for
this prototype, using the enemy names/descriptions/movesets supplied by the user.

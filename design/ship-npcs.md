# Ship NPCs

`npc_catalog.gd` references the original supplied character sheets. Polygon UVs
separate each left-hand world sprite from the right-hand dialogue portrait without
changing the source art. RGB sheets use a black-matte shader; mipmaps keep small
sprites readable. Dialogue lines are starter lines and can be edited in the catalog.

`ship_npcs.gd` stores fixed placements calibrated to the three screenshots in
`characters/NPCS/Placements`. The sleeping man is at the lounge, the kids are at the
stools, and the cook is beside the galley. Handler stands by the sync-room desk.
Engineer replaces the baked-in figure between the workshop benches; Mechanic is
provisionally placed to the left of those benches. Cyber Security Analyst and Info
Broker are catalogued but intentionally not spawned until the computer room exists.

`ShipCrew` stores one cockpit assignment per ship visit: pilot alone, copilot alone,
or both, at the two marked floor positions. Opening rooms does not change it.
Only ending an active run (victory, death, Give Up) rolls a different assignment.
Repeated end calls are ignored. Fixed NPCs never move.

E opens, advances, and closes dialogue. Portrait dialogue locks player movement;
the ship menu remains available and preserves that lock on Resume.

## Workshop background edit

Built-in imagegen removed only the old engineer from the workshop background.
Saved asset: `rooms/Engineering Workshop Without Engineer.png`.
Original source remains in `rooms/Steampunk Automaton Engineering Workshop.png`.

Prompt: Edit this exact game room background. Remove ONLY the small standing
female engineer at image coordinates approximately x840-908 y670-850, between the
two front workbenches. Replace her and her shadow with matching uninterrupted
wooden floorboards. Preserve everything else, all furniture, all three robots,
room boundary, windows, lamps, colors, perspective, proportions and framing
exactly. No new characters or objects. Output the same full room landscape composition.

Preview images are in `reviews/npcs_*.png` and `reviews/dialogue_*.png`.

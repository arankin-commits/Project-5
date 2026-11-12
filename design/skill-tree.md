# Elemental skill tree

The workshop's old core-selection interface is replaced by the supplied artwork
with 20 selectable nodes. Permanent progression is stored in `user://skill_tree.cfg`.
Run cores, energy, and Final Stand usage reset for each run.

## Initial balance values

These are defaults for values not specified in the design request:

- Regular nodes spend XP only: Final Stand, Nanobots, wall-stun damage, backstab damage.
- Special nodes spend Aether Gears only: core capacity and the five ability upgrades.
- Enemies award 10 XP; the boss awards 100 XP; clearing a chamber awards 25 XP.
- Chamber 4 and the boss each award one Aether Gear, retained even if the run is lost.
- Special abilities cost one gear. Power of Two costs two; Power of Three costs three.
- Regular ranks cost 100/150/200 XP; Nanobots extends to 250/300 XP. Final Stand costs 150 XP.
- Perfect dodge: evade an incoming hit within the first 0.12 seconds of a dash;
  gain 25% damage for five seconds. Repeated perfect dodges refresh, rather than stack.
- Chain Dodge: two uses, with both restored after the normal recharge period.
- Charged Strike: hold primary attack for at least 0.6 seconds, then release;
  double strike damage and 180-pixel collision-aware knockback.
- Energy: 5 per melee enemy hit, or 10 with Energy Siphon, capped at 100.
- Grapple (F): pull a small enemy within 360 pixels; Heavy Grapple adds brutes.
  Bosses stay anchored. Two-second cooldown, with walls blocking the hook.
- Wall collision stuns an enemy for 1.5 seconds. Damage ranks add 15/30/45%
  while stunned. Backstab ranks increase the class's backstab damage by 20/40/60%.
- Final Stand: once per run, lethal damage restores half maximum health and grants
  two seconds of invulnerability.
- Nanobots: heal 5/10/15/20/25 on first entry to a new room, capped at maximum health.

## Elemental cores

Each cleared nonfinal chamber offers one eligible elemental core alongside two
salvage options while there is a free slot. Duplicates are excluded. At capacity,
all three options are salvage and no further elemental encounters occur.
Capacity is 1, 2 with Power of Two, or 3 with Power of Three.

Q spends 25 energy to activate all equipped elements within 240 pixels, with a
one-second cooldown and wall occlusion. Fire deals 40 base damage; Water deals
25 and slows for three seconds; Lightning deals 25 and knocks enemies back.
Class damage and the perfect-dodge buff scale these initial core effects.

Run headless tests with `-- --test-mode` to avoid loading or writing player saves.

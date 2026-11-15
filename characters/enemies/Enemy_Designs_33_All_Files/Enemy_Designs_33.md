# Industrial Biomes — Expanded Design Specs for 33 Enemies

**Source:** User-provided `Pasted markdown(1).md` (33 enemy concepts). Core attacks and descriptions preserved; new quantitative timings and secondary actions are proposed for playtesting.

## Shared standards

- Player: **100 HP**; movement **5 world units/s**.
- Size classes: **Tiny** (under 0.5 u body width); **Small** (0.5–1.0 u); **Medium** (roughly 0.8–1.6 u); **Large** (roughly 1.5–2.5 u).
- Danger tier: **1–5**, based on encounter complexity and threat rather than HP alone.
- Attack states: idle / approach / telegraph / commit / active damage frames / recovery. A visible decal remains readable at fixed isometric camera scale.
- Damage is applied only on active hit frames; attacks locked after their final aiming tell. Individual hazard ticks and swarm attacks must respect invulnerability/damage-cooldown rules.
- Elite HP values are proposed starting points; elite behaviors must have their own telegraphs.
- All enemies occupy a single walkable floor height; hovering enemies maintain floor shadows.

## Maintenance

### Inspection Wasp — Flying

**Size:** Small (0.8 × 0.8 × 1.1 u; hovers 1.2 u above floor)  
**Health:** 35 HP  
**Speed:** 4.2 u/s  
**Danger:** Tier 2/5

**Visual graybox:** Triangular wedge shell, one large circular camera eye, two horizontal cylinder thrusters, small stabilizer fins and a long telescoping needle under the center. Keep the entire silhouette visibly nose-down.

**Animation pivots / construction:** Independently swivel both thrusters; telescope the needle; roll the shell into dives; eye emissive state controls warnings.

**AI behavior:** Orbits at 3–6 u range. Chooses Probe Dive when aligned, Scanner Sting at medium range, and Strafe when cornered. Body tilts with velocity, then returns upright.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Probe Dive | 0.50 s: nose pitches down, eye turns red and a narrow lane appears | Lunges along locked lane for 9 damage (up to 5 u). | 0.55 s wobble to stabilize with needle extended. | 3.0 s |
| Scanner Sting | 0.70 s: thin targeting beam fixes a direction | Fires one electrical pulse for 7 damage along the beam. | 0.35 s eye shutter closes and reopens. | 4.0 s |
| Evasive Strafe | 0.20 s: one side thruster flashes | Sideways burst 2.0 u; deals no damage. | 0.25 s hover settles; cannot attack. | 3.2 s |

**Elite — Hunter Wasp:** Two inspection needles and orange-edged wing fins; follows the first dive with a second separately warned dive after a 0.35 s realignment. Elite HP 53.

**Death animation:** 0.0–0.25 s rotor desynchronization; 0.25–0.65 s spiral drop; 0.65–1.1 s three-piece impact scatter; eye light flickers out.

---

### Dust Mites — Swarm

**Size:** Tiny (0.35 × 0.35 × 0.35 u each; hover 0.35 u; base pack 6)  
**Health:** 12 HP  
**Speed:** 4.0 u/s  
**Danger:** Tier 2/5

**Visual graybox:** Each bot is a flattened sphere, single central eye, two tiny cylinder side thrusters, and one visible circular brush disk below. Give individual bots 5–10% scale variations; six bodies form a loose flock.

**Animation pivots / construction:** Spin brush and thrusters separately; eye is one warning element; each unit has its own hover pivot and knockback.

**AI behavior:** Loose flocking around the player; attacks staggered. Six units maximum for a standard group. No stacking contact damage in one hit window.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Brush Strike | 0.35 s: one eye flashes red and brush spins faster | Unit darts 0.9 u for 4 contact damage. Shared victim hit cooldown prevents simultaneous chip hits. | 0.30 s drift backward and reposition. | 1.8 s/unit |
| Swarm Rush | 0.80 s: all surviving eyes flash in sync and group compresses | Coordinated multi-bot dive; up to 12 total damage from the entire wave. | 0.65 s flock scatters and slows. | 6.0 s/pack |
| Regroup | 0.40 s: lights shift cyan and movement slows | Units converge into a 1.2 u formation; no damage, prepares the next Rush. | 0.25 s synchronized hover. | 5.0 s/pack |

**Elite — Red-Eye Cluster:** One visibly larger command bot (24 HP) conducts two Rush waves separated by 0.65 s. Destroying it restores normal uncoordinated behavior.

**Death animation:** Each destroyed bot sparks, loses altitude in 0.2 s, bounces once, and rolls to rest for 0.5 s before disappearing; surviving units do not pause.

---

### Pressure Purger — AOE

**Size:** Large (2.0 × 2.0 × 2.4 u)  
**Health:** 110 HP  
**Speed:** 1.6 u/s  
**Danger:** Tier 3/5

**Visual graybox:** Tall vertical cylinder with an octagonal plinth, eight evenly spaced rectangular vents, four bracing pistons, front pressure dial and rotating warning beacon. Large circular plan-view silhouette.

**Animation pivots / construction:** One pivot for each port flap, one for the beacon, four for stabilizer pistons, and one gauge needle.

**AI behavior:** Moves to open central space, anchors before major attacks, and cannot turn once a sweep begins. Puddles disappear clearly.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Steam Ring | 1.10 s: stabilizers extend; circular floor decal grows | Expanding steam ring deals 18 damage when crossed. | 0.75 s vents exhaust harmless vapor. | 6.0 s |
| Vent Sweep | 0.70 s: front vent opens and 90° cone is marked | Sweeps hot steam through cone for 12 damage. | 0.60 s vent shutter slowly closes. | 4.0 s |
| Chemical Overflow | 0.90 s: liquid leaks at the base inside a marked circle | Leaves a corrosive puddle for 3 s; proposed 3 damage/s, nonstacking. | 0.45 s pump drains and shuts. | 7.0 s |

**Elite — Double Purger:** Two independently telegraphed steam rings separated by 0.70 s; second ring has a smaller safe inner radius. Elite HP 165.

**Death animation:** Gauge needle pegs; 0.25 s bolts pop; 0.4 s harmless venting; 0.5 s cylinder buckles onto its base. Final cloud cannot damage.

---

### Spanner Guard — Close Range

**Size:** Medium (1.1 × 0.9 × 2.0 u)  
**Health:** 90 HP  
**Speed:** 2.8 u/s  
**Danger:** Tier 2/5

**Visual graybox:** Rectangular chest, squat cylindrical head with visor slit, broad box shoulders, piston forearms, oversized wrench hands, short blocky shins and heavy boot prisms.

**Animation pivots / construction:** Separate shoulder yaw, elbow hinge, wrist/tool rotation, torso twist, hips and knees. Place hitboxes on wrench arcs, not whole arms.

**AI behavior:** Closes to 1.4 u and generally uses the two-hit string. Uses overhead crush separately against a stationary target. Each slash has a discrete damage window.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Wrench Slash 1 | 0.45 s: right wrench draws back; a 100° arc appears | Horizontal swipe for 9 damage. | 0.20 s arm follow-through; links into Slash 2. | Combo |
| Wrench Slash 2 | 0.30 s: torso counter-rotates and left wrench cocks | Reverse swing for 11 damage. | 0.65 s dual-arm cooldown after combo. | 3.3 s/combo |
| Overhead Crush | 0.90 s: both wrenches lift over head; short floor rectangle lights | Downward smash for 19 damage. | 0.90 s wrenches stuck briefly in floor. | 6.0 s |

**Elite — Master Spanner:** Brass shoulder collar and longer wrench handles. Adds Overhead Crush as a delayed third strike after Slash 2 with its full 0.90 s warning. Elite HP 135.

**Death animation:** Drops one wrench first, backward torso tip, knee pistons buckle, body collapses on its side, remaining wrist opens involuntarily.

---

### Foreman Node — Summoner

**Size:** Large (1.9 × 1.9 × 2.0 u; hovers 0.5 u)  
**Health:** 130 HP  
**Speed:** 1.3 u/s  
**Danger:** Tier 4/5

**Visual graybox:** Central cylindrical command pod with one circular eye, four radiating fabrication arms and six docking bay slots underneath. Outer panel petals fold open to reveal mini-bot slots.

**Animation pivots / construction:** Use six independently hinged docking lids, four tool-arm pivots, whole-body hover and an expanding defensive ring.

**AI behavior:** Retreats to 5–7 u. Summons only if under alive-unit cap; prioritizes pulse if approached. Existing summoned bots remain after Foreman death.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Deploy Cleaners | 1.30 s: lower hatches unfold and fabrication arms cycle | Summons 3 Dust Mites, no direct damage; cap 6 summons alive per Foreman. | 0.70 s doors reseal. | 7.0 s |
| Defensive Pulse | 0.85 s: cyan perimeter ring turns red and expands | Pushes nearby player back and deals 9 damage. | 0.55 s ring contracts. | 5.0 s |
| Assembly Barrage | 0.70 s: front arms unfold and two barrels align | Fires 2 short-range scrap projectiles for 6 damage each. | 0.50 s arm retraction. | 4.0 s |

**Elite — Chief Foreman:** Wider command halo, orange docking doors, 4 Mites per wave, and 3 s of temporary armor on new bots. Still obeys total summon cap of 6. Elite HP 195.

**Death animation:** Doors pop open; fabrication arms lose synchronization; eye flashes red; levitation cuts and pod drops straight down. Existing summons remain alive.

---

### Cable Snare Unit — Grappler

**Size:** Medium (1.0 × 1.0 × 1.5 u; grapple reach 6 u)  
**Health:** 80 HP  
**Speed:** 2.5 u/s  
**Danger:** Tier 4/5

**Visual graybox:** Narrow rectangle chassis on three hinged legs, exposed circular cable drum, telescoping claw on one disproportionately long arm, small rear balance weight.

**Animation pivots / construction:** Cable reel rotates; claw jaws open independently; telescope arm sections; cable is a line rendered between spool and claw.

**AI behavior:** Holds 3.5–6 u range and tries to catch the player before melee. Hook can be dodged or broken with a defined escape input; never drags through walls.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Grapple Launch | 0.75 s: thin targeting line locks onto one lane, claw jaws open | Fires claw up to 6 u; contact deals 6 damage and enables Cable Reel. | 0.55 s missed claw retracts. | 5.0 s |
| Cable Reel | 0.25 s: cable tightens visibly after a successful hook | Pulls player toward unit for up to 0.75 s; stops at solid geometry; no extra damage. | 0.50 s recoil as spool resets. | On hook |
| Clamp Strike | 0.40 s: claw opens wide, short 70° cone appears | Short mechanical chop for 13 damage. | 0.65 s claw closes and resets. | 3.5 s |

**Elite — Twin-Spool Snare:** Second spool and mirrored claw arm. A missed first hook can trigger a second, with its own 0.75 s targeting tell. Elite HP 120.

**Death animation:** Spool overspins, cable whips down harmlessly, drum breaks free, tripod folds and collapses into a coil of loose wire.

---

### Phase Custodian — Teleport

**Size:** Medium (0.85 × 0.7 × 2.1 u)  
**Health:** 80 HP  
**Speed:** 3.4 u/s  
**Danger:** Tier 4/5

**Visual graybox:** Slim long-limbed android: vertically stacked rectangular body panels, elongated hinge arms, rectangular head, segmented legs and narrow baton. Keep shoulder width notably narrow.

**Animation pivots / construction:** Separate torso plates for phase effect; arm/leg joints for lunges; floor destination decal persists until arrival.

**AI behavior:** Prefers flanking, not guaranteed rear teleports. Never attacks during invisibility; the landing point and slash direction remain visible before damage.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Phase Step | 0.60 s: body segments flicker; a destination marker appears | Moves instantly to the selected visible floor marker; no damage. | 0.25 s solidification; no collision damage. | 5.0 s |
| Ambush Slash | 0.45 s AFTER reappearing: shoulder winds back and arc flashes | Fast blade strike for 14 damage toward locked facing. | 0.65 s weapon passes target and pauses. | 4.0 s |
| Shock Baton | 0.55 s: narrow baton lights cyan and a 2 u line is marked | Short electrical jab for 10 damage. | 0.45 s baton vents sparks. | 3.5 s |

**Elite — Phantom Custodian:** Twice blinks between separate marked positions; harmless afterimage remains at each. Final Ambush Slash retains full tell. Elite HP 120.

**Death animation:** Flickers between opacity states, panels separate vertically and crumble into glowing fragments; last grounded shadow fades only after defeat.

---

### Signal Scrambler — Disruptor

**Size:** Small (0.85 × 0.85 × 1.2 u; floats 0.6 u)  
**Health:** 60 HP  
**Speed:** 3.0 u/s  
**Danger:** Tier 3/5

**Visual graybox:** Spherical switchboard core with protruding antenna needles, two rotating edge dials, and a circular projector ring. A distinct spiky ring silhouette from above.

**Animation pivots / construction:** Antenna telescopes, dial pointers rotate separately, outer ring scales with each pulse.

**AI behavior:** Hovers behind allies; does not hide attack telegraphs, distort controls, or invert camera input. Debuff uses a visible player-status icon.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Interference Pulse | 0.85 s: needles align and cyan boundary turns amber | Radial 3.5 u wave; on hit, slows ability-energy regeneration 40% for 3 s. | 0.65 s dials reverse and reset. | 7.0 s |
| Static Jitter | 0.50 s: three small marked floor disks appear | Fires short electrical arcs toward disks, 6 damage on impact. | 0.40 s antenna shutters retract. | 4.5 s |
| Channel Drift | 0.35 s: screen flashes blue | Slides sideways 2 u, breaks target tracking; no damage. | 0.25 s reacquisition. | 4.0 s |

**Elite — Broadband Scrambler:** Extra concentric antenna ring and amber top beacon. Sends two slower concentric pulses 0.55 s apart, each dodgeable separately. Elite HP 90.

**Death animation:** Antennas retract out of sequence, dials spin backward uncontrollably, outer ring falls, and the central sphere cracks into halves.

---

## Factory

### Conveyor Hound — Charging

**Size:** Medium (1.4 × 0.75 × 1.0 u)  
**Health:** 90 HP  
**Speed:** 3.2 u/s  
**Danger:** Tier 3/5

**Visual graybox:** Low six-legged mechanical dog with two long conveyor belts on its flanks, a mouth of stacked feed rollers, and small square warning lamps over the jaw. Low horizontal silhouette.

**Animation pivots / construction:** Six leg hinges; each side belt scrolls independently; roller jaws spin; chest compresses before bursts.

**AI behavior:** Tracks at 3–6 u, commits to one straight lane before chasing, and never homes during the high-speed portion.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Belt-Line Chase | 0.75 s: flank belts briefly reverse, jaws chatter; 1 u-wide floor lane | Accelerates to 9 u/s and runs straight up to 7 u; bites at the end for 18 damage. | 0.85 s belt overrun carries it past the target. | 5.0 s |
| Roller Snap | 0.40 s: top roller lifts and jaw gap widens | 1.4 u bite cone for 10 damage. | 0.40 s reverse-roller jaw release. | 3.0 s |
| Belt Shred | 0.65 s: leg braces lower; side belt spins bright | Short 2 u lateral scrape dealing 8 damage along its flank. | 0.50 s belt stalls. | 4.2 s |

**Elite — Twin-Belt Hound:** Secondary upper belt and longer jaw housing. Can follow first charge with a clearly indicated reverse charge at 70% speed. Elite HP 135.

**Death animation:** Legs mis-time; side belts spin off their shafts; jaw rollers seize and body skids forward trailing harmless sparks.

---

### Link Crawlers — Swarm

**Size:** Tiny (0.22 × 0.4 × 0.25 u per link; 5 links per chain)  
**Health:** 14 HP  
**Speed:** 4.1 u/s  
**Danger:** Tier 2/5

**Visual graybox:** Miniature conveyor-chain centipedes made of rectangular toothed link segments; bright exposed hinge pins and a small flat head plate. Form a narrow articulated train rather than flying discs.

**Animation pivots / construction:** Each hinge bends independently; segment row stiffens into a single aligned spear for lunges.

**AI behavior:** Uses short straight bursts rather than surrounding the player. Chain bodies share one attack budget to avoid simultaneous multi-link hits.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Linked Spear | 0.65 s: segments snap rigid; straight narrow lane appears | Whole chain lunges 3 u, 11 damage if struck by head. | 0.55 s segments separate at joints. | 4.0 s |
| Tail Whip | 0.35 s: rear links curl left, 90° arc lights | Last 3 links sweep for 6 damage. | 0.35 s tail reknits. | 3.0 s |
| Chain Scatter | 0.40 s: hinge lights flash in sequence | Splits briefly into 2 smaller independently targetable groups, no damage. | 0.60 s reconnection at head. | 6.0 s |

**Elite — Ratchet Train:** Six heavier links with gold hinge pins. After Linked Spear it immediately telegraphs a second Tail Whip from the other side. Elite chain 100 HP total.

**Death animation:** Hinge sparks propagate front-to-back; links release one by one and clatter into a short line of debris.

---

### Gearburst Canister — AOE

**Size:** Medium (1.3 diameter × 1.15 u tall)  
**Health:** 80 HP  
**Speed:** 2.0 u/s  
**Danger:** Tier 3/5

**Visual graybox:** Armored squat rolling drum with eight radial seam slots and spring-loaded toothed gears inside. Removable outer annular armor is visually obvious.

**Animation pivots / construction:** One drum roll pivot; eight radial shutters; outer ring becomes detached during recovery.

**AI behavior:** Moves slowly toward middle of room then bursts at distance. Reliable gaps between gear rays are mandatory.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Eight-Gear Burst | 0.95 s: seam lines glow and gears rattle inward; eight radial lanes appear | Ejects 8 slowly traveling straight-line gears, 10 damage each (one-hit cooldown per volley). | 0.9 s outer armor ring opens exposing the center. | 6.5 s |
| Rolling Pinch | 0.50 s: drum tips toward player, two side indicators flash | Rolls 2.5 u along a short lane, 9 collision damage. | 0.55 s axle realigns. | 4.0 s |
| Spring Pop | 0.60 s: top hatch vibrates, small center disk glows | Vertical gear pops above unit and lands in marked 1 u circle for 8 damage. | 0.50 s lid snaps closed. | 5.0 s |

**Elite — Double-Indexed Drum:** Ten-sided gear barrel, upgraded steel ring. Fires an initial eight-lane burst then a separately warned burst rotated by 22.5°. Elite HP 120.

**Death animation:** Ring detaches, springs discharge harmlessly, drum unrolls on its side and individual metal teeth slide free.

---

### Shearblade — Close Range

**Size:** Medium (1.0 × 0.8 × 2.3 u; extended blade width 2.4 u)  
**Health:** 95 HP  
**Speed:** 3.0 u/s  
**Danger:** Tier 3/5

**Visual graybox:** Tall slim automaton with two enormous crossed scissor blades as arms, exposed chest hinge, narrow piston legs and a very small faceplate.

**Animation pivots / construction:** Big opposed shoulder hinges, rotating scissor pivot, torso tilt, knee flex. Mark narrow closing V rather than a generic circle.

**AI behavior:** Approaches diagonally and forces short dodges across a narrowing V. Vulnerable hinge is exposed during long recovery.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Closing V | 0.65 s: both blades open and narrow V is projected | Two-stage crossing cut aimed at the player’s previous position, 10 + 12 damage if hit twice. | 0.80 s blades lock closed, exposing hinge. | 4.5 s |
| One-Side Snip | 0.40 s: one blade rotates 90° outward | Fast diagonal cut for 9 damage. | 0.40 s spring resets. | 3.0 s |
| Hinge Lunge | 0.65 s: torso compresses and a thin lane appears | Stabs with joined blade tips 2.5 u forward for 13 damage. | 0.65 s tip catches in floor briefly. | 5.0 s |

**Elite — Double-Edge Shear:** Visible four-blade scissors with red center pivot. Closing V alternates two diagonal sectors with a 0.4 s gap. Elite HP 143.

**Death animation:** Blade lock freezes; shoulder springs eject; two long blades fall outward and the central hinge splits.

---

### Presswall Worker — Shield

**Size:** Large (1.8 × 1.2 × 2.2 u; shield plate 1.75 u wide)  
**Health:** 160 HP  
**Speed:** 1.8 u/s  
**Danger:** Tier 4/5

**Visual graybox:** Broad heavy two-legged industrial worker holding a rectangular sliding press plate in front. Exaggerated side hydraulic pistons and tracks allow the plate to shift beyond the arms.

**Animation pivots / construction:** Shield runs on side-mounted telescoping rails; piston legs plant; shoulder blocks show visible exposed flanks.

**AI behavior:** Moves toward allies to provide frontal cover. Cannot guard while shoving or track-slamming; player should flank rather than wait.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Press-Plate Shove | 0.80 s: side pistons brace; rectangular lane appears | Plate drives 2.4 u forward for 17 damage and knockback. | 1.0 s plate overshoots, exposing its left side. | 5.0 s |
| Front Guard | 0.25 s: plate clicks into upright track | Blocks 85% frontal damage in 140° sector for up to 2.0 s. | 0.5 s plate lowers and side joints expose. | 4.0 s |
| Side Track Slam | 0.70 s: plate slides toward one side; off-center rectangle lights | Wide side smash for 12 damage. | 0.70 s plate re-centers slowly. | 4.5 s |

**Elite — Forepress Worker:** Thicker press plate with twin red hydraulic rails. Guard becomes 160° but after shove both lateral pistons are vulnerable. Elite HP 240.

**Death animation:** Hydraulic rails fail asymmetrically; shield slams face down, torso pitches over it, and piston legs fold.

---

### Torque Thief — Disruptor

**Size:** Medium (0.9 × 0.85 × 1.7 u)  
**Health:** 75 HP  
**Speed:** 3.1 u/s  
**Danger:** Tier 3/5

**Visual graybox:** Crooked short-limbed tool-stealing robot; one shoulder higher than the other, exposed oversize wrist gears and a backpack capacitor drum.

**Animation pivots / construction:** Hands open claw fingers, wrist gears reverse, shoulder hunches and energy capacitor fills.

**AI behavior:** Uses Torque Swipe at melee range, then backs off to discharge or escape. Energy-stealing move needs an especially obvious tell.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Torque Swipe | 0.55 s: wrist gears reverse; narrow crescent appears | Close swipe for 8 damage and steals 12 ability-energy points on hit (never below zero). | 0.70 s gears stall storing stolen charge. | 4.0 s |
| Charged Toss | 0.75 s: backpack capacitor glows and one gear opens | Tosses a slow charged cog for 9 damage; no energy drain. | 0.50 s capacitor cools. | 5.0 s |
| Gear Feint | 0.35 s: one claw clicks open; no red attack decal | Quick sidestep 1.6 u; does not damage or steal. | 0.30 s brief balance correction. | 4.0 s |

**Elite — Double-Pawl Thief:** Two enlarged geared wrists and twin capacitor lamps. Swipe steals 18 energy; Charged Toss remains unchanged. Elite HP 113.

**Death animation:** Wrist gears jam in opposite directions, energy escapes in harmless arcs, and crooked arms snap into a rigid pose as body falls.

---

### Crane Hooker — Grappler

**Size:** Large (1.5 × 1.2 × 2.5 u; hanging hook reach 6 u)  
**Health:** 115 HP  
**Speed:** 1.8 u/s  
**Danger:** Tier 4/5

**Visual graybox:** Ground-walking portal crane with four blocky legs, tall overhead horizontal beam, suspended iron claw on chain and winch housing. Large rectangular upper silhouette.

**Animation pivots / construction:** Boom rotates separately; chain length adjustable; hanging claw casts a growing shadow on floor; winch drum spins.

**AI behavior:** Avoids tight corners and seeks lanes near presses. Drag terminates at obstacles and never guarantees environmental damage; claw itself is dodgeable.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Overhead Grab | 0.85 s: claw rises; circular floor shadow tracks, then locks | Drops claw into marked disk for 8 damage; on hit hooks player. | 0.75 s winch jams if it misses. | 6.0 s |
| Hazard Drag | 0.30 s: hooked chain pulls taut | Drags caught player up to 2.5 u toward existing marked stamped lane; no damage from reel itself. | 0.65 s chain unwinds and releases. | On grab |
| Boom Sweep | 0.80 s: overhead beam turns; long narrow strip lights | Swings hanging hook through a 130° arc for 14 damage. | 0.70 s hook oscillates and slows. | 5.0 s |

**Elite — Forked Crane:** Double cable claw and taller beam. Telegraphed two-circle drop in sequence, not simultaneous. Elite HP 173.

**Death animation:** Cable frays, top beam tips, claw lands separately and the crane body folds under the weight of its own boom.

---

### Chain Binder — Grappler

**Size:** Medium (1.2 × 0.9 × 1.4 u)  
**Health:** 90 HP  
**Speed:** 2.3 u/s  
**Danger:** Tier 3/5

**Visual graybox:** Squat chain-coiling machine with twin circular drums, scissoring hook arms and a low box chassis. Crossed hanging chains are clear even from above.

**Animation pivots / construction:** Two reel pivots, both claw arms independently yaw; loop renders as a closed line for player feedback.

**AI behavior:** Tries to cut off narrow routes rather than approach directly; crossed telegraph must leave clear side openings.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Chain Loop | 0.70 s: twin hooks fan outward; crossed red lanes appear | Throws a short loop 3.5 u; catches and pulls for up to 0.6 s, 6 damage on impact. | 0.70 s chain snares own axle after miss. | 5.0 s |
| Scissor Hook | 0.45 s: claws separate on two sides | Two hooks close into a 1.6 u front cone for 11 damage. | 0.50 s gear teeth release. | 3.5 s |
| Chain Lash | 0.65 s: left reel accelerates, sideways line lights | Sweeps one tether through 100° for 9 damage. | 0.60 s reel winds slack. | 4.5 s |

**Elite — Triple-Reel Binder:** Adds top drum and third hook forming a triangular capture zone with a marked escape wedge. Elite HP 135.

**Death animation:** Hooks cross and seize, reels overheat, one chain snaps harmlessly upward, body tips forward and settles.

---

## Boiler Room

### Cinder Kettle — Flying

**Size:** Small (0.95 × 0.9 × 1.0 u; hovers 1.0 u)  
**Health:** 55 HP  
**Speed:** 3.8 u/s  
**Danger:** Tier 2/5

**Visual graybox:** Floating copper kettle with half-sphere lid, pointed hot spout, two steam-jet fins and one glowing firebox window beneath the belly.

**Animation pivots / construction:** Spout yaw; hinged lid rattle; fins flap; jet nozzles expand during bursts.

**AI behavior:** Flies in lazy circles then commits to a short pour lane. Its shadow always remains visible on floor.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Ember Pour | 0.65 s: lid rattles and a narrow moving lane lights | Darts over a 4 u lane while laying a 1.5 s ember ribbon; crossing burns 5 damage/s. | 0.75 s kettle rattles empty and recharges. | 5.0 s |
| Scalding Spit | 0.55 s: spout reddens and tilts downward | Short ember blob for 9 damage in targeted direction. | 0.40 s steam jet hisses. | 3.5 s |
| Pressure Hop | 0.35 s: twin jets flare white | Repositions diagonally 2 u; deals no damage. | 0.35 s hover oscillates. | 4.0 s |

**Elite — Coal-Lid Kettle:** Two spouts with crossed pouring lanes and a larger black lid; lanes fire sequentially with a 0.4 s gap. Elite HP 83.

**Death animation:** Lid blows open without damage, firebox flickers blue then black, steam fins sputter and the empty kettle falls and dents.

---

### Soot Torpedo — Charging

**Size:** Medium (1.6 × 0.8 × 0.9 u)  
**Health:** 100 HP  
**Speed:** 2.5 u/s  
**Danger:** Tier 3/5

**Visual graybox:** Low charcoal-black rocket trolley with triangular nose bumper, two narrow skid runners and one massive rear furnace bell.

**Animation pivots / construction:** Furnace bell expansion, front suspension, side exhaust flaps, body recoil after wall impact.

**AI behavior:** Seeks clear straight lanes. Ricochet direction is predictable and visible before launch; only one reflection.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Ricochet Rocket | 0.85 s: ignition coughs twice and a smoky straight lane appears | Rockets at 11 u/s for up to 6 u, ricochets once off wall; 19 damage on contact. | 1.1 s exhaust sputters and engine stalls. | 6.0 s |
| Soot Blast | 0.55 s: side vents open and triangular cone appears | Point-blank rear exhaust burst for 10 damage. | 0.55 s soot settles. | 4.0 s |
| Ignition Skip | 0.40 s: furnace flashes orange | Short fixed-angle hop 1.5 u; no contact damage. | 0.30 s stabilizers reset. | 3.5 s |

**Elite — Twin-Combustor Torpedo:** Two rear furnace bells and bright orange exhaust shutters; gains a second short final thrust after ricochet, with new red floor lane. Elite HP 150.

**Death animation:** Rear furnace cools unevenly, wheel runners shear, exhaust bell falls off and chassis skids until it stops.

---

### Condensate Mortar — Projectile

**Size:** Medium (1.2 × 1.1 × 1.8 u)  
**Health:** 75 HP  
**Speed:** 1.5 u/s  
**Danger:** Tier 3/5

**Visual graybox:** Copper samovar tank mounted on four insulated cuboid legs, curved swan-neck spout, pressure cap on top and a visible condensation coil.

**Animation pivots / construction:** Spout elevation and swivel, lid lift, pressure cap rotation, droplet particles tracking projectile path.

**AI behavior:** Holds long range and attacks with parabolic projectiles. No puddle stacks damage with a second puddle.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Scalding Lob | 0.80 s: water beads along spout; target circle locks | Lobs a globule into a marked 1.5 u disk, 12 splash damage; leaves 1 s steam puddle. | 0.65 s pressure cap hisses. | 4.5 s |
| Twin Drip | 0.55 s: spout points twice, two landing circles appear | Two weaker lobs for 7 damage each in successive marked locations. | 0.55 s nozzle drains. | 5.0 s |
| Safety Valve Jet | 0.65 s: top cap lifts, 90° nearby cone glows | Close steam fan for 9 damage. | 0.60 s cap settles. | 4.0 s |

**Elite — Double-Spout Samovar:** Two asymmetric curved spouts and larger condensation collar; alternates two different lob arcs with separate landing warnings. Elite HP 113.

**Death animation:** Pressure cap twists loose, hot reservoir leaks harmless vapor, four support legs collapse one after another.

---

### Soot Midges — Swarm

**Size:** Tiny (Pack ~1.2 × 1.2 × 0.8 u; 5 visual midges)  
**Health:** 14 HP  
**Speed:** 4.1 u/s  
**Danger:** Tier 3/5

**Visual graybox:** Dense ash insect cloud formed from five black bead-like bodies with tiny copper wings and prominent pinprick orange eyes. Cloud has one collective hitbox rather than five invisible hits.

**Animation pivots / construction:** Each midge wing pivots and trails particulate smoke; whole flock compresses to a thin vertical line.

**AI behavior:** Slow circling between aggressive linear dives. Damage is capped by single flock hitbox.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Needle Dive | 0.70 s: flock collapses into a black vertical needle with orange eyes | Dashes along a 4 u lane for 12 damage using one shared hitbox. | 0.70 s cloud loses cohesion and drifts. | 4.5 s |
| Ash Burst | 0.60 s: wingbeats accelerate and ring appears beneath flock | Expands into 2 u smoke burst for 8 damage, then disperses. | 0.50 s swarm reforms. | 5.0 s |
| Flock Fold | 0.35 s: cloud dims and swirls | Swaps from loose formation to narrow travel form; no damage. | 0.30 s reformation. | 3.5 s |

**Elite — Soot Lance:** Longer spear-cloud with brighter eyes, performs two clearly warned short dives from orthogonal directions. Elite HP 100 group.

**Death animation:** Cloud collapses inward as eye sparks die; each little wing loses lift, leaving falling ash that evaporates without dealing damage.

---

### Spark Wisps — Swarm

**Size:** Small (0.25 u diameter each; 4–5 motes per group)  
**Health:** 18 HP  
**Speed:** 4.0 u/s  
**Danger:** Tier 3/5

**Visual graybox:** Tiny bright flame motes each ringed by a brass ignition coil; thin orange lines dynamically link nearby motes into a zigzag chain.

**Animation pivots / construction:** Mote coils orbit, link ribbons stretch, each ignition pulse alternates brightness; motes have separate shadows.

**AI behavior:** Wanders in four- or five-mote chains. Keeping motes separated stops chain attacks; all damage is cooldown-capped.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Linked Ignition | 0.80 s: visible orange threads link three nearby motes | One chained ignition jumps between linked members; 8 damage per touched unit, max 16 per sequence. | 0.70 s threads burn out after one pass. | 5.0 s |
| Spark Flick | 0.40 s: one mote brightens white | Small straight bolt for 6 damage. | 0.35 s mote dims briefly. | 2.8 s |
| Chain Rearrange | 0.50 s: threads disconnect and reform | Motes relocate within 2 u without damaging. | 0.35 s new formation settles. | 4.0 s |

**Elite — Flash Constellation:** Six motes including a larger central conductor. Linked Ignition can extend one more hop; conductor flashes a clear second warning. Elite total HP 126.

**Death animation:** Connections snap one at a time, coils fall as tiny brass rings, flames wink out in sequence.

---

### Grate Mauler — Close Range

**Size:** Large (1.8 × 1.2 × 2.2 u)  
**Health:** 155 HP  
**Speed:** 1.9 u/s  
**Danger:** Tier 4/5

**Visual graybox:** Massive square furnace grate torso on piston legs, two huge burning grate fists and a wide barred face with orange light behind slats.

**Animation pivots / construction:** Fist pistons extend separately; vent slats brighten and open; legs brace widely.

**AI behavior:** Heavy plodding pursuit. Cannot rotate mid-double-punch; flanks are its weakness.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Furnace Double Punch | 0.75 s: both elbows spread and slats turn orange | Two slow forward punches 0.4 s apart, 15 damage each, each creating a 0.7 u hot circle. | 0.95 s fists cool, retract through grate. | 5.0 s |
| Hot Shoulder | 0.65 s: torso leans and one side heats | Short 2 u shoulder check for 13 damage. | 0.65 s vents flare downward. | 4.5 s |
| Grate Flare | 0.90 s: slats spread and a narrow cone lights | Front-facing burst of embers for 12 damage. | 0.75 s grate dims. | 6.0 s |

**Elite — White-Hot Mauler:** White heated grates and twin piston braces; adds an independently telegraphed third stomp only after two punches. Elite HP 233.

**Death animation:** Fists stop mid-motion, grate light dies from white to ember, front bars separate and heavy chest falls onto knees.

---

### Ash Shunter — Close Range

**Size:** Medium (0.8 × 0.8 × 2.2 u; polearm reach 3.0 u)  
**Health:** 95 HP  
**Speed:** 3.0 u/s  
**Danger:** Tier 3/5

**Visual graybox:** Slender soot-black service knight with cylindrical pressure joints, long valve-wheel polearm, chimney-collar shoulder plates and tiny lit visor.

**Animation pivots / construction:** Separate polearm shaft and turning valve-wheel tip; hip-backstep pivot and two-handed sweep grips.

**AI behavior:** Engages at 2.5–3 u; alternates a three-stage thrust-backstep-sweep with independent short pokes when cornered.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Valve Thrust | 0.45 s: polearm spins once then aligns with a thin lane | Long 3 u thrust for 12 damage. | 0.25 s front foot returns. | Combo |
| Backward Step | 0.20 s: foot pistons retract | Retreats 1.5 u, no damage; leaves a visible safe interval. | 0.25 s crouched settle. | Combo |
| Wide Pole Sweep | 0.70 s: weapon comes to side, 160° arc appears | Large sweep for 16 damage after backstep. | 0.85 s valve-wheel tip catches briefly in floor. | 4.0 s/string |

**Elite — Cinder Shunter:** Dual spinning valve rings on polehead; wide sweep ends in a short ember burst warned by orange wheel glow. Elite HP 143.

**Death animation:** Polearm digs into floor and stays; its neck valve vents, torso sinks and the service knight topples without creating a flame hazard.

---

### Heat Mirage — Disruptor

**Size:** Medium (0.7 × 0.65 × 2.0 u)  
**Health:** 70 HP  
**Speed:** 3.2 u/s  
**Danger:** Tier 4/5

**Visual graybox:** Very thin glowing radiator walker with two broad horizontal refractive heat fins, a small metal core and long straight support legs.

**Animation pivots / construction:** Fin unfold mechanism produces mirage distortion; real shadow always present beneath body.

**AI behavior:** Offsets confusion with consistent cues: only real model casts solid shadow, attack decals never distort, decoys cannot collide.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| False Advance | 0.70 s: two refracted false silhouettes appear with no solid shadows | Harmless phantom lunges forward, then real body stabs along clearly marked line for 13 damage. | 0.70 s cooling fins open wide to clear illusion. | 5.0 s |
| Heat Ripple | 0.85 s: ring shimmers but hazard border stays crisp | Wave reduces player visibility only inside limited local haze for 2 s; no direct damage, clear floor markers retained. | 0.65 s fins retract. | 6.5 s |
| Radiator Jab | 0.45 s: real core glows brighter than decoys | Short metal stab for 8 damage. | 0.40 s real core flickers. | 3.5 s |

**Elite — Triple-Mirage Radiator:** Three false silhouettes and a large red core in the real body. Only one copy produces a normal shadow; final attack retains 0.7 s telegraph. Elite HP 105.

**Death animation:** Heat fins fan fully out then shatter into harmless sparks; fake figures dissolve first; radiator core hits floor with metallic ping.

---

### Forge Bellows — Buffer

**Size:** Medium (1.3 × 1.0 × 1.5 u)  
**Health:** 85 HP  
**Speed:** 2.0 u/s  
**Danger:** Tier 3/5

**Visual graybox:** Four-legged mobile forge bellows with accordion leather chest, metal compression frame, fan-shaped rear housing and orange vented exhaust.

**Animation pivots / construction:** Accordion folds independently; all four legs have simple hinges; glowing heat tethers attach to buffed allies.

**AI behavior:** Tries to remain behind melee allies; active buff link is visibly breakable by killing or distancing the bellows.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Weapon Reheat | 0.95 s: bellows pull wide and target weapon turns amber | Heats one allied melee weapon for 4 s: +25% attack damage and a purely visual ember trail. | 0.75 s bellows fold flat and relight slowly. | 7.0 s |
| Ember Puff | 0.60 s: back nozzle swells, short cone appears | Blows embers 2 u for 9 damage. | 0.50 s exhaust rattles. | 4.0 s |
| Draft Escape | 0.35 s: leg pistons flare | Backsteps 1.8 u with no damage. | 0.35 s bellows rebalancing. | 4.2 s |

**Elite — Master Bellows:** Twin accordion chambers and two visible orange hoses. Can heat two allies at once, no stacking bonuses. Elite HP 128.

**Death animation:** Leather folds burst, rear fan wobbles free, orange exhaust fades to black and all four legs flatten.

---

## Toxin Refinery

### Corrosion Eel — Charging

**Size:** Medium (2.4 × 0.55 × 0.65 u body length)  
**Health:** 95 HP  
**Speed:** 3.6 u/s  
**Danger:** Tier 3/5

**Visual graybox:** Serpentine line of 7 linked corroded pipe segments, syringe-shaped iron head, thin elbow joint fins and luminous acid flowing along transparent slots.

**Animation pivots / construction:** Seven rotating pipe hinges; head syringe plunger telescopes; head-to-tail glow travels during startup.

**AI behavior:** Occupies narrow lanes and turns only at indicated bend. Never spontaneously tracks the player after charge begins.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Pivot Rush | 0.75 s: pipe segments stiffen and luminous fluid runs toward head; two linked floor lanes display one pivot | Head-first rush 6 u with exactly one predetermined bend, 17 damage. | 0.85 s corroded joints seize; tail is exposed. | 5.5 s |
| Syringe Jab | 0.45 s: head piston compresses; 2.5 u line glows | Extends head syringe forward for 11 damage. | 0.45 s plunger retracts. | 3.2 s |
| Acid Flick | 0.60 s: rear pipe twitches and droplets collect | Whips tail to scatter two small 1 s acid drops, 3 damage/s each, nonstacking. | 0.50 s body straightens. | 5.0 s |

**Elite — Split-Pivot Eel:** Nine pipe segments and two clearly painted pivot nodes. Can make two sharp bends in a rush, each marked during windup. Elite HP 143.

**Death animation:** Fluid stops circulating; head plunger droops, hinges freeze sequentially from head to tail, body spills into a loose pile of pipes.

---

### Rust Lice — Swarm

**Size:** Tiny (0.3 × 0.2 × 0.22 u each; pack 5–7)  
**Health:** 13 HP  
**Speed:** 3.8 u/s  
**Danger:** Tier 2/5

**Visual graybox:** Tiny rust-orange mechanical arthropods with spiky scrap-shell backs, four angled legs and clawed hook mandibles.

**Animation pivots / construction:** Claws latch, individual legs kick, and shell flakes shed small harmless particles.

**AI behavior:** Group attacks are staggered and at most one louse can cling at once; a sweep or dodge dislodges attachments without ongoing lockout.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Clinging Leap | 0.50 s: rust flakes shake off and claws brace against floor | Leaps up to 2.2 u and attaches to player; 3 damage on hit then 2 damage/s for at most 2 s. | 0.50 s after being shaken off, lands upside down. | 4.2 s/unit |
| Mandible Nibble | 0.30 s: front pincers chatter | Short bite for 4 damage when near player. | 0.30 s shell bobs. | 2.2 s/unit |
| Scuttle Scatter | 0.40 s: all legs extend visibly | Rapidly breaks formation; no direct damage. | 0.35 s direction correction. | 5.0 s/pack |

**Elite — Oxide Brood:** One larger plated louse leader with visible ocher crest; leader directs a synchronized two-unit leap, still respects single-attachment cap. Elite pack HP increased 40%.

**Death animation:** Carapace crumbles, legs curl, sparks pop from the mandibles and each louse rolls onto its back before fading.

---

### Etch Claw — Close Range

**Size:** Medium (1.2 × 0.8 × 1.75 u; claw span 2.0 u)  
**Health:** 105 HP  
**Speed:** 3.1 u/s  
**Danger:** Tier 3/5

**Visual graybox:** Lean six-limbed etching frame with two large acid-filled claw tips, four smaller stabilizing legs, and chest-mounted wash vat connected by narrow tubing.

**Animation pivots / construction:** Twin front claws have yaw/roll pivots; inner acid cylinders extend; chest rinse valves open and close.

**AI behavior:** Pursues at mid-close range, uses lateral step to find V-angle. Short-lived corrosion only where tips touch the floor, not a giant poison puddle.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Cross-Etch | 0.55 s: both claws spread and narrow V lights on floor | Two quick crossing slashes, 10 then 11 damage; 1 s corrosive patch only at two impact endpoints. | 0.80 s claw tips immerse in chest vat and rinse. | 4.5 s |
| Acid Needle | 0.50 s: one claw tip extends like a lance | Short 2.4 u stab for 9 damage. | 0.50 s blade pumps back. | 3.5 s |
| Etching Step | 0.35 s: rear legs bend laterally | Quickly sidesteps 1.5 u; no damage. | 0.35 s front claws rebalance. | 4.0 s |

**Elite — Precision Etcher:** Three acid channels per claw and red rinse tank. Cross-Etch adds a third narrowly telegraphed finishing puncture after wash delay. Elite HP 158.

**Death animation:** Acid lines reverse into wash vat, twin claws lock open and then detach; four walking legs fold in sequence.

---

### Leech Harvester — Grappler

**Size:** Medium (0.9 × 0.8 × 1.8 u; proboscis reach 4.5 u)  
**Health:** 95 HP  
**Speed:** 2.5 u/s  
**Danger:** Tier 4/5

**Visual graybox:** Slim siphon harvesting robot with four long flexible segmented proboscises, an open transparent belly pump, and short angled metal legs.

**Animation pivots / construction:** Four independent articulated siphon tips; visible pumping diaphragm; capture tether is a physical line.

**AI behavior:** Seeks isolated targets 3–5 u away; a successful siphon never becomes indefinite immobilization. Belly pump is an exposed punish point.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Siphon Hook | 0.70 s: two proboscises widen and a needle-thin 4.5 u lane appears | Hooks target for 5 contact damage then slowly reels up to 1.8 u. | 0.60 s hook retracts on miss. | 5.5 s |
| Health Siphon | 0.30 s: on successful hook belly pump flashes | Drains 3 HP/s for maximum 2 s; restored enemy HP capped at 6. Breakable by dodge or strike. | 0.75 s pump overfills and sputters on failed hold. | On hook |
| Proboscis Jab | 0.45 s: one tube straightens | Short puncture for 10 damage. | 0.50 s tube recoils. | 3.5 s |

**Elite — Quad-Harvester:** Two extra transparent pump vessels and four separately aiming tubes. Hook has wider warning angle but siphon duration stays capped at 2 s. Elite HP 143.

**Death animation:** Belly pump overfills, transparent reservoir cracks, fluid pressure drops and four tubes curl inward as unit folds.

---

### Vapor Walker — Teleport

**Size:** Medium (0.75 × 0.6 × 2.0 u)  
**Health:** 75 HP  
**Speed:** 3.0 u/s  
**Danger:** Tier 4/5

**Visual graybox:** Hollow chemical-protection suit silhouette with a transparent glass dome mask, visible inner framework and translucent flowing vapor inside sleeves. Heavy boots anchor materialization.

**Animation pivots / construction:** Separate vapor layer and suit panels; mask iris; vent spawn markers projected onto floor; humanlike walking joints.

**AI behavior:** Never appears without a floor marker. Real materialized suit casts a shadow; vent transit does not permit attacks.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Vent Transit | 0.70 s: shell dissolves into colored vapor as TWO floor vents light | Travels between marked vent mouths; hidden during travel, cannot damage player during transit. | 0.45 s suit re-forms at destination, leaving condensate droplets. | 5.5 s |
| Poison Jab | 0.50 s AFTER arrival: syringe baton points at player, cone appears | Short stab for 12 damage and 2 damage/s for 2 s; damage does not stack. | 0.60 s sleeve leaks visible droplets. | 4.0 s |
| Mist Fan | 0.80 s: mask vents flare and 90° arc appears | Creates 1.5 s narrow vapor fan dealing 5 damage/s inside. | 0.60 s body re-condenses. | 6.0 s |

**Elite — Double-Vent Walker:** Two extra gas cylinders; cycles across three marked vents but reveals the final destination before its jab. Elite HP 113.

**Death animation:** Suit loses pressure, glass visor cracks, colored vapor escapes harmlessly, empty fabric shell crumples around frame.

---

### Contamination Siren — Disruptor

**Size:** Medium (0.95 × 0.95 × 2.3 u)  
**Health:** 80 HP  
**Speed:** 1.6 u/s  
**Danger:** Tier 3/5

**Visual graybox:** Tall hazard-alarm pillar with concentric black-and-yellow painted warning rings, top rotating beacon, circular speaker diaphragm and heavy bolted base.

**Animation pivots / construction:** Top beacon rotates; concentric speaker rings expand; base stabilizers anchor during wave.

**AI behavior:** Stationary for most attacks; wave never removes player input or obscures other enemy tells. Entire ring has a deliberate escape gap.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Weakening Siren | 0.90 s: beacon flashes; one warning ring propagates out with a visible gap | A 4.5 u wave applies -25% player attack damage for 3 s ONLY if it connects. | 0.75 s beacon dims for chemistry reset. | 7.0 s |
| Corrosive Ping | 0.60 s: speaker center compresses; short line lights | Straight ultrasonic dart for 8 damage. | 0.50 s loudspeaker membrane resets. | 4.2 s |
| Alarm Reposition | 0.50 s: footing bolts retract | Slides 1.5 u to safer spot, no damage. | 0.40 s bolts anchor again. | 5.0 s |

**Elite — Double-Alarm Siren:** Two offset rotating beacons, alternating ring gaps. Two independently warned weakening waves; debuff never stacks. Elite HP 120.

**Death animation:** Beacon cracks and dims, loudspeaker cone caves inward, warning rings detach one after another and base tips sideways.

---

### Corrosion Shellback — Shield

**Size:** Large (2.0 × 1.5 × 1.3 u)  
**Health:** 170 HP  
**Speed:** 1.8 u/s  
**Danger:** Tier 4/5

**Visual graybox:** Huge broad armored crustacean-style machine with overlapping etched shell plates, thick short angled legs and a narrow acid-dripping front lip. Back is rounded rather than a flat plate.

**Animation pivots / construction:** Shell plates slide shut or lift individually; short legs scuttle; rear breathing hinge exposed when venting.

**AI behavior:** Presses toward the player with a guarded front but slow turning speed. Rear remains fully vulnerable; cannot guard while exposing vents.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Shell March | 0.35 s: overlapping front plates lock and amber lights turn solid | Advances 2.5 u protected from 85% frontal damage in 150° arc; touch shove for 7 damage. | 0.75 s plates must lift to breathe, exposing rear. | 4.0 s |
| Acid Lip | 0.75 s: front rim drips and forward semicircle is marked | Splashes 2 u 140° acid fan for 12 damage. | 0.70 s shell edges drip harmlessly. | 5.0 s |
| Side Scuttle | 0.40 s: side legs flare and one edge lights | Side shove 1.5 u for 9 damage. | 0.50 s legs resettle. | 3.8 s |

**Elite — Iron-Oxide Shellback:** Extra overlapping copper-etched plating; shell march now defends 170° front but vents for 1.0 s afterward. Elite HP 255.

**Death animation:** Front plates peel apart, leg joints seize one side at a time, shell settles with a hollow thud, corrosion dust puffs harmlessly.

---

### Vat Lid Warden — Shield

**Size:** Large (1.4 × 1.1 × 2.1 u; circular lid 1.6 u across)  
**Health:** 145 HP  
**Speed:** 2.0 u/s  
**Danger:** Tier 4/5

**Visual graybox:** Tall refinery biped with a gigantic circular tank lid held to one side, rusted arm bracing it, narrow respirator face and visible valve on lid center.

**Animation pivots / construction:** Circular lid rotates on arm hinge; elbow and torso pivot for shoves; expose far-side weapon arm behind shield.

**AI behavior:** Moves with shield angled toward the player, slows turning while guarding. Favors Rotary Lid Shove if flanked, opening its opposite side.

**Full moveset**

| Move | Windup / tell | Active effect | Recovery / counterplay | Cooldown |
|---|---|---|---|---|
| Lid Guard | 0.30 s: tank lid faces player and rim becomes amber | Blocks 85% frontal damage over 145° until next move or maximum 2 s. | 0.45 s shield rotates aside exposing opposite arm. | 3.6 s |
| Rotary Lid Shove | 0.75 s: lid spins and broad 120° arc glows | Wide shield shove for 16 damage and small knockback. | 0.85 s rotating lid exposes unguarded arm. | 5.0 s |
| Valve Burst | 0.65 s: lid valve compresses; short cone appears | Chemical vent blast for 11 damage at 2 u. | 0.60 s valve droops to stop. | 4.5 s |

**Elite — Cyclone Warden:** Two concentric rotating lid rims and red valve hub. Rotary Lid Shove sweeps an extra 45° segment after brief pause, marked separately. Elite HP 218.

**Death animation:** Shield rim spins too fast and dislodges; lid drops and rolls in a slow harmless circle as guard slumps and visor darkens.

---

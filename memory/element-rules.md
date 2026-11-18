# Element Rules

## Fact or rule

### Damage Colors
- **Fire / Burn / Explosive:** Red (`Color("ff3b30")`)
- **Earth:** Brown (`Color("a65e2e")`)
- **Lightning / Electricity:** Yellow (`Color("ffe600")`)
- **Water / Rust:** Blue (`Color("3399ff")`)
- **Wind:** Green (`Color("38d978")`)
- **Ice / Frost:** Frozen Blue (`Color("a8f0ff")`)
- **Regular / Physical / Default:** Grey (`Color("cccccc")`)
- **Separate Damage Numbers:** If an attack deals regular and elemental damage, both appear separately using their respective colors.
- **Type Retention:** Elemental damage retains its original type. If a normal attack activates both Fire and Lightning, its Burn damage remains red, and its Lightning damage remains yellow. Neither replaces the other.

### Elemental Status Reactions & Interactions
- **Fire & Ice Cancellation (Vaporize / Melt -> Wet):**
  - Applying Burn on top of Frost cancels both and inflicts the Wet status.
  - Applying Frost to a burning enemy also cancels both statuses and applies Wet, making the reaction work symmetrically in either direction.
  - Any Fire/Frost reaction creates Wet, regardless of application order. This gives multi-element builds a predictable way to produce Wet and exploit its Lightning and Ice bonuses.
  - All applicable elemental effects activate, except when reactions cancel them. An attack that applies both Fire and Ice resolves the interaction and applies Wet instead of leaving both Burn and Frost active.
  - When Burn or Frost is canceled by another element, its corresponding buildup meter resets to zero.
- **Wet Status Vulnerabilities & Resistances:**
  - **Vulnerability Bonus:** Wet multiplies Ice and Lightning damage by 1.5 (+50%). It does not increase the regular attack component.
  - **Burn Immunity Under Wet:** Enemies cannot be burned under Wet status.
  - **Extinguishing Burn:** Applying Wet to a burning enemy extinguishes Burn and resets its Burn meter to zero.
  - **Accelerated Freezing:** Frost meter attack gain is doubled under Wet status.
  - **Mud Formation:** Earth attacks against Wet enemies apply Mud, slowing their movement by 20% for 2 seconds.
- **Burn & Frost Mutual Exclusivity:**
  - Enemies cannot be under Frost or Frozen status while under Burn.
- **Wind Interactions:**
  - **Fanning the Flames:** Wind's 50% Burn damage bonus does not stack. Repeated Wind attacks refresh it.
  - **Wind Knockback Spread:** Knocking back a Burning enemy spreads Wet to the first enemy it collides with if the source of the knockback was Wind. Knocking back a Wet enemy also spreads Wet to the first enemy it collides with if the source of the knockback was Wind.
- **Secondary Effects & Recursion Control:**
  - Secondary effects cannot trigger themselves. Lightning splash damage cannot create another splash. Wind Bomb cannot endlessly create more Wind Bombs.
- **Lightning Reactions:**
  - **Burn Acceleration:** Lightning hitting a burning enemy triggers an immediate additional Burn tick, without reducing Burn duration.
  - **Chain Targeting:** A Lightning chain cannot hit the same enemy twice during the same chain unless a card explicitly permits it. Chains prioritize the closest enemy that has not already been struck.
- **Frozen Enemy Resistances:**
  - **Brittle Resistance:** Earth and Burn damage deal 50% damage (0.5x damage) to frozen enemies.
- **Duration Resetting & Simultaneous Statuses:**
  - **Duration Refresh:** Reapplying Burn, Frost, or Wet resets its duration instead of adding time.
  - **Multiple Statuses:** Enemies can have multiple elemental statuses simultaneously unless a specific reaction cancels them.
  - **Hit Frequency Limiting:** Elemental reactions occur once per qualifying hit. This prevents rapid attacks from triggering unlimited reactions from the same damage event.
- **Buildup vs Direct Damage:**
  - Elemental status buildup and direct elemental damage are separate. This keeps different elements useful even when an enemy resists or is immune to a particular status.

### Elemental Meters & Explosions
- **Qualifying Buildup Applications:** Burn and Freeze meters only increase from qualifying elemental applications. DoT ticks and secondary chain damage do not automatically increase buildup.
- **Multi-Hit Controlled Buildup:** Multi-hit abilities should have controlled buildup. Each enemy receives a maximum of one meter increase per application or defined attack interval.
- **Burn Explosions:** Burn meter can only increase while Burn is active. When an explosion triggers, the meter resets to zero, and excess buildup from the triggering hit is discarded. The enemy can begin accumulating buildup again on the next hit.
- **Freeze Meter:** Freeze Meter cannot rise above 100. When freezing occurs, the meter resets to zero. During the Freeze duration, additional Frost hits deal their normal elemental damage but do not build another Freeze.
- **Lightning Chains:** A Lightning chain cannot hit the same enemy twice during the same chain unless a card explicitly permits it. Chains prioritize the closest enemy that has not already been struck.

### Boss & Enemy Rules
- **Boss Crowd Control Diminishing Returns:** Bosses cannot be permanently stunned, frozen, or trapped. Repeated hard crowd control grants temporary resistance.
- **Boss Knockback Halving:** Knockback effects are halved against bosses.
- **Explicit Resistances:** Enemies are not automatically resistant to their own element. Resistances must be explicitly defined per enemy.

### Terrain, Puddles & Construct Interactions
- **Water Puddle Terrain Interaction:** Water interacts with terrain. Puddles can be electrified, frozen, or evaporated, allowing players to create combinations through positioning:
  - **Freezing:** Ice freezes a puddle, turning it into a temporary slippery surface for grounded enemies.
  - **Evaporation:** Fire attacks evaporate a water puddle, creating a short-lived steam cloud that obscures enemy vision without applying Burn.
  - **Electrification:** Lightning hitting a water puddle electrifies it briefly, damaging grounded enemies inside it.
- **Earth Construct Interactions:**
  - **Heated Constructs:** Fire attacks can heat a rock construct for 5 seconds. Enemies colliding with it receive Burn.
  - **Frozen Constructs:** Ice attacks can freeze Earth constructs, causing enemies that touch them to accumulate Frost meter.
  - **Separate Construct Capacity Limits:** Orbiting rocks and stationary constructs have separate capacity limits.
  - **Rock Fragment Trigger Inheritance Prevention:** Rock fragments do not inherit Rock Shot triggers. This prevents Shotgun fragments from continuously splitting or returning to the player.

### Combat Build & Player Safety Rules
- **Player Damage Immunity:** Elemental attacks and hazards created by the player cannot damage the player unless a specific mechanic states otherwise.
- **Multi-Core Attack Damage Separation:** Three-core builds should not automatically deal triple regular attack damage. Additional cores provide extra elemental effects and possible synergies, but regular attack damage remains separate.
- **Armor Retaliation Cooldown:** Armor retaliation has a 0.5-second cooldown to prevent enemies with rapid attacks from triggering excessive damage.
- **Elemental Armor Projectile Restriction:** Elemental Armor effects do not work on projectiles. Retaliation damage, reactive procs, and armor defense mechanisms do not activate against or apply to projectile damage.
- **Burn Tick Timer Preservation:** Reapplying Burn refreshes its expiration timer but does not reset the tick timer. Otherwise, fast attacks could prevent Burn damage from ever ticking.

### Elemental Cards & Drafting System
When getting an element as a reward, the player is offered exactly **3 choices** of elemental cards:
- **Rarity Distribution:** Commons appear more often than Rares, Rares more often than Epics, and Epics more often than Legendaries.
- **Prerequisites:** Cards that have prerequisites cannot show up if the player does not have the prerequisite.

#### 1. Lightning Cards (Focus: Burst damage, speed, chaining, multiple enemies)
- **Base core effect:** Lightning has a 35% chance to spread to the closest enemy within range. Secondary lightning strikes deal 50% of the original Lightning damage.
- **Common:**
  - *Lightning Attack:* 8 / 8 / 12 per combo hit
  - *Lightning Special:* 20 to each enemy hit
  - *Lightning Armor:* 16 to the enemy that attacks you. Getting hit while charging energy does lightning damage
  - *Lightning Dash:* 18 to each enemy dashed through. Dashing through an enemy causes lightning to strike down on them
- **Rare:**
  - *Lightning Slam:* Ground Slam will electrify the ground, and after a second, a massive delayed lightning strike deals 40 damage to enemies inside the Ground Slam AoE.
  - *Electric Energy:* Energy charging speed increased by 200%. Cannot move while charging.
  - *Stronger Lightning:* Lightning can spread to two additional enemies, dealing 50% damage to each.
- **Epic:**
  - *Raging Tempest:* Every 30 energy gained while charging triggers lightning strikes dealing 18 damage each to up to three nearby enemies.
  - *Chain Lightning:* Lightning can chain through up to four additional enemies. Each chain hit deals 50% of the original strike.
  - *Light Speed:* Dash becomes an instant teleport. Lightning Dash still affects enemies between the starting and ending locations.
- **Legendary:**
  - *Lightning Overload:* Lightning strikes deal 60% of their damage to all other enemies within a small radius. This replaces ordinary lightning spreading.

#### 2. Fire Cards (Focus: Damage over time, rapid attacks, explosive damage)
- **Base core effect:** Burn damage: 6 damage per second. Burn duration: 3 seconds. Total damage uninterrupted: 18. Burn meter gain: 10 per qualifying hit once Explosion is unlocked. Wind increases Burn damage by 50% (9 damage per second).
- **Common:**
  - *Fire Attack:* Applies Burn: 6 per second
  - *Fire Special:* Applies Burn: 6 per second
  - *Fire Armor:* Applies Burn: 6 per second to the attacker. Being attacked while charging energy applies Burn to enemies
  - *Fire Dash:* Applies Burn: 6 per second
- **Rare:**
  - *Fire Trail:* Leaves a trail lasting 3 seconds. Applies and refreshes Burn on grounded enemies.
  - *Fire Spread:* Killing a burning enemy applies a fresh Burn to the closest enemy.
  - *Fire Slam:* Ground Slam produces a ring of fire that expands outwards and burns enemies it passes through. Expanding ring deals 18 Fire damage and applies Burn.
- **Epic:**
  - *Explosion:* Reaching 100 Burn meter causes 100 explosive damage. Resets the meter to zero.
  - *Scorching End:* Enemies killed by explosions leave burning ground for 3 seconds. Deals 8 Fire damage per second to grounded enemies inside it.
  - *Lasting Fire:* Increases Burn duration to 5 seconds, for 30 total Burn damage.
- **Legendary:**
  - *Explosive Fury:* Explosions deal 60 explosive damage to surrounding enemies. Enemies with at least 70 Burn meter immediately trigger their own 100-damage explosion. (Prerequisite: Explosion)

#### 3. Water Cards (Focus: Weakening enemies, rust damage, armor reduction, elemental synergy)
- **Base core effect:** Wet reduces enemy damage by 20%. Wet duration: 3 seconds. Wet does not cause damage until Rust is unlocked. Lightning and Ice deal 50% more elemental damage against Wet enemies.
- **Common:**
  - *Water Attack:* Applies Wet for 3 seconds.
  - *Water Special:* Applies Wet to all enemies hit.
  - *Water Armor:* Applies Wet to the attacker. Being attacked while charging energy applies Wet
  - *Water Dash:* Applies Wet to enemies dashed through.
- **Rare:**
  - *Tidal Slam:* Ground Slam releases an expanding wave that deals 16 Water damage, pushes enemies away, and applies Wet.
  - *Water Damage:* Wet now reduces enemy damage by 35%
  - *Erosion:* Wet enemies take an additional 5% regular damage for each second they remain Wet, capped at 25%.
- **Epic:**
  - *Drenched:* Wet duration increased to 5 seconds.
  - *Whirlpool:* Creates a whirlpool for 3 seconds, dealing 8 Water damage per second and continuously applying Wet. Maximum base damage: 24.
  - *Rust:* Wet now deals 8 Rust damage per second. A full three-second Wet duration deals 24 damage.
- **Legendary:**
  - *Wear and Tear:* Each consecutive Rust tick increases the next tick's damage by 3, up to a maximum of 32 damage per tick. (Prerequisite: Rust)

#### 4. Wind Cards (Focus: Knockback, collision damage, movement, stuns)
- **Base core effect:** Knockback distance increased by 25%. Wall or construct collision: 16 Wind damage. Enemy-to-enemy collision: 8 Wind damage to each enemy when Pinball is unlocked. Wall collision stun: 0.5 seconds for eligible enemies.
- **Common:**
  - *Wind Attack:* 5 / 5 / 8 plus knockback
  - *Wind Special:* 14 plus knockback
  - *Wind Armor:* 10 to nearby enemies plus knockback. Being attacked while charging energy does wind damage and knockback to the attacker
  - *Wind Dash:* 8 to enemies dashed through, pulling them behind the player
- **Rare:**
  - *Pinball:* Enemy-to-enemy collisions deal 8 damage to both enemies and transfer momentum.
  - *Fleet Foot:* Dashing through an enemy increases movement speed by 25% for 2 seconds.
  - *Gust:* All knockback distances are increased by another 30%.
- **Epic:**
  - *Vortex:* Normal attacks pull enemies toward the player instead of pushing them away. Damage remains 5 / 5 / 8.
  - *Come Hither:* Enemies that collide with a wall or construct are pushed back off it, dealing 12 additional Wind damage.
- **Legendary:**
  - *Wind Bomb:* Enemy collisions create a shockwave dealing 24 Wind damage and knocking back nearby enemies.

#### 5. Ice Cards (Focus: Crowd control, slowing, freezing, trapping, execution)
- **Base core effect:** Frost slows enemy movement by 25%. Frost duration: 3 seconds. Freeze meter gain: 10 per qualifying hit once Freeze is unlocked. Freeze duration: 2 seconds. Wet enemies gain 20 Freeze meter per qualifying hit. Bosses take 80 Ice damage when their Freeze meter reaches 100 instead of freezing.
- **Common:**
  - *Ice Attack:* 5 / 5 / 8 and applies Frost
  - *Ice Special:* 14 and applies Frost
  - *Ice Armor:* 12 to the attacker and applies Frost. While charging, energy does Ice damage to attacking enemies
  - *Ice Dash:* 10 and applies Frost
- **Rare:**
  - *Ice Slam:* Ground Slam creates ice pillars around enemies caught in its area. Ice pillars deal 22 Ice damage and trap eligible enemies for 2 seconds.
  - *Frost Recharge:* Encase yourself in ice to charge energy. Protects the player from three hits while charging. Cannot move or cancel until fully charged.
  - *Snow Down:* Increases Frost movement slow from 25% to 40%.
- **Epic:**
  - *Freeze:* Freezes non-boss enemies for 2 seconds when their Freeze meter reaches 100. Bosses take 80 Ice damage instead.
  - *Everlasting Winter:* Frost duration increased to 5 seconds.
  - *Cold Spirit:* Frost reduces enemy attack speed by 25%.
- **Legendary:**
  - *Flash Freeze:* Frozen non-boss enemies below 15% maximum health immediately shatter and die. Boss Freeze burst damage increases from 80 to 160 (240 if Wet). (Prerequisite: Freeze)

#### 6. Earth Cards (Focus: Heavy damage, defense, constructs, projectile deflection)
- **Base core effect:** Max stationary constructs: 3. Max orbiting rocks: 3. Rock existence counter: 3. Construct existence counter: 5. Orbiting rock contact damage: 16. Orbiting rock launch damage: 32. Rocks hitting enemies and blocking, or deflecting projectiles decrease existence counter.
- **Common:**
  - *Earthen Attack:* 10 / 10 / 14
  - *Earthen Special:* 24 to each enemy hit
  - *Earthen Armor: Orbiting Wall:* Creates a rock every 45 energy. Rocks deal 16 damage on contact. Rocks also block projectiles.
  - *Earthen Dash: Stone Creation:* Creates a stationary construct at dash start location. Deals no initial damage.
- **Rare:**
  - *Earthen Slam:* Ground Slam releases earth spikes, dealing 28 Earth damage to grounded enemies.
  - *Earth Arsenal:* Maximum orbiting rocks increased from 3 to 5.
  - *Orbiting Fortress:* Rocks now deflect projectiles.
- **Epic:**
  - *Rock Shot:* Allows player to launch orbiting rocks at enemies, dealing 32 Earth damage per rock.
  - *Rocksplosion:* Rocks reaching zero existence explode, dealing 36 Earth damage to nearby enemies and staggering them for 0.5 seconds.
  - *Earth Bender:* Launched rocks return after hitting an enemy if they have remaining existence. Launch damage remains 32. (Prerequisite: Rock Shot)
- **Legendary:**
  - *Shotgun:* A launched rock splits into three smaller rocks after first impact. Each fragment deals 12 Earth damage to a different enemy. (Prerequisite: Rock Shot)

## Why

The user provided this complete specification of elemental rules to establish consistent, emergent combat interactions across damage numbers, statuses, meters, bosses, terrain, and multi-core builds.

## How to apply

When writing or modifying combat abilities, projectile damage, enemy statuses, terrain hazards, core powers, or UI damage numbers, follow these interaction rules and use `scripts/elemental_system.gd` as the shared reference engine.

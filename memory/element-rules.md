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

## Why

The user provided this complete specification of elemental rules to establish consistent, emergent combat interactions across damage numbers, statuses, meters, bosses, terrain, and multi-core builds.

## How to apply

When writing or modifying combat abilities, projectile damage, enemy statuses, terrain hazards, core powers, or UI damage numbers, follow these interaction rules and use `scripts/elemental_system.gd` as the shared reference engine.

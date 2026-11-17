# Flying Liberty — Adaptive Biome Soundtrack Vol. 3

Three original instrumental revisions of the earlier biome soundtrack, now orchestrated for gameplay intensity changes using **horizontal leitmotif continuity** and **vertical remixing**. No vocals, chiptune, or incidental environmental noise samples.

## What changed

The short, recognizable leitmotif rises by intervals `0, +3, +7, +10, +7, +3` (relative to the tonal center). It is transformed rather than repeated verbatim:

| Biome | Meter | BPM | Key | Sound and transformation | Length |
|---|---|---:|---|---|---:|
| Maintenance | 3/4 | 102 | D minor | High airy flute/celesta, a gentle mechanical waltz, and soft pizzicato strings | ~70.59 sec |
| Factory | 4/4 | 136 | E minor | Clipped syncopated low-trombone version of the same phrase, four-square kick/snare pulse, heavy brass | ~70.59 sec |
| Toxin Refinery | 5/4 | 90 | C# minor | Sparse oboe/vibraphone melody, uneasy semitone color, bassoon and suspended strings | 80 sec |

## Included audio in each biome folder

- `Foundation.ogg` — harmonic atmosphere and bass; always on.
- `Motif.ogg` — recognizable melodic identity; on during both exploration and combat.
- `Pulse.ogg` — lighter moving rhythm and clockwork percussion, becomes stronger in combat.
- `Combat.ogg` — brass, strings and/or striking percussion. Muted in exploration; faded in during combat.
- `Exploration_Loop.ogg` and `Combat_Loop.ogg` — two pre-bounced modes, convenient if you do not yet want vertical mixing.
- `Exploration_Preview.mp3`, `Combat_Preview.mp3`, `Dynamic_Mix_Demo.mp3` — listen to the arrangements without requiring Godot.

Every stem in a particular biome was rendered at **32,000 Hz stereo, with exactly equal sample counts**, and the MP3 files are for previews rather than seamless in-game looping. Use the **OGG files for looping**.

### Suggested exploration -> combat state change

1. Exploration plays Foundation + Motif + soft Pulse.
2. When enemies engage, blend in the Combat layer and increase the Pulse layer, without resetting or changing the chord progression.
3. Fade the new layers gradually so attacks, tempo and melody remain in sync.
4. After the room is cleared, fade them back out. Do not stop and restart the song between encounters.

The ZIP includes `Godot/AdaptiveBiomeMusic.gd` using Godot 4.x `AudioStreamSynchronized`. It begins all stems simultaneously, and crossfades their relative volume when `set_combat(true)` or `set_combat(false)` is called. See Godot's own [AudioStreamSynchronized docs](https://docs.godotengine.org/en/stable/classes/class_audiostreamsynchronized.html).

### Godot setup

Copy the `Maintenance`, `Factory`, and `Toxin_Refinery` folders, with their OGGs, into `res://Audio/Flying_Liberty_Adaptive_Biome_OST_v3/`. Place `Godot/AdaptiveBiomeMusic.gd` on a node or autoload. Use `play_biome("Factory")` when entering the factory and `set_combat(true)` when combat starts. Each biome swaps to its own composition. The GDScript integration has been authored against the documented 4.x API but has **not been executed in a Godot runtime**.

## Editing and licensing

The `MIDI` folder contains the complete track and each of the four MIDI stems for all three biomes. `compose_and_render.py` is the exact Python source used to arrange and render the supplied audio. It uses a locally installed **TimGM6mb** General MIDI SoundFont and a FluidSynth backend, which are **not bundled**. The musical note arrangements are original, but sampled instrument licensing should be checked before commercial game distribution; re-render the MIDI with a cleared SoundFont or licensed commercial instrument library if necessary.

## Note on layering and loop precision

All OGG stem lengths within each biome were verified equal after encoding. This is essential for synchronized looping. The first and last samples can still differ, and actual seamless looping should be auditioned inside Godot; verify the join before shipping. This is a sampled MIDI orchestration and not a live studio orchestra.

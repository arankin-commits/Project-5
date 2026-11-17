# Godot 4.x — Flying Liberty synchronized biome music
# Attach to a Node (autoload recommended). Place the three music folders under:
# res://Audio/Flying_Liberty_Adaptive_Biome_OST_v3/
# Public functions: play_biome("Maintenance"), set_combat(true/false)
# All 4 stems are ONE AudioStreamSynchronized stream so they start at the same sample.
extends Node

@export_dir var asset_root: String = "res://Audio/Flying_Liberty_Adaptive_Biome_OST_v3"
@export var initial_biome: String = "Maintenance"
@export_range(0.1, 5.0, 0.1) var fade_seconds: float = 1.2

const STEMS := ["Foundation", "Motif", "Pulse", "Combat"]
const BIOMES := {
    "Maintenance": {"bpm":102.0, "meter":3},
    "Factory": {"bpm":136.0, "meter":4},
    "Toxin_Refinery": {"bpm":90.0, "meter":5},
}
const MIX_EXPLORATION := [0.78, 0.90, 0.42, 0.0]
const MIX_COMBAT := [0.85, 0.88, 0.98, 0.95]

var _player: AudioStreamPlayer
var _synced: AudioStreamSynchronized
var _current_biome: String = ""
var _combat: bool = false
var _fade_tween: Tween

func _ready() -> void:
    _player = AudioStreamPlayer.new()
    _player.name = "Music"
    add_child(_player)
    _player.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
    play_biome(initial_biome)

func play_biome(biome: String) -> void:
    if not BIOMES.has(biome):
        push_error("Unknown biome: " + biome)
        return
    if _fade_tween and _fade_tween.is_running():
        _fade_tween.kill()
    _current_biome = biome
    _combat = false
    _player.stop()

    _synced = AudioStreamSynchronized.new()
    _synced.stream_count = STEMS.size()
    for i in range(STEMS.size()):
        var path := asset_root.path_join(biome).path_join(STEMS[i] + ".ogg")
        var audio: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_file(path)
        if audio == null:
            push_error("Cannot load music stem: " + path)
            return
        audio.loop = true
        audio.loop_offset = 0.0
        audio.bpm = BIOMES[biome]["bpm"]
        audio.bar_beats = BIOMES[biome]["meter"]
        _synced.set_sync_stream(i, audio)
        _synced.set_sync_stream_volume(i, _db(MIX_EXPLORATION[i]))

    _player.stream = _synced
    _player.play()

func set_combat(is_combat: bool) -> void:
    if _synced == null or _combat == is_combat:
        return
    _combat = is_combat
    if _fade_tween and _fade_tween.is_running():
        _fade_tween.kill()
    _fade_tween = create_tween().set_parallel(true)
    var mix: Array = MIX_COMBAT if _combat else MIX_EXPLORATION
    for i in range(STEMS.size()):
        var start_db := _synced.get_sync_stream_volume(i)
        var end_db := _db(mix[i])
        _fade_tween.tween_method(Callable(self, "_set_stem_volume_db").bind(i), start_db, end_db, fade_seconds)

func _set_stem_volume_db(db: float, index: int) -> void:
    if _synced != null:
        _synced.set_sync_stream_volume(index, db)

func _db(linear_gain: float) -> float:
    return linear_to_db(maxf(linear_gain, 0.001))

func current_biome() -> String:
    return _current_biome

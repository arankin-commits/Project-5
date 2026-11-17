# Flying Liberty — 16 original lobby themes with vertical remixing (Godot 4.x)
# Put Audio folder at res://Flying_Liberty_Lobby_OST_16_v1/Audio/
# Attach to Node/Autoload. Call play_track("01_Copper_Hearth") and set_story_focus(true).
# Engine-runtime integration has not been tested.
extends Node

@export_dir var audio_root: String = "res://Flying_Liberty_Lobby_OST_16_v1/Audio"
@export var starting_track: String = "01_Copper_Hearth"
@export_range(0.1, 5.0, 0.1) var layer_fade_seconds: float = 1.5

const STEMS: Array[String] = ["Foundation", "Theme", "Counterpoint", "Atmosphere"]
const QUIET_MIX: Array[float] = [0.86, 0.88, 0.35, 0.48]
const STORY_MIX: Array[float] = [0.86, 0.95, 0.83, 0.88]

var _player: AudioStreamPlayer
var _sync: AudioStreamSynchronized
var _track: String = ""
var _story: bool = false
var _fade: Tween

func _ready() -> void:
    _player = AudioStreamPlayer.new()
    _player.name = "FlyingLibertyLobbyAudio"
    add_child(_player)
    _player.bus = "Music" if AudioServer.get_bus_index("Music") != -1 else "Master"
    play_track(starting_track)

func play_track(track_slug: String) -> void:
    if track_slug == _track and _player.playing:
        return
    if _fade and _fade.is_running():
        _fade.kill()
    var sync := AudioStreamSynchronized.new()
    sync.stream_count = STEMS.size()
    for i in range(STEMS.size()):
        var path := audio_root.path_join(track_slug).path_join(STEMS[i] + ".ogg")
        var audio := AudioStreamOggVorbis.load_from_file(path)
        if audio == null:
            push_error("Missing lobby stem: " + path)
            return
        audio.loop = true
        sync.set_sync_stream(i, audio)
        sync.set_sync_stream_volume(i, linear_to_db(QUIET_MIX[i]))
    _track = track_slug
    _story = false
    _sync = sync
    _player.stop()
    _player.stream = sync
    _player.play()

func set_story_focus(enabled: bool) -> void:
    if _sync == null or _story == enabled:
        return
    _story = enabled
    if _fade and _fade.is_running():
        _fade.kill()
    _fade = create_tween().set_parallel(true)
    var mix := STORY_MIX if enabled else QUIET_MIX
    for i in range(STEMS.size()):
        var current_db := _sync.get_sync_stream_volume(i)
        var target_db := linear_to_db(mix[i])
        _fade.tween_method(Callable(self, "_set_layer_volume").bind(i), current_db, target_db, layer_fade_seconds)

func _set_layer_volume(db_value: float, index: int) -> void:
    if _sync != null:
        _sync.set_sync_stream_volume(index, db_value)

func current_track() -> String:
    return _track

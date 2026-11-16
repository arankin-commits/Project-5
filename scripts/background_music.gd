extends AudioStreamPlayer

const BOILER := preload("res://Music/Boiler area music.mp3")
const FLYING_LIBERTY := preload("res://Music/Flying Liberty music.mp3")

var active_ship_track: AudioStream = FLYING_LIBERTY
var active_ship_pitch := 1.0
var active_song_id := "copper_hearth"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	volume_db = -12.0

func play_boiler() -> void:
	pitch_scale = 1.0
	_play_track(BOILER)

func play_ship() -> void:
	pitch_scale = active_ship_pitch
	_play_track(active_ship_track)

func play_jukebox_song(stream_resource: AudioStream, pitch: float, song_id: String) -> void:
	active_ship_track = stream_resource
	active_ship_pitch = pitch
	active_song_id = song_id
	pitch_scale = pitch
	if stream_resource is AudioStreamMP3:
		stream_resource.loop = true
	stream = stream_resource
	play()

func get_active_song_id() -> String:
	return active_song_id

func is_song_playing(song_id: String) -> bool:
	return playing and active_song_id == song_id

func _play_track(track: AudioStream) -> void:
	# Keep the current song running when moving between rooms in the same area.
	if stream == track and playing:
		return
	if track is AudioStreamMP3:
		track.loop = true
	stream = track
	play()

extends AudioStreamPlayer

const BOILER := preload("res://Music/Boiler area music.mp3")
const FLYING_LIBERTY := preload("res://Music/Flying Liberty music.mp3")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	volume_db = -12.0

func play_boiler() -> void:
	_play_track(BOILER)

func play_ship() -> void:
	_play_track(FLYING_LIBERTY)

func _play_track(track: AudioStreamMP3) -> void:
	# Keep the current song running when moving between rooms in the same area.
	if stream == track and playing:
		return
	track.loop = true
	stream = track
	play()

extends Node

# Small synthesized effects keep the combat self-contained; no external audio.
var cues: Dictionary = {}
var random := RandomNumberGenerator.new()

func _ready() -> void:
	random.seed = 9471
	for spec in [["strike",150.0,0.09,0.35],["dash",500.0,0.16,0.8],["hit",90.0,0.13,0.6],["clear",680.0,0.45,0.0]]:
		var wave := AudioStreamWAV.new()
		wave.format = AudioStreamWAV.FORMAT_16_BITS
		wave.mix_rate = 22050
		var bytes := PackedByteArray()
		var count := int(22050 * float(spec[2]))
		bytes.resize(count*2)
		for i in count:
			var t := float(i)/22050.0
			var envelope := pow(1.0-float(i)/count,2.0)*minf(1.0,t*300)
			var pitch := float(spec[1])*(1.0-t*0.7)
			var sample := lerpf(sin(t*pitch*TAU),random.randf_range(-1,1),float(spec[3]))
			bytes.encode_s16(i*2,int(sample*envelope*9500))
		wave.data = bytes
		cues[spec[0]] = wave

func play_cue(id: String) -> void:
	if not cues.has(id):
		return
	var voice := AudioStreamPlayer.new()
	voice.stream = cues[id]
	voice.volume_db = -9
	add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()

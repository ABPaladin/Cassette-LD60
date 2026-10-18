extends RefCounted
## Original synthesized test cues; no downloaded audio or musical material.
static func make_cue(gunshot: bool) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var seconds := 0.55 if gunshot else 1.6
	var count := int(seconds * stream.mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var random := RandomNumberGenerator.new()
	random.seed = 1998
	for i in range(count):
		var time := float(i) / stream.mix_rate
		var sample: float
		if gunshot:
			sample = (random.randf_range(-1,1) * .6 + sin(TAU * 78.0 * time) * .25) * exp(-time * 18.0)
		else:
			sample = (sin(TAU * (83.0 * time + 8.0 * time * time)) * .16 + random.randf_range(-.04,.04)) * sin(PI * time / seconds)
		bytes.encode_s16(i * 2, int(clampf(sample, -.95, .95) * 32767.0))
	stream.data = bytes
	return stream

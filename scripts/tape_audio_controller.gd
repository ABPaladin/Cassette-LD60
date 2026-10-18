extends Node
signal position_changed(seconds: float, duration: float)
signal state_changed(state: String)
signal completed
signal timestamp_reached(id: String)
signal region_entered(id: String)
signal region_exited(id: String)
signal fragment_collected(id: String)
signal fragment_order_changed(order: Array[String])
signal playback_advanced(previous: float, current: float)
signal seeked(seconds: float)
@export var data: Resource = preload("res://resources/test_tape.tres")
var position_seconds := 0.0
var duration := 180.0
var playing := false
var pitch := 1.0
var player: AudioStreamPlayer
var active_regions: Array[String] = []
var fragments: Array[String] = []
var fragment_order: Array[String] = []
var bus_name: StringName

func _ready() -> void:
	player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = data.recording
	if player.stream == null and not data.recording_path.is_empty():
		player.stream = load(data.recording_path) as AudioStream
	duration = player.stream.get_length() if player.stream != null else data.simulated_duration
	duration = maxf(duration, 0.01)
	pitch = clampf(data.pitch, 0.25, 2.0)
	player.pitch_scale = pitch
	player.finished.connect(_audio_finished)
	bus_name = StringName("Cassette_" + str(get_instance_id()))
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, &"Cassette")
	player.bus = bus_name
	# Web Sample playback cannot run bus effects. Shipping media is pre-rendered.
	if OS.has_feature("web"): return
	var distortion := AudioEffectDistortion.new()
	distortion.drive = data.distortion
	AudioServer.add_bus_effect(index, distortion)
	AudioServer.set_bus_effect_enabled(index, 0, data.distortion > 0.0)
	var reverb := AudioEffectReverb.new()
	reverb.wet = data.reverb
	AudioServer.add_bus_effect(index, reverb)
	AudioServer.set_bus_effect_enabled(index, 1, data.reverb > 0.0)
	var lowpass := AudioEffectLowPassFilter.new()
	lowpass.cutoff_hz = 600.0
	AudioServer.add_bus_effect(index, lowpass)
	AudioServer.set_bus_effect_enabled(index, 2, false)

func _exit_tree() -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index > 0: AudioServer.remove_bus(index)

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if not playing: return
	var previous := position_seconds
	position_seconds = minf(duration, position_seconds + delta * pitch)
	playback_advanced.emit(previous, position_seconds)
	for marker in data.timestamps:
		var time := float(marker.get("time", -1.0))
		if previous < time and position_seconds >= time:
			timestamp_reached.emit(str(marker.get("id", "")))
	# A long frame may cross an entire short region; still notify both boundaries.
	for region in data.regions:
		var start := float(region.get("start", 0.0))
		var end := float(region.get("end", 0.0))
		if previous < start and position_seconds >= end and end > start:
			region_entered.emit(str(region.get("id", "")))
			region_exited.emit(str(region.get("id", "")))
	_update_regions()
	position_changed.emit(position_seconds, duration)
	if position_seconds >= duration: _finish()

func play() -> void:
	if position_seconds >= duration: seek(0.0)
	playing = true
	if player.stream != null: player.play(position_seconds)
	state_changed.emit("PLAY")

func pause() -> void:
	playing = false
	player.stop()
	state_changed.emit("PAUSE")

func toggle() -> void:
	if playing: pause()
	else: play()

func stop() -> void:
	pause()
	seek(0.0)
	state_changed.emit("STOP")

func seek(seconds: float) -> void:
	position_seconds = clampf(seconds, 0.0, duration)
	seeked.emit(position_seconds)
	if playing and player.stream != null: player.play(position_seconds)
	_update_regions()
	position_changed.emit(position_seconds, duration)
	if position_seconds >= duration and playing: _finish()

func set_pitch(value: float) -> void:
	pitch = clampf(value, 0.25, 2.0)
	player.pitch_scale = pitch

func set_muffled(value: bool) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index >= 0 and AudioServer.get_bus_effect_count(index) > 2:
		AudioServer.set_bus_effect_enabled(index, 2, value)

func _finish() -> void:
	playing = false
	player.stop()
	state_changed.emit("END")
	completed.emit()

func _audio_finished() -> void:
	if playing:
		position_seconds = duration
		position_changed.emit(position_seconds, duration)
		_finish()

func _update_regions() -> void:
	var next: Array[String] = []
	for region in data.regions:
		if position_seconds >= float(region.get("start", 0.0)) and position_seconds < float(region.get("end", 0.0)):
			var id := str(region.get("id", ""))
			next.append(id)
			if id not in active_regions: region_entered.emit(id)
	for id in active_regions:
		if id not in next: region_exited.emit(id)
	active_regions = next

func collect_fragment(id: String) -> void:
	# Investigation awards fragments only after playback, never from seek notifications.
	if not id.is_empty() and id not in fragments:
		fragments.append(id)
		fragment_collected.emit(id)

func set_fragment_order(order: Array[String]) -> bool:
	var seen: Array[String] = []
	for id in order:
		if id not in fragments or id in seen: return false
		seen.append(id)
	fragment_order = order.duplicate()
	fragment_order_changed.emit(fragment_order)
	return true

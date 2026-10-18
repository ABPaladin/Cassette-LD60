extends Node
const UI = preload("res://scripts/ui_style.gd")
var lamp: AudioStreamPlayer
var room: AudioStreamPlayer
var room_enabled := false
var ducked := false
var tension := false
var levels := {"Master":0.8,"Ambience":0.7,"Cassette":1.0,"SFX":0.8}

func _ready() -> void:
	lamp = _loop("res://assets/audio/placeholder/lamp.wav",-24.0)
	room = _loop("res://assets/audio/placeholder/room.wav",-34.0)
	for bus in levels: set_volume(bus,levels[bus])

func _loop(path: String, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = load(path).duplicate()
	player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	player.stream.loop_end = int(player.stream.get_length() * player.stream.mix_rate)
	player.bus = &"Ambience"
	player.volume_db = volume
	add_child(player)
	return player

func start_room(tape: Node) -> void:
	room_enabled = true
	tension = false
	ducked = false
	tape.state_changed.connect(func(state): ducked = state == "PLAY")
	lamp.play()
	room.play()

func stop_room() -> void:
	room_enabled = false
	lamp.stop()
	room.stop()

func _process(delta: float) -> void:
	if not room_enabled: return
	var offset := (-8.0 if ducked else 0.0) + (3.0 if tension else 0.0)
	lamp.volume_db = lerpf(lamp.volume_db,-24.0+offset,1-exp(-3*delta))
	room.volume_db = lerpf(room.volume_db,-34.0+offset,1-exp(-3*delta))

func set_volume(bus: String, value: float) -> void:
	levels[bus] = clampf(value,0,1)
	var index := AudioServer.get_bus_index(bus)
	if index >= 0:
		AudioServer.set_bus_mute(index,value <= .001)
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(value,.001)))

func make_controls(parent: Control, origin: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = origin
	panel.theme = UI.make_theme()
	parent.add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	for bus in levels:
		var row := HBoxContainer.new()
		column.add_child(row)
		var label := UI.label(row,str(bus).to_upper(),16)
		label.custom_minimum_size.x = 110
		var slider := HSlider.new()
		slider.custom_minimum_size.x = 180
		slider.max_value = 1.0
		slider.step = .01
		slider.value = levels[bus]
		slider.value_changed.connect(func(value): set_volume(bus,value))
		row.add_child(slider)
	UI.button(column,"CLOSE",panel.hide)
	panel.hide()
	return panel

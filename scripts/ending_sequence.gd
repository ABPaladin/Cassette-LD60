extends Node
signal finished
signal stage_changed(stage: String)
@export var timing_scale := 1.0
@export var noise_sound: AudioStream
@export var gunshot_sound: AudioStream
var active := false
var complete := false
var stage := "idle"
var table: Node3D
var overlay: ColorRect
var cue: AudioStreamPlayer3D
var ending_panel: Control
var sequence: Tween

func _ready() -> void:
	table = get_parent()
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0,0,0,0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(overlay)
	cue = AudioStreamPlayer3D.new()
	cue.position = Vector3(-.4, .4, 5.1)
	cue.volume_db = -13.0
	cue.unit_size = 3.0
	table.add_child(cue)
	if noise_sound == null: noise_sound = preload("res://scripts/placeholder_sfx.gd").make_cue(false)
	if gunshot_sound == null: gunshot_sound = preload("res://scripts/placeholder_sfx.gd").make_cue(true)

func begin() -> void:
	if active or complete: return
	active = true
	table.inspector.leave()
	table.inspector.enabled = false
	table.camera.cinematic = true
	table.ui.hide()
	var tape = table.get_node("Objects/Cassette/TapeAudioController")
	tape.pause()
	cue.bus = tape.bus_name
	_set_stage("noise")
	cue.stream = noise_sound
	cue.play()
	sequence = create_tween()
	sequence.tween_interval(.8 * timing_scale)
	sequence.tween_callback(func(): _set_stage("turn"))
	var pose := Transform3D(Basis.IDENTITY, Vector3(0,1.15,2.7)).looking_at(Vector3(-.4,.2,5.35))
	sequence.tween_property(table.camera, "global_transform", pose, 1.5 * timing_scale).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sequence.tween_callback(func(): _set_stage("door"))
	sequence.tween_property(table.get_node("DoorPivot"), "rotation:y", 1.2, 2.3 * timing_scale)
	sequence.tween_interval(.45 * timing_scale)
	sequence.tween_callback(_shot)
	sequence.tween_property(overlay, "color:a", 0.0, .28 * timing_scale)
	sequence.tween_callback(func():
		tape.set_muffled(true)
		cue.stream = noise_sound
		cue.volume_db = -22.0
		cue.play()
		_set_stage("fall"))
	var fallen := pose
	fallen.origin = Vector3(.4,-1.1,2.9)
	fallen.basis = pose.basis.rotated(pose.basis.z.normalized(), 1.3)
	sequence.tween_property(table.camera, "global_transform", fallen, 1.15 * timing_scale).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sequence.tween_callback(func(): overlay.color = Color(0,0,0,0); _set_stage("fade"))
	sequence.tween_property(overlay, "color:a", 1.0, 1.8 * timing_scale)
	sequence.tween_callback(_complete)

func _shot() -> void:
	_set_stage("shot")
	cue.stream = gunshot_sound
	cue.play()
	overlay.color = Color(.8, .015, .005, .85)
	# Reuse the installed PSX effects for the damaged image; no second shader.
	if table.has_node("RetroPresentation"):
		table.get_node("RetroPresentation").set_distressed(true)

func _complete() -> void:
	active = false
	complete = true
	_set_stage("end")
	ending_panel = VBoxContainer.new()
	ending_panel.position = Vector2(315,220)
	ending_panel.custom_minimum_size = Vector2(330,100)
	ending_panel.theme = preload("res://scripts/ui_style.gd").make_theme()
	overlay.add_child(ending_panel)
	var label := preload("res://scripts/ui_style.gd").label(ending_panel, "END OF RECORDING", 26)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preload("res://scripts/ui_style.gd").button(ending_panel, "RETURN TO MENU", func(): finished.emit())

func _set_stage(value: String) -> void:
	stage = value
	stage_changed.emit(stage)

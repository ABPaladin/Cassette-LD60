extends Node
## Screen-space angular gestures drive the same transport used by playback.
signal exited
@export var sensitivity := 1.0
@export var rotation_smoothing := 14.0
@export var tape_seconds_per_turn := 12.0
@export var invert_direction := false
@export var maximum_seek_speed := 30.0
@export var dead_radius_pixels := 14.0
var active := false
var holding := false
var angle_valid := false
var previous_angle := 0.0
var last_event_usec := 0
var target_rotation := 0.0
var displayed_rotation := 0.0
var tape: Node
var cassette: Node3D
var pencil: Node3D
var camera: Camera3D
var inserted_pencil: Node3D
var reel: Node3D
var saved_reel_rotation := 0.0

func begin(cassette_object: Node3D, pencil_object: Node3D, view_camera: Camera3D) -> void:
	if active: finish()
	cassette = cassette_object
	pencil = pencil_object
	camera = view_camera
	tape = cassette.get_node("TapeAudioController")
	tape.pause()
	cassette.reset_model_rotation()
	reel = cassette.get_node("Visual/ReelLeft")
	saved_reel_rotation = reel.rotation.y
	target_rotation = saved_reel_rotation
	displayed_rotation = saved_reel_rotation
	inserted_pencil = pencil.get_node("Visual").duplicate() as Node3D
	inserted_pencil.name = "InsertedPencil"
	inserted_pencil.rotation = Vector3.ZERO
	inserted_pencil.scale = Vector3.ONE * .65
	inserted_pencil.position = Vector3(0, .9, 0)
	cassette.get_node("Visual/ReelLeft/PencilSocket").add_child(inserted_pencil)
	create_tween().tween_property(inserted_pencil, "position:y", .35, .35)
	pencil.hide()
	pencil.collision_layer = 0
	active = true
	holding = false
	angle_valid = false

func center_on_screen() -> Vector2:
	return camera.unproject_position(reel.global_position)

func start_drag(cursor: Vector2) -> void:
	tape.pause()
	holding = true
	angle_valid = false
	last_event_usec = Time.get_ticks_usec()
	drag_to(cursor, 0.016)

func drag_to(cursor: Vector2, delta: float) -> void:
	if not active or not holding: return
	var radial := cursor - center_on_screen()
	if radial.length() < dead_radius_pixels:
		angle_valid = false
		return
	var angle := radial.angle()
	if angle_valid:
		var movement := wrapf(angle - previous_angle, -PI, PI)
		var seconds := -movement / TAU * tape_seconds_per_turn * sensitivity
		if invert_direction: seconds = -seconds
		seconds = clampf(seconds, -maximum_seek_speed * delta, maximum_seek_speed * delta)
		tape.seek(tape.position_seconds + seconds)
		target_rotation += movement
	previous_angle = angle
	angle_valid = true

func release() -> void:
	holding = false
	angle_valid = false

func finish() -> void:
	release()
	active = false
	if is_instance_valid(inserted_pencil): inserted_pencil.queue_free()
	inserted_pencil = null
	if is_instance_valid(pencil):
		pencil.show()
		pencil.collision_layer = 2
	exited.emit()

func _process(delta: float) -> void:
	if not active: return
	displayed_rotation = lerpf(displayed_rotation, target_rotation, 1.0 - exp(-rotation_smoothing * delta))
	reel.rotation.y = displayed_rotation

func _unhandled_input(event: InputEvent) -> void:
	if not active: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: start_drag(event.position)
		else: release()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: release()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		release()
	elif active and holding and event is InputEventMouseMotion:
		# Continue a held circle over the timeline; GUI controls must not eat its arc.
		var now := Time.get_ticks_usec()
		var delta := clampf(float(now - last_event_usec) / 1000000.0, 0.001, 0.1)
		last_event_usec = now
		drag_to(event.position, delta)
		get_viewport().set_input_as_handled()

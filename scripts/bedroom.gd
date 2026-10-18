extends Node3D
## A seated interaction sandbox. All art is saved in the scene and editable.

const LOOK_SENSITIVITY := 0.0024
const LOOK_LIMIT := Vector2(1.22, 0.90)
const REACH := 3.2

@onready var camera: Camera3D = $Seat/Camera3D
@onready var ray: RayCast3D = $Seat/Camera3D/InteractionRay
@onready var prompt: Label = $HUD/Prompt
@onready var message: Label = $HUD/Message
@onready var inventory: Label = $HUD/Inventory
@onready var reticle: Label = $HUD/Reticle
@onready var pause_panel: Control = $HUD/PausePanel
@onready var lamp: OmniLight3D = $Lighting/DeskLight
@onready var tape_audio: AudioStreamPlayer3D = $Props/CassettePlayer/TapeAudio
@onready var click_audio: AudioStreamPlayer = $ClickAudio
@onready var pet_audio: AudioStreamPlayer3D = $Props/Tamagotchi/ChirpAudio

var target: StaticBody3D
var has_cassette := false
var cassette_loaded := false
var tape_playing := false
var has_pencil := false
var sketch_stage := 0
var pet_awake := false
var lamp_on := true
var elapsed := 0.0
var message_time := 8.0
var yaw := 0.0
var pitch := -0.30
var pet_blink_time := 0.0
var controls_active := true

func _ready() -> void:
	ray.target_position = Vector3(0.0, 0.0, -REACH)
	for audio_player in [tape_audio, $RoomTone]:
		var stream := audio_player.stream as AudioStreamWAV
		if stream != null:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_set_captured(true)
	_update_inventory()
	_show_message("A quiet room. Five familiar things.", 7.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_set_captured(not controls_active)
			return
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()
			return
		if event.keycode == KEY_E and controls_active:
			_interact_target()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not controls_active:
			_set_captured(true)
		else:
			_interact_target()
	if event is InputEventMouseMotion and controls_active:
		yaw = clampf(yaw - event.relative.x * LOOK_SENSITIVITY, -LOOK_LIMIT.x, LOOK_LIMIT.x)
		pitch = clampf(pitch - event.relative.y * LOOK_SENSITIVITY, -LOOK_LIMIT.y, 0.38)
		camera.rotation = Vector3(pitch, yaw, 0.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready():
		_set_captured(false)

func _set_captured(captured: bool) -> void:
	controls_active = captured
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE
	pause_panel.visible = not captured
	# Suspend room audio and animations while the pointer is released.
	tape_audio.stream_paused = not captured
	$RoomTone.stream_paused = not captured
	if not captured:
		prompt.text = ""
		reticle.visible = false

func _physics_process(_delta: float) -> void:
	target = null
	if not controls_active:
		return
	ray.force_raycast_update()
	if ray.is_colliding():
		var hit := ray.get_collider() as StaticBody3D
		if hit != null and hit.has_meta("interaction"):
			target = hit
	reticle.visible = true
	reticle.text = "+" if target != null else "·"
	prompt.text = "[ E / LMB ]  " + _prompt_for(str(target.get_meta("interaction"))) if target != null else ""

func _process(delta: float) -> void:
	if not controls_active:
		return
	elapsed += delta
	message_time = maxf(0.0, message_time - delta)
	message.modulate.a = minf(message_time, 1.0)
	var flicker := 1.0
	if tape_playing:
		flicker = 0.94 + 0.035 * sin(elapsed * 21.0) + 0.025 * sin(elapsed * 37.0)
		$Props/CassettePlayer/ReelLeft.rotate_y(delta * 2.4)
		$Props/CassettePlayer/ReelRight.rotate_y(delta * 2.4)
	lamp.light_energy = 2.0 * flicker if lamp_on else 0.0
	pet_blink_time += delta
	$Props/Tamagotchi/Face.visible = fmod(pet_blink_time, 4.8) < 4.55

func _interact_target() -> void:
	# Refresh immediately so a fast turn and click cannot use last frame's hit.
	_physics_process(0.0)
	if target != null:
		interact(str(target.get_meta("interaction")))

func _prompt_for(id: String) -> String:
	match id:
		"cassette": return "CASSETTE  /  pick up"
		"player":
			if cassette_loaded: return "CASSETTE PLAYER  /  " + ("stop" if tape_playing else "play")
			return "CASSETTE PLAYER  /  " + ("insert tape" if has_cassette else "inspect")
		"pencil": return "PENCIL  /  pick up"
		"sketchbook": return "SKETCHBOOK  /  " + ("sketch" if has_pencil else "inspect")
		"pet": return "TAMAGOTCHI  /  " + ("feed" if pet_awake else "wake up")
		"lamp": return "DESK LAMP  /  " + ("switch off" if lamp_on else "switch on")
	return ""

func interact(id: String) -> void:
	match id:
		"cassette":
			if has_cassette or cassette_loaded: return
			has_cassette = true
			_hide_pickup($Props/Cassette)
			_show_message("Side A. No date, no name. Try the player.")
		"player":
			if not cassette_loaded:
				if not has_cassette:
					_show_message("The deck is empty. The cassette is beside it.")
				else:
					has_cassette = false
					cassette_loaded = true
					$Props/CassettePlayer/LoadedTape.visible = true
					_show_message("The tape clicks into place. Press play.")
			else:
				tape_playing = not tape_playing
				$Props/CassettePlayer/PlayIndicator.visible = tape_playing
				if tape_playing:
					tape_audio.play()
					_show_message("Only hiss... and something almost like a melody.")
				else:
					tape_audio.stop()
					_show_message("The room sounds larger without the tape.")
		"pencil":
			if has_pencil: return
			has_pencil = true
			_hide_pickup($Props/Pencil)
			_show_message("A blunt pencil. There is room on the page.")
		"sketchbook":
			if not has_pencil:
				_show_message("An unfinished page. Pick up the pencil to draw.")
			else:
				sketch_stage = (sketch_stage + 1) % 4
				for index in range(3):
					$Props/Sketchbook/Drawing.get_child(index).visible = index < sketch_stage
				_show_message(["A fresh page.", "First, the room.", "Then, the window.", "A small shape in the glass. Just a sketch."][sketch_stage])
		"pet":
			pet_awake = not pet_awake
			$Props/Tamagotchi/Heart.visible = pet_awake
			pet_audio.play()
			_show_message("A tiny heartbeat. It seems pleased." if pet_awake else "Fed and sleepy. At least one of you is comfortable.")
		"lamp":
			lamp_on = not lamp_on
			_show_message("The window is the only light now." if not lamp_on else "Warm light returns to the desk.")
		_:
			return
	click_audio.play()
	_update_inventory()

func _hide_pickup(body: StaticBody3D) -> void:
	body.visible = false
	body.collision_layer = 0
	body.collision_mask = 0

func _update_inventory() -> void:
	var items: PackedStringArray = []
	if has_cassette: items.append("CASSETTE")
	if has_pencil: items.append("PENCIL")
	inventory.text = "IN HAND  /  " + (" + ".join(items) if not items.is_empty() else "—")
	$HUD/TapeStatus.text = "SIDE A  /  " + ("PLAYING" if tape_playing else ("STOPPED" if cassette_loaded else "NO TAPE"))

func _show_message(text: String, duration: float = 4.5) -> void:
	message.text = text
	message_time = duration
	message.modulate.a = 1.0

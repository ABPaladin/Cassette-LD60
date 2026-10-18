extends SceneTree
## Run with: godot --headless --path . --script tests/prototype_smoke.gd
## Add -- --capture with a graphical renderer to save a viewport preview.

var room: Node3D
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func _aim(path: String) -> void:
	room.call("_set_captured", true)
	var body := room.get_node(path) as StaticBody3D
	var shape := body.get_node("Collision") as CollisionShape3D
	var camera := room.get_node("Seat/Camera3D") as Camera3D
	camera.look_at(shape.global_position)
	await physics_frame
	await physics_frame
	room.call("_physics_process", 0.0)
	_check(room.get("target") == body, "Raycast reaches " + path)
	_check(not (room.get_node("HUD/Prompt") as Label).text.is_empty(), "Interaction prompt for " + path)

func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	room.call("_unhandled_input", event)

func _run() -> void:
	var packed := load("res://scenes/bedroom_prototype.tscn") as PackedScene
	_check(packed != null, "Saved scene loads")
	if packed == null:
		quit(1)
		return
	room = packed.instantiate()
	root.add_child(room)
	current_scene = room
	await physics_frame
	await process_frame
	var camera := room.get_node("Seat/Camera3D") as Camera3D
	var origin := camera.global_position
	if "--capture" in OS.get_cmdline_user_args():
		room.call("_set_captured", true)
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png("res://prototype_preview.png")
		_check(error == OK, "Viewport preview saved")

	await _aim("Props/CassettePlayer")
	_key(KEY_E)
	_check(not room.get("cassette_loaded"), "Empty player cannot play")
	await _aim("Props/Cassette")
	_key(KEY_E)
	_check(room.get("has_cassette"), "Cassette picked up through E input")
	_check(not room.get_node("Props/Cassette").visible, "Picked-up cassette hidden")
	_check(room.get_node("Props/Cassette").collision_layer == 0, "Picked-up cassette cannot intercept rays")
	await _aim("Props/CassettePlayer")
	_key(KEY_E)
	_check(room.get("cassette_loaded") and not room.get("has_cassette"), "Tape moves from inventory into deck")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	room.call("_unhandled_input", click)
	_check(room.get("tape_playing") and room.get_node("Props/CassettePlayer/TapeAudio").playing, "Tape starts with audible stream")
	_check(room.get_node("Props/CassettePlayer/PlayIndicator").visible, "Play indicator enabled")
	_key(KEY_E)
	_check(not room.get("tape_playing"), "Tape stops")
	await _aim("Props/Sketchbook")
	_key(KEY_E)
	_check(room.get("sketch_stage") == 0, "Drawing requires pencil")
	await _aim("Props/Pencil")
	_key(KEY_E)
	_check(room.get("has_pencil"), "Pencil picked up")
	await _aim("Props/Sketchbook")
	for i in range(3): _key(KEY_E)
	_check(room.get("sketch_stage") == 3, "Sketch progresses through three stages")
	_check(room.get_node("Props/Sketchbook/Drawing/Stage2").visible, "Final sketch appears on paper")
	_key(KEY_E)
	_check(room.get("sketch_stage") == 0 and not room.get_node("Props/Sketchbook/Drawing/Stage0").visible, "Sketch cycles to fresh page")
	await _aim("Props/Tamagotchi")
	_key(KEY_E)
	_check(room.get("pet_awake") and room.get_node("Props/Tamagotchi/Heart").visible, "Pet interaction updates screen")
	await _aim("Props/Lamp")
	_key(KEY_E)
	room.call("_process", 0.1)
	_check(room.get_node("Lighting/DeskLight").light_energy == 0.0, "Lamp can switch off")
	_key(KEY_E)
	room.call("_process", 0.1)
	_check(room.get_node("Lighting/DeskLight").light_energy > 0.0, "Lamp can switch on")
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(10000, -10000)
	room.call("_unhandled_input", motion)
	_check(absf(camera.rotation.y) <= 1.221 and camera.rotation.x <= 0.381, "Mouse-look is clamped")
	_check(camera.global_position.is_equal_approx(origin), "Player stays seated")
	_key(KEY_ESCAPE)
	_check(not room.get("controls_active") and room.get_node("HUD/PausePanel").visible, "Escape releases pointer and shows resume overlay")
	var paused_rotation := camera.rotation
	room.call("_unhandled_input", motion)
	_check(camera.rotation == paused_rotation, "Released mouse cannot move camera")
	_key(KEY_ESCAPE)
	_check(room.get("controls_active"), "Escape resumes")
	room.call("_notification", MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(not room.get("controls_active"), "Focus loss releases mouse")
	room.call("_unhandled_input", click)
	_check(room.get("controls_active"), "Click resumes after focus loss")
	_key(KEY_R)
	await process_frame
	await process_frame
	room = current_scene
	_check(room != null and not room.get("has_pencil") and not room.get("cassette_loaded"), "Reset restores initial state")
	room.queue_free()
	await process_frame
	await process_frame
	print("PROTOTYPE CHECKS COMPLETE: ", failures, " failures")
	quit(0 if failures == 0 else 1)

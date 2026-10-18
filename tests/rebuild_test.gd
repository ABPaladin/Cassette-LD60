extends SceneTree
var failures := 0
var scene: Node
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, note: String) -> void:
	print("PASS: " if ok else "FAIL: ", note)
	if not ok: failures += 1
func _run() -> void:
	var packed := load("res://scenes/tabletop.tscn") as PackedScene
	if packed == null:
		quit(1)
		return
	scene = packed.instantiate()
	root.add_child(scene)
	await process_frame
	var camera = scene.get_node("TabletopCamera")
	camera.set_process(false)
	var original: Vector3 = camera.position
	camera.step_camera(0.1, Vector2(1,0))
	check(camera.focus.x > 0 and camera.focus.z < .25, "Cursor upper-right pans across table")
	check(camera.position.distance_to(original) < 1.0, "Camera movement interpolates")
	for i in range(100): camera.step_camera(.1, Vector2(1,0))
	check(is_equal_approx(camera.focus.x, camera.movement_limits.x), "Camera X boundary")
	check(is_equal_approx(camera.focus.z, -camera.movement_limits.y), "Camera Z boundary")
	var saved: Vector3 = camera.focus
	camera.inspect_at(Vector3(1,.5,1),1.2)
	camera.step_camera(.1,Vector2.ZERO)
	check(camera.focus == saved, "Inspection suspends table pan")
	camera.return_to_table()
	check(camera.focus == saved, "Exact previous tabletop focus restored")
	var inspector = scene.get_node("InspectController")
	for object in scene.get_node("Objects").get_children():
		var rest: Transform3D = object.global_transform
		inspector.select(object)
		await create_timer(.4).timeout
		check(object.global_position.y > rest.origin.y, object.name + " lifts into inspection")
		var previous: Basis = object.visual.basis
		object.rotate_model(Vector2(30,20))
		check(object.visual.basis != previous, object.name + " rotates as a 3D model")
		inspector.leave()
		await create_timer(.4).timeout
		check(object.global_transform.is_equal_approx(rest), object.name + " returns to its exact place")
	check(scene.get_node("Objects").get_child_count() == 4, "Exactly four objects; no cassette player")
	var tape = scene.get_node("Objects/Cassette/TapeAudioController")
	tape.set_process(false)
	tape.play()
	tape.advance(1.25)
	check(is_equal_approx(tape.position_seconds, 1.25), "Simulated transport tracks real seconds")
	tape.pause()
	tape.advance(2.0)
	check(is_equal_approx(tape.position_seconds, 1.25), "Pause holds position")
	tape.play()
	tape.advance(1.0)
	check(is_equal_approx(tape.position_seconds, 2.25), "Resume continues from held position")
	tape.seek(32.0)
	check("development_region" in tape.active_regions, "Seek enters configured region")
	tape.seek(40.0)
	check(tape.active_regions.is_empty(), "Seek exits configured region")
	tape.seek(tape.duration - .1)
	tape.advance(.2)
	check(not tape.playing and tape.position_seconds == tape.duration, "Completion clamps and stops")
	tape.seek(-20.0)
	check(tape.position_seconds == 0.0, "Seek cannot underflow")
	inspector.select(scene.get_node("Objects/Pencil"))
	scene._use_pencil()
	await create_timer(.5).timeout
	var rewind = scene.rewinder
	check(rewind.active and not scene.get_node("Objects/Pencil").visible, "Selected pencil inserts into cassette reel")
	tape.seek(60.0)
	var center: Vector2 = rewind.center_on_screen()
	rewind.start_drag(center + Vector2(90,0))
	for i in range(1,65):
		var angle := TAU * float(i) / 64.0
		rewind.drag_to(center + Vector2(cos(angle),sin(angle))*90.0,.05)
	check(absf(tape.position_seconds - 48.0) < .05, "One clockwise turn rewinds actual tape by 12 seconds")
	for i in range(63,-1,-1):
		var angle := TAU * float(i) / 64.0
		rewind.drag_to(center + Vector2(cos(angle),sin(angle))*90.0,.05)
	check(absf(tape.position_seconds - 60.0) < .05, "Opposite turn advances tape across angle wrap")
	rewind.release()
	rewind.drag_to(center+Vector2(0,90),1.0)
	check(absf(tape.position_seconds - 60.0) < .05, "Released mouse cannot seek")
	inspector.leave()
	check(not rewind.active and scene.get_node("Objects/Pencil").visible, "Leaving rewind restores pencil")
	scene.queue_free()
	await process_frame
	print("REBUILD TESTS: ",failures," failures")
	quit(failures)

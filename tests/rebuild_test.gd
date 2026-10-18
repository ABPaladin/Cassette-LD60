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
	camera.step_camera(3.0, Vector2(.5,.5))
	var original: Transform3D = camera.global_transform
	var original_fov: float = camera.fov
	var inspector = scene.get_node("InspectController")
	var home_pixel: Vector2 = camera.unproject_position(scene.get_node("Objects/Cassette").global_position) / root.get_visible_rect().size
	check(home_pixel.distance_to(Vector2(.5,.5)) < .08, "Fixed composition centers the cassette")
	check(rad_to_deg(-camera.rotation.x) > 70.0, "Elevated tabletop angle matches the overhead reference")
	camera.step_camera(.016, Vector2(1,0))
	check(camera.look_angles.x < 0 and camera.look_angles.y > 0, "Mouse-look rotates toward the cursor")
	check(absf(camera.look_angles.x) < deg_to_rad(camera.horizontal_look_degrees) * .5, "Mouse-look interpolates instead of snapping")
	camera.step_camera(3.0, Vector2(.5,.5))
	var probes: Dictionary = {}
	var baseline: Dictionary = {}
	for object in scene.get_node("Objects").get_children():
		# The notebook is deliberately cropped: test its visible lower-right page area.
		var point: Vector3 = object.global_position + (Vector3(.3,0,.35) if object.object_id == "sketchbook" else Vector3.ZERO)
		probes[object] = point
		baseline[object] = camera.unproject_position(point) / root.get_visible_rect().size
	for cursor in [Vector2.ZERO,Vector2(1,0),Vector2(0,1),Vector2.ONE,Vector2(-2,3)]:
		for i in range(120): camera.step_camera(.1,cursor)
		check(camera.global_position == original.origin and camera.fov == original_fov, "Position and FOV remain fixed at cursor " + str(cursor))
		check(absf(rad_to_deg(camera.look_angles.x)) <= 3.001 and absf(rad_to_deg(camera.look_angles.y)) <= 2.001, "Rotation stays within 3/2 degree limits at " + str(cursor))
		for object in probes:
			var pixel: Vector2 = camera.unproject_position(probes[object])
			var normalized: Vector2 = pixel / root.get_visible_rect().size
			check(Rect2(0,0,1,1).has_point(normalized) and inspector.pick(pixel) == object, object.name + " stays visible and clickable at " + str(cursor))
			check(normalized.distance_to(baseline[object]) < .09, object.name + " stays near its composed screen position")
			if object.object_id != "sketchbook":
				var half_size: Vector3 = object.get_node("Collision").shape.size * .5
				var fully_visible := true
				for x in [-1,1]:
					for y in [-1,1]:
						for z in [-1,1]:
							var vertex: Vector3 = object.global_transform * (half_size * Vector3(x,y,z))
							var screen: Vector2 = camera.unproject_position(vertex) / root.get_visible_rect().size
							if not Rect2(0,0,1,1).has_point(screen): fully_visible = false
				check(fully_visible, object.name + " remains fully within the frame")
		var table_fills_view := true
		for screen_corner in [Vector2.ZERO,Vector2(1,0),Vector2(0,1),Vector2.ONE]:
			var pixel: Vector2 = screen_corner * root.get_visible_rect().size
			var surface: Variant = Plane(Vector3.UP,0).intersects_ray(camera.project_ray_origin(pixel),camera.project_ray_normal(pixel))
			if surface == null or absf(surface.x) > 4.0 or absf(surface.z) > 3.0: table_fills_view = false
		check(table_fills_view,"Brown tabletop covers every corner at " + str(cursor))
	camera.step_camera(3.0,Vector2(.5,.5))
	check(camera.global_transform.is_equal_approx(original), "Centered cursor smoothly restores neutral orientation")
	var distance_before: float = camera.inspect_distance
	camera.zoom(-.5)
	camera.step_camera(.1,Vector2(.5,.5))
	check(camera.inspect_distance == distance_before and camera.global_position == original.origin and camera.fov == original_fov, "Zoom is ignored outside inspection")
	camera.step_camera(3.0,Vector2(1,0))
	var saved: Transform3D = camera.global_transform
	var saved_angles: Vector2 = camera.look_angles
	camera.inspect_at(Vector3(1,.5,1),1.2)
	camera.step_camera(.1,Vector2.ZERO)
	check(camera.look_angles == saved_angles and camera.global_position != saved.origin, "Inspection permits translation and suspends tabletop mouse-look")
	camera.zoom(-.1)
	check(is_equal_approx(camera.inspect_distance,1.1), "Inspection zoom remains available")
	camera.return_to_table()
	camera.step_camera(.016,Vector2(1,0))
	check(camera.returning and camera.global_position != saved.origin, "Inspection return interpolates without a jump")
	for i in range(120): camera.step_camera(.1,Vector2(1,0))
	check(not camera.returning and camera.global_transform.is_equal_approx(saved), "Inspection returns to the fixed position and previous look")
	camera.step_camera(3.0,Vector2(.5,.5))
	for object in scene.get_node("Objects").get_children():
		var rest: Transform3D = object.global_transform
		inspector.select(object)
		camera.step_camera(2.0,Vector2(.5,.5))
		await create_timer(.4).timeout
		var pixel: Vector2 = camera.unproject_position(object.global_position)
		check(inspector.pick(pixel) == object, object.name + " can be raycast from the inspection view")
		check(object.global_position.y > rest.origin.y, object.name + " lifts into inspection")
		var previous: Basis = object.visual.basis
		object.rotate_model(Vector2(30,20))
		check(object.visual.basis != previous, object.name + " rotates as a 3D model")
		inspector.leave()
		await create_timer(.4).timeout
		check(object.global_transform.is_equal_approx(rest), object.name + " returns to its exact place")
	check(scene.get_node("Objects").get_child_count() == 4, "Exactly four objects; no cassette player")
	var tape = scene.get_node("Objects/Cassette/TapeAudioController")
	check(not scene.timeline.slider.editable, "Tape position strip cannot bypass the pencil by scrubbing")
	var transport_buttons: Array[Node] = scene.timeline.find_children("*", "Button", true, false)
	check(transport_buttons.size() == 1 and transport_buttons[0] == scene.timeline.play_button, "Cassette controls contain only PLAY/PAUSE, without time-jump buttons")
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
	var marks: Array[String] = []
	tape.timestamp_reached.connect(func(id): marks.append(id))
	tape.seek(59.5)
	tape.play()
	tape.advance(1.0)
	check(marks == ["development_mark"], "Playback emits configured timestamp event")
	tape.pause()
	tape.collect_fragment("test-a")
	tape.collect_fragment("test-b")
	var valid_order: Array[String] = ["test-b","test-a"]
	var invalid_order: Array[String] = ["unknown"]
	check(tape.set_fragment_order(valid_order) and not tape.set_fragment_order(invalid_order), "Fragment API accepts owned fragments without a hardcoded solution")
	var entered: Array[String] = []
	tape.region_entered.connect(func(id): entered.append(id))
	tape.seek(29.0)
	tape.play()
	tape.advance(8.0)
	check(entered == ["development_region"], "Long frame still emits crossed region entry")
	tape.pause()
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
	rewind.start_drag(center + Vector2(90,0))
	rewind.drag_to(center, .05)
	rewind.drag_to(center + Vector2(-90,0), .05)
	check(absf(tape.position_seconds - 60.0) < .05, "Crossing the reel center resets angle without a tape jump")
	rewind.release()
	rewind.start_drag(center+Vector2(90,0))
	var before_limit: float = tape.position_seconds
	rewind.drag_to(center+Vector2(-90,0),.001)
	check(absf(tape.position_seconds-before_limit) <= rewind.maximum_seek_speed*.001+.001, "Gesture seek rate is capped")
	rewind.release()
	rewind.invert_direction = true
	rewind.start_drag(center+Vector2(90,0))
	var before_invert: float = tape.position_seconds
	rewind.drag_to(center+Vector2(0,90),1.0)
	check(tape.position_seconds > before_invert, "Direction inversion changes seek direction")
	var released := InputEventMouseButton.new()
	released.button_index = MOUSE_BUTTON_LEFT
	released.pressed = false
	rewind._input(released)
	check(not rewind.holding, "Mouse release over GUI cancels circular gesture")
	rewind.release()
	inspector.leave()
	check(not rewind.active and scene.get_node("Objects/Pencil").visible, "Leaving rewind restores pencil")
	var book = scene.get_node("Objects/Sketchbook")
	inspector.select(book)
	book.set_open(true)
	book.turn_page(1)
	check(book.page_index == 1 and book.page_label.text.contains("Drawings"), "3D sketchbook turns to drawing page")
	book.turn_page(1)
	book.turn_page(1)
	check(book.page_index == 2, "Book stops at last placeholder page")
	book.turn_page(-1)
	check(book.page_index == 1, "Book turns backward")
	inspector.leave()
	check(not book.opened, "Book closes when returned")
	var pet = scene.get_node("Objects/Tamagotchi")
	inspector.select(pet)
	pet.press_button(2)
	check(pet.current_value() == "12", "Pet next button cycles configurable numbers")
	pet.press_button(1)
	check(pet.screen_state == "SELECTED", "Pet middle button selects displayed value")
	pet.press_button(0)
	check(pet.current_value() == "00", "Pet previous button reverses sequence")
	pet.press_button(0)
	check(pet.current_value() == "56", "Pet wraps configurable sequence")
	camera.step_camera(2.0,Vector2(.5,.5))
	await create_timer(.4).timeout
	for index in range(3):
		var button: Node3D = pet.get_node("Visual/Button%d" % index)
		var pixel: Vector2 = camera.unproject_position(button.global_position + Vector3.UP * .025)
		check(pet.button_at(pixel,camera) == index, "Physical raycast reaches pet button %d" % index)
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		click.position = pixel
		var before: int = pet.press_count
		pet._input(click)
		check(pet.press_count == before + 1, "Pet button %d responds to mouse input" % index)
	inspector.leave()
	scene.queue_free()
	await process_frame
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game.transition_seconds = .01
	check(game.state == "menu", "Game starts in 3D cassette main menu")
	game.start_intro()
	await create_timer(.08).timeout
	check(game.state == "intro", "START enters introduction")
	var intro = game.content
	intro.advance()
	check(intro.body.visible_characters == intro.body.text.length(), "Advance reveals typewriter text")
	intro.advance()
	check(intro.line_index == 1, "Introduction advances sequentially")
	intro.skip()
	await create_timer(.08).timeout
	check(game.state == "tabletop", "Skip transitions to new tabletop scene")
	var ending = game.content.ending
	ending.timing_scale = .02
	game.content._debug_ending()
	await create_timer(.4).timeout
	check(ending.complete and ending.stage == "end", "Debug ending completes every timed stage")
	check(game.content.get_node("DoorPivot").rotation.y > 1.0, "Ending opens rear door")
	check(game.content.camera.position.y < 0.0, "Ending camera falls to floor")
	check(not game.content.get_node("Objects/Cassette/TapeAudioController").playing, "Ending stops cassette")
	ending.finished.emit()
	await create_timer(.08).timeout
	check(game.state == "menu", "Ending returns to main menu")
	# Exercise the same transport with an actual native audio stream, not just its clock.
	var native = preload("res://scripts/tape_audio_controller.gd").new()
	native.data = preload("res://resources/test_tape.tres").duplicate(true)
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = 22050
	var samples := PackedByteArray()
	samples.resize(22050*2*4)
	audio.data = samples
	native.data.recording = audio
	root.add_child(native)
	native.set_process(false)
	native.play()
	check(native.player.playing and native.duration == 4.0, "Configured native audio stream plays and supplies duration")
	native.seek(1.5)
	check(native.position_seconds == 1.5 and native.player.playing, "Native stream supports seek during playback")
	native.pause()
	check(not native.player.playing, "Native audio pauses")
	native.play()
	check(native.player.playing and native.position_seconds == 1.5, "Native audio resumes at held time")
	native.queue_free()
	game.queue_free()
	await process_frame
	print("REBUILD TESTS: ",failures," failures")
	quit(failures)

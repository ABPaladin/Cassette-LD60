extends SceneTree
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(value: bool, message: String) -> void:
	print("PASS: " if value else "FAIL: ",message)
	if not value: failures += 1
func run() -> void:
	var table = load("res://scenes/tabletop.tscn").instantiate()
	root.add_child(table)
	await process_frame
	var cassette = table.get_node("Objects/Cassette")
	var tape = cassette.tape
	check(tape.player.stream is AudioStreamOggVorbis and tape.player.stream.resource_path == "res://audio/emily recording.ogg" and absf(tape.duration-177.84)<.01,"Final Emily OGG loads with its measured duration")
	check(absf(table.timeline.slider.max_value-tape.duration)<.01,"Timeline uses final recording duration")
	table.inspector.select(cassette)
	tape.seek(24.0)
	tape.play()
	await create_timer(.8).timeout
	check(tape.player.get_playback_position()>24.4,"Actual decoder plays from sought recording position")
	check(absf(tape.position_seconds-tape.player.get_playback_position())<.1,"Timeline follows decoder position")
	check(table.subtitle_panel.visible and table.subtitle.text.begins_with("Radio DJ\nCheck your watches"),"Existing draft cue follows actual playback clock; spoken alignment unverified")
	var previous: float = tape.position_seconds
	tape.advance(90.0)
	check(tape.position_seconds-previous<.1,"Large frame delta cannot advance a real recording's clock")
	tape.pause()
	var held: float = tape.position_seconds
	await create_timer(.2).timeout
	check(tape.player.stream_paused and tape.position_seconds==held,"Pause holds actual audio and transport")
	check(table.subtitle_panel.visible,"Paused listening retains subtitle")
	check(table.puzzle.discovered.is_empty(),"Real playback does not reveal or award words")
	check(not table.puzzle.record_word("wrong"),"Incorrect manual entry is rejected")
	check(table.puzzle.record_word("CHECK"),"Manual NOTE WORD accepts configured provisional clue; spoken timing unverified")
	table._open_fragments()
	check(not table.subtitle_panel.visible,"Arrangement hides subtitles")
	table.fragment_panel.dismiss()
	table.inspector.select(table.get_node("Objects/Pencil"))
	table._use_pencil()
	await create_timer(.5).timeout
	table.camera.step_camera(3.0,Vector2(.5,.5))
	var rewind = table.rewinder
	tape.seek(60.0)
	var center: Vector2 = rewind.center_on_screen()
	rewind.start_drag(center+Vector2(80,0))
	for i in range(1,65):
		var angle := TAU*float(i)/64
		rewind.drag_to(center+Vector2(cos(angle),sin(angle))*80,.05)
	check(absf(tape.position_seconds-72)<.05,"Clockwise pencil circle advances the loaded recording")
	for i in range(63,-1,-1):
		var angle := TAU*float(i)/64
		rewind.drag_to(center+Vector2(cos(angle),sin(angle))*80,.05)
	check(absf(tape.position_seconds-60)<.05,"Counterclockwise circle rewinds across angle wrap")
	check(table.subtitle_panel.visible and table.subtitle.text.contains("Nothing clever"),"Pencil seek selects the draft subtitle at the same audio position")
	rewind.release()
	table._stop_rewind()
	tape.play()
	await create_timer(.5).timeout
	check(tape.player.get_playback_position()>60.2 and tape.player.get_playback_position()<61,"Removing pencil resumes actual recording at new position")
	tape.seek(10)
	await create_timer(.3).timeout
	check(tape.position_seconds>10 and tape.position_seconds<11,"Backward seek during playback stays synchronized")
	tape.seek(tape.duration-.2)
	await create_timer(.5).timeout
	check(not tape.playing and tape.position_seconds==tape.duration,"Real recording completion stops at its duration")
	table.queue_free()
	await process_frame
	print("REAL AUDIO TESTS: ",failures," failures")
	quit(failures)

extends SceneTree
var failures := 0
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	print("PASS: " if ok else "FAIL: ",label)
	if not ok: failures += 1
func run() -> void:
	var table = load("res://scenes/tabletop.tscn").instantiate()
	root.add_child(table)
	await process_frame
	var tape = table.get_node("Objects/Cassette/TapeAudioController")
	tape.set_process(false)
	var puzzle = table.puzzle
	check(tape.player.stream != null and absf(tape.duration-180.0)<.1,"Bundled three-minute recording is loaded")
	var audio = root.get_node_or_null("AudioManager")
	check(audio != null and audio.lamp.playing and audio.room.playing,"Lamp and room loops start in tabletop")
	tape.play()
	await create_timer(.5).timeout
	check(audio.ducked and audio.lamp.volume_db < -28.0,"Ambience ducks while cassette plays")
	tape.pause()
	check(not audio.ducked,"Pause releases ambience ducking")
	audio.set_volume("SFX",0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"SFX volume control can mute its bus")
	audio.set_volume("SFX",.8)
	var answer: Array[String] = ["2","4","1","3"]
	check(not puzzle.submit(answer),"Undiscovered correct answer is rejected")
	for fragment in puzzle.data.fragments:
		tape.pause()
		tape.seek(fragment.time)
		tape.advance(2.0)
		check(str(fragment.id) not in puzzle.discovered,"Seeking/paused time cannot discover " + fragment.id)
		tape.seek(fragment.time - puzzle.data.tolerance_seconds + .1)
		tape.play()
		tape.advance(.6)
		check(str(fragment.id) not in puzzle.discovered,"Brief playback is not enough for " + fragment.id)
		tape.seek(fragment.time + .2)
		tape.advance(.5)
		check(str(fragment.id) not in puzzle.discovered,"Seeking resets listening credit for " + fragment.id)
		tape.advance(.6)
		check(str(fragment.id) in puzzle.discovered,"Playing near timestamp discovers " + fragment.id)
	tape.pause()
	var wrong: Array[String] = ["1","2","3","4"]
	check(not puzzle.submit(wrong) and not puzzle.solved,"Incorrect order permits another attempt")
	var pet = table.get_node("Objects/Tamagotchi")
	check(pet.sequence.values == PackedStringArray(puzzle.data.correct_order),"Pet memory follows central sequence data")
	var book = table.get_node("Objects/Sketchbook")
	book.set_open(true)
	book.turn_page(2)
	check(book.page_label.text.contains("00:24") and book.page_label.text.contains("01:44"),"Notebook exposes configured timestamps")
	book.turn_page(-1)
	var original_page: Resource = book.pages[1]
	var page: Resource = original_page.duplicate()
	var image := Image.create(40,80,false,Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	page.artwork = ImageTexture.create_from_image(image)
	book.pages[1] = page
	book._show_page()
	check(book.page_art.visible and book.page_label.visible,"Illustration and caption coexist on the 3D page")
	check(is_equal_approx(book.page_art.pixel_size * 80,.74),"Portrait fitting preserves original aspect ratio")
	book.pages[1] = original_page
	book._show_page()
	table._open_fragments()
	for id in answer: table.fragment_panel.place(id)
	check(table.fragment_panel.slots == answer,"Fragment UI places discovered words into four slots")
	table.fragment_panel.selected_slot = 0
	table.fragment_panel.place("1")
	check(table.fragment_panel.slots.count("1") == 1,"Moving a fragment cannot duplicate it")
	puzzle.data = puzzle.data.duplicate(true)
	puzzle.data.reveal_seconds = .02
	puzzle.data.suspense_seconds = .02
	table.ending.timing_scale = .02
	check(puzzle.submit(answer),"Correct discovered order solves the puzzle")
	check(not puzzle.submit(answer),"Solution cannot trigger twice")
	check(not table.inspector.enabled and not tape.playing,"Reveal locks interaction and stops tape")
	await create_timer(.4).timeout
	check(table.ending.complete,"Solved signal completes the preserved ending")
	check(not audio.lamp.playing and not audio.room.playing,"Ending stops ambience before the gunshot")
	table.queue_free()
	await process_frame
	print("INVESTIGATION TESTS: ",failures," failures")
	quit(failures)

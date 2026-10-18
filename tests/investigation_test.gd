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
	check(pet.sequence.values == puzzle.data.correct_order,"Pet memory follows central sequence data")
	var book = table.get_node("Objects/Sketchbook")
	book.set_open(true)
	book.turn_page(2)
	check(book.page_label.text.contains("00:24") and book.page_label.text.contains("01:44"),"Notebook exposes configured timestamps")
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
	table.queue_free()
	await process_frame
	print("INVESTIGATION TESTS: ",failures," failures")
	quit(failures)

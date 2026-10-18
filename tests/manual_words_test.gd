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
	var tape = table.get_node("Objects/Cassette/TapeAudioController")
	tape.set_process(false)
	tape.player.stream = null # Explicit simulated fallback for deterministic clue validation.
	var puzzle = table.puzzle
	var answers := [" check! ","DON’T", "the  door.","Trust-Him"]
	var correct: Array[String] = ["2","4","1","3"]
	check(not puzzle.submit(correct),"Arrangement cannot use undiscovered words")
	for i in range(4):
		var fragment: Dictionary = puzzle.data.fragments[i]
		tape.seek(fragment.time)
		check(not puzzle.record_word(answers[i]),"Seek alone cannot record a word")
		tape.play()
		tape.advance(.6)
		check(puzzle.discovered.size() == i,"Passing the timestamp never awards a word automatically")
		check(not puzzle.record_word(answers[i]),"Recording requires a deliberate pause")
		tape.pause()
		check(not puzzle.record_word("unrelated guess"),"Wrong text is rejected without revealing the answer")
		if i == 0:
			table.inspector.select(table.get_node("Objects/Cassette"))
			table._open_word_note()
			check(table.word_note.visible and not table.inspector.enabled,"Small note input blocks world input")
			table.word_note.entry.text = answers[i]
			table.word_note.submit_word()
			table.word_note.dismiss()
			check(table.inspector.enabled,"Returning from note entry restores inspection")
		else: check(puzzle.record_word(answers[i]),"Case, spaces and harmless punctuation are normalized")
		check(str(fragment.id) in puzzle.discovered,"Correct manual word is added to investigation notes")
		check(puzzle.record_word(answers[i]) and puzzle.discovered.size() == i+1,"Repeated correct note does not duplicate a fragment")
	tape.seek(0)
	tape.play()
	tape.advance(.6)
	tape.pause()
	check(not puzzle.record_word("CHECK"),"Correct text at the wrong recording position is rejected")
	var wrong: Array[String] = ["1","2","3","4"]
	check(not puzzle.submit(wrong) and not puzzle.solved,"Wrong reconstruction can be corrected")
	puzzle.data = puzzle.data.duplicate(true)
	puzzle.data.reveal_seconds = .02
	puzzle.data.suspense_seconds = .02
	table.ending.timing_scale = .02
	check(puzzle.submit(correct) and not puzzle.submit(correct),"Correct manual reconstruction triggers only once")
	await create_timer(.45).timeout
	check(table.ending.complete and not table.inspector.enabled,"Existing ending completes with input locked")
	table.queue_free()
	await process_frame
	print("MANUAL WORD TESTS: ",failures," failures")
	quit(failures)

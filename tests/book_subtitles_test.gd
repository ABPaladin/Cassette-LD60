extends SceneTree
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(value: bool, message: String) -> void:
	print("PASS: " if value else "FAIL: ",message)
	if not value: failures += 1
func press(table: Node, text: String) -> void:
	for button in table.actions.get_children():
		if button.text == text:
			button.pressed.emit()
			return
	check(false,"Missing button: " + text)
func run() -> void:
	var table = load("res://scenes/tabletop.tscn").instantiate()
	root.add_child(table)
	await process_frame
	var book = table.get_node("Objects/Sketchbook")
	table.inspector.select(book)
	press(table,"OPEN / CLOSE")
	check(book.opened and book.get_node("Visual/PageSurface").visible,"OPEN shows the existing 3D pages")
	press(table,"PAGE >")
	check(book.page_index == 1 and book.page_label.text.contains(book.pages[1].title),"PAGE > displays current drawing-page content")
	press(table,"< PAGE")
	check(book.page_index == 0,"< PAGE returns to the previous page")
	press(table,"OPEN / CLOSE")
	check(not book.opened,"CLOSE hides pages")
	press(table,"RETURN")
	check(table.inspector.selected == null,"RETURN leaves 3D inspection")
	var tape = table.get_node("Objects/Cassette/TapeAudioController")
	check(table.subtitles_enabled and not table.subtitle_panel.visible,"Subtitles enabled by default; idle tape has no dialogue")
	var cassette = table.get_node("Objects/Cassette")
	table.inspector.select(cassette)
	tape.seek(24.0)
	check(table.subtitle.text.begins_with("Radio DJ\nCheck your watches"),"Seek selects the supplied cue without marking secret words")
	tape.play()
	await create_timer(.5).timeout
	check(absf(tape.position_seconds-tape.player.get_playback_position())<.1 and table.subtitle_panel.visible,"Subtitles follow actual OGG playback position")
	tape.pause()
	var held: String = table.subtitle.text
	await create_timer(.1).timeout
	check(table.subtitle.text == held and table.subtitle_panel.visible,"Pause retains the relevant subtitle")
	check(table.puzzle.discovered.is_empty(),"Subtitles and playback do not collect any puzzle word")
	check(not table.puzzle.record_word("wrong"),"Incorrect manual word is rejected")
	check(table.puzzle.record_word("check"),"NOTE WORD still requires correct manually supplied text")
	table._open_fragments()
	check(not table.subtitle_panel.visible,"ARRANGE FRAGMENTS immediately hides paused subtitles")
	table.fragment_panel.dismiss()
	check(table.subtitle_panel.visible,"Closing arrangement restores the current cassette cue")
	table._open_word_note()
	check(table.word_note.visible and not table.subtitle_panel.visible,"NOTE WORD hides subtitles")
	table.word_note.dismiss()
	var sound_panel = table.ui.get_node(".").get_children().filter(func(node): return node is PanelContainer and node != table.timeline and node != table.subtitle_panel and node != table.word_note and node != table.fragment_panel)[0]
	sound_panel.show()
	check(not table.subtitle_panel.visible,"Sound settings also block subtitles")
	sound_panel.hide()
	for object in [table.get_node("Objects/Tamagotchi"),book]:
		table.inspector.select(object)
		check(not table.subtitle_panel.visible,"Other object inspections hide subtitles")
	table.inspector.leave()
	check(not table.subtitle_panel.visible,"Returning to tabletop hides paused subtitles")
	table.inspector.select(cassette)
	check(table.subtitle.text == held and table.subtitle_panel.visible,"Returning to cassette restores its current paused cue")
	tape.seek(79.2)
	check(table.subtitle.text.contains("The door is wrong"),"Paused seek updates subtitle immediately")
	tape.seek(12.0)
	check(table.subtitle.text.contains("I almost called"),"Rewinding selects the earlier subtitle")
	tape.seek(23.5)
	check(not table.subtitle_panel.visible,"Subtitles disappear in a dialogue gap")
	tape.seek(104.0)
	table._set_subtitles(false)
	check(not table.subtitle_panel.visible,"Subtitle setting can hide paused dialogue")
	table._set_subtitles(true)
	check(table.subtitle.text.contains("Trust him with the order") and table.subtitle_panel.visible,"Re-enabling restores the current cue")
	tape.seek(177.2)
	check(table.subtitle.text == "Waiter\nAnything else?","Final waiter cue is present")
	tape.seek(178.7)
	check(table.subtitle.text == "Emily\nNo, thank you.","Final Emily reply is present")
	tape.stop()
	check(not table.subtitle_panel.visible,"Stopping clears subtitles")
	table._begin_rewind()
	await create_timer(.4).timeout
	table.camera.set_process(false)
	table.camera.step_camera(3.0,Vector2(.5,.5))
	tape.seek(60.0)
	check(table.subtitle_panel.visible,"Pencil interface displays the current cue")
	var rewind = table.rewinder
	var center: Vector2 = rewind.center_on_screen()
	var reel: Node3D = rewind.reel
	var spoke_before: Vector2 = table.camera.unproject_position(reel.to_global(Vector3(.1,0,0)))-center
	var right: Node3D = cassette.get_node("Visual/ReelRight")
	var right_before: Basis = right.basis
	var pencil_before: Basis = rewind.inserted_pencil.global_basis
	rewind.start_drag(center+Vector2(80,0))
	for i in range(1,65):
		var angle := TAU*float(i)/64.0
		rewind.drag_to(center+Vector2(cos(angle),sin(angle))*80,.05)
		if i == 16:
			rewind._process(1.0)
			var spoke_after: Vector2 = table.camera.unproject_position(reel.to_global(Vector3(.1,0,0)))-center
			check(wrapf(spoke_after.angle()-spoke_before.angle(),-PI,PI)>0,"Reel visibly rotates clockwise with the mouse")
			check(not right.basis.is_equal_approx(right_before) and not rewind.inserted_pencil.global_basis.is_equal_approx(pencil_before),"Both reels and inserted pencil follow the same rotation")
	check(absf(tape.position_seconds-72.0)<.05,"Clockwise circle advances actual cassette position")
	for i in range(63,-1,-1):
		var angle := TAU*float(i)/64.0
		rewind.drag_to(center+Vector2(cos(angle),sin(angle))*80,.05)
	check(absf(tape.position_seconds-60.0)<.05,"Counterclockwise circle rewinds across the angle boundary")
	rewind.release()
	table.inspector.leave()
	check(not table.subtitle_panel.visible,"Leaving pencil interface hides subtitles immediately")
	table.inspector.select(cassette)
	tape.seek(tape.duration-.1)
	tape.play()
	await create_timer(.35).timeout
	check(not table.subtitle_panel.visible and not tape.playing,"Recording completion clears subtitles")
	table.queue_free()
	await process_frame
	print("BOOK/SUBTITLE TESTS: ",failures," failures")
	quit(failures)

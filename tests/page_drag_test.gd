extends SceneTree
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(value: bool, message: String) -> void:
	print("PASS: " if value else "FAIL: ",message)
	if not value: failures += 1
func gesture(table: Node, book: Node, direction: int, progress: float) -> void:
	var start: Vector2 = table.camera.unproject_position(book.corner_position(direction))
	var finish: Vector2 = table.camera.unproject_position(book.corner_position(-direction))
	check(root.get_visible_rect().has_point(start),"Page corner is inside the inspection viewport")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = start
	table.inspector._unhandled_input(press)
	check(book.page_dragging,"Corner press grabs the physical page")
	var motion := InputEventMouseMotion.new()
	motion.position = start.lerp(finish,progress)
	motion.relative = motion.position-start
	table.inspector._input(motion)
	await create_timer(.12).timeout
	check(absf(book.turn_pivot.rotation.z) > .05,"Page mesh follows drag around binding")
	press.pressed = false
	press.position = motion.position
	table.inspector._input(press)
	await create_timer(.35).timeout
func run() -> void:
	var table = load("res://scenes/tabletop.tscn").instantiate()
	root.add_child(table)
	await process_frame
	var book = table.get_node("Objects/Sketchbook")
	table.inspector.select(book)
	await create_timer(.5).timeout
	table.camera.step_camera(3.0,Vector2(.5,.5))
	book.set_open(true)
	await create_timer(.45).timeout
	var basis: Basis = book.visual.basis
	await gesture(table,book,1,.15)
	check(book.page_index == 0 and not book.turn_busy,"Early release cancels without changing page")
	await gesture(table,book,1,.7)
	check(book.page_index == 1 and book.page_label.text.contains("Drawings"),"Completed forward drag reveals drawing page")
	check(book.visual.basis.is_equal_approx(basis) and not table.inspector.dragging,"Page drag cannot rotate the whole object")
	await gesture(table,book,1,.7)
	check(book.page_index == 2 and book.page_label.text.contains("00:24"),"Next drag reveals configured investigation page")
	await gesture(table,book,-1,.7)
	check(book.page_index == 1,"Left-hand page drag returns to previous page")
	check(not book.turn_pivot.visible and book.page_art.get_parent() == book.get_node("Visual/PageSurface"),"Page content remains on the physical 3D surface")
	for button in table.actions.get_children():
		check(not button.text.contains("PAGE"),"No visible page navigation buttons")
	table.inspector.leave()
	check(not book.opened and not book.page_dragging,"Returning closes book and clears page input")
	table.queue_free()
	await process_frame
	print("PAGE DRAG TESTS: ",failures," failures")
	quit(failures)

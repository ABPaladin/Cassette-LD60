extends SceneTree
var game: Node
func _initialize() -> void:
	_run.call_deferred()
func shot(name: String) -> void:
	await create_timer(.15).timeout
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://artifacts/" + name + ".png")
	print("CAPTURE ",name," ",error)
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	game.transition_seconds = .05
	await shot("01-menu")
	game.start_intro()
	await create_timer(.2).timeout
	game.content.advance()
	await shot("02-introduction")
	game.content.skip()
	await create_timer(.3).timeout
	var table = game.content
	table.camera.set_process(false)
	table.camera.focus = table.camera.home_focus
	table.camera.step_camera(3.0,Vector2(.5,.5))
	await shot("03-tabletop")
	for id in ["Pencil", "Sketchbook", "Tamagotchi"]:
		var object = table.get_node("Objects/" + id)
		table.camera.focus = Vector3(clampf(object.position.x,-table.camera.movement_limits.x,table.camera.movement_limits.x),0,clampf(object.position.z,-table.camera.movement_limits.y,table.camera.movement_limits.y))
		table.camera.step_camera(3.0,Vector2(.5,.5))
		await shot("tabletop-" + id)
	table.camera.focus = table.camera.home_focus
	table.camera.step_camera(3.0,Vector2(.5,.5))
	for id in ["Cassette", "Pencil", "Sketchbook", "Tamagotchi"]:
		var object = table.get_node("Objects/" + id)
		table.inspector.select(object)
		for i in range(90): table.camera.step_camera(1.0/60.0,Vector2(.5,.5))
		await create_timer(.45).timeout
		if id == "Sketchbook": object.set_open(true); await create_timer(.5).timeout
		await shot("inspect-" + id)
		if id == "Pencil":
			table._use_pencil()
			for i in range(90): table.camera.step_camera(1.0/60.0,Vector2(.5,.5))
			await create_timer(.5).timeout
			await shot("04-pencil-rewind")
		table.inspector.leave()
		await create_timer(.4).timeout
	table.ending.timing_scale = .3
	table._debug_ending()
	await create_timer(1.2).timeout
	await shot("05-door")
	await create_timer(2.0).timeout
	await shot("06-ending")
	game.queue_free()
	await process_frame
	print("VISUAL REVIEW COMPLETE")
	quit()

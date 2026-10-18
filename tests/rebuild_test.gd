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
	scene.queue_free()
	await process_frame
	print("REBUILD TESTS: ",failures," failures")
	quit(failures)

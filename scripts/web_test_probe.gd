extends Node
## Read-only telemetry, instantiated solely by the separate Web QA export feature.
var elapsed := 0.0
func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < .1: return
	elapsed = 0
	var game = get_parent()
	var state := {"state":game.state,"buttons":[]}
	_buttons(game,state.buttons)
	if game.state == "tabletop":
		var table = game.content
		var tape = table.get_node("Objects/Cassette/TapeAudioController")
		state.merge({"selected":table.inspector.selected.object_id if table.inspector.selected != null else "", "time":tape.position_seconds,"playing":tape.playing,"discovered":table.puzzle.discovered,"solved":table.puzzle.solved,"ending":table.ending.stage,"rewind":table.rewinder.active,"page":table.get_node("Objects/Sketchbook").page_index,"pet":table.get_node("Objects/Tamagotchi").current_value(),"camera_position":[table.camera.position.x,table.camera.position.y,table.camera.position.z],"camera_fov":table.camera.fov})
		state["objects"] = {}
		for object in table.get_node("Objects").get_children():
			var point: Vector3 = object.global_position + (Vector3(.3,0,.35) if object.object_id == "sketchbook" else Vector3.ZERO)
			var pixel: Vector2 = table.camera.unproject_position(point)
			state.objects[object.object_id] = [pixel.x,pixel.y]
		if table.rewinder.active:
			var center: Vector2 = table.rewinder.center_on_screen()
			state["reel"] = [center.x,center.y]
		var pet = table.get_node("Objects/Tamagotchi")
		state["pet_buttons"] = []
		for i in range(3):
			var pixel: Vector2 = table.camera.unproject_position(pet.get_node("Visual/Button%d" % i).global_position + Vector3.UP*.025)
			state.pet_buttons.append([pixel.x,pixel.y])
	JavaScriptBridge.eval("window.cassetteQA = " + JSON.stringify(state) + ";",true)

func _buttons(node: Node, result: Array) -> void:
	if node is Button and node.is_visible_in_tree():
		var rect: Rect2 = node.get_global_rect()
		result.append({"text":node.text,"x":rect.get_center().x,"y":rect.get_center().y,"disabled":node.disabled})
	for child in node.get_children(): _buttons(child,result)

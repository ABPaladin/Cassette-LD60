extends SceneTree
func _initialize() -> void:
	print("PACK ",ProjectSettings.load_resource_pack("res://build/web-qa/index.pck",true))
	var data = load("res://resources/investigation.tres")
	print("DATA ",data," order=",data.correct_order," fragments=",data.fragments," props=",data.get_property_list())
	quit()

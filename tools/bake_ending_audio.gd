extends SceneTree
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/audio/placeholder")
	var noise := preload("res://scripts/placeholder_sfx.gd").make_cue(false)
	noise.save_to_wav("res://assets/audio/placeholder/rear_noise.wav")
	preload("res://scripts/placeholder_sfx.gd").make_cue(true).save_to_wav("res://assets/audio/placeholder/shot.wav")
	var filtered := noise.data.duplicate()
	var previous := 0.0
	for i in range(filtered.size() / 2):
		previous = lerpf(previous,float(noise.data.decode_s16(i*2)),.12)
		filtered.encode_s16(i*2,int(previous))
	noise.data = filtered
	noise.save_to_wav("res://assets/audio/placeholder/rear_muffled.wav")
	quit()

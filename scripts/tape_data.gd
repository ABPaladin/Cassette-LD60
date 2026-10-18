extends Resource
## Replace these placeholders with the final recording and authored markers later.
@export var recording: AudioStream
@export_file("*.wav", "*.ogg", "*.mp3") var recording_path := ""
@export var simulated_duration := 180.0
@export var label := "EMILY / SIDE A"
@export var regions: Array[Dictionary] = []
@export var timestamps: Array[Dictionary] = []
@export var pitch := 1.0
@export_range(0.0,1.0) var distortion := 0.0
@export_range(0.0,1.0) var reverb := 0.0

extends Resource
## Replace these placeholders with the final recording and authored markers later.
@export var recording: AudioStream
@export var background_music: AudioStreamOggVorbis
@export_range(-60.0, 0.0) var music_volume_db := -24.0
@export_range(500.0, 20000.0) var music_lowpass_hz := 3200.0
@export_file("*.wav", "*.ogg", "*.mp3") var recording_path := ""
@export var simulated_duration := 180.0
@export var label := "EMILY / SIDE A"
@export var recording_notice := ""
@export var regions: Array[Dictionary] = []
@export var timestamps: Array[Dictionary] = []
@export var pitch := 1.0
@export_range(0.0,1.0) var distortion := 0.0
@export_range(0.0,1.0) var reverb := 0.0

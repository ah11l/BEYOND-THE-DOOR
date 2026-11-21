extends Node

## Audio manager for ambient music and pooled SFX playback (prototype procedural WAV assets).

const MUSIC_PATH := "res://assets/audio/music/ambient_void.wav"
const SFX_PATHS := {
	"door_open": "res://assets/audio/sfx/door_open.wav",
	"door_locked": "res://assets/audio/sfx/door_locked.wav",
	"echo_record": "res://assets/audio/sfx/echo_record.wav",
	"echo_replay": "res://assets/audio/sfx/echo_replay.wav",
	"plate_press": "res://assets/audio/sfx/plate_press.wav",
	"key_pickup": "res://assets/audio/sfx/key_pickup.wav",
	"secret_found": "res://assets/audio/sfx/secret_found.wav",
	"checkpoint": "res://assets/audio/sfx/checkpoint.wav",
	"stage_complete": "res://assets/audio/sfx/stage_complete.wav",
	"state_shift": "res://assets/audio/sfx/state_shift.wav",
	"gravity_flip": "res://assets/audio/sfx/gravity_flip.wav",
	"portal_warp": "res://assets/audio/sfx/portal_warp.wav",
	"ui_click": "res://assets/audio/sfx/ui_click.wav",
}

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_streams: Dictionary = {}
var _pool_index: int = 0


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = _resolve_bus(&"Music")
	add_child(_music_player)

	for i in range(6):
		var p := AudioStreamPlayer.new()
		p.bus = _resolve_bus(&"SFX")
		add_child(p)
		_sfx_pool.append(p)

	_preload_audio()
	apply_volumes()
	SaveManager.settings_changed.connect(apply_volumes)
	play_ambient_music()


func _resolve_bus(bus_name: StringName) -> StringName:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return bus_name
	return &"Master"


func _preload_audio() -> void:
	for key in SFX_PATHS.keys():
		var path: String = SFX_PATHS[key]
		if ResourceLoader.exists(path):
			_sfx_streams[key] = load(path)
		else:
			push_warning("AudioManager: Missing SFX resource at %s" % path)


func play_ambient_music() -> void:
	if not ResourceLoader.exists(MUSIC_PATH):
		push_warning("AudioManager: Missing ambient music at %s" % MUSIC_PATH)
		return
	var stream: AudioStream = load(MUSIC_PATH)
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music_player.stream = stream
	if not _music_player.playing:
		_music_player.play()


func play_sfx(sfx_name: String, pitch_jitter: float = 0.04) -> void:
	if not _sfx_streams.has(sfx_name):
		return
	var player := _sfx_pool[_pool_index]
	_pool_index = (_pool_index + 1) % _sfx_pool.size()
	player.stream = _sfx_streams[sfx_name]
	player.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	player.play()


func apply_volumes() -> void:
	var music_vol := clampf(float(SaveManager.get_setting("music_volume", 0.75)), 0.0, 1.0)
	var sfx_vol := clampf(float(SaveManager.get_setting("sfx_volume", 0.85)), 0.0, 1.0)
	_set_bus_linear(&"Music", music_vol)
	_set_bus_linear(&"SFX", sfx_vol)


func _set_bus_linear(bus_name: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.001)))

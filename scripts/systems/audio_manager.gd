extends Node

## Audio Manager — plays pooled AudioStreamPlayer2D nodes.
## Drop audio files into assets/audio/sfx/ and assets/audio/music/
## and this system will load + play them automatically.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"

var tension_level: float = 0.0

# Preloaded audio cache
var _sfx_cache: Dictionary = {}
var _music_player: AudioStreamPlayer = null
var _current_music_name: String = ""

# Audio pool for positional SFX
var _sfx_pool: Array[AudioStreamPlayer2D] = []
const POOL_SIZE := 12

# Footstep config
var _footstep_sounds: Dictionary = {
	"walk": [],
	"run": [],
	"crouch": []
}


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	_build_sfx_pool()
	_discover_audio_files()


func _build_sfx_pool() -> void:
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer2D.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_pool.append(player)


func _discover_audio_files() -> void:
	## Auto-discover any audio files dropped into assets/audio/sfx/
	## Supported extensions: .wav, .ogg, .mp3
	var sfx_path := SFX_DIR
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(sfx_path)):
		return
	var dir := DirAccess.open(sfx_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var ext := file_name.get_extension().to_lower()
			if ext in ["wav", "ogg", "mp3"]:
				var res_path: String = sfx_path + file_name
				var stream: AudioStream = load(res_path) as AudioStream
				if stream:
					var key: String = file_name.get_basename().to_lower()
					_sfx_cache[key] = stream
					# Categorize footstep sounds automatically
					if key.begins_with("footstep_walk"):
						_footstep_sounds["walk"].append(stream)
					elif key.begins_with("footstep_run"):
						_footstep_sounds["run"].append(stream)
					elif key.begins_with("footstep_crouch"):
						_footstep_sounds["crouch"].append(stream)
		file_name = dir.get_next()
	dir.list_dir_end()


func play_sfx(sound_name: String, position: Vector2 = Vector2.ZERO, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _sfx_cache.get(sound_name.to_lower(), null)
	if stream == null:
		# Silently ignore missing audio — no crashes
		return
	var player := _get_free_sfx_player()
	if player == null:
		return
	player.stream = stream
	player.global_position = position
	player.volume_db = volume_db
	player.play()


func play_footstep(movement_mode: String) -> void:
	var sounds: Array = _footstep_sounds.get(movement_mode, [])
	if sounds.is_empty():
		return
	var stream: AudioStream = sounds[randi() % sounds.size()]
	var player := _get_free_sfx_player()
	if player == null:
		return
	player.stream = stream
	# Footsteps come from player position
	if GameManager.player:
		player.global_position = GameManager.player.global_position
	player.volume_db = -8.0 if movement_mode == "crouch" else 0.0
	player.play()


func play_music(track_name: String, loop: bool = true) -> void:
	if _current_music_name == track_name:
		return
	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.bus = "Music"
		add_child(_music_player)

	var path := MUSIC_DIR + track_name
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = loop

	_music_player.stream = stream
	_current_music_name = track_name
	_music_player.play()


func set_tension_level(level: float) -> void:
	tension_level = clampf(level, 0.0, 1.0)
	if _music_player and _music_player.playing:
		# Pitch up music slightly as tension rises
		_music_player.pitch_scale = lerpf(1.0, 1.08, tension_level)


func _get_free_sfx_player() -> AudioStreamPlayer2D:
	for player in _sfx_pool:
		if not player.playing:
			return player
	# All busy — steal the oldest (first in pool)
	return _sfx_pool[0]

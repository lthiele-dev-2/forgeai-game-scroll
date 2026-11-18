extends Node

const BUS_BGM: String = "BGM"
const BUS_SFX: String = "SFX"

@export var sfx_player_count: int = 8

var _bgm_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	_ensure_bus(BUS_BGM)
	_ensure_bus(BUS_SFX)
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = BUS_BGM
	add_child(_bgm_player)
	for i in range(sfx_player_count):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % i
		player.bus = BUS_SFX
		add_child(player)
		_sfx_players.append(player)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)


func play_bgm(stream: AudioStream) -> void:
	_bgm_player.stream = stream
	_bgm_player.play()


func stop_bgm() -> void:
	_bgm_player.stop()


func play_sfx(stream: AudioStream) -> void:
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return

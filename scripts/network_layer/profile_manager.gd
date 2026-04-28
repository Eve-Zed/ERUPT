extends Node

var _player_info: ProfileInfo 

var player_info: Dictionary:
	get:
		return _player_info.to_dictionary()

func _ready() -> void:
	_player_info = ProfileInfo.new()

func set_profile_name(profile_name: String) -> void:
	_player_info.player_name = profile_name

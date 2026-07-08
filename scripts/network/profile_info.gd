extends Node
class_name ProfileInfo

var player_name: String
var profile_picture: String
var profile_picture_hash: String


func to_dictionary() -> Dictionary:
	return {
		"name": player_name,
		"profile_picture": profile_picture,
		"picture_hash": profile_picture_hash
	}

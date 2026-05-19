extends RefCounted
class_name FileMetadata

var file_hash: String
var priority: int
var campaigns: PackedStringArray

func to_dictionary() -> Dictionary:
	return {}

func to_json_string() -> String:
	return JSON.stringify(to_dictionary())

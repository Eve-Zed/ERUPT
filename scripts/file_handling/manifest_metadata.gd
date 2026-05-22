extends RefCounted
class_name ManifestMetadata

const KEY_NAME := "name"
const KEY_PRIORITY := "prio"
const KEY_SIZE := "size"
const KEY_CAMPAIGNS := "campaigns"

var file_name: String
var priority: int
var size: int
var campaigns: PackedStringArray #Array for Campaign IDs - leave empty to make file global

func _init(_file_name: String, _priority: int, _size: int, _campaigns: PackedStringArray) -> void:
	file_name = _file_name
	priority = _priority
	size = _size
	campaigns = _campaigns

func to_dictionary() -> Dictionary:
	var metadata := {}
	metadata[KEY_NAME] = file_name
	metadata[KEY_PRIORITY] = priority
	metadata[KEY_SIZE] = size
	metadata[KEY_CAMPAIGNS] = campaigns
	return metadata

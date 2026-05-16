extends Node
class_name FileMetadata

var file_hash: String
var size: int
var prio: int
var global: bool
var campaigns: PackedStringArray

func _init(_file_hash: String, _size: int, _prio: int, _global: bool, _campaigns: PackedStringArray) -> void:
	file_hash = _file_hash
	size = _size
	prio = _prio
	global = _global
	campaigns = _campaigns
	
func to_dictionary():
	pass
	
static func create_from_dictionary(_dict: Dictionary):
	pass

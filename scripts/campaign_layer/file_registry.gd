extends Node
class_name FileRegistry

var root_path: String
var json_file_name: String
var version: int

var _file_registry: Dictionary[String, FileMetadata] = {}

func _init(_root_path: String, _json_file_name: String, _version: int) -> void:
	root_path = _root_path
	json_file_name = _json_file_name
	version = _version

static func validate_registry_json(data: Dictionary) -> Error:
	#TODO implement method
	return OK

extends Node
class_name FileRegistry

var root_path: String
var json_file_name: String
var version: int

var _file_registry: Dictionary[String, FileMetadata] = {}

var json_path: String:
	get:
		return root_path.path_join(json_file_name)
var file_registry: Dictionary[String, FileMetadata] = {}:
	get:
		return _file_registry.duplicate(true)

func _init(_root_path: String, _json_file_name: String, _version: int) -> void:
	root_path = _root_path
	json_file_name = _json_file_name
	version = _version

func _build_registry(data: Dictionary) -> Dictionary[String, FileMetadata]:
	var registry: Dictionary[String, FileMetadata] = {}
	
	for file in data:
		registry[file] = FileMetadata.create_from_dictionary(data[file])
	
	return registry

func registry_to_json() -> String:
	var data := {}
	for file_name: String in file_registry.keys():
		data[file_name] = file_registry[file_name].to_dictionary()
	return JSON.stringify(data)

func save_registry() -> Error:
	#TODO append if file exists
	return FileUtils.atomic_save(json_path,registry_to_json())

func load_registry() -> Error:
	var res := FileUtils.load_json_file(json_path)
	var json = res.value
	if json.is_empty():
		return res.error
	
	var parsed = JSON.parse_string(json)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("Failed to load registry: Could not parse json")
		return ERR_PARSE_ERROR
	
	var parse_err := validate_registry(parsed)
	if parse_err != OK:
		return parse_err
	
	_file_registry = _build_registry(parsed)
	return OK

func add_file(_file_path: String, metadata: FileMetadata) -> void:
	pass

static func validate_registry(data: Dictionary) -> Error:
	#TODO implement method
	return OK

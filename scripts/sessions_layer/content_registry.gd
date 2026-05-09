extends Resource
class_name ContentRegistry

static var validate_error_prefix := "Failed to validate json: " 

var _root_path: String
var _json_file_name: String

var _locked := false

var _file_registry : Dictionary[String, FileMetadata] = {}

var root_path: String:
	get:
		return _root_path
	set(value):
		if value.is_absolute_path():
			_root_path = value
		else:
			push_error("Failed to set root_path: not a valid path "+value)
var json_file_name : String:
	get:
		return _json_file_name
var json_path : String:
	get:
		return _root_path.path_join(_json_file_name)

var file_registry: Dictionary[String, FileMetadata] = {}:
	get:
		return _file_registry.duplicate(true)
#Filename -> Metadata(hash, size, prio, source) 

func _init(path: String, json_name: String) -> void:
	_root_path = path
	_json_file_name = json_name

func registry_to_json() -> String:
	var data := {}
	for file_name: String in file_registry.keys():
		data[file_name] = file_registry[file_name].to_dictionary()
	return JSON.stringify(data)

func save_registry() -> Error:
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
	
	var parse_err := validate_registry_json(parsed)
	if parse_err != OK:
		return parse_err
	
	_set_registry(_build_registry(parsed))
	return OK

func get_file_path(file_name: String) -> String:
	return root_path.path_join(file_name)

func has_file(file_name: String, expected_hash: String) -> bool:
	return _file_registry.get(file_name) != null and _file_registry[file_name].file_hash == expected_hash

func _build_registry(data: Dictionary) -> Dictionary[String, FileMetadata]:
	var registry: Dictionary[String, FileMetadata] = {}
	
	for file in data:
		registry[file] = FileMetadata.create_from_dictionary(data[file])
	
	return registry

func _set_registry(data: Dictionary[String, FileMetadata]) -> void:
	if not _locked:
		_file_registry = data

func _alter_registry(file_name: String, data: FileMetadata) -> void:
	if not _locked:
		_file_registry[file_name] = data

func _delete_registry_entry(file_name: String) -> bool:
	if not _locked:
		return _file_registry.erase(file_name)
	return false

static func validate_registry_json(data: Dictionary) -> Error:
	for key in data:
		if typeof(key) != TYPE_STRING or key.is_empty():
			push_error(validate_error_prefix + "Invalid file path")
			return ERR_FILE_BAD_PATH
			
		if typeof(data[key]) != TYPE_DICTIONARY or data[key].is_empty():
			push_error(validate_error_prefix + "Invalid file metadata")
			return ERR_INVALID_DATA
		
		if not data[key].has_all(FileMetadata.metadata_keys) or data[key].size() != FileMetadata.metadata_keys.size() :
			push_error(validate_error_prefix + "Invalid metadata parameters")
			return ERR_INVALID_DATA
		
		if typeof(data[key]["hash"]) != TYPE_STRING or data[key]["hash"].is_empty():
			push_error(validate_error_prefix + "Invalid hash")
			return ERR_INVALID_PARAMETER
		
		if typeof(data[key]["size"]) != TYPE_FLOAT or data[key]["size"] <= 0:
			push_error(validate_error_prefix + "Invalid size")
			return ERR_INVALID_PARAMETER
			
		if typeof(data[key]["prio"]) != TYPE_FLOAT or data[key]["prio"] < 0:
			push_error(validate_error_prefix + "Invalid prio")
			return ERR_INVALID_PARAMETER

		if typeof(data[key]["source"]) != TYPE_FLOAT or data[key]["source"] < 0:
			push_error(validate_error_prefix + "Invalid source")
			return ERR_INVALID_PARAMETER
			
	return OK

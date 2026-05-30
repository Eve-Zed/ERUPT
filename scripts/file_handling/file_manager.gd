extends Node
#Autoload class_name FileManager

const INDEX_NAME := "file_index.json" #All addded files are recorded here in the format path -> metadata

var  files_path := "user://files"
var _file_index: Dictionary[String, IndexMetadata] = {}

#for dependency injection to make unit testing easier
var file_access_class := FileAccess
var file_utils_class := FileUtils
var game_utils_class := GameUtils
var dir_access_class := DirAccess

var index_path: String:
	get:
		return files_path.path_join(INDEX_NAME)
var file_index: Dictionary[String, IndexMetadata]:
	get:
		return _file_index.duplicate(true)

func _ready() -> void:
	_initialise()

func add_file(file_path: String, campaigns: PackedStringArray = [], visibility: PackedStringArray = [], 
description: String = "", tags: PackedStringArray = []) -> Error:
	if not file_access_class.file_exists(file_path):
		push_error("Could not add file: %s does not exist" % [file_path])
		return ERR_FILE_NOT_FOUND
		
	var simplyfied_path := file_path.simplify_path()
	if _file_index.has(simplyfied_path):
		push_error("Could not add file: %s already in file index" % [simplyfied_path])
		return ERR_ALREADY_EXISTS
		
	var file_hash := file_utils_class.hash_file(file_path)
	var prio := game_utils_class.get_file_priority(file_path)
	var metadata := IndexMetadata.new(file_hash, prio, campaigns, visibility, description, tags)
	
	_file_index[simplyfied_path] = metadata
	var err := _save_file_index()
	if err != OK:
		push_error("Could not save file index: " + error_string(err))
		return err
	return OK

func remove_file(file_path: String) -> Error:
	_file_index.erase(file_path)
	return _save_file_index()

func get_file_metadata(file_path: String) -> IndexMetadata:
	return _file_index[file_path]

func modify_file_metadata(file_path: String, metadata: IndexMetadata) -> Error:
	if not _file_index.has(file_path):
		push_error("Could not modify file metadata: " + file_path + " does not exist in file index")
		return ERR_FILE_NOT_FOUND
	_file_index[file_path] = metadata
	return _save_file_index()

func _save_file_index() -> Error:
	var file_data := {}
	for path: String in _file_index:
		file_data[path] = _file_index[path].to_dictionary()
		
	return file_utils_class.atomic_save(index_path, JSON.stringify(file_data))

func _load_file_index() -> Error:
	var res := file_utils_class.load_json_file(index_path)
	if res.error != OK:
		push_error("Could not load file index: " + error_string(res.error))
		return res.error
	if typeof(res.value) != TYPE_DICTIONARY:
		#TODO maybe further validate json
		push_error("Could not load file index: invalid json")
		return ERR_PARSE_ERROR
	var json = res.value as Dictionary
	for file in json:
		if file_access_class.file_exists(file):
			_file_index[file] = IndexMetadata.create_from_dictionary(json[file])
		else:
			push_warning(file + " doesn't exist and can't be added to file index")
	return OK

func _initialise() -> void:
	if !dir_access_class.dir_exists_absolute(files_path):
		var err := dir_access_class.make_dir_recursive_absolute(files_path)
		if not err == OK:
			push_error("Could not create files folder: " + error_string(err))
	var load_err := _load_file_index()
	if not load_err == OK:
		push_error("Failed to load file index: " + error_string(load_err))

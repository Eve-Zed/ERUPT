extends Node
#Autoload class_name FileManager

const FILES_PATH := "user://files"
const INDEX_NAME := "file_index.json" #All addded files are recorded here in the format path -> metadata

var _file_index: Dictionary[String, IndexMetadata] = {}

var index_path: String:
	get:
		return FILES_PATH.path_join(INDEX_NAME)
var file_index: Dictionary[String, IndexMetadata]:
	get:
		return _file_index.duplicate(true)

func _ready() -> void:
	if !DirAccess.dir_exists_absolute(FILES_PATH):
		DirAccess.make_dir_recursive_absolute(FILES_PATH)
	_load_file_index()

func add_file(file_path: String, campaigns: PackedStringArray = [], visibility: PackedStringArray = [], 
description: String = "", tags: PackedStringArray = []) -> Error:
	if not FileAccess.file_exists(file_path):
		push_error("Could not add file: %s does not exist" % [file_path])
		return ERR_FILE_NOT_FOUND
		
	var simplyfied_path := file_path.simplify_path()
	if _file_index.has(simplyfied_path):
		push_error("Could not add file: %s already in file index" % [simplyfied_path])
		return ERR_ALREADY_EXISTS
		
	var file_hash := FileUtils.hash_file(file_path)
	var prio := GameUtils.get_file_priority(file_path)
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
		return ERR_FILE_NOT_FOUND
	_file_index[file_path] = metadata
	return _save_file_index()

func _save_file_index() -> Error:
	var file_data := {}
	for path: String in _file_index:
		file_data[path] = _file_index[path].to_dictionary()
		
	return FileUtils.atomic_save(index_path, JSON.stringify(file_data))

func _load_file_index() -> Error:
	var res := FileUtils.load_json_file(index_path)
	if res.error != OK:
		return res.error
	if typeof(res.value) != TYPE_DICTIONARY:
		return ERR_PARSE_ERROR
	var json = res.value as Dictionary
	for file in json:
		if FileAccess.file_exists(file):
			_file_index[file] = IndexMetadata.create_from_dictionary(json[file])
		else:
			#TODO throw alert
			pass
	return OK

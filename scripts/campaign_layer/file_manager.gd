extends Node
#Autoload class_name FileManager

const FILES_PATH := "user://files"
const INDEX_NAME := "file_index.json" #All addded files are recorded here in the format path -> metadata
const MANIFEST_NAME_SUFFIX := ".json" #Will be created for each campaign and user to handle file sharing, CampaignID + UserID + Suffix

var _file_index: Dictionary[String, IndexMetadata] = {}

var index_path: String:
	get:
		return FILES_PATH.path_join(INDEX_NAME)
var file_index: Dictionary[String, IndexMetadata]:
	get:
		return _file_index.duplicate(true)

func _init() -> void:
	_load_file_index()

func add_file(file_path: String, campaigns: PackedStringArray = [], visibility: PackedStringArray = [], 
description: String = "", tags: PackedStringArray = []) -> Error:
	if !FileAccess.file_exists(file_path):
		push_error("Could not add file: %s does not exist" % [file_path])
		return ERR_FILE_NOT_FOUND
	var file_hash := FileUtils.hash_file(file_path)
	var prio := GameUtils.get_file_priority(file_path)
	var metadata := IndexMetadata.new(file_hash, prio, campaigns, visibility, description, tags)
	
	_file_index[file_path] = metadata
	var err := _save_file_index()
	if err != OK:
		push_error("Could not save file index: " + error_string(err))
		return err
	return OK

func _save_file_index() -> Error:
	var file_data := {}
	for file in _file_index.keys():
		file_data[file] = _file_index[file].to_dictionary()
	return FileUtils.atomic_save(index_path, JSON.stringify(file_data))

func _load_file_index() -> Error:
	var res := FileUtils.load_json_file(index_path)
	if res.error != OK:
		return res.error
	if typeof(res.value) != TYPE_DICTIONARY:
		return ERR_PARSE_ERROR
	var json = res.value as Dictionary
	for file in json:
		#TODO see if files still exist at path, else throw a alert
		_file_index[file] = IndexMetadata.create_from_dictionary(json[file])
	return OK
	

extends Node

const FILES_PATH = "user://files"
const MANIFEST_NAME = "manifest.json"
const INDEX_NAME = "index.json"

var index: FileIndex

func _init() -> void:
	_load_index()

func add_file_to_campaigns(file_path: String, campaign_ids: PackedStringArray = []) -> Error:
	var size := FileAccess.get_file_as_bytes(file_path).size()
	var global := campaign_ids.is_empty()
	var metadata := ManifestFileMetadata.new(FileUtils.hash_file(file_path), size, GameUtils.get_priority(file_path), global, campaign_ids, [], "", [])
	index.add_file(file_path, metadata)
	return OK

func _load_index() -> Error:
	var file_index := FileIndex.new()
	if file_index == null:
		return FAILED
	index = file_index
	return OK

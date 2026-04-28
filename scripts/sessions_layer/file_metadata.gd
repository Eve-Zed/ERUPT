extends RefCounted
class_name FileMetadata

static var metadata_keys := ["hash","size","prio","source"]

enum FileSource 
{
	GLOBAL,
	SHARED_CACHE,
	SESSION_CACHE,
	INVALID
}

var file_hash: String
var size: int
var prio: int
var source: FileSource

func _init(_file_hash: String, _size: int, _prio: int, _source:int) -> void:
	file_hash = _file_hash
	size = _size
	prio = _prio
	source = _source as FileSource

func to_dictionary() -> Dictionary:
	return {
		"hash": file_hash,
		"size": size,
		"prio": prio,
		"source": int(source)
	}

static func create_from_dictionary(dict: Dictionary) -> FileMetadata:
	var d_size := int(dict["size"])
	var d_prio := int(dict["prio"])
	var d_source := int(dict["source"])
	var metadata := FileMetadata.new(dict["hash"], d_size, d_prio, d_source)
	return metadata

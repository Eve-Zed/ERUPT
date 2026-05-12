extends RefCounted
class_name FileMetadata

static var metadata_keys := ["hash","size","prio"]



var file_hash: String
var size: int
var prio: int

func _init(_file_hash: String, _size: int, _prio: int) -> void:
	file_hash = _file_hash
	size = _size
	prio = _prio

func to_dictionary() -> Dictionary:
	return {
		"hash": file_hash,
		"size": size,
		"prio": prio,
	}

static func create_from_dictionary(dict: Dictionary) -> FileMetadata:
	var d_size := int(dict["size"])
	var d_prio := int(dict["prio"])
	var metadata := FileMetadata.new(dict["hash"], d_size, d_prio)
	return metadata

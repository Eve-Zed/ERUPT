extends FileMetadata
class_name ManifestFileMetadata

static var metadata_keys := ["hash","size","prio","global","campaigns","visibility","description","tags"]

var visibility: PackedStringArray
var description: String
var tags: PackedStringArray

func _init(_file_hash: String, _size: int, _prio: int, _global: bool, _campaigns: PackedStringArray, 
_visibility: PackedStringArray, _desciption: String, _tags: PackedStringArray) -> void:
	super(_file_hash, _size, _prio, _global, _campaigns)
	visibility = _visibility
	description = _desciption
	tags = _tags

func to_dictionary() -> Dictionary:
	return {
		metadata_keys[0]: file_hash,
		metadata_keys[1]: size,
		metadata_keys[2]: prio,
		metadata_keys[3]: global,
		metadata_keys[4]: campaigns,
		metadata_keys[5]: visibility,
		metadata_keys[6]: description,
		metadata_keys[7]: tags
	}

static func create_from_dictionary(dict: Dictionary) -> ManifestFileMetadata:
	var d_size := int(dict["size"])
	var d_prio := int(dict["prio"])
	var b_global := bool(dict["global"])
	var metadata := ManifestFileMetadata.new(dict["hash"], d_size, d_prio, b_global, 
	dict["campaigns"], dict["visibility"], dict["description"], dict["tags"])
	return metadata

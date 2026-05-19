extends FileMetadata
class_name IndexMetadata

const KEY_VISIBILITY := "visibility"
const KEY_DESCRIPTION := "desc"
const KEY_TAGS := "tags"

var visibility: PackedStringArray #Array of User/Group IDs - leave empty for no visibility restrictions
var description: String
var tags: PackedStringArray

func _init(_file_hash: String, _priority: int, _campaigns: PackedStringArray, _visibility: PackedStringArray, 
_description: String, _tags: PackedStringArray) -> void:
	file_hash = _file_hash
	priority = _priority
	campaigns = _campaigns
	visibility = _visibility
	description = _description
	tags = _tags

func to_dictionary() -> Dictionary:
	var metadata := {}
	metadata[KEY_HASH] = file_hash
	metadata[KEY_PRIORITY] = priority
	metadata[KEY_CAMPAIGNS] = campaigns
	metadata[KEY_VISIBILITY] = visibility
	metadata[KEY_DESCRIPTION] = description
	metadata[KEY_TAGS] = tags
	return metadata

static func create_from_dictionary(dict: Dictionary) -> IndexMetadata:
	return IndexMetadata.new(
		str(dict.get(KEY_HASH, "")),
		int(dict.get(KEY_PRIORITY, -1)),
		PackedStringArray(dict.get(KEY_CAMPAIGNS, [])),
		PackedStringArray(dict.get(KEY_VISIBILITY, [])),
		str(dict.get(KEY_DESCRIPTION, "")),
		PackedStringArray(dict.get(KEY_TAGS, []))
	)

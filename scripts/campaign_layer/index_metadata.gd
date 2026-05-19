extends FileMetadata
class_name IndexMetadata

const KEYS := ["hash", "prio", "campaigns", "visibility", "desc", "tags"]

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
	metadata[KEYS[0]] = file_hash
	metadata[KEYS[1]] = priority
	metadata[KEYS[2]] = campaigns
	metadata[KEYS[3]] = visibility
	metadata[KEYS[4]] = description
	metadata[KEYS[5]] = tags
	return metadata

static func create_from_dictionary(dict: Dictionary) -> IndexMetadata:
	var _file_hash: String = ""
	if dict.has(KEYS[0]):
		_file_hash = dict[KEYS[0]]
	var _priority: int = -1
	if dict.has(KEYS[1]):
		_priority = int(dict[KEYS[1]])
	var _campaigns: PackedStringArray = []
	if dict.has(KEYS[2]):
		_campaigns = dict[KEYS[2]]
	var _visibility: PackedStringArray = []
	if dict.has(KEYS[3]):
		_visibility = dict[KEYS[3]]
	var _description: String = ""
	if dict.has(KEYS[4]):
		_description = dict[KEYS[4]]
	var _tags: PackedStringArray = []
	if dict.has(KEYS[5]):
		_visibility = dict[KEYS[5]]
	return IndexMetadata.new(_file_hash, _priority, _campaigns, _visibility, _description, _tags)

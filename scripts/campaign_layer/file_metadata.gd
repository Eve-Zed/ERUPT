extends RefCounted
class_name FileMetadata

const KEY_HASH := "hash"
const KEY_PRIORITY := "prio"
const KEY_CAMPAIGNS := "campaigns"

var file_hash: String
var priority: int
var campaigns: PackedStringArray

func to_dictionary() -> Dictionary:
	push_error("to_dictionary() must be implemented")
	return {}

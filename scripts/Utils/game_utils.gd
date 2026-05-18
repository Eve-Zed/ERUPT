extends Node
class_name GameUtils

static var game_version = 0.1

static func generate_uuid_v4() -> String:
	var bytes := PackedByteArray()
	bytes.resize(16)

	for i in range(16):
		bytes[i] = randi() & 0xFF

	# Version 4
	bytes[6] = (bytes[6] & 0x0F) | 0x40
	# Variant
	bytes[8] = (bytes[8] & 0x3F) | 0x80

	var hex := ""
	for i in range(16):
		hex += "%02x" % bytes[i]

	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8),
		hex.substr(8, 4),
		hex.substr(12, 4),
		hex.substr(16, 4),
		hex.substr(20, 12)
	]
	
static func get_priority(file_path: String) -> int:
	#TODO actually write this method
	return 1

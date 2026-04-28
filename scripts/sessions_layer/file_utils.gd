extends Node
class_name FileUtils

static var save_error_prefix := "Failed to save file: "
static var load_error_prefix := "Failed to load file: "
static var load_error := OK

static var hash_chunk_size = 1024

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

static func atomic_save(path: String, data: Variant) -> Error:
	if path.is_empty():
		push_error(save_error_prefix + "Path is empty")
		return ERR_FILE_BAD_PATH
	
	var base_dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(base_dir):
		var err = DirAccess.make_dir_recursive_absolute(base_dir)
		if err != OK:
			push_error(save_error_prefix + "Could not create directory %s (%s)" % [base_dir, err])
			return err
	
	var temp_path := path.get_basename() + ".tmp"
	
	var file := FileAccess.open(temp_path,FileAccess.WRITE)
	if file == null:
		var open_err := FileAccess.get_open_error()
		push_error(save_error_prefix + "Could not open %s (%s)" % [temp_path, open_err])
		return open_err
	
	var result : bool
	# so json files are properly formatted
	if typeof(data) == TYPE_STRING:
		result = file.store_string(data)
	elif typeof(data) == TYPE_PACKED_BYTE_ARRAY:
		result = file.store_buffer(data)
	else:
		result = file.store_var(data)
		
	if not result:
		file.close()
		push_error(save_error_prefix + "Could not write: " + temp_path)
		return ERR_FILE_CANT_WRITE

	file.close()	
	
	if DirAccess.rename_absolute(temp_path, path) != OK:
		push_error(save_error_prefix + "Could not finalize write: " + path)
		DirAccess.remove_absolute(temp_path)
		return Error.ERR_FILE_CANT_WRITE
	
	return OK

static func load_json_file(path: String) -> String:
	if path.is_empty() or not path.ends_with(".json"):
		push_error(load_error_prefix + "Invalid path")
		load_error = ERR_FILE_BAD_PATH
		return ""
	
	if not FileAccess.file_exists(path):
		push_error(load_error_prefix + "Json file does not exist " + path)
		load_error = ERR_FILE_NOT_FOUND
		return ""
	
	var file := FileAccess.open(path,FileAccess.READ)
	if file == null:
		var open_err := FileAccess.get_open_error()
		push_error(load_error_prefix + "Could not open %s (%s)" % [path, open_err])
		load_error = open_err
		return ""
		
	var content := file.get_as_text()
	file.close()
	
	var parsed = JSON.parse_string(content)
	if parsed == null:
		push_error(load_error_prefix + "Could not parse json " + path)
		load_error = Error.ERR_PARSE_ERROR
		return ""
	
	load_error = OK
	return JSON.stringify(parsed)

static func delete_file(path: String) -> Error:
	var err := DirAccess.remove_absolute(path)
	if err != OK:
		push_error("Failed to delete File: " + path)
		return err
	return OK

static func hash_file(path) -> String:
	if not FileAccess.file_exists(path):
		push_error(load_error_prefix + "File does not exist " + path)
		return ""

	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)

	var file := FileAccess.open(path, FileAccess.READ)

	while file.get_position() < file.get_length():
		var remaining = file.get_length() - file.get_position()
		ctx.update(file.get_buffer(min(remaining, hash_chunk_size)))

	var res := ctx.finish()
	
	return res.hex_encode()

static func sanitize_filename(filename: String, max_length: int = 64) -> String:
	if filename.is_empty():
		return "untitled"
	var sanitized := filename.strip_edges().to_lower()
	var result = ""
	for c in sanitized:
		if c.is_valid_filename() and c != ".":
			result += c
		else:
			result += "_"
	sanitized = result.substr(0, max_length)
	return sanitized

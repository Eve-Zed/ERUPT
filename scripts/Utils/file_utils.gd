extends Node
class_name FileUtils

static var save_error_prefix := "Failed to save file: "
static var load_error_prefix := "Failed to load file: "

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

static func load_json_file(path: String) -> Result:
	
	var res = load_file(path)
	
	if res.value == null:
		return Result.new(res.error)
		
	var content = res.value.get_string_from_utf8()
	var parsed = JSON.parse_string(content)
	
	if parsed == null:
		push_error(load_error_prefix + "Could not parse json " + path)
		return Result.new(ERR_PARSE_ERROR)

	return Result.new(OK, JSON.stringify(parsed))

static func load_file(file_path: String) -> Result:
	if file_path.is_empty() or not file_path.is_absolute_path():
		push_error(load_error_prefix + "Invalid path")
		return Result.new(ERR_FILE_BAD_PATH)
	
	if not FileAccess.file_exists(file_path):
		push_error(load_error_prefix + "file does not exist " + file_path)
		return Result.new(ERR_FILE_NOT_FOUND)	
	
	var file := FileAccess.open(file_path,FileAccess.READ)
	if file == null:
		var open_err := FileAccess.get_open_error()
		push_error(load_error_prefix + "Could not open %s (%s)" % [file_path, open_err])
		return Result.new(open_err)
	
	var content := file.get_buffer(file.get_length())
	file.close()
	
	return Result.new(OK, content)

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

static func sanitize_filename(file_name: String, max_length: int = 64) -> String:
	if file_name.is_empty():
		return "untitled"
	var sanitized := file_name.strip_edges().to_lower()
	var result = ""
	for c in sanitized:
		if c.is_valid_filename() and c != ".":
			result += c
		else:
			result += "_"
	sanitized = result.substr(0, max_length)
	return sanitized

static func remove_recursive(directory: String) -> void:
	for dir_name in DirAccess.get_directories_at(directory):
		remove_recursive(directory.path_join(dir_name))
	for file_name in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file_name))
		
	DirAccess.remove_absolute(directory)

static func get_file_priority(file_path: String) -> int:
	#TODO actually write this method
	return 1

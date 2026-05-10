extends ContentRegistry
class_name ContentCache

func _init(path: String) -> void:
	super(path, SessionManager.INDEX_NAME)

func store_file(file_name: String, data: PackedByteArray, prio: int) -> Error:
	var path := get_file_path(file_name)
	
	var write_err := FileUtils.atomic_save(path, data)
	if write_err != OK:
		return write_err
	
	var meta := _build_metadata(path, data.size(), prio)
	if meta == null:
		DirAccess.remove_absolute(path)
		return ERR_FILE_CANT_WRITE
	
	_alter_registry(file_name, meta)
	return OK

func delete_file(file_name: String, file_hash: String) -> Error:
	var path := get_file_path(file_name)
	
	if !has_file(file_name, file_hash):
		push_error("File doesn't exist in index.json " + file_name)
		return ERR_FILE_NOT_FOUND
	
	var err := FileUtils.delete_file(path)
	if err != OK:
		push_error("Failed to delete file " + path)
		return err
		
	if !_delete_registry_entry(file_name):
		push_error("Failed to delete index.json entry")
		return Error.ERR_FILE_NOT_FOUND
		
	return OK

func get_file_hash(file_name: String) -> String:
	#TODO actually implement method
	return ""

func _build_metadata(path: String, size: int, prio: int) -> FileMetadata:
	var file_hash := FileUtils.hash_file(path)
	if file_hash.is_empty():
		push_error("Failed to hash file: " + path)
		return null

	var source := _detect_source(path)
	if source == FileMetadata.FileSource.INVALID:
		push_error("Invalid source for file: " + path)
		return null

	return FileMetadata.new(file_hash, size, prio, source)

func _detect_source(path: String) -> FileMetadata.FileSource:
	if path.begins_with(SessionManager.SESSIONS_PATH):
		return FileMetadata.FileSource.SESSION_CACHE
	if path.begins_with(SessionManager.SHARED_FILES_PATH):
		return FileMetadata.FileSource.SHARED_CACHE
	if path.begins_with(SessionManager.GLOBAL_CACHE_PATH):
		return FileMetadata.FileSource.GLOBAL

	return FileMetadata.FileSource.INVALID

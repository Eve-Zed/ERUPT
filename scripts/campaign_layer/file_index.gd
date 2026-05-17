extends FileRegistry
class_name FileIndex

var manifest_path: String:
	get:
		return root_path.path_join(FileManager.MANIFEST_NAME)

func _init() -> void:
	super(FileManager.FILES_PATH, FileManager.INDEX_NAME, GameUtils.game_version)

func create_manifest(session_id: String) -> Error:
	var result_dict = {}
	result_dict["version"] = version
	result_dict["files"] = {}
	for file in file_registry.keys():
		if file_registry[file].campaigns.has(session_id):
			result_dict["files"][file] = file_registry[file].to_dictionary()
	FileUtils.atomic_save(manifest_path, JSON.stringify(result_dict))
	return OK

func add_file(file_path: String, metadata: FileMetadata) -> void:
	assert(metadata is ManifestFileMetadata)
	var manifest_metadata: ManifestFileMetadata = metadata
	_file_registry[file_path] = manifest_metadata

func alter_file_metadata(file_path: String, metadata: ManifestFileMetadata) -> void:
	if file_registry.has(file_path):
		_file_registry[file_path] = metadata

static func validate_registry(data: Dictionary) -> Error:
	var err := super(data)
	if err != OK:
		return err
	#TODO implement method
	return OK

static func diff(index: FileRegistry, manifest: FileRegistry) -> Dictionary:
	#TODO implement
	return {}

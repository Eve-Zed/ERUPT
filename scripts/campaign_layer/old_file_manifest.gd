extends FileRegistry
class_name FileManifest

#region Enums
enum FileAction {
	DELETE,
	DOWNLOAD,
	UPDATE
}
#endregion

#region Lifecycle
func _init(path: String, registry: Dictionary[String, ManifestFileMetadata]) -> void:
	super(path, FileManager.MANIFEST_NAME)
	_set_registry(registry)
	_locked = true
#endregion

#region Static Functions
static func generate_from_index(index: FileIndex) -> Result:
	if index == null:
		push_error("Failed to generate manifest: Index does not exist")
		return Result.new(ERR_DOES_NOT_EXIST)
	
	var manifest := FileManifest.new(index.root_path, index.file_registry)
	return Result.new(OK, manifest)

static func diff(manifest: FileManifest, cache: FileIndex) -> Dictionary[String, FileAction]:
	var result_dict: Dictionary[String, FileAction] = {}
	var index := cache.file_registry
	for file in manifest.file_registry:
		if index.has(file):
			if manifest.file_registry[file] != index[file]:
				result_dict[file] = FileAction.UPDATE
			index.erase(file)
		else:
			result_dict[file] = FileAction.DOWNLOAD
	for file in index:
		result_dict[file] = FileAction.DELETE
	return result_dict
#endregion

extends ContentRegistry
## Represents the authoritative list of files shared within a session.
##
## A ContentManifest defines which files should exist for a synchronized session.
## It is generated from a [ContentCache] (index) and distributed to peers.
## [br][b]Note:[/b] Manifests are locked and immutable after creation.
class_name ContentManifest

#region Enums
## Used when computing differences between a manifest and a [ContentCache].
##
## [br][color=lightblue]DELETE[/color]: File exists locally but is not present in the manifest.
## [br][color=lightblue]DOWNLOAD[/color]: File exists in the manifest but not locally.
## [br][color=lightblue]UPDATE[/color]: File exists in both locations but metadata differs.
enum FileAction {
	DELETE,
	DOWNLOAD,
	UPDATE
}
#endregion

#region Lifecycle
## Creates a new ContentManifest.
## [br][b]Note:[/b] Don't use this constructor directly, generate a manifest with a [ContentCache] 
## by calling [method generate_from_index] instead
func _init(path: String, registry: Dictionary[String, FileMetadata]) -> void:
	super(path, SessionManager.MANIFEST_NAME)
	_set_registry(registry)
	_locked = true
#endregion

#region Static Functions
## Used by the session host to generate the authoritative manifest before distributing it to peers.
## [br][br][b]Parameters:[/b]
## [br][param index]: The source [ContentCache].
## [br][br][b]Returns:[/b]
## [br][Result](OK, ContentManifest) on success.
## [br][Result](ERR_DOES_NOT_EXIST) if index is null.
static func generate_from_index(index: ContentCache) -> Result:
	if index == null:
		push_error("Failed to generate manifest: Index does not exist")
		return Result.new(ERR_DOES_NOT_EXIST)
	
	var manifest := ContentManifest.new(index.root_path, index.file_registry)
	return Result.new(OK, manifest)

## Computes the difference between a manifest and a local cache. This includes files that don't exist
## in the cache, files that have differing metadata and files that are not in the manifest but the cache.
## [br][br][b]Parameters[/b]
## [br][param manifest]: The authoritative session manifest.
## [br][param cache]: The local [ContentCache]
## [br][br][b]Returns:[/b]
## [br]A [Dictionary] mapping file paths ([String]) to [enum FileAction] values.
static func diff(manifest: ContentManifest, cache: ContentCache) -> Dictionary[String, FileAction]:
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

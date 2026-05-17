extends FileRegistry
class_name FileIndex

#TODO Add necessary FileREgistry overwrites

func create_manifest( session_id: String) -> Error:
	#TODO implement
	return OK

static func diff_from_paths(index_path: String, manifest_path: String) -> Dictionary:
	#TODO load path and creates Fileregistries
	var index: FileRegistry
	var manifest: FileRegistry
	return diff(index, manifest)

static func diff(index: FileRegistry, manifest: FileRegistry) -> Dictionary:
	#TODO implement
	return {}

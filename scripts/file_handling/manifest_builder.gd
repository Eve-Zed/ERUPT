extends Node
class_name ManifestBuilder

const MANIFEST_NAME_SUFFIX := ".json" #Will be created for each campaign and user to handle file sharing, CampaignID + UserID + Suffix

static func build_manifest(campaign_id: String, user_id: String) -> Dictionary:
	var visibility_ids := [user_id]
	#TODO look up in which groups user is and add group ids to array
	var campaigns := PackedStringArray([campaign_id])
	var manifest: Dictionary[String, Dictionary] = {}
	for path: String in FileManager.file_index:
		var metadata := FileManager.get_file_metadata(path)
		if metadata != null:
			# empty campaigns means global | empty visibility means visible to everyone
			if metadata.campaigns.is_empty() or metadata.campaigns.has(campaign_id):
				#TODO evaluate if arrays_share_value becomes a perfomance concern
				if metadata.visibility.is_empty() or GameUtils.arrays_share_value(metadata.visibility, visibility_ids):
					manifest[metadata.file_hash] = ManifestMetadata.new(
						path.get_file().get_basename(), 
						metadata.priority, 
						FileUtils.get_file_size(path), 
						campaigns
					).to_dictionary()
	return manifest

static func save_manifest(campaign_id: String, user_id: String) -> Error:
	var manifest := build_manifest(campaign_id, user_id)
	
	var manifest_name := campaign_id + "_" + user_id + MANIFEST_NAME_SUFFIX
	var manifest_path := FileManager.FILES_PATH.path_join(manifest_name)
	
	return FileUtils.atomic_save(manifest_path, JSON.stringify(manifest))

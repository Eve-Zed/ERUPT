extends Node
class_name ManifestBuilder

const MANIFEST_NAME_SUFFIX := ".json" #Will be created for each campaign and user to handle file sharing, CampaignID + UserID + Suffix

#for dependency injection to make unit testing easier
static var file_manager_class := FileManager

static func build_manifest(campaign_id: String, user_id: String) -> Dictionary:
    var visibility_ids := [user_id]
    #TODO look up in which groups user is and add group ids to array
    var campaign := PackedStringArray([campaign_id])
    var manifest: Dictionary[String, Dictionary] = {}
    for path: String in file_manager_class.file_index:
        var metadata := file_manager_class.get_file_metadata(path)
        if metadata != null:
            # empty campaigns means global | empty visibility means visible to everyone
            if metadata.campaigns.is_empty() or metadata.campaigns.has(campaign_id):
                #TODO evaluate if arrays_share_value becomes a perfomance concern
                if metadata.visibility.is_empty() or GameUtils.arrays_share_value(metadata.visibility, visibility_ids):
                    manifest[metadata.file_hash] = ManifestMetadata.new(
                        path.get_file().get_basename(), 
                        metadata.priority, 
                        FileUtils.get_file_size(path), 
                        campaign
                    ).to_dictionary()
    return manifest

static func save_manifest(campaign_id: String, user_id: String) -> Error:
    var manifest := build_manifest(campaign_id, user_id)
    
    var manifest_name := campaign_id + "_" + user_id + MANIFEST_NAME_SUFFIX
    var manifest_path := file_manager_class.files_path.path_join(manifest_name)
    
    return FileUtils.atomic_save(manifest_path, JSON.stringify(manifest))

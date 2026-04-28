extends Node



func _ready() -> void:
	randomize()
	
	var session = Session.load_session("user://sessions/ravnica__wings_of_dept").value as Session

	session.cache._delete_registry_entry("explosion.wav")
	session.cache._file_registry["testfile.idk"] = FileMetadata.new("fsdfsdfs",3,2,1)
	
	var diff = ContentManifest.diff(session.manifest,session.cache)
	print(str(diff))

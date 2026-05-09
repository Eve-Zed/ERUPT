extends Node



func _ready() -> void:
	print(FileUtils.load_json_file("user://sessions/ravnica__wings_of_dept/index.json").value)

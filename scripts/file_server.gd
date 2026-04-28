extends Node

var server := TCPServer.new()
var peers: Array[StreamPeerTCP] = []

func _ready():
	var err = server.listen(8080)
	if err == OK:
		print("Server listening on 8080")
	else:
		print("Failed to start server")

func _process(_delta):
	if server.is_connection_available():
		var peer = server.take_connection()
		peers.append(peer)
		print("Client connected")

	for peer in peers:
		if peer.get_available_bytes() > 0:
			receive_file(peer)

func receive_file(peer: StreamPeerTCP):
	# 1. Read filename length
	var name_len = peer.get_32()
	var filename = peer.get_data(name_len)[1].get_string_from_utf8()

	# 2. Read file size
	var file_size = peer.get_64()

	# 3. Read file bytes
	var file_bytes = peer.get_data(file_size)[1]

	var file = FileAccess.open("user://%s" % filename, FileAccess.WRITE)
	file.store_buffer(file_bytes)
	file.close()

	print("File received:", filename)

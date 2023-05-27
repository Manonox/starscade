extends Node


var port : int = 31337

func start_dedicated_server() -> Error:
	var server_enet := ENetMultiplayerPeer.new()
	var err := server_enet.create_server(port)
	if err != OK:
		return err
	DedicatedServer.multiplayer.multiplayer_peer = server_enet
	return OK


func connect_to_localhost() -> Error:
	return connect_to("127.0.0.1")


func connect_to(ip: String) -> Error:
	var client_enet := ENetMultiplayerPeer.new()
	var err := client_enet.create_client(ip, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = client_enet
	return OK

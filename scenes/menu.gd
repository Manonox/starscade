extends Node


@export var game_scene : PackedScene


func _ready():	
	var server_multiplayer := MultiplayerAPI.create_default_interface()
	server_multiplayer.server_relay = false
	DedicatedServer.set_multiplayer(server_multiplayer)
	var client_multiplayer := MultiplayerAPI.create_default_interface()
	get_tree().set_multiplayer(client_multiplayer)
	
	Net.port = 31337
	
	# play_singleplayer()


func play_singleplayer() -> void:
	Net.start_dedicated_server()
	DedicatedServer.load_scene(game_scene)
	get_tree().change_scene_to_packed(game_scene)

	get_tree().create_timer(0.1).timeout.connect(func():
		Net.connect_to_localhost()
		#DedicatedServer.multiplayer.multiplayer_peer.refuse_new_connections = true
	)

func play_host() -> void:
	Net.start_dedicated_server()
	DedicatedServer.load_scene(game_scene)
	get_tree().change_scene_to_packed(game_scene)
	
	get_tree().create_timer(0.1).timeout.connect(func():
		Net.connect_to_localhost()
	)

func play_connect(ip: String) -> void:
	get_tree().change_scene_to_packed(game_scene)
	
	get_tree().create_timer(0.1).timeout.connect(func():
		Net.connect_to(ip)
	)


func _on_connect_pressed() -> void:
	var ip : String = %IP.text
	if ip == "":
		ip = "127.0.0.1"
	play_connect(ip)

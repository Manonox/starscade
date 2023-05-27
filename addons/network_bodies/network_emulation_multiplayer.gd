extends MultiplayerAPIExtension
class_name NetworkEmulationMultiplayer


var base_multiplayer = SceneMultiplayer.new()
var parameters : NetworkEmulationParameters = NetworkEmulationParameters.new()

func _init():
	var cts = connected_to_server
	var cf = connection_failed
	var pc = peer_connected
	var pd = peer_disconnected
	base_multiplayer.connected_to_server.connect(func(): cts.emit())
	base_multiplayer.connection_failed.connect(func(): cf.emit())
	base_multiplayer.peer_connected.connect(func(id): pc.emit(id))
	base_multiplayer.peer_disconnected.connect(func(id): pd.emit(id))


func _rpc(peer: int, object: Object, method: StringName, args: Array) -> Error:
	var time := parameters.get_fake_ping() / 1000.0
	#if time > 0.0:
	await object.get_tree().create_timer(time).timeout
	
	while randf() < parameters.duplicate_chance:
		await object.get_tree().create_timer(0.005).timeout
		if randf() < parameters.drop_chance:
			continue
		base_multiplayer.rpc(peer, object, method, args)
		
	if randf() < parameters.drop_chance:
		return OK
	return base_multiplayer.rpc(peer, object, method, args)

func _object_configuration_add(object, config: Variant) -> Error:
	return base_multiplayer.object_configuration_add(object, config)

func _object_configuration_remove(object, config: Variant) -> Error:
	return base_multiplayer.object_configuration_remove(object, config)

func _set_multiplayer_peer(p_peer: MultiplayerPeer):
	base_multiplayer.multiplayer_peer = p_peer

func _get_multiplayer_peer() -> MultiplayerPeer:
	return base_multiplayer.multiplayer_peer

func _get_unique_id() -> int:
	return base_multiplayer.get_unique_id()

func _get_peer_ids() -> PackedInt32Array:
	return base_multiplayer.get_peers()

func _get_remote_sender_id() -> int:
	return base_multiplayer.get_remote_sender_id()

func _poll() -> Error:
	return base_multiplayer.poll()

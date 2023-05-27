extends Node


var _map := {}


func _input(event: InputEvent) -> void:
	if multiplayer.is_server(): return
	if event.is_action_released("undo"):
		rpc_id(1, &"_server_undo_request")
		get_viewport().set_input_as_handled()


func push(playerOrId, nodes: Array) -> void:
	var id := 0
	if playerOrId is Player:
		id = playerOrId.peer_id
	elif playerOrId is int:
		id = playerOrId
	else:
		push_error("Undo.push argument #1 must be a player id or a player")
	
	if not _map.has(id):
		_map[id] = []
	var array : Array = _map[id]
	array.push_back(nodes)


func pop(playerOrId) -> void:
	var id := 0
	if playerOrId is Player:
		id = playerOrId.peer_id
	elif playerOrId is int:
		id = playerOrId
	else:
		push_error("Undo.pop argument #1 must be a player id or a player")

	if not _map.has(id):
		return
	var array : Array = _map[id]
	var nodes = array.pop_back()
	if nodes == null:
		return
	
	for node in nodes:
		if node is Node:
			rpc(&"_client_remove_node", get_path_to(node))


@rpc("call_local", "reliable")
func _client_remove_node(path: NodePath) -> void:
	var node := get_node_or_null(path)
	if node == null:
		return
	
	var parent := node.get_parent()
	if parent == null:
		return
	
	parent.remove_child(node)
	node.queue_free()


@rpc("any_peer", "call_remote", "reliable")
func _server_undo_request() -> void:
	pop(multiplayer.get_remote_sender_id())

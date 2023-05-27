extends Node


func get_game_instance(node: Node) -> Game:
	if node == null:
		return null
	while not (node is Game):
		node = node.get_parent()
		if node == null:
			return null
	return node


var _luau_component_cache := {}
func get_luau_component(node: Node) -> LuauComponent:
	if _luau_component_cache.has(node):
		return _luau_component_cache[node]
	
	for child in node.get_children():
		if child is LuauComponent:
			_luau_component_cache[node] = child
			return child
	return null

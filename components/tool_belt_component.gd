extends Node
class_name ToolBeltComponent


@export var player : Player

var selected_tool := -1:
	set(value):
		_send_swap(selected_tool, value)
		selected_tool = value


func use(mouse_button: int, pressed: bool) -> void:
	_send_use(selected_tool, mouse_button, pressed)


func _tool_is_valid(tool: int) -> bool:
	if tool < 0: return false
	if tool >= get_child_count(): return false
	return true


func _send_use(tool: int, mouse_button: int, pressed: bool) -> void:
	if not _tool_is_valid(tool): return
	var child = get_child(tool)
	child.use(player, mouse_button, pressed)


func _send_swap(old_tool: int, new_tool: int) -> void:
	if _tool_is_valid(old_tool):
		get_child(old_tool).unequip(player)
	if _tool_is_valid(new_tool):
		get_child(new_tool).equip(player)

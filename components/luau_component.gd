extends Node
class_name LuauComponent


@export var metatable_name : String


func is_registered(luau_script: LuauScript) -> bool:
	return luau_script.registered_metatables.has(metatable_name)

func register(luau_script: LuauScript) -> void:
	luau_script.registered_metatables[metatable_name] = true
	var luau_vm := luau_script.luau_vm
	luau_vm.newmetatable(metatable_name)
	# ... 

func push(luau_script: LuauScript) -> void:
	pass
	#luau_vm.

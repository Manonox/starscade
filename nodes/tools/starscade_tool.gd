extends Node


func use(player: Player, mouse_button: int, pressed: bool) -> void:
	if not pressed: return
	
	var luau_editor_visible : bool = LuauEditor.visible
	if mouse_button == MOUSE_BUTTON_RIGHT and not luau_editor_visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		LuauEditor.open()
	
	if mouse_button == MOUSE_BUTTON_LEFT:
		var game := Starscade.get_game_instance(player)
		if game == null: return
		
		var code := LuauEditor.get_content()
		var dict := {
			code = code
		}
		
		game.script_creator.send_project_to_server(dict)

func equip(player: Player) -> void:
	pass

func unequip(player: Player) -> void:
	pass

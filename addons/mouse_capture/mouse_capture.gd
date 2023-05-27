extends Control


@export_flags("Left", "Right", "Middle") var button_mask: int

func _gui_input(event):
	if event is InputEventMouseButton:
		var i : int = 2 ** (event.button_index - 1)
		if i & button_mask > 0:
			capture()


func capture() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

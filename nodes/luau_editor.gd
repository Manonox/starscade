extends Panel


@onready var code_edit = %CodeEdit

func _ready():
	visible = false


func open() -> void:
	visible = true
	move_to_front()
	code_edit.grab_focus()


func close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func get_content() -> String:
	return code_edit.text

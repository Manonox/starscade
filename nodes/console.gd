extends Control


const HISTORY_SIZE := 512
const OVERLAY_HISTORY_SIZE := 16

@export var stdout_server_color : Color
@export var stdout_client_color : Color

var main_message_history := History.new(HISTORY_SIZE)
var overlay_message_history := History.new(OVERLAY_HISTORY_SIZE)
var last_scroll_bar_value := 0.0
var current_message_index := 0
var last_message_index := 0

@onready var overlay = %Overlay
@onready var main_control = $MainControl
@onready var main = %Main
@onready var animation_player = %AnimationPlayer
@onready var scroll_bar : VScrollBar = main.get_v_scroll_bar()
@onready var back_to_present_button = %BackToPresentButton
@onready var main_panel = $MainControl/MainPanel


func _ready():
	main_panel.set_deferred(&"size", Vector2(get_viewport().size) * Vector2(1.0, 0.66))
	main.finished.connect(self._fix_scroll_bar)

func _process(delta: float) -> void:
	_update_main()


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("console"):
		if not main_control.visible:
			open()
		else:
			close()
		accept_event()


func open() -> void:
	overlay.visible = false
	animation_player.play("main_open")
	scroll_bar.value = scroll_bar.max_value
	move_to_front()
	LuauEditor.close()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	overlay.visible = true
	animation_player.play("main_close")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func push_overlay(s: String) -> void:
	overlay_message_history.append(s)
	_update_overlay()

func push_log(s: String, is_serverside: bool) -> void:
	main_message_history.append([s, is_serverside])
	current_message_index += 1


func _update_main() -> void:
	last_scroll_bar_value = scroll_bar.value
	back_to_present_button.visible = scroll_bar.value < scroll_bar.max_value - scroll_bar.page
	
	var arr := main_message_history.get_head()
	arr.reverse()
	main.clear()
	for pair in arr:
		var color := stdout_server_color if pair[1] else stdout_client_color
		main.push_color(color)
		main.add_text(pair[0])
		main.newline()
		main.pop()


func _update_overlay() -> void:
	var text := ""
	var messages := overlay_message_history.get_head()
	messages.reverse()
	for message in messages:
		text += message + "\n"
	text = text.replace("\t", "    ")
	overlay.text = text


func _fix_scroll_bar() -> void:
	var offset := 0.0
	if not main.scroll_following:
		if scroll_bar.value < scroll_bar.max_value - scroll_bar.page:
			offset = current_message_index - last_message_index
			offset = maxf(offset, 0.0)
		else:
			main.scroll_following = true
		var newvalue := last_scroll_bar_value - offset * 20.0
		if newvalue < 0.0:
			newvalue = scroll_bar.max_value
			main.scroll_following = true
		scroll_bar.value = newvalue
	else:
		scroll_bar.value = scroll_bar.max_value
	last_message_index = current_message_index


func _on_main_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			main.scroll_following = false


func _on_back_to_present_button_pressed():
	scroll_bar.value = scroll_bar.max_value
	main.scroll_following = true

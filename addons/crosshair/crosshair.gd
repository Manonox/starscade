@tool
extends Marker2D
class_name Crosshair


@export var enabled : bool = true :
	set(value): enabled = value; queue_redraw()

@export var color : Color = Color(1.0, 1.0, 1.0, 1.0) :
	set(value): color = value; queue_redraw()

@export_range(1, 20, 1) var length : int = 3 :
	set(value): length = value; queue_redraw()
@export_range(1, 20, 1) var thickness : int = 2 :
	set(value): thickness = value; queue_redraw()
@export_range(1, 20, 1) var gap : int = 2 :
	set(value): gap = value; queue_redraw()


func _ready():
	queue_redraw()

func _draw():
	if !enabled:
		return
	
	var oddity : int = thickness % 2

	draw_rect(Rect2(-(thickness+1) / 2, -gap, thickness, -length).abs(), color, true) # Top
	draw_rect(Rect2(-(thickness+1) / 2, gap-oddity, thickness, length).abs(), color, true) # Down
	draw_rect(Rect2(-gap, -(thickness+1) / 2, -length, thickness).abs(), color, true) # Left
	draw_rect(Rect2(gap-oddity, -(thickness+1) / 2, length, thickness).abs(), color, true) # Right

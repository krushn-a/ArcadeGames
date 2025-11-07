extends Node2D

@onready var area := $Area2D

var dragging := false
var offset := Vector2.ZERO

func _ready():
	# Ensure Area2D is set up for input
	area.input_pickable = true

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			offset = global_position - get_global_mouse_position()
			dragging = true
			print("Started dragging:", name)
		else:
			dragging = false
			print("Stopped dragging:", name)

func _process(delta):
	if dragging:
		global_position = get_global_mouse_position() + offset

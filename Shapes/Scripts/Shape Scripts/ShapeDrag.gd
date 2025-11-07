extends Node2D

# This script is disabled - dragging is handled by InputManager autoload
# If you want to use this script instead, disable InputManager in Project Settings > Autoload

@onready var area := $Area2D

var dragging := false
var offset := Vector2.ZERO

func _ready():
	# Disable input on Area2D since InputManager handles it
	area.input_pickable = false
	set_process(false)

# Disabled - InputManager handles dragging
#func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int):
#	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
#		if event.pressed:
#			offset = global_position - get_global_mouse_position()
#			dragging = true
#			print("Started dragging:", name)
#		else:
#			dragging = false
#			print("Stopped dragging:", name)
#
#func _process(delta):
#	if dragging:
#		global_position = get_global_mouse_position() + offset

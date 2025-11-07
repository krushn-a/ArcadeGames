extends Node

func _ready():
	print("InputManager ready and active.")

func _unhandled_input(event):
	if event.is_action_pressed("Mouse_click_drag"):
		print("Mouse click drag pressed!")
	elif event.is_action_released("Mouse_click_drag"):
		print("Mouse click drag released!")

	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		print("Mouse is dragging at:", event.position)
func _process(_delta):
	if Input.is_action_pressed("Mouse_click_drag"):
		print("Holding drag button...")

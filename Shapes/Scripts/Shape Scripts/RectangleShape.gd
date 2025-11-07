extends Area2D

@export var shape_id: String = "rectangle"
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var sprite: Sprite2D = $Sprite2D

var dragging := false
var offset := Vector2.ZERO
var initial_scale := Vector2.ONE

func _ready():
	add_to_group("shapes")
	initial_scale = scale

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			offset = global_position - get_global_mouse_position()
		else:
			dragging = false

func _process(_delta):
	if dragging:
		global_position = get_global_mouse_position() + offset

	if Input.is_action_just_pressed("rotate_shape"):
		rotation += deg_to_rad(15)

	if Input.is_action_pressed("scale_up"):
		scale = initial_scale * 1.2
	elif Input.is_action_pressed("scale_down"):
		scale = initial_scale * 0.8

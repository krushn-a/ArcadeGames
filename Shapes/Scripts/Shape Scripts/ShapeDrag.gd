extends Node2D

@onready var area := $Area2D

# State variables
var is_selected: bool = false
var interaction_mode: String = "none"  # "none", "drag", "rotate"
var drag_offset: Vector2 = Vector2.ZERO

# Target values for smooth interpolation
var target_scale: Vector2 = Vector2.ONE
var target_rotation: float = 0.0

# Scale limits
const MIN_SCALE: float = 0.3
const MAX_SCALE: float = 2.0
const SCALE_SPEED: float = 0.15

# Rotation settings
const ROTATION_SPEED: float = 0.2

# Pinch-to-zoom for mobile
var touch_points: Dictionary = {}
var initial_pinch_distance: float = 0.0
var initial_scale: Vector2 = Vector2.ONE
var is_pinching: bool = false

func _ready():
	# Initialize target values
	target_scale = scale
	target_rotation = rotation
	area.input_pickable = false  # InputManager handles selection

func _process(delta):
	# Smooth interpolation for scale and rotation
	scale = scale.lerp(target_scale, SCALE_SPEED)
	rotation = lerp_angle(rotation, target_rotation, ROTATION_SPEED)
	
	# Handle dragging
	if interaction_mode == "drag":
		var mouse_pos = get_global_mouse_position_with_camera()
		global_position = mouse_pos + drag_offset

func _input(event):
	if not is_selected:
		return
	
	# Handle pinch-to-zoom for mobile
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
			if touch_points.size() == 2:
				is_pinching = true
				var touches = touch_points.values()
				initial_pinch_distance = touches[0].distance_to(touches[1])
				initial_scale = scale
		else:
			touch_points.erase(event.index)
			if touch_points.size() < 2:
				is_pinching = false
	
	elif event is InputEventScreenDrag:
		touch_points[event.index] = event.position
		if is_pinching and touch_points.size() == 2:
			var touches = touch_points.values()
			var current_distance = touches[0].distance_to(touches[1])
			var scale_factor = current_distance / initial_pinch_distance
			var new_scale = initial_scale * scale_factor
			new_scale.x = clamp(new_scale.x, MIN_SCALE, MAX_SCALE)
			new_scale.y = clamp(new_scale.y, MIN_SCALE, MAX_SCALE)
			target_scale = new_scale

# Called by InputManager when mode changes
func set_interaction_mode(mode: String):
	interaction_mode = mode
	if mode == "drag":
		var mouse_pos = get_global_mouse_position_with_camera()
		drag_offset = global_position - mouse_pos

# Public methods called by InputManager
func scale_by(delta: float):
	target_scale = target_scale + Vector2(delta, delta)
	target_scale.x = clamp(target_scale.x, MIN_SCALE, MAX_SCALE)
	target_scale.y = clamp(target_scale.y, MIN_SCALE, MAX_SCALE)

func rotate_by(degrees: float):
	target_rotation += deg_to_rad(degrees)

func get_global_mouse_position_with_camera() -> Vector2:
	var viewport = get_viewport()
	var camera = viewport.get_camera_2d()
	var mouse_pos = viewport.get_mouse_position()
	
	if camera:
		return camera.get_global_mouse_position()
	else:
		return viewport.get_global_canvas_transform().affine_inverse() * mouse_pos

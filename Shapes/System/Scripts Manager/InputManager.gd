extends Node

var selected_shape: Node2D = null
var offset: Vector2
var target_scale: Vector2 = Vector2.ONE  # Target scale for smooth interpolation

# Pinch-to-zoom tracking
var touch_points: Dictionary = {}  # Dictionary to track touch positions
var initial_pinch_distance: float = 0.0
var initial_scale: Vector2 = Vector2.ONE
var is_pinching: bool = false

# Scale limits
const MIN_SCALE: float = 0.3
const MAX_SCALE: float = 2.0
const SCALE_STEP: float = 0.05  # Smaller step for smoother scaling
const SCALE_SPEED: float = 0.15  # Interpolation speed for smooth transitions

func _ready():
	# Fix CollisionPolygon2D build_mode for Area2D shapes
	await get_tree().process_frame
	for node in get_tree().get_nodes_in_group("draggable"):
		for child in node.get_children():
			if child is Area2D:
				for collision_child in child.get_children():
					if collision_child is CollisionPolygon2D:
						# Fix: Change build_mode from 1 (segments) to 0 (solids) for Area2D
						if collision_child.build_mode == 1:
							collision_child.build_mode = 0

func _process(delta):
	# Smoothly interpolate scale for selected shape
	if selected_shape:
		selected_shape.scale = selected_shape.scale.lerp(target_scale, SCALE_SPEED)

func _unhandled_input(event):
	if event.is_action_pressed("Mouse_click_drag"):
		# Get viewport and camera
		var viewport = get_viewport()
		var camera = viewport.get_camera_2d()
		
		# Get mouse position in world coordinates
		var mouse_pos = viewport.get_mouse_position()
		var global_mouse_pos: Vector2
		
		if camera:
			# If there's a camera, transform through it
			global_mouse_pos = camera.get_global_mouse_position()
		else:
			# No camera, use canvas transform
			global_mouse_pos = viewport.get_global_canvas_transform().affine_inverse() * mouse_pos
		
		# Get the current scene tree
		var space_state = get_tree().root.get_world_2d().direct_space_state
		
		var params = PhysicsPointQueryParameters2D.new()
		params.position = global_mouse_pos
		params.collide_with_areas = true
		params.collide_with_bodies = false
		params.collision_mask = 1  # Layer 1

		var results = space_state.intersect_point(params)

		if results.size() > 0:
			# Find the topmost draggable shape (highest z_index or scene tree order)
			var topmost_shape: Node2D = null
			var topmost_z_index = -999999
			var topmost_tree_index = -1
			
			for res in results:
				# Check if the Area2D's parent is in the draggable group
				var parent = res.collider.get_parent()
				if parent and parent.is_in_group("draggable"):
					var shape_z = parent.z_index
					var shape_tree_index = parent.get_index()
					
					# Compare by z_index first, then by tree index if z_index is the same
					if topmost_shape == null or shape_z > topmost_z_index or (shape_z == topmost_z_index and shape_tree_index > topmost_tree_index):
						topmost_shape = parent
						topmost_z_index = shape_z
						topmost_tree_index = shape_tree_index
			
			if topmost_shape:
				selected_shape = topmost_shape
				offset = selected_shape.global_position - global_mouse_pos
				target_scale = selected_shape.scale  # Initialize target scale
				
				# Bring selected shape to front by moving it to the end of parent's children
				var parent = selected_shape.get_parent()
				if parent:
					parent.move_child(selected_shape, parent.get_child_count() - 1)
				return

	elif event.is_action_released("Mouse_click_drag"):
		selected_shape = null

	elif event is InputEventMouseMotion and selected_shape:
		var viewport = get_viewport()
		var camera = viewport.get_camera_2d()
		var global_mouse_pos: Vector2
		
		if camera:
			global_mouse_pos = camera.get_global_mouse_position()
		else:
			global_mouse_pos = viewport.get_global_canvas_transform().affine_inverse() * event.position
		
		selected_shape.global_position = global_mouse_pos + offset
	
	# Handle pinch-to-zoom for mobile
	elif event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
			# If we have 2 touches, start pinch detection
			if touch_points.size() == 2 and selected_shape:
				is_pinching = true
				var touches = touch_points.values()
				initial_pinch_distance = touches[0].distance_to(touches[1])
				initial_scale = selected_shape.scale
		else:
			touch_points.erase(event.index)
			if touch_points.size() < 2:
				is_pinching = false
	
	elif event is InputEventScreenDrag:
		touch_points[event.index] = event.position
		# Update pinch zoom if we have 2 fingers
		if is_pinching and touch_points.size() == 2 and selected_shape:
			var touches = touch_points.values()
			var current_distance = touches[0].distance_to(touches[1])
			var scale_factor = current_distance / initial_pinch_distance
			var new_scale = initial_scale * scale_factor
			# Clamp scale to maintain aspect ratio
			new_scale.x = clamp(new_scale.x, MIN_SCALE, MAX_SCALE)
			new_scale.y = clamp(new_scale.y, MIN_SCALE, MAX_SCALE)
			selected_shape.scale = new_scale
	
	# Desktop: Mouse wheel to scale
	elif event is InputEventMouseButton and selected_shape:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			scale_shape(selected_shape, SCALE_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			scale_shape(selected_shape, -SCALE_STEP)
	
	# Desktop: Keyboard shortcuts for scaling
	elif event is InputEventKey and selected_shape and event.pressed and not event.echo:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:  # + key
			scale_shape(selected_shape, SCALE_STEP)
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:  # - key
			scale_shape(selected_shape, -SCALE_STEP)

# Helper function to scale shape uniformly
func scale_shape(shape: Node2D, delta: float):
	# Update target scale instead of directly changing scale
	target_scale = target_scale + Vector2(delta, delta)
	target_scale.x = clamp(target_scale.x, MIN_SCALE, MAX_SCALE)
	target_scale.y = clamp(target_scale.y, MIN_SCALE, MAX_SCALE)

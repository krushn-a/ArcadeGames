extends Node

var selected_shape: Node2D = null

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

func _unhandled_input(event):
	# Left-click to select shape for dragging/scaling
	if event.is_action_pressed("Mouse_click_drag"):
		var shape = get_shape_at_position(get_global_mouse_position())
		if shape:
			if selected_shape and selected_shape != shape:
				# Deselect previous shape
				selected_shape.set("is_selected", false)
				selected_shape.set("interaction_mode", "none")
			
			selected_shape = shape
			selected_shape.set("is_selected", true)
			selected_shape.set("interaction_mode", "drag")
			bring_to_front(selected_shape)
	
	elif event.is_action_released("Mouse_click_drag"):
		if selected_shape:
			selected_shape.set("interaction_mode", "none")
	
	# Right-click to select shape for rotation
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			var shape = get_shape_at_position(get_global_mouse_position())
			if shape:
				if selected_shape and selected_shape != shape:
					selected_shape.set("is_selected", false)
					selected_shape.set("interaction_mode", "none")
				
				selected_shape = shape
				selected_shape.set("is_selected", true)
				selected_shape.set("interaction_mode", "rotate")
				bring_to_front(selected_shape)
		else:
			if selected_shape:
				selected_shape.set("interaction_mode", "none")
	
	# Mouse wheel for scaling/rotating
	elif event is InputEventMouseButton and selected_shape:
		var mode = selected_shape.get("interaction_mode")
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			if mode == "rotate":
				selected_shape.call("rotate_by", 15.0)
			else:
				selected_shape.call("scale_by", 0.05)
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			if mode == "rotate":
				selected_shape.call("rotate_by", -15.0)
			else:
				selected_shape.call("scale_by", -0.05)

func get_global_mouse_position() -> Vector2:
	var viewport = get_viewport()
	var camera = viewport.get_camera_2d()
	var mouse_pos = viewport.get_mouse_position()
	
	if camera:
		return camera.get_global_mouse_position()
	else:
		return viewport.get_global_canvas_transform().affine_inverse() * mouse_pos

func get_shape_at_position(global_pos: Vector2) -> Node2D:
	var space_state = get_tree().root.get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = global_pos
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.collision_mask = 1

	var results = space_state.intersect_point(params)
	
	if results.size() > 0:
		# Find topmost shape
		var topmost_shape: Node2D = null
		var topmost_z_index = -999999
		var topmost_tree_index = -1
		
		for res in results:
			var parent = res.collider.get_parent()
			if parent and parent.is_in_group("draggable"):
				var shape_z = parent.z_index
				var shape_tree_index = parent.get_index()
				
				if topmost_shape == null or shape_z > topmost_z_index or (shape_z == topmost_z_index and shape_tree_index > topmost_tree_index):
					topmost_shape = parent
					topmost_z_index = shape_z
					topmost_tree_index = shape_tree_index
		
		return topmost_shape
	
	return null

func bring_to_front(shape: Node2D):
	var parent = shape.get_parent()
	if parent:
		parent.move_child(shape, parent.get_child_count() - 1)

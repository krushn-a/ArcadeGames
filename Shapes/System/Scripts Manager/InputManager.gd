extends Node

var selected_shape: Node2D = null
var offset: Vector2

func _ready():
	# Debug: Print all Area2D nodes in the scene
	await get_tree().process_frame
	print("\n=== Debugging Area2D nodes ===")
	for node in get_tree().get_nodes_in_group("draggable"):
		print("Draggable node:", node.name, "at position:", node.global_position)
		for child in node.get_children():
			if child is Area2D:
				print("  - Has Area2D child:", child.name, "at global pos:", child.global_position)
				print("    Collision layer:", child.collision_layer)
				print("    Collision mask:", child.collision_mask)
				print("    Monitorable:", child.monitorable)
				print("    Monitoring:", child.monitoring)
				for collision_child in child.get_children():
					if collision_child is CollisionPolygon2D:
						print("    - Collision shape:", collision_child.name, "at global pos:", collision_child.global_position)
						print("      Local position:", collision_child.position)
						print("      Polygon points:", collision_child.polygon.size(), "disabled:", collision_child.disabled)
						print("      Build mode:", collision_child.build_mode)
						# FIX: Change build_mode from 1 (segments) to 0 (solids) for Area2D
						if collision_child.build_mode == 1:
							print("      WARNING: Fixing build_mode from 1 to 0")
							collision_child.build_mode = 0
					elif collision_child is CollisionShape2D:
						print("    - Collision shape:", collision_child.name, "at global pos:", collision_child.global_position)
						print("      Local position:", collision_child.position)
	print("=== End debug ===\n")

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

		print("Clicked at global:", global_mouse_pos, "Results:", results.size())

		if results.size() > 0:
			for res in results:
				print("Hit Area2D:", res.collider.name, "Parent:", res.collider.get_parent().name)
				# Check if the Area2D's parent is in the draggable group
				var parent = res.collider.get_parent()
				if parent and parent.is_in_group("draggable"):
					selected_shape = parent
					offset = selected_shape.global_position - global_mouse_pos
					print("Selected shape:", selected_shape.name)
					return
			print("Hit something but not draggable")
		else:
			print("No shape hit")

	elif event.is_action_released("Mouse_click_drag"):
		if selected_shape:
			print("Released:", selected_shape.name)
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

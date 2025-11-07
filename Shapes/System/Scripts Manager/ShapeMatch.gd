extends Node2D

@export var silhouette_node_path: NodePath
@export var required_shapes: Array[NodePath]
@export var match_threshold: float = 0.95  # 95% coverage needed (stricter)
@export var overhang_penalty: float = 0.3  # Penalty for shapes outside silhouette

signal level_completed

@onready var silhouette: Area2D = get_node(silhouette_node_path)

func _ready():
	# optional: periodic check every 0.5 sec
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.connect("timeout", Callable(self, "_on_check_match"))
	add_child(timer)

func _on_check_match():
	if is_match_successful():
		print("✅ Silhouette matched successfully!")
		emit_signal("level_completed")


func is_match_successful() -> bool:
	# get silhouette polygon
	var silhouette_poly: CollisionPolygon2D = silhouette.get_node_or_null("CollisionPolygon2D")
	if not silhouette_poly:
		return false

	var silhouette_area = polygon_area(silhouette_poly.polygon)
	if silhouette_area <= 0:
		return false

	# collect all world-space polygons from shapes
	var shape_polygons: Array = []
	for shape_path in required_shapes:
		var shape = get_node_or_null(shape_path)
		if shape:
			# Look for CollisionPolygon2D inside Area2D child
			var area2d = shape.get_node_or_null("Area2D")
			if area2d:
				var shape_poly: CollisionPolygon2D = area2d.get_node_or_null("CollisionPolygon2D")
				if shape_poly:
					var world_poly = shape_to_world(area2d, shape_poly.polygon)
					shape_polygons.append(world_poly)

	if shape_polygons.is_empty():
		return false

	# Convert silhouette polygon to world space
	var world_silhouette = shape_to_world(silhouette, silhouette_poly.polygon)

	# merge all shape polygons into a single union
	var merged_poly: Array = []
	merged_poly.append(shape_polygons[0])
	for i in range(1, shape_polygons.size()):
		var new_merged = []
		for existing in merged_poly:
			var merged = Geometry2D.merge_polygons(existing, shape_polygons[i])
			if merged.size() > 0:
				new_merged += merged
			else:
				new_merged.append(existing)
		merged_poly = new_merged

	# compute overlap area between merged shapes and silhouette
	var overlap_area: float = 0.0
	var total_shapes_area: float = 0.0
	
	for poly in merged_poly:
		# Calculate how much of the shapes are inside the silhouette
		var intersections = Geometry2D.intersect_polygons(world_silhouette, poly)
		for inter in intersections:
			overlap_area += polygon_area(inter)
		
		# Calculate total area of merged shapes
		total_shapes_area += polygon_area(poly)

	# Calculate overhang (shapes outside silhouette)
	var overhang_area = total_shapes_area - overlap_area
	
	# Coverage of silhouette
	var coverage = overlap_area / silhouette_area
	
	# Penalty for shapes sticking out
	var overhang_ratio = overhang_area / silhouette_area
	var final_score = coverage - (overhang_ratio * overhang_penalty)
	
	return final_score >= match_threshold


# --- Helper functions ---
func shape_to_world(shape: Node2D, local_points: PackedVector2Array) -> PackedVector2Array:
	var world_points: PackedVector2Array = []
	for p in local_points:
		world_points.append(shape.to_global(p))
	return world_points

func polygon_area(poly: PackedVector2Array) -> float:
	if poly.size() < 3:
		return 0.0
	var area = 0.0
	for i in range(poly.size()):
		var j = (i + 1) % poly.size()
		area += poly[i].x * poly[j].y - poly[j].x * poly[i].y
	return abs(area / 2.0)

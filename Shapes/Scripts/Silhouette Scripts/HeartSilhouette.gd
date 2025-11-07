extends Area2D

@export var silhouette_id: String = "heart"
@onready var collision_polygon: CollisionPolygon2D = $CollisionPolygon2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	connect("area_entered", _on_shape_entered)
	connect("area_exited", _on_shape_exited)

var overlapping_shapes: Array[Area2D] = []

func _on_shape_entered(area: Area2D):
	if area.is_in_group("shapes"):
		overlapping_shapes.append(area)

func _on_shape_exited(area: Area2D):
	if area.is_in_group("shapes"):
		overlapping_shapes.erase(area)

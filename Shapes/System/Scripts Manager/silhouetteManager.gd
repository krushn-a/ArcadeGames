extends Node

@export var silhouette_paths := [
	"res://Scenes/Silhouettes/HeartSilhouette.tscn",
	"res://Scenes/Silhouettes/PlusSilhouette.tscn",
    "res://Scenes/Silhouettes/DiamondSilhouette.tscn"
]

@onready var shape_container = get_node("../ShapeContainer")

var current_index := 0
var current_silhouette : Area2D = null

signal level_completed(silhouette_name: String)

func _ready():
	load_silhouette(current_index)

func load_silhouette(index: int):
	# Cleanup
	if current_silhouette:
		current_silhouette.queue_free()
	for child in shape_container.get_children():
		child.queue_free()

	# Load silhouette scene
	var scene := load(silhouette_paths[index])
	current_silhouette = scene.instantiate()
	add_child(current_silhouette)

	# Connect signals
	current_silhouette.connect("matched", Callable(self, "_on_silhouette_matched"))
	current_silhouette.connect("request_pieces", Callable(self, "_on_request_pieces"))

func _on_request_pieces(pieces_data: Array):
	for piece_data in pieces_data:
		var piece_scene = load(piece_data["scene"])
		var piece = piece_scene.instantiate()
		piece.global_position = piece_data["spawn_pos"]
		shape_container.add_child(piece)

func _on_silhouette_matched():
	var name = current_silhouette.silhouette_name
	emit_signal("level_completed", name)
	print("✅", name, "completed!")

	# Load next silhouette
	current_index += 1
	if current_index < silhouette_paths.size():
		load_silhouette(current_index)
	else:
		print("🏁 All silhouettes complete!")

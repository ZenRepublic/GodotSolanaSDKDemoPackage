extends Node

@onready var loading_canvas:CanvasLayer = $LoadingCanvas

signal scene_loaded
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	loading_canvas.visible=false
	connect("scene_loaded",on_scene_loaded)
	pass # Replace with function body.


func load_scene(scene_path:String) -> void:
	loading_canvas.visible=true
	await get_tree().create_timer(0.01).timeout
	
	get_tree().change_scene_to_file(scene_path)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func on_scene_loaded() -> void:
	loading_canvas.visible=false

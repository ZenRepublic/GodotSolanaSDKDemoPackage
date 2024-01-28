extends Button

@export_file("*.tscn") var path_to_scene:String

func _on_pressed() -> void:
	SceneLoader.load_scene(path_to_scene)

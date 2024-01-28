extends Node

@export_file("*.tscn") var path_to_scene:String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SolanaService.wallet.connect("on_logged_in",confirm_login)	


func confirm_login(login_success:bool) -> void:
	if login_success:
		SceneLoader.load_scene(path_to_scene)


func _on_login_button_pressed() -> void:
	SolanaService.wallet.try_login()

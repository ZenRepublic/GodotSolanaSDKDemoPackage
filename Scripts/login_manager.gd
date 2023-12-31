extends Node

@export var scene_to_load:PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SolanaService.wallet.connect("on_logged_in",confirm_login)	


func confirm_login(login_success:bool) -> void:
	if login_success:
		get_tree().change_scene_to_packed(scene_to_load)


func _on_login_button_pressed() -> void:
	SolanaService.wallet.try_login()

extends Node

@export_file("*.tscn") var path_to_scene:String
@onready var login_overlay = $LoginOverlay

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	login_overlay.visible=false
	
	SolanaService.wallet.on_logged_in.connect(confirm_login)	
	SolanaService.wallet.on_login_begin.connect(begin_login)	
	SolanaService.wallet.on_login_cancel.connect(cancel_login)	


func confirm_login(login_success:bool) -> void:
	login_overlay.visible=false
	if login_success:
		SceneLoader.load_scene(path_to_scene)


func _on_login_button_pressed() -> void:
	SolanaService.wallet.try_login()
	
func begin_login()-> void:
	login_overlay.visible=true

func cancel_login()-> void:
	login_overlay.visible=false

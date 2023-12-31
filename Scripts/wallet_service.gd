extends Node
class_name WalletService

@export var use_generated = false
#for generated wallets, user may enter their own wallet's private key
#DANGER IT'S SUPER UNSAFE AND SHOULD ONLY BE USED FOR TESTING
@export var custom_private_key:String
@export var autologin = false

@onready var phantom_controller:PhantomController = $PhantomController
@onready var login_overlay = $LoginPanel

var keypair:Keypair

signal on_logged_in

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if autologin:
		try_login()


func try_login() -> void:
	login_overlay.visible=true
	if use_generated:
		login_game_wallet()
	else:
		login_phantom()
	
	
func login_game_wallet() -> void:
	if custom_private_key.length()==0:
		keypair = SolanaService.generate_keypair()
	else:
		var seed = SolanaSDK.bs58_decode(custom_private_key)
		keypair = Keypair.new_from_seed(seed)
	log_in_success()

func login_phantom() -> void:
	phantom_controller.connect("connection_established",log_in_success)
	phantom_controller.connect("connection_error",log_in_fail)
	phantom_controller.connect_phantom()

func log_in_success() -> void:
	emit_signal("on_logged_in",true)
	login_overlay.visible=false
	
func log_in_fail() -> void:
	emit_signal("on_logged_in",false)
	login_overlay.visible=false

func get_pubkey() -> Pubkey:
	var key:Pubkey
	if use_generated:
		key = Pubkey.new_from_string(keypair.get_public_value())
	else:
		var address = SolanaSDK.bs58_encode(phantom_controller.get_connected_key())
		key = Pubkey.new_from_string(address)
	return key
	
func get_kp():
	if use_generated:
		return keypair
	else:
		return phantom_controller

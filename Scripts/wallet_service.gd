extends Node
class_name WalletService

@export var use_generated = false
#for generated wallets, user may enter their own wallet's private key
#DANGER IT'S SUPER UNSAFE AND SHOULD ONLY BE USED FOR TESTING
@export var custom_private_key:String
@export var autologin = false

@export var wallet_adapter_ui_scn:PackedScene
var adapter_instance:WalletAdapterUI

@onready var wallet_adapter:WalletAdapter = $WalletAdapter
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
		pop_adapter()
	
	
func login_game_wallet() -> void:
	if custom_private_key.length()==0:
		keypair = SolanaService.generate_keypair()
	else:
		var seed = SolanaSDK.bs58_decode(custom_private_key)
		keypair = Keypair.new_from_seed(seed)
	log_in_success()
	
func pop_adapter() -> void:
	adapter_instance = wallet_adapter_ui_scn.instantiate()
	adapter_instance.setup(wallet_adapter.get_available_wallets())
	add_child(adapter_instance)
	
	adapter_instance.connect("on_provider_selected",login_adapter)

func login_adapter(provider_id:int) -> void:
	wallet_adapter.wallet_type = provider_id
		
	wallet_adapter.connect("connection_established",log_in_success)
	wallet_adapter.connect("connection_error",log_in_fail)
	wallet_adapter.connect_wallet()

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
		var address = SolanaSDK.bs58_encode(wallet_adapter.get_connected_key())
		key = Pubkey.new_from_string(address)
	return key
	
func get_kp():
	if use_generated:
		return keypair
	else:
		return wallet_adapter

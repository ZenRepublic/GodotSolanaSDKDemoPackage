extends Node
class_name WalletService

@export var use_generated = false
#for testing in editor with a custom wallet, you may create a txt file with private key as text in it
#and enter the path to the file here
@export var custom_wallet_path:String
@export var autologin = false

@onready var wallet_adapter:WalletAdapter = $WalletAdapter

var keypair:Keypair

signal on_login_begin
signal on_logged_in

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if autologin:
		try_login()


func try_login() -> void:
	if use_generated:
		login_game_wallet()
	else:
		emit_signal("on_login_begin")
	
func login_game_wallet() -> void:
	if custom_wallet_path.length()==0:
		keypair = SolanaService.generate_keypair(true)
		#uncomment this to print your derived private key
#		print(keypair.get_private_value())
	else:
		keypair = Keypair.new_from_file(custom_wallet_path)
		if keypair==null:
			print("Failed to fetch keypair from a local file")
			return
	log_in_success()

func login_adapter(provider_id:int) -> void:
	wallet_adapter.wallet_type = provider_id	
	wallet_adapter.connect("connection_established",log_in_success)
	wallet_adapter.connect("connection_error",log_in_fail)
	wallet_adapter.connect_wallet()

func log_in_success() -> void:
	if !use_generated:
		wallet_adapter.disconnect("connection_established",log_in_success)
		wallet_adapter.disconnect("connection_error",log_in_fail)
	emit_signal("on_logged_in",true)
	
func log_in_fail() -> void:
	if !use_generated:
		wallet_adapter.disconnect("connection_established",log_in_success)
		wallet_adapter.disconnect("connection_error",log_in_fail)
	emit_signal("on_logged_in",false)

func get_pubkey() -> Pubkey:
	if use_generated:
		return Pubkey.new_from_string(keypair.get_public_value())
	else:
		return wallet_adapter.get_connected_key()
	
func get_kp():
	if use_generated:
		return keypair
	else:
		return wallet_adapter
		
func is_logged_in() -> bool:
	if use_generated:
		return true
	return wallet_adapter.get_connected_key().get_value()!=""
		

#func read_kp_from_file(file_path: String) -> Keypair:
	#var file = FileAccess.open(file_path, FileAccess.READ)
	#if file==null:
		#return null
		#
	#var kp_text = file.get_as_text()
	#var keypair:Keypair = SolanaService.generate_keypair_from_pk(kp_text)
	#return keypair
extends Node

@export var balance_token_address:String
@export var balance_visualizer:TokenVisualizer

@onready var account_address:Label = $AccountAddress
@onready var balance_label:Label = $Balance

var solana_service
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	solana_service = get_node("/root/SolanaService")
	var wallet_address = solana_service.wallet.get_pubkey().get_value()
	account_address.text = wallet_address
	
	if balance_visualizer!=null:
		var balance:float
		if balance_token_address.length()==0:
			balance = solana_service.get_sol_balance(wallet_address)
		else:
			balance = solana_service.get_token_balance(wallet_address,balance_token_address)

		balance_visualizer.set_token_data(Pubkey.new_from_string(balance_token_address),balance)

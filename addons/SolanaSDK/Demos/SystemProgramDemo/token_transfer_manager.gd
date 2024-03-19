extends Node
enum TokenType{SOL, SPL}

@export var input_field_system:InputFieldSystem
@export var token_type:TokenType

var solana_service

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	solana_service = get_node("/root/SolanaService")
	input_field_system.connect("on_input_submit", transfer_tokens)
	
func transfer_tokens(input_data:Array[String]) -> void:
	match token_type:
		TokenType.SOL:
			var receiver = input_data[0]
			var amount = float(input_data[1])
			var tx_id:String = await solana_service.transfer_sol_to_address(receiver,amount)
			if tx_id != "":
				input_field_system.clear_fields()
		TokenType.SPL:
			var token_address = input_data[0]
			var receiver = input_data[1]
			var amount = float(input_data[2])
			var tx_id:String = await solana_service.transfer_spl_to_address(token_address,receiver,amount)
			if tx_id != "":
				input_field_system.clear_fields()
		

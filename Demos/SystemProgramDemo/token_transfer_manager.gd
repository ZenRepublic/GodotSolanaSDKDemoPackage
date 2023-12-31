extends Node
enum TokenType{SOL, SPL}

@export var input_field_system:InputFieldSystem
@export var token_type:TokenType

var solana_service

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	solana_service = get_node("/root/SolanaService")
	solana_service.transaction_processor.connect("on_transaction_finish", transaction_finish_callback)
	input_field_system.connect("on_input_submit", transfer_tokens)
	
func transfer_tokens(input_data:Array[String]) -> void:
	match token_type:
		TokenType.SOL:
			var receiver = input_data[0]
			var amount = float(input_data[1])
			solana_service.transfer_sol_to_address(receiver,amount)
		TokenType.SPL:
			var token_address = input_data[0]
			var receiver = input_data[1]
			var amount = float(input_data[2])
			solana_service.transfer_spl_to_address(token_address,receiver,amount)


func transaction_finish_callback(transaction_id:String) -> void:
	print(transaction_id)
	if transaction_id != "":
		input_field_system.clear_fields()
		

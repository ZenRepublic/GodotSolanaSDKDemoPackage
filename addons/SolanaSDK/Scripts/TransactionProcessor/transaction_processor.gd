extends Node
class_name TransactionProcessor

enum PriorityLevel {NONE,LOW, MEDIUM, HIGH}
var wallet_adapter:WalletAdapter


var priority_fee_low:float = 0.0001
var priority_fee_medium:float = 0.0003
var priority_fee_high:float = 0.0005

signal on_transaction_init
signal on_transaction_signed
signal on_transaction_finish
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func setup(adapter:WalletAdapter) -> void:
	wallet_adapter = adapter
	
#var transaction:Transaction

func sign_transaction(wallet,instructions:Array[Instruction],tx_commitment:String="confirmed",priority_level:PriorityLevel=PriorityLevel.HIGH) -> String:
	emit_signal("on_transaction_init")
	var transaction:Transaction = Transaction.new()	
	transaction.url_override = SolanaService.active_rpc
	add_child(transaction)
	#
	for idx in range(instructions.size()):
		if instructions[idx] == null:
			push_error("instruction %s is null, couldn't build a transaction!"%idx)
			emit_signal("on_transaction_finish","")
			return ""
		transaction.add_instruction(instructions[idx])
	
	transaction.set_payer(wallet)
	
	var priority_fee = get_priority_fee(priority_level)
	transaction.set_unit_limit(priority_fee)
	transaction.set_unit_price(priority_fee)
	
	transaction.update_latest_blockhash()
	await transaction.blockhash_updated
	
	transaction.sign()
	#await transaction.fully_signed
	print("SIGNED")
	emit_signal("on_transaction_signed")
	#var serialized_tx:PackedByteArray = transaction.serialize()
	#var tx_id:String = await sign_serialized_transaction(wallet,serialized_tx,tx_commitment)
	var tx_id:String = await send_transaction(transaction,tx_commitment)
	
	transaction.queue_free()
	emit_signal("on_transaction_finish",tx_id)
	
	return tx_id
	

func sign_serialized_transaction(wallet,transaction_bytes:PackedByteArray,tx_commitment:String="confirmed") -> String:
	emit_signal("on_transaction_init")
	var transaction:Transaction = Transaction.new_from_bytes(transaction_bytes)
	transaction.url_override = SolanaService.active_rpc
	
	add_child(transaction)
	transaction.set_signers([wallet])
	
	var tx_id:String = await send_transaction(transaction,tx_commitment)
	
	transaction.queue_free()
	emit_signal("on_transaction_finish",tx_id)
	
	return tx_id
	
func send_transaction(tx:Transaction,tx_commitment:String="confirmed") -> String:
	tx.send()
	var response:Dictionary = await tx.transaction_response_received
	
	if response.size() == 0:
		return ""
		
	if response.has("error"):
		print(response["error"])
		return ""

	match tx_commitment:
		"confirmed":    
			while !tx.is_confirmed():
				await get_tree().create_timer(1).timeout
		"finalized":    
			while !tx.is_finalized():
				await get_tree().create_timer(1).timeout    
				
	print("Transaction ID: ",response["result"])
	return response["result"]
	

func get_priority_fee(priority_level:PriorityLevel) -> float:
	var fee:float
	match priority_level:
		PriorityLevel.NONE:
			fee = 0
		PriorityLevel.LOW:
			fee = priority_fee_low
		PriorityLevel.MEDIUM:
			fee = priority_fee_medium
		PriorityLevel.HIGH:
			fee =  priority_fee_high
	
	return fee
	
	
	
	
	

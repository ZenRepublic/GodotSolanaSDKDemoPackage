extends Node
class_name TransactionProcessor

var wallet_adapter:WalletAdapter

signal on_transaction_init
signal on_transaction_finish
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func setup(adapter:WalletAdapter) -> void:
	wallet_adapter = adapter
	wallet_adapter.connect("message_signed",process_transaction_pass)
	wallet_adapter.connect("signing_error",process_transaction_error)
	
	
var transaction:Transaction
var commitment:String

func try_sign_transaction(wallet,instructions:Array[Instruction], tx_commitment:String="confirmed") -> void:
	emit_signal("on_transaction_init")
	commitment=tx_commitment
	transaction = Transaction.new()	
	transaction.set_url(SolanaService.client.url)
	add_child(transaction)
	#
	for idx in range(instructions.size()):
		if instructions[idx] == null:
			push_error("instruction %s is null, couldn't build a transaction!"%idx)
			emit_signal("on_transaction_finish","")
			return
		transaction.add_instruction(instructions[idx])
	
	transaction.set_payer(wallet)

	transaction.update_latest_blockhash("")
	transaction.connect("transaction_response",process_transaction_pass)
	transaction.connect("sign_error",process_transaction_error)
	#print(transaction.serialize())
	transaction.sign_and_send()
	#var response:Dictionary = await transaction.transaction_response
	
	
func process_transaction_pass(response:Dictionary) -> void:	
	print("TEST")
	if response.has("error"):
		print(response["error"])
		process_transaction_error()
		return
		
	match commitment:
		"confirmed":	
			while !transaction.is_confirmed():
				await get_tree().create_timer(0.1).timeout
		"finalized":	
			while !transaction.is_finalized():
				await get_tree().create_timer(0.1).timeout	
	
	print("Transaction ID: ",response["result"])
	emit_signal("on_transaction_finish",response["result"])
	cleanup()
	

func process_transaction_error(signer_index:int=0) -> void:	
	print("TEST2")
	emit_signal("on_transaction_finish","")
	cleanup()
	
func cleanup()->void:
	transaction.disconnect("transaction_response",process_transaction_pass)
	transaction.disconnect("sign_error",process_transaction_error)
	transaction.queue_free()
	transaction=null

	
	
	
	

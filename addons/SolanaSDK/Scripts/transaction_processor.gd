extends Node
class_name TransactionProcessor

@export var loading_panel:Node
@export var fail_panel:Node
@export var success_panel:Node

@export var time_to_close = 2.5

@onready var screen_switcher = $ScreenSwitcher

var wallet_adapter:WalletAdapter

signal on_transaction_finish
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	loading_panel.visible=false
	fail_panel.visible=false
	success_panel.visible=false
	
func setup(adapter:WalletAdapter) -> void:
	wallet_adapter = adapter
	wallet_adapter.connect("message_signed",process_transaction_pass)
	wallet_adapter.connect("signing_error",process_transaction_error)
	
	
func enable_tx_loader() -> void:
	screen_switcher.switch_active_panel(loading_panel)
	
var transaction:Transaction

func try_sign_transaction(wallet:WalletService,instructions:Array[Instruction]) -> void:
	enable_tx_loader()
	transaction = Transaction.new()	
	#
	for ix in instructions:
		if ix == null:
			push_error("One of the instructions is null, couldn't build a transaction!")
			screen_switcher.close_active_panel()
			return
		transaction.add_instruction(ix)
	
	if wallet.use_generated:
		transaction.set_payer(wallet.keypair)
	else:
		transaction.set_payer(wallet.wallet_adapter)

	transaction.update_latest_blockhash("")

	transaction.connect("transaction_response",process_transaction_pass)
	transaction.connect("sign_error",process_transaction_error)
	#print(transaction.serialize())
	transaction.sign_and_send()
	
	
func process_transaction_pass(response:Dictionary) -> void:	
	if response.has("error"):
		print(response["error"])
		process_transaction_error()
		return
		
	transaction.disconnect("transaction_response",process_transaction_pass)
	transaction.disconnect("sign_error",process_transaction_error)
	transaction=null
	
	print("Transaction ID: ",response["result"])
	
	screen_switcher.switch_active_panel(success_panel)
	emit_signal("on_transaction_finish",response["result"])
	await get_tree().create_timer(time_to_close).timeout
	screen_switcher.close_active_panel()
	

func process_transaction_error(signer_index:int=0) -> void:	
	transaction.disconnect("transaction_response",process_transaction_pass)
	transaction.disconnect("sign_error",process_transaction_error)
	transaction=null
	
	screen_switcher.switch_active_panel(fail_panel)
	emit_signal("on_transaction_finish","")
	await get_tree().create_timer(time_to_close).timeout
	screen_switcher.close_active_panel()

	
	
	
	

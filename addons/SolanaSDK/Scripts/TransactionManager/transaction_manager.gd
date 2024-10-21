extends Node
class_name TransactionManager

## wallet adapters automatically add unit limit of 800000 and unit price of 8000
@export var use_custom_priority_fee:bool
## used to fetch estimated unit price. if you don't configure it with your own rpc key, fallback value will be used
@export var helius_api:HeliusAPI
@export var fallback_compute_unit_limit = 800000
@export var fallback_compute_unit_price = 8000

enum Commitment{PROCESSED,CONFIRMED,FINALIZED}

signal on_tx_create_start
signal on_tx_sign_start
signal on_tx_signed
signal on_tx_finish(tx_data:TransactionData)

func setup() -> void:
#	temporary solution. Don't use custom fees if using phantom
	#var selected_provider_id:int = SolanaService.wallet.get_wallet_provider_id()
	#if selected_provider_id == 0:
		#use_custom_priority_fee=false
	pass

func create_transaction(instructions:Array[Instruction],payer) -> Transaction:
	on_tx_create_start.emit()
	var transaction:Transaction = Transaction.new()	
	add_child(transaction)
	transaction.set_payer(payer)
	
	for idx in range(instructions.size()):
		if instructions[idx] == null:
			push_error("instruction %s is null, couldn't build a transaction!"%idx)
			return null
		transaction.add_instruction(instructions[idx])
		
	transaction.update_latest_blockhash()
	await transaction.blockhash_updated
		
	if use_custom_priority_fee:
		var consumed_units:int = await get_compute_units_used(transaction,20)
		transaction.set_unit_limit(consumed_units)
		var estimated_fee = await get_needed_unit_price(transaction)
		transaction.set_unit_price(estimated_fee)
		print("Using custom priority fee with following values:")
		print("Compute Unit Limit: ",consumed_units)
		print("Microlamports fee per Compute Unit: ",estimated_fee)
	
	return transaction
	

func sign_and_send(transaction:Transaction,tx_commitment:Commitment=Commitment.CONFIRMED,custom_signer=null) -> TransactionData:
	if transaction == null:
		on_tx_finish.emit(TransactionData.new({}))
		return TransactionData.new({})
		
	var needed_signers:Array
	if custom_signer!= null:
		needed_signers = [custom_signer]
	else:
		needed_signers = [SolanaService.wallet.get_kp()]
	
	transaction = await sign_transaction_normal(transaction,needed_signers,custom_signer)
	
	on_tx_signed.emit()
	var tx_data:TransactionData = await send_transaction(transaction,tx_commitment)
	
	on_tx_finish.emit(tx_data)
	return tx_data
	
func send_transaction(tx:Transaction,tx_commitment:Commitment=Commitment.CONFIRMED) -> TransactionData:
	#trying to force a staked connection if network is considered congested	
	if helius_api!=null:
		if helius_api.is_network_congested(tx.get_unit_price()):
			var staked_url = helius_api.get_rpc_url(true)
			if staked_url != "":
				print("CONGESTION IDENTIFIED, USING STAKED CONNECTION RPC!")
				tx.set_url_override(staked_url)
		
	tx.send()
	var response:Dictionary = await tx.transaction_response_received
	var tx_data:TransactionData = TransactionData.new(response)
	
	if !tx_data.is_successful():
		print(tx_data.get_error_message())
		return tx_data
		
	print("Transaction %s is sent! \nAwaiting confirmation..." % tx_data.data["result"])
	
##	1 - processed
##	2 - confirmed
##	3 - finalized
##	4 - failed
	#var tx_status:int
	#while true:
		#tx_status = await tx.confirmation_status_changed
		#print(tx_status)
		#if tx_status == 4:
			#break
		#
		#match tx_commitment:
			#Commitment.PROCESSED:
				#if tx_status == 1:
					#break
			#Commitment.CONFIRMED:
				#if tx_status == 2:
					#break
			#Commitment.FINALIZED:
				#if tx_status == 3:
					#break
		#print(tx_status)
		
	match tx_commitment:
		Commitment.PROCESSED:
			await tx.processed
		Commitment.CONFIRMED:
			await tx.confirmed
		Commitment.FINALIZED:
			await tx.finalized  
		
	tx.queue_free()	
	
	#if tx_status == 4:
		#return TransactionData.new({})

	print_rich("[url]%s[/url]" % tx_data.get_link())
	return tx_data
		
	
func sign_transaction_normal(transaction:Transaction, all_needed_signers:Array,custom_signer=null) -> Transaction:
	var wallet
	if custom_signer!=null:
		wallet = custom_signer
	else:
		wallet = SolanaService.wallet.get_kp()
		
	transaction.set_payer(wallet)
	
	transaction.update_latest_blockhash()
	await transaction.blockhash_updated
	
	await add_signature(transaction,wallet,all_needed_signers)
	return transaction

func sign_transaction_serialized(tx_bytes:PackedByteArray, all_needed_signers:Array, custom_signer=null) -> Transaction:
	var wallet
	if custom_signer!=null:
		wallet = custom_signer
	else:
		wallet = SolanaService.wallet.get_kp()
	
	var transaction:Transaction = Transaction.new_from_bytes(tx_bytes)
	add_child(transaction)
	
	await add_signature(transaction,wallet,all_needed_signers)
	return transaction
	
func add_signature(transaction:Transaction,signer,all_needed_signers:Array) -> Transaction:
	on_tx_sign_start.emit()
	
	if all_needed_signers.size() == 0:
		print("No signers provided for signature")
		return null
	
	if all_needed_signers.size() == 1:
		transaction.sign()
		if signer is WalletAdapter:
			await transaction.fully_signed
		print("Signature Added!")
		
	elif all_needed_signers.size() > 1:
		transaction.set_signers(all_needed_signers)
		transaction.partially_sign([signer])
		if signer is WalletAdapter:
			await transaction.signer_state_changed
		print("Partial Signature Added!")
	
	on_tx_signed.emit()
	return transaction
	
	
func get_compute_units_used(transaction:Transaction, inflate_percentage:int=0) -> int:
	var simulated_tx_data:Dictionary = await SolanaService.simulate_transaction(transaction)
	var consumed_units:int
	if simulated_tx_data.size() == 0:
		consumed_units = fallback_compute_unit_limit
		return consumed_units
		
	consumed_units = int(simulated_tx_data["result"]["value"]["unitsConsumed"])
	if inflate_percentage > 0:
		var inflate_amount:float = inflate_percentage/float(100)
		consumed_units += consumed_units*inflate_amount
		
	return consumed_units
	
func get_needed_unit_price(transaction:Transaction) -> int:
	var estimated_unit_price:int = 0
	if helius_api!=null:
		estimated_unit_price = await helius_api.get_estimated_priority_fee(transaction)
		
	if estimated_unit_price == 0:
		print("Failed to fetch estimated priority fee, using default value...")
		estimated_unit_price = fallback_compute_unit_price
		
	return estimated_unit_price
	
	
func transfer_sol(receiver:String,amount:float,tx_commitment=Commitment.CONFIRMED, custom_sender:Keypair=null) -> TransactionData:
	var instructions:Array[Instruction]
	
	var sender_keypair = SolanaService.wallet.get_kp()
	var sender_account:Pubkey = SolanaService.wallet.get_pubkey()
	if custom_sender!=null:
		sender_keypair = custom_sender
		sender_account = Pubkey.new_from_string(custom_sender.get_public_string())
	
	var receiver_account:Pubkey = Pubkey.new_from_string(receiver)  
	
	var amount_in_lamports = int(amount*1000000000)
	
	var sol_transfer_ix:Instruction = SystemProgram.transfer(sender_keypair,receiver_account,amount_in_lamports)
	instructions.append(sol_transfer_ix)
	
	var transaction:Transaction = await create_transaction(instructions,sender_keypair)
	
	if custom_sender!=null:
		var tx_data:TransactionData = await sign_and_send(transaction,tx_commitment,custom_sender)
		return tx_data
	else:
		var tx_data:TransactionData = await sign_and_send(transaction)
		return tx_data

func transfer_token(token_address:String,receiver:String,amount:float,tx_commitment=Commitment.CONFIRMED,custom_sender:Keypair=null) -> TransactionData:
	var instructions:Array[Instruction]
	
	var sender_keypair = SolanaService.wallet.get_kp()
	var sender_account:Pubkey = SolanaService.wallet.get_pubkey()
	if custom_sender!=null:
		sender_keypair = custom_sender
		sender_account = Pubkey.new_from_string(custom_sender.get_public_string())
		
	var receiver_account:Pubkey = Pubkey.new_from_string(receiver) 
	var token_mint:Pubkey = Pubkey.new_from_string(token_address) 
	
	var sender_ata:Pubkey = await SolanaService.get_associated_token_account(sender_account.to_string(),token_address)
	
	#check if an ATA for this token exists in wallet. if not, add initalize as instruction
	var receiver_ata:Pubkey = await SolanaService.get_associated_token_account(receiver_account.to_string(),token_address)
	if receiver_ata == null:
		receiver_ata = Pubkey.new_associated_token_address(receiver_account,token_mint)
		var init_ata_ix:Instruction = AssociatedTokenAccountProgram.create_associated_token_account(
			sender_keypair,
			receiver_account,
			token_mint,
			SolanaService.TOKEN_PID
			)
		instructions.append(init_ata_ix)
		
	#get the decimals of the token to multiply by the amount provided
	var token_decimals = await SolanaService.get_token_decimals(token_address)
	var decimal_amount = amount*pow(10,token_decimals)
	var transfer_ix:Instruction = TokenProgram.transfer_checked(sender_ata,token_mint,receiver_ata,sender_keypair,decimal_amount,token_decimals)
	instructions.append(transfer_ix)
	
	var transaction:Transaction = await create_transaction(instructions,sender_keypair)
	
	if custom_sender!=null:
		var tx_data:TransactionData = await sign_and_send(transaction,tx_commitment,custom_sender)
		return tx_data
	else:
		var tx_data:TransactionData = await sign_and_send(transaction)
		return tx_data

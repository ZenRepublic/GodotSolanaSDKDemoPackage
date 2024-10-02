extends Node
class_name TransactionManager

enum Commitment{PROCESSED,CONFIRMED,FINALIZED}

signal on_tx_init
signal on_tx_signed
signal on_tx_finish(tx_data:TransactionData)

func create_transaction(instructions:Array[Instruction],priority_fee:float=0.0) -> Transaction:
	var transaction:Transaction = Transaction.new()	
	add_child(transaction)
	
	for idx in range(instructions.size()):
		if instructions[idx] == null:
			push_error("instruction %s is null, couldn't build a transaction!"%idx)
			return null
		transaction.add_instruction(instructions[idx])
		
	#transaction.set_unit_limit(priority_fee)
	#transaction.set_unit_price(priority_fee)
	
	transaction.update_latest_blockhash()
	await transaction.blockhash_updated
	
	return transaction
	

func sign_transaction(transaction:Transaction,tx_commitment:Commitment=Commitment.CONFIRMED,custom_signer=null) -> TransactionData:
	on_tx_init.emit()
	if transaction == null:
		on_tx_finish.emit(TransactionData.new({}))
		return TransactionData.new({})
	
	var wallet
	if custom_signer!=null:
		wallet = custom_signer
	else:
		wallet = SolanaService.wallet.get_kp()
		
		
	transaction.set_payer(wallet)
	#
	#transaction.set_unit_limit(0.0)
	#transaction.set_unit_price(0.0)
	transaction.sign()
	print("SIGNED!")
	#await transaction.fully_signed
	
	#var double_signed_tx:Transaction = await RubianServer.get_oracle_signature(transaction)
	#print(double_signed_tx.get_signers())
	#return
	
	on_tx_signed.emit()
	var tx_data:TransactionData = await send_transaction(transaction,tx_commitment)
	
	on_tx_finish.emit(tx_data)
	return tx_data
	

func sign_serialized_transaction(signers:Array,transaction_bytes:PackedByteArray,tx_commitment:Commitment=Commitment.CONFIRMED,priority_fee:float=0.0) -> TransactionData:
	on_tx_init.emit()
	var transaction:Transaction = Transaction.new_from_bytes(transaction_bytes)
	add_child(transaction)
	
	transaction.set_signers(signers)
	transaction.sign()
	#transaction.set_unit_limit(priority_fee)
	#transaction.set_unit_price(priority_fee)

	var tx_data:TransactionData = await send_transaction(transaction,tx_commitment)
	
	on_tx_finish.emit(tx_data)
	
	return tx_data
	
func send_transaction(tx:Transaction,tx_commitment:Commitment=Commitment.CONFIRMED) -> TransactionData:
	tx.send()
	var response:Dictionary = await tx.transaction_response_received
	var tx_data:TransactionData = TransactionData.new(response)
	
	if !tx_data.is_successful():
		print(tx_data.get_error_message())
		return tx_data

	match tx_commitment:
		Commitment.PROCESSED:
			await tx.processed
		Commitment.CONFIRMED:
			await tx.confirmed
		Commitment.FINALIZED:
			await tx.finalized  
		
	tx.queue_free()	
	print_rich("[url]%s[/url]" % tx_data.get_link())
	return tx_data
		
	
# a couple of default transactions (sol_transfer, spl_transfer)
	
func transfer_sol(receiver:String,amount:float,tx_commitment=Commitment.CONFIRMED,priority_fee:float=0.0, custom_sender:Keypair=null) -> TransactionData:
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
	
	var transaction:Transaction = await create_transaction(instructions,priority_fee)
	#var double_signed_tx:Transaction = await RubianServer.get_oracle_signature(transaction)
	#print(double_signed_tx.get_signers())
	#return
	
	if custom_sender!=null:
		var tx_data:TransactionData = await sign_transaction(transaction,tx_commitment,custom_sender)
		return tx_data
	else:
		var tx_data:TransactionData = await sign_transaction(transaction)
		return tx_data

func transfer_token(token_address:String,receiver:String,amount:float,tx_commitment=Commitment.CONFIRMED,priority_fee:float=0.0,custom_sender:Keypair=null) -> TransactionData:
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
	
	var transaction:Transaction = await create_transaction(instructions,priority_fee)
	
	if custom_sender!=null:
		var tx_data:TransactionData = await sign_transaction(transaction,tx_commitment,custom_sender)
		return tx_data
	else:
		var tx_data:TransactionData = await sign_transaction(transaction)
		return tx_data

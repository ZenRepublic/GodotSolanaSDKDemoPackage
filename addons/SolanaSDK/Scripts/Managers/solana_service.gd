extends Node
enum RpcCluster{Mainnet,Devnet}
@export var rpc_cluster:RpcCluster=RpcCluster.Mainnet
@export var mainnet_rpc:String
@export var devnet_rpc:String

var default_devnet = "https://api.devnet.solana.com"
var default_mainnet = "https://api.mainnet-beta.solana.com"

var active_rpc:String

var token_pid:String = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
var associated_token_pid:String = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"

@onready var wallet:WalletService = $WalletService
@onready var transaction_processor:TransactionProcessor = $TransactionProcessor
@onready var nft_manager:NFTManager = $NFTManager
@onready var file_loader:FileLoader = $FileLoader
@onready var candy_machine_manager:CandyMachineManager = $CandyMachineManager

var rpc:String

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	nft_manager.setup()
	
	if mainnet_rpc=="":
		mainnet_rpc=default_mainnet
	if devnet_rpc=="":
		devnet_rpc=default_devnet
		
	set_rpc_cluster(rpc_cluster)
	
	
func set_rpc_cluster(new_cluster:RpcCluster)->void:
	match new_cluster:
		RpcCluster.Mainnet:
			active_rpc = mainnet_rpc
		RpcCluster.Devnet:
			active_rpc = devnet_rpc
	
	rpc_cluster = new_cluster
	
#	sol_client.url_override = "https://api.mainnet-beta.solana.com"
#	print(SolanaClient.get_latest_blockhash())
func spawn_client_instance()->SolanaClient:
	var sol_client:SolanaClient = SolanaClient.new()
	add_child(sol_client)
	sol_client.url_override = active_rpc
	return sol_client
	
	
func get_sol_balance(address_to_check:String) -> float:
	var client:SolanaClient = spawn_client_instance()
	var response_dict:Dictionary = client.get_balance(address_to_check)
	response_dict = await client.http_response_received
	client.queue_free()
	var balance = response_dict["result"]["value"] / 1000000000
	return balance
	
func get_token_balance(address_to_check:String,token_address:String)->float:
	var token_account:Pubkey = await get_associated_token_account(address_to_check,token_address)
	if token_account == null:
		return 0	
	
	var client:SolanaClient = spawn_client_instance()
	var response_dict:Dictionary = client.get_token_account_balance(token_account.to_string())
	response_dict = await client.http_response_received
	client.queue_free()
	
	var lamport_balance = response_dict["result"]["value"]["amount"]
	var token_decimals = response_dict["result"]["value"]["decimals"]
	return float(lamport_balance)/(10**token_decimals)
	
func get_token_decimals(token_address:String)->int:
	var client:SolanaClient = spawn_client_instance()
	var response_dict:Dictionary = client.get_token_supply(token_address)
	response_dict = await client.http_response_received
	client.queue_free()
	
	return response_dict["result"]["value"]["decimals"]
	
func get_associated_token_account(address_to_check:String,token_address:String) -> Pubkey:
	var client:SolanaClient = spawn_client_instance()
	var response_dict:Dictionary = client.get_token_accounts_by_owner(address_to_check,token_address,associated_token_pid)
	response_dict = await client.http_response_received
	client.queue_free()
	
	var ata:String
	
	if response_dict.has("error"):
		return null

	if response_dict["result"]["value"].size() == 0:
		return null
	
	return Pubkey.new_from_string(response_dict["result"]["value"][0]["pubkey"])
	
func get_wallet_tokens(wallet_address:String) -> Array[Pubkey]:
	var client:SolanaClient = spawn_client_instance()
	var response_dict:Dictionary = client.get_token_accounts_by_owner(wallet_address,"",token_pid)
	response_dict = await client.http_response_received
	client.queue_free()

	var wallet_tokens:Array[Pubkey]
	for token in response_dict["result"]["value"]:
		var token_byte_data = SolanaUtils.bs64_decode(token["account"]["data"][0])
		var token_data:Dictionary = parse_token_data(token_byte_data)
		
		#remove token accounts which no longer hold an NFT
		if token_data["amount"] == 0:
			continue
		wallet_tokens.append(Pubkey.new_from_string(token_data["mint"]))
	
	return wallet_tokens
	
func parse_token_data(data: PackedByteArray) -> Dictionary:
	# Ensure that the data has a minimum length
	if data.size() < 64:
		print("Invalid token data")
		return {}
	
	# Extract the mint address (first 32 bytes)
	var mint_address = SolanaUtils.bs58_encode(data.slice(0, 32))
	var owner_address = SolanaUtils.bs58_encode(data.slice(32, 64))

	# Extract the amount (next 8 bytes) and convert it to a 64-bit integer
	var amount_bytes = data.slice(64, 72)
	var amount = amount_bytes.decode_u64(0)
	
	return {"mint":mint_address,"owner":owner_address,"amount":amount}
	
	
	
func generate_keypair(derive_from_machine:bool=false) -> Keypair:
	var randomizer = RandomNumberGenerator.new()
	randomizer.randomize()
	if derive_from_machine:
		randomizer.set_seed(OS.get_unique_id().hash()) 

	var keypair = Keypair.new();
	keypair.set_unique(false)
	var seed := PackedByteArray()
	for i in range(32):
		var random_value := randomizer.randi() % 256  # randi() generates a random integer
		seed.append(random_value)
#	seed.resize(32)
	keypair.set_seed(seed);
	return keypair
	
func generate_keypair_from_pk(pk:String) -> Keypair:
	var seed = SolanaUtils.bs58_decode(pk)
	var keypair = Keypair.new_from_seed(seed)
	#var keypair = Keypair.new_from_file("C:\\Users\\thoma\\Desktop\\kp\\kp.json")
	return keypair

func transfer_sol_to_address(receiver:String,amount:float, sender:Keypair=null) -> String:
	var instructions:Array[Instruction]
	
	var sender_keypair = wallet.get_kp()
	var sender_account:Pubkey = wallet.get_pubkey()
	if sender!=null:
		sender_keypair = sender
		sender_account = Pubkey.new_from_string(sender.get_public_string())
	
	var receiver_account:Pubkey = Pubkey.new_from_string(receiver)  
	
	var amount_in_lamports = int(amount*1000000000)
	
	var sol_transfer_ix:Instruction = SystemProgram.transfer(sender_account,receiver_account,amount_in_lamports)
	instructions.append(sol_transfer_ix)
	
	var tx_id:String = await transaction_processor.sign_transaction(sender_keypair,instructions)
	return tx_id
	
func transfer_spl_to_address(token_address:String,receiver:String,amount:float,sender:Keypair=null) -> String:
	var instructions:Array[Instruction]
	
	var sender_keypair = wallet.get_kp()
	var sender_account:Pubkey = wallet.get_pubkey()
	if sender!=null:
		sender_keypair = sender
		sender_account = Pubkey.new_from_string(sender.get_public_string())
		
	var receiver_account:Pubkey = Pubkey.new_from_string(receiver) 
	var token_mint:Pubkey = Pubkey.new_from_string(token_address) 
	
	var sender_ata:Pubkey = await get_associated_token_account(sender_account.to_string(),token_address)
	
	#check if an ATA for this token exists in wallet. if not, add initalize as instruction
	var receiver_ata:Pubkey = await get_associated_token_account(receiver_account.to_string(),token_address)
	if receiver_ata == null:
		receiver_ata = Pubkey.new_associated_token_address(receiver_account,token_mint)
		var init_ata_ix:Instruction = AssociatedTokenAccountProgram.create_associated_token_account(
			sender_account,
			receiver_account,
			token_mint,
			associated_token_pid
			)
		instructions.append(init_ata_ix)
		
	#get the decimals of the token to multiply by the amount provided
	var token_decimals = await get_token_decimals(token_address)
	var transfer_ix:Instruction = TokenProgram.transfer_checked(sender_ata,token_mint,receiver_ata,sender_account,amount,token_decimals)
	instructions.append(transfer_ix)
	
	var tx_id:String = await transaction_processor.sign_transaction(sender_keypair,instructions)
	return tx_id


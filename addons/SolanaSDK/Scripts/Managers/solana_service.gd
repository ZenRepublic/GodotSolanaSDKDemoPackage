extends Node
enum RpcCluster{MAINNET,DEVNET,SONIC,HONEYNET}
@export var rpc_cluster:RpcCluster=RpcCluster.MAINNET
@export var mainnet_rpc:String
@export var devnet_rpc:String
@export var sonic_rpc:String
@export var honeycomb_rpc:String

var default_devnet = "https://api.devnet.solana.com"
var default_mainnet = "https://api.mainnet-beta.solana.com"


var active_rpc:String

var das_supported_rpc_providers:Array[String] = [
	"helius-rpc"
]
var das_compatible_rpc:String

var TOKEN_METADATA_PID:String = "metaqbxxUerdq28cj1RbAWkYQm3ybzjb6a8bt518x1s"
var TOKEN_PID:String = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
var ATA_TOKEN_PID:String = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
var SYSVAR_RENT_PUBKEY:String = "SysvarRent111111111111111111111111111111111"

var WRAPPED_SOL_CA:String = "So11111111111111111111111111111111111111112"

@onready var wallet:WalletService = $WalletService
@onready var transaction_manager:TransactionManager = $TransactionManager
@onready var file_loader:FileLoader = $FileLoader
@onready var account_inspector:AccountInspector = $AccountInspector
@onready var candy_machine_manager:CandyMachineManager = $CandyMachineManager
@onready var asset_manager:AssetManager = $AssetManager

var rpc:String

signal on_rpc_cluster_set

## Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	if mainnet_rpc=="":
		mainnet_rpc=default_mainnet
	if devnet_rpc=="":
		devnet_rpc=default_devnet
		
	set_rpc_cluster(rpc_cluster)
	
	wallet.on_login_finish.connect(handle_login)
	asset_manager.setup()
	
func handle_login(success:bool)->void:
	if !success:
		return
	transaction_manager.setup()
	
	
func set_rpc_cluster(new_cluster:RpcCluster)->void:
	match new_cluster:
		RpcCluster.MAINNET:
			active_rpc = mainnet_rpc
		RpcCluster.DEVNET:
			active_rpc = devnet_rpc
		RpcCluster.SONIC:
			active_rpc = sonic_rpc
		RpcCluster.HONEYNET:
			active_rpc = honeycomb_rpc
			
	ProjectSettings.set_setting("solana_sdk/client/default_url",active_rpc)
	rpc_cluster = new_cluster
	
	if is_rpc_das_compatible(active_rpc):
		das_compatible_rpc = active_rpc
		
	on_rpc_cluster_set.emit()
	
func is_rpc_das_compatible(rpc_url:String) -> bool:
	for rpc_provider in das_supported_rpc_providers:
		if rpc_url.contains(rpc_provider):
			return true
	return false
	
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
	
func spawn_client_instance()->SolanaClient:
	var sol_client:SolanaClient = SolanaClient.new()
	add_child(sol_client)
	return sol_client
	
func spawn_mpl_metadata_client() -> MplTokenMetadata:
	var mpl_metadata:MplTokenMetadata = MplTokenMetadata.new()
	add_child(mpl_metadata)
	return mpl_metadata
	
func spawn_mpl_candy_machine_client() -> MplCandyMachine:
	var candy_machine:MplCandyMachine = MplCandyMachine.new()
	add_child(candy_machine)
	return candy_machine
	
func spawn_program_instance(original_program:AnchorProgram)->AnchorProgram:
	var program_instance:AnchorProgram = AnchorProgram.new()
	program_instance.set_pid(original_program.get_pid())
	program_instance.set_json_file(original_program.get_json_file())
	program_instance.set_idl(original_program.get_idl())
	add_child(program_instance)
	return program_instance
	
func get_account_info(account:Pubkey) -> Dictionary:
	var client:SolanaClient = spawn_client_instance()
	client.get_account_info(account.to_string())
	var response_dict:Dictionary = await client.http_response_received
	client.queue_free()
	return response_dict
	
func get_airdrop(address:String,sol_lamport_amount:int) -> void:
	var client:SolanaClient = spawn_client_instance()
	client.request_airdrop(address,sol_lamport_amount)
	var response_dict:Dictionary = await client.http_response_received
	print(response_dict)
	
	client.queue_free()
	
func get_balance(address_to_check:String,token_address:String="") -> float:
	var client:SolanaClient = spawn_client_instance()
	if token_address == "":
		client.get_balance(address_to_check)
		var response_dict:Dictionary = await client.http_response_received
		client.queue_free()
		var balance = response_dict["result"]["value"] / 1000000000
		return balance
	else:
		var token_account:Pubkey = await get_associated_token_account(address_to_check,token_address)
		if token_account == null:
			return 0
		var balance = await get_ata_balance(token_account.to_string())
		return balance
		
func get_ata_balance(associated_token_account:String) -> float:
	var client:SolanaClient = spawn_client_instance()
	client.get_token_account_balance(associated_token_account)
	var response_dict:Dictionary = await client.http_response_received
	client.queue_free()
	
	if response_dict.has("error"):
		push_error("Failed to ata balance")
		return 0
		
	var lamport_balance = response_dict["result"]["value"]["amount"]
	var token_decimals = response_dict["result"]["value"]["decimals"]
	return float(lamport_balance)/(10**token_decimals)	
		
func get_token_decimals(token_address:String)->int:
	var client:SolanaClient = spawn_client_instance()
	client.get_token_supply(token_address)
	var response_dict:Dictionary = await client.http_response_received
	client.queue_free()
	
	if response_dict.has("error"):
		push_error("Failed to get token decimals for token %s" % token_address)
		return 0
		
	return response_dict["result"]["value"]["decimals"]
	
func simulate_transaction(transaction:Transaction) -> Dictionary:
	var client:SolanaClient = spawn_client_instance()
	var serialized_tx:String = SolanaUtils.bs64_encode(transaction.serialize())
	client.simulate_transaction(serialized_tx,false,false,[],"base64")
	var result = await client.http_response_received
	client.queue_free()
	
	if result.size() == 0 or result.has("error"):
		push_error("Failed to simulate transaction")
		print(result)
		return {}
		
	return result
	
func get_associated_token_account(address_to_check:String,token_address:String) -> Pubkey:
	var client:SolanaClient = spawn_client_instance()
	client.get_token_accounts_by_owner(address_to_check,token_address,ATA_TOKEN_PID)
	var response_dict:Dictionary = await client.http_response_received
	client.queue_free()
	
	var ata:String
	
	if response_dict.has("error"):
		push_error("Failed to get fetch ATA")
		return null

	if response_dict["result"]["value"].size() == 0:
		return null
	
	return Pubkey.new_from_string(response_dict["result"]["value"][0]["pubkey"])
	
func fetch_program_account_of_type(program:AnchorProgram,account_type:String,key:Pubkey) -> Dictionary:
	var program_instance:AnchorProgram = spawn_program_instance(program)
	
	program_instance.fetch_account(account_type,key)
	var account:Dictionary = await program_instance.account_fetched
	program_instance.queue_free()
	return account
	
func fetch_all_program_accounts_of_type(program:AnchorProgram,account_type:String,filter:Array=[]) -> Dictionary:
	var program_instance:AnchorProgram = spawn_program_instance(program)
	program_instance.fetch_all_accounts(account_type,filter)
	var accounts:Dictionary = await program_instance.accounts_fetched
	program_instance.queue_free()
	return accounts
	
#DAS ONLY!
func get_asset_data(asset_id:Pubkey) -> Dictionary:
	if das_compatible_rpc == "":
		push_error("Can't get asset data - DAS compatible RPC is not configured")
		return {}
	var client:SolanaClient = spawn_client_instance()
	client.url_override = das_compatible_rpc
			
	client.get_asset(asset_id)
	var response_dict:Dictionary = await client.http_response_received
	client.queue_free()

	if response_dict.has("error"):
		print("Failed to fetch asset data")
		return {}
		
	return response_dict["result"]
	
#DAS ONLY!
func get_wallet_assets_data(wallet_to_check:Pubkey,asset_limit:int=1000) -> Array:
	var page_id:int=1
	var wallet_assets:Array
	
	if das_compatible_rpc == "":
		push_error("Can't get wallet assets - DAS compatible RPC is not configured")
		return []
	
	while true:
		var client:SolanaClient = spawn_client_instance()
		client.url_override = das_compatible_rpc
			
		client.get_assets_by_owner(wallet_to_check,page_id,asset_limit)
		var response_dict:Dictionary = await client.http_response_received
		client.queue_free()
		if response_dict.has("error"):
			push_error("Error fetching DAS assets data, stopping paging operation")
			push_error(response_dict)
			break
			
		var loaded_page_assets:Array = response_dict["result"]["items"]
		for item in loaded_page_assets:
			wallet_assets.append(item)
		
		if loaded_page_assets.size() < asset_limit:
			break
		page_id+=1

	return wallet_assets
	
#DAS ONLY!
func get_collection_assets_data(nft_owner:Pubkey,collection_mint:Pubkey,asset_limit:int=1000) -> Array:
	var page_id:int=1
	var owned_collection_assets:Array
	
	if das_compatible_rpc == "":
		push_error("Can't get collection assets - DAS compatible RPC is not configured")
		return []
	
	while true:
		var client:SolanaClient = spawn_client_instance()
		client.url_override = das_compatible_rpc
			
		client.get_assets_by_group("collection_id",collection_mint,page_id,asset_limit)
		var response_dict:Dictionary = await client.http_response_received
		client.queue_free()
		if response_dict.has("error"):
			push_error("Error fetching DAS collection assets data, stopping paging operation")
			break
			
		var loaded_page_assets:Array = response_dict["result"]["items"]
		if loaded_page_assets.size() < asset_limit:
			break
		page_id+=1
	return owned_collection_assets
	
func get_token_accounts(wallet_to_check:Pubkey) -> Array[Dictionary]:
	var client:SolanaClient = spawn_client_instance()
	client.get_token_accounts_by_owner(wallet_to_check.to_string(),"",TOKEN_PID)
	var response_dict:Dictionary = await client.http_response_received
	client.queue_free()
	
	if response_dict.has("error"):
		push_error("Failed to fetch token accounts")
		return []
	
	var wallet_tokens:Array[Dictionary]
	for token in response_dict["result"]["value"]:
		var token_byte_data = SolanaUtils.bs64_decode(token["account"]["data"][0])
		var token_data:Dictionary = parse_token_data(token_byte_data)
		#remove token accounts which no longer hold an NFT
		if token_data["amount"] == 0:
			continue
		wallet_tokens.append(token_data)
	
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
	

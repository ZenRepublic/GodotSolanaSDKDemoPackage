extends Control
enum RpcCluster{Mainnet,Devnet}
@export var rpc_cluster:RpcCluster=RpcCluster.Mainnet
@export var mainnet_rpc:String
@export var devnet_rpc:String

var default_devnet = "https://api.devnet.solana.com"
var default_mainnet = "https://api.mainnet-beta.solana.com"

@onready var wallet:WalletService = $OverlayLayer/WalletService
@onready var transaction_processor:TransactionProcessor = $OverlayLayer/TransactionProcessor
@onready var nft_manager:NFTManager = $NFTManager
@onready var file_loader:FileLoader = $FileLoader
@onready var candy_machine_manager:CandyMachineManager = $CandyMachineManager

var rpc:String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if mainnet_rpc=="":
		mainnet_rpc=default_mainnet
	if devnet_rpc=="":
		devnet_rpc=default_devnet
		
	SolanaClient.set_encoding("base64");	
	set_rpc_cluster(rpc_cluster)
	
	
func set_rpc_cluster(new_cluster:RpcCluster)->void:
	match new_cluster:
		RpcCluster.Mainnet:
			SolanaClient.set_url(mainnet_rpc)
		RpcCluster.Devnet:
			SolanaClient.set_url(devnet_rpc)
	
#	SolanaClient.set_url("https://api.mainnet-beta.solana.com")
#	print(SolanaClient.get_latest_blockhash())
	
	
func get_sol_balance(address_to_check:String) -> float:
	var response_dict:Dictionary = SolanaClient.get_balance(address_to_check)
	var balance = response_dict["result"]["value"] / 1000000000
	return balance
	
func get_token_balance(address_to_check:String,token_address:String)->float:
	var token_program_id = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
	var token_account:Pubkey = get_associated_token_account(address_to_check,token_address)
	if token_account == null:
		return 0	

	var response_dict:Dictionary = SolanaClient.get_token_account_balance(token_account.get_value())
	var lamport_balance = response_dict["result"]["value"]["amount"]
	var token_decimals = response_dict["result"]["value"]["decimals"]
	return float(lamport_balance)/(10**token_decimals)
	
func get_token_decimals(token_address:String)->int:
	var response_dict:Dictionary = SolanaClient.get_token_supply(token_address)
	return response_dict["result"]["value"]["decimals"]
	
func get_associated_token_account(address_to_check:String,token_address:String) -> Pubkey:
	var token_program_id = "ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL"
	var response_dict:Dictionary = SolanaClient.get_token_accounts_by_owner(address_to_check,token_address,token_program_id)
	var ata:String
	
	if response_dict.has("error"):
		return null

	if response_dict["result"]["value"].size() == 0:
		return null
	
	return Pubkey.new_from_string(response_dict["result"]["value"][0]["pubkey"])
	
	
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
	var seed = SolanaSDK.bs58_decode(pk)
	var keypair = Keypair.new_from_seed(seed)
	return keypair

func transfer_sol_to_address(receiver:String,amount:float) -> void:
	var instructions:Array[Instruction]
	
	var sender_account:Pubkey = wallet.get_pubkey()
	var receiver_account:Pubkey = Pubkey.new_from_string(receiver)  
	
	var amount_in_lamports = int(amount*1000000000)
	
	var sol_transfer_ix:Instruction = SystemProgram.transfer(sender_account,receiver_account,amount_in_lamports)
	instructions.append(sol_transfer_ix)
	
	transaction_processor.try_sign_transaction(wallet,instructions)
	
func transfer_spl_to_address(token_address:String,receiver:String,amount:float) -> void:
	var instructions:Array[Instruction]
	
	var sender_account:Pubkey = wallet.get_pubkey()
	var receiver_account:Pubkey = Pubkey.new_from_string(receiver) 
	var token_mint:Pubkey = Pubkey.new_from_string(token_address) 
	var token_program_id:Pubkey = Pubkey.new_from_string("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL")
	
	var sender_ata:Pubkey = get_associated_token_account(sender_account.get_value(),token_address)
	
	#check if an ATA for this token exists in wallet. if not, add initalize as instruction
	var receiver_ata:Pubkey = get_associated_token_account(receiver_account.get_value(),token_address)
	if receiver_ata == null:
		receiver_ata = Pubkey.new_associated_token_address(receiver_account,token_mint)
		var init_ata_ix:Instruction = AssociatedTokenAccountProgram.create_associated_token_account(
			sender_account,
			receiver_account,
			token_mint,
			token_program_id
			)
		instructions.append(init_ata_ix)
		
	#get the decimals of the token to multiply by the amount provided
	var token_decimals = get_token_decimals(token_address)
	var transfer_ix:Instruction = TokenProgram.transfer_checked(sender_ata,token_mint,receiver_ata,sender_account,amount,token_decimals)
	instructions.append(transfer_ix)
	
	transaction_processor.try_sign_transaction(wallet,instructions)
	pass


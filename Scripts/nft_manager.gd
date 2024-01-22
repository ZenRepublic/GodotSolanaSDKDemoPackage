extends Node
class_name NFTManager

@export var load_on_login:bool 
@export var load_textures:bool
var owned_nfts:Array[Nft]
var nfts_loaded=false

signal on_nft_load_started
signal on_nft_loaded
signal on_nft_load_finished

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if load_on_login:
		SolanaService.wallet.connect("on_logged_in",try_load_nfts)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func try_load_nfts(logged_in:bool) -> void:
	if logged_in:
		load_nfts()
	
func load_nfts()->void:
	var token_program_id = "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
	var connected_wallet:Pubkey = SolanaService.wallet.get_pubkey()
	var raw_response:Dictionary = SolanaClient.get_token_accounts_by_owner(connected_wallet.get_value(),"",token_program_id)
	var nft_mints:Array[Pubkey]
	for token in raw_response["result"]["value"]:
		var token_byte_data = SolanaSDK.bs64_decode(token["account"]["data"][0])
		var token_data:Dictionary = parse_solana_token_data(token_byte_data)
		
		#remove token accounts which no longer hold an NFT
		#also remove all tokens with amount bigger than 1, it indicates that its an spl token
		#there might also be some spls left which the user hold 1 of. those will be removed later
		if token_data["amount"] == 0 || token_data["amount"] > 1:
			continue
		nft_mints.append(Pubkey.new_from_string(token_data["mint"]))
	
	emit_signal("on_nft_load_started",nft_mints.size())
	
	for i in range(nft_mints.size()):	
		var nft:Nft = await get_nft_from_mint(nft_mints[i],load_textures)
		if nft == null:
			continue
		owned_nfts.append(nft)
		emit_signal("on_nft_loaded",nft)
		
	
	emit_signal("on_nft_load_finished",owned_nfts)
	nfts_loaded=true

	
func parse_solana_token_data(data: PackedByteArray) -> Dictionary:
	# Ensure that the data has a minimum length
	if data.size() < 64:
		print("Invalid token data")
		return {}
	
	# Extract the mint address (first 32 bytes)
	var mint_address = SolanaSDK.bs58_encode(data.slice(0, 32))
	var owner_address = SolanaSDK.bs58_encode(data.slice(32, 64))

	# Extract the amount (next 8 bytes) and convert it to a 64-bit integer
	var amount_bytes = data.slice(64, 72)
	var amount = amount_bytes.decode_u64(0)
	
	return {"mint":mint_address,"owner":owner_address,"amount":amount}
	
func get_nft_from_mint(nft_mint:Pubkey, load_texture:bool=false) -> Nft:
	var nft:Nft = Nft.new()
	
	var metadata = MplTokenMetadata.get_mint_metadata(nft_mint)
	print(metadata)
	if metadata==null:
		return null
	
	var uri:String = metadata.get_uri()
	#print(SolanaService.file_loader.test)
	var offchain_metadata = await SolanaService.file_loader.load_token_metadata(uri)
	#remove any token which is not an nft. spls dont have properties
	print(offchain_metadata)
	if !offchain_metadata.has("properties"):
		return null

	nft.set_data(nft_mint,metadata,offchain_metadata,load_texture)
	return nft
	

func get_all_owned_nfts() -> Array[Nft]:
	return owned_nfts
	
func get_nfts_from_collection(collection:NFTCollection) -> Array[Nft]:
	var collection_nfts:Array[Nft]
	
	for nft in owned_nfts:
		if collection.belongs_to_collection(nft):
			collection_nfts.append(nft)
			
	return collection_nfts
		
	
	

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
	var connected_wallet:Pubkey = SolanaService.wallet.get_pubkey()
	var wallet_tokens:Array[Pubkey] = await SolanaService.get_wallet_tokens(connected_wallet.get_value())
	emit_signal("on_nft_load_started",wallet_tokens.size())
	
	for i in range(wallet_tokens.size()):	
		var nft:Nft = await get_nft_from_mint(wallet_tokens[i],load_textures)
		if nft == null:
			continue
		owned_nfts.append(nft)
		emit_signal("on_nft_loaded",nft)
		
	
	emit_signal("on_nft_load_finished",owned_nfts)
	nfts_loaded=true

	
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
		
	
	
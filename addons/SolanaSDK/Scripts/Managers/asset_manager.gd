extends Node
class_name AssetManager

enum AssetFetchMode{OG,DAS}

enum AssetType {NONE,NFT, TOKEN}

@export var load_on_login:bool
@export var load_asset_textures:bool
@export var load_token_balances:bool
@export var log_loaded_assets:bool=false

var owned_assets:Array[WalletAsset]
var asset_cache:Array[WalletAsset]

@export var missing_texture_visual:Texture2D

var is_loading:bool=false
var assets_loaded=false

var asset_fetch_mode:AssetFetchMode

signal on_asset_load_started(asset_keys:Array[Pubkey])
signal on_asset_loaded(asset:WalletAsset)
signal on_asset_load_finished(assets:Array[WalletAsset])

func setup() -> void:
	set_asset_fetch_mode()
	SolanaService.on_rpc_cluster_set.connect(set_asset_fetch_mode)
	
	if load_on_login:
		SolanaService.wallet.on_login_finish.connect(try_load_assets)
		
func set_asset_fetch_mode() -> void:
	if SolanaService.das_compatible_rpc == "":
		asset_fetch_mode = AssetFetchMode.OG
	else:
		asset_fetch_mode = AssetFetchMode.DAS
		
func try_load_assets(logged_in:bool) -> void:
	if logged_in:
		load_assets()
		
func load_assets()->void:
#	if currently loading, dont trigger again
	if is_loading:
		return
		
	is_loading=true
	assets_loaded=false
	
	var wallet_to_load:Pubkey = SolanaService.wallet.get_pubkey()
	
	owned_assets.clear()
	
	#loading from OG and DAS are 2 different ways completely
	match asset_fetch_mode:
		AssetFetchMode.OG:	
			var wallet_token_accounts:Array[Dictionary] = await SolanaService.get_token_accounts(wallet_to_load)
			on_asset_load_started.emit(wallet_token_accounts.size())
			await load_user_assets_og(wallet_token_accounts)
		AssetFetchMode.DAS:
			var assets_data:Array = await SolanaService.get_wallet_assets_data(wallet_to_load,1000)
			on_asset_load_started.emit(assets_data.size())
			await load_das_assets(assets_data)
			#this only fetches NFTs, so gotta additionally load tokens as well
			#no need to adjust anything, because NFTs will be in cache and will be skipped
			var wallet_token_accounts:Array[Dictionary] = await SolanaService.get_token_accounts(wallet_to_load)
			await load_user_assets_og(wallet_token_accounts)
		
	on_asset_load_finished.emit(owned_assets)
	assets_loaded=true
	is_loading=false
	
func load_user_assets_og(token_accounts:Array[Dictionary]) -> void:
	for i in range(token_accounts.size()):	
		var asset_mint:Pubkey = Pubkey.new_from_string(token_accounts[i]["mint"])
		if get_owned_asset(asset_mint) != null:
			continue
			
		var asset:WalletAsset = await get_asset_from_mint(asset_mint,load_asset_textures)
		if asset == null:
			continue
		
		if asset is Token && load_token_balances:
			var token = asset as Token
			token.decimals = await SolanaService.get_token_decimals(asset_mint.to_string())
			token.balance = token_accounts[i]["amount"] / pow(10,token.decimals)
			
		if log_loaded_assets:
			print("Loaded: ",asset.asset_name," ",asset.mint.to_string())
		owned_assets.append(asset)
		on_asset_loaded.emit(asset)
		
		
func load_das_assets(assets_data:Array) -> void:
	for asset_data in assets_data:
		var metadata = MetaData.new()
		metadata.copy_from_dict(asset_data)
		var offchain_metadata:Dictionary = asset_data["content"]["metadata"]
		if asset_data["content"]["links"].has("image"):
			offchain_metadata["image"] = asset_data["content"]["links"]["image"]
			
		if get_owned_asset(metadata.get_mint()) != null:
			continue
			
		var asset:WalletAsset = await create_asset(metadata.get_mint(),metadata,offchain_metadata,load_asset_textures)
		if asset == null:
			continue
		
		if log_loaded_assets:
			print("Loaded: ",asset.asset_name," ",asset.mint.to_string())
		owned_assets.append(asset)
		on_asset_loaded.emit(asset)
		
#func load_assets_from_collection(nft_owner:Pubkey,collection_id:Pubkey) -> void:
	#match asset_fetch_mode:
		#AssetFetchMode.OG:	
			#push_error("This function only works in DAS fetch mode!")
			#return
		#AssetFetchMode.DAS:
			#var assets_data:Array = await SolanaService.get_collection_assets_data(nft_owner,collection_id)
			#print(assets_data)
			#await load_das_assets(assets_data)
	
func get_owned_asset(asset_mint:Pubkey) -> WalletAsset:
	for asset in owned_assets:
		if asset.mint.to_string() == asset_mint.to_string():
			return asset
	return null

func try_find_in_cache(asset_mint:Pubkey) -> WalletAsset:
	for asset in asset_cache:
		
		if asset.mint.to_string() == asset_mint.to_string():
			return asset
	return null

func get_asset_from_mint(asset_mint:Pubkey, load_texture:bool=false) -> WalletAsset:		
	var metadata:MetaData = await fetch_asset_metadata(asset_mint)
	if metadata==null:
		return null

	var asset:WalletAsset = await create_asset(asset_mint,metadata,{},load_texture)
	return asset
	
func fetch_asset_metadata(asset_mint:Pubkey) -> MetaData:
	var metadata:MetaData
	
	match asset_fetch_mode:
		AssetFetchMode.OG:
			var mpl_metadata:MplTokenMetadata = SolanaService.spawn_mpl_metadata_client()
			mpl_metadata.get_mint_metadata(asset_mint)
			metadata = await mpl_metadata.metadata_fetched
			mpl_metadata.queue_free()
		AssetFetchMode.DAS:
			var asset_data:Dictionary = await SolanaService.get_asset_data(asset_mint)
			metadata = MetaData.new()
			metadata.copy_from_dict(asset_data)
			
	return metadata
	
func create_asset(asset_mint:Pubkey, asset_data:MetaData,offchain_metadata:Dictionary,load_texture:bool) -> WalletAsset:		
	var asset_type:AssetType = get_asset_type(asset_data)
	match asset_type:
		AssetType.NONE:
			return null
		AssetType.NFT:
			var nft:Nft = Nft.new()
			await nft.set_data(asset_mint,asset_data,offchain_metadata,asset_type,load_texture)
			asset_cache.append(nft as WalletAsset)
			return nft
			pass
		AssetType.TOKEN:
			var token:Token = Token.new()
			await token.set_data(asset_mint,asset_data,offchain_metadata,asset_type,load_texture)
			asset_cache.append(token as WalletAsset)
			return token
			pass
			
	return null
	
	
# 0 - Non fungible token (Simple NFT)
# 1 - Semi fungible token (SFT)
# 2 - Fungible token (SPL)
# 3 - Non fungible edition (NFT edition)
# 4 - Programmable NFT
# 5 - Programmable NFT Edition		
func get_asset_type(metadata:MetaData) -> AssetType:
	if metadata.get_token_standard() == null:
		return AssetType.NONE
		
	var token_standard:int = metadata.get_token_standard()
	match token_standard:
		1,2:
			return AssetType.TOKEN
		0,3,4,5:
			return AssetType.NFT
			
	return AssetType.NONE

func get_owned_nfts() -> Array[WalletAsset]:
	var owned_nfts:Array[WalletAsset]
	for asset in owned_assets:
		if asset is Nft:
			owned_nfts.append(asset)
	return owned_nfts
	
func get_owned_tokens() -> Array[WalletAsset]:
	var owned_tokens:Array[WalletAsset]
	for asset in owned_assets:
		if asset is Token:
			owned_tokens.append(asset)
	return owned_tokens
	
func get_owned_nfts_from_collection_key(collection_id:Pubkey) -> Array[WalletAsset]:
	var collection_nfts:Array[WalletAsset]
	var owned_nfts:Array[WalletAsset] = get_owned_nfts()
	for nft in owned_nfts:
		if nft.metadata.get_collection() == null:
			continue
		if nft.metadata.get_collection().key.to_string() == collection_id.to_string():
			collection_nfts.append(nft)
			
	return collection_nfts
	
func get_owned_nfts_from_collection(collection:NFTCollection) -> Array[WalletAsset]:
	var collection_nfts:Array[WalletAsset]
	var owned_nfts:Array[WalletAsset] = get_owned_nfts()
	for nft in owned_nfts:
		if collection.belongs_to_collection(nft):
			collection_nfts.append(nft)
			
	return collection_nfts
	

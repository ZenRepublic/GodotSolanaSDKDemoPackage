extends Node
class_name WalletAsset

var mint:Pubkey

var asset_name:String
var symbol:String
var image:Texture2D

var asset_type:AssetManager.AssetType

var metadata:MetaData
var offchain_metadata:Dictionary

signal on_data_loaded

func set_data(mint_address:Pubkey,token_metadata:MetaData,token_offchain_metadata:Dictionary,asset_type:AssetManager.AssetType,autoload_image:bool=false,image_size:int=256) -> void:
	mint = mint_address
	metadata = token_metadata
	asset_name = metadata.get_token_name()
	symbol = metadata.get_symbol()
	self.asset_type = asset_type
	
	if token_offchain_metadata.size()>0:
		offchain_metadata = token_offchain_metadata
	else:
		if metadata.get_uri() != null and metadata.get_uri().length() > 0:
			offchain_metadata = await SolanaService.file_loader.load_token_metadata(metadata.get_uri())
			if offchain_metadata.size() == 0:
				push_warning("Offchain metadata of %s failed to load" % mint_address.to_string())
				
	if autoload_image:
		await try_load_image(image_size)
		
func try_load_image(size:int=256) -> void:
	if offchain_metadata.size()==0:
		return
		
	if !offchain_metadata.has("image"):
		push_warning("image does not exist on mint: %s" % mint.to_string())
		image = SolanaService.asset_manager.missing_texture_visual
		return
		
	image = await SolanaService.file_loader.load_token_image(offchain_metadata["image"],size)
	if image == null:
		push_warning("Couldn't fetch image for mint: %s" % mint.to_string())
		image = SolanaService.asset_manager.missing_texture_visual
		
	

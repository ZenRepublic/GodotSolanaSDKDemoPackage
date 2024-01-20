class_name Nft

var mint:Pubkey

var nft_name:String
var symbol:String
var image:Texture2D

#this is a state of a model, it can be used to instantiate a 3D node whenever using this:
#	var model:Node = gltf_document.generate_scene(state)
#	add_child(model)
var model_state:GLTFState

var metadata:MetaData
var offchain_metadata:Dictionary

signal on_data_loaded

func set_data(mint_address:Pubkey,token_metadata:MetaData, token_offchain_metadata:Dictionary,autoload_image:bool=false) -> void:
	mint = mint_address
	metadata = token_metadata
	nft_name = metadata.get_token_name()
	symbol = metadata.get_symbol()
	offchain_metadata = token_offchain_metadata
#	print(offchain_metadata)
	if autoload_image:
		load_image()
	
	
func load_image(size:int=512) -> void:
	image = await SolanaService.file_loader.load_token_image(offchain_metadata["image"],size)
	
func get_category() -> String:
	if offchain_metadata["properties"].has("category"):
		return offchain_metadata["properties"]["category"]
	else:
		return ""
		
func get_collection_mint() -> Pubkey:
	var nft_collection:MetaDataCollection = metadata.get_collection()[0]
	return nft_collection.key
	
func is_3D_model() -> bool:
	return get_category() == "vr"
	
func load_model() -> void:
	model_state = await SolanaService.file_loader.load_3d_model(offchain_metadata["animation_url"])
	
	
	

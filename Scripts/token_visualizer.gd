extends Node
class_name TokenVisualizer
#@export_file("*.png","*.jpg") var sol_icon_path:String
#@export_file("*.png","*.jpg") var missing_icon_path:String

@export var amount_label:Label
@export var token_visual:TextureRect
		
func set_token_data(token_mint:Pubkey,amount:float=0) -> void:
	amount_label.text = str(amount)
	
	if token_visual==null:
		push_error("No token visual provided!")
		return
		
	var onchain_metadata:MetaData = MplTokenMetadata.get_mint_metadata(token_mint)
	var uri:String = onchain_metadata.get_uri()
	
	var metadata_json:Dictionary = await SolanaService.file_loader.load_token_metadata(uri)
	var token_image:Texture2D = await SolanaService.file_loader.load_token_image(metadata_json["image"])

	token_visual.texture = token_image

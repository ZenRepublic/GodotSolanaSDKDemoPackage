extends Node
class_name TokenVisualizer
#@export_file("*.png","*.jpg") var missing_icon_path:String

@export var amount_label:Label
@export var token_visual:TextureRect
@export var load_on_ready:bool=false
@export var token_to_load:String
@export_file("*.png","*.jpg") var sol_icon_path:String

func _ready() -> void:
	if load_on_ready:
		load_token()
			
func load_token() -> void:
	var balance:float
	var user_wallet:String = SolanaService.wallet.get_pubkey().get_value()
	if token_to_load.length()==0:
		balance = SolanaService.get_sol_balance(user_wallet)
		set_token_data(balance)
	else:
		balance = SolanaService.get_token_balance(user_wallet,token_to_load)
		set_token_data(balance,Pubkey.new_from_string(token_to_load))
		
func set_token_data(amount:float=0,token_mint:Pubkey=null) -> void:
	amount_label.text = str(amount)
	
	if token_visual==null:
		push_error("No token visual provided!")
		return
		
	if token_mint == null:
		token_visual.texture=load(sol_icon_path)
	
	if token_mint!=null:
		token_to_load = token_mint.get_value()
		var onchain_metadata:MetaData = MplTokenMetadata.get_mint_metadata(token_mint)
		if onchain_metadata==null:
			push_error("Failed to fetch token metadata in a token visualizer!")
			return
			
		var uri:String = onchain_metadata.get_uri()
		var metadata_json:Dictionary = await SolanaService.file_loader.load_token_metadata(uri)
		var token_image:Texture2D = await SolanaService.file_loader.load_token_image(metadata_json["image"])

		token_visual.texture = token_image

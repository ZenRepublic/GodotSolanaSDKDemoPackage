extends Node

@export var model_nft_scn:PackedScene
@export var model_spawn:Node3D
var models:Array[ModelNFT]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !SolanaService.nft_manager.nfts_loaded:
		SolanaService.nft_manager.connect("on_nft_loaded",add_to_list)
		SolanaService.nft_manager.connect("on_nft_load_finished",nft_load_finished)
		SolanaService.nft_manager.load_nfts()
	else:
		setup(SolanaService.nft_manager.owned_nfts)
	pass # Replace with function body.


func setup(nfts:Array[Nft]) -> void:
	if models.size()!=null:
		clear_models()
	
	if nfts.size()==0:
		return
		
	for nft in nfts:
		add_to_list(nft)
		
func add_to_list(nft:Nft) -> void:
	if !nft.is_3D_model():
		return
		
	var model_nft:ModelNFT = model_nft_scn.instantiate()
	model_spawn.add_child(model_nft)
		
	model_nft.set_model(nft)
	models.append(model_nft)
	
func nft_load_finished(owned_nfts:Array[Nft])->void:
	pass
	
		
func clear_models() -> void:
	for model in models:
		model.queue_free()
	
	models.clear()


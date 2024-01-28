extends Node

@export var displayable_nft_scn:PackedScene
@export var collection_filter:Array[NFTCollection]
@export var container:Container

@export var no_nft_overlay:Control

var displayables:Array[DisplayableNFT]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !SolanaService.nft_manager.nfts_loaded:
		SolanaService.nft_manager.connect("on_nft_loaded",add_to_list)
		SolanaService.nft_manager.connect("on_nft_load_finished",nft_load_finished)
		SolanaService.nft_manager.load_nfts()
	else:
		if collection_filter.size()==0:
			setup(SolanaService.nft_manager.owned_nfts)
		else:
			for collection in collection_filter:
				setup(SolanaService.nft_manager.get_nfts_from_collection(collection))
	pass # Replace with function body.


func setup(nfts:Array[Nft],clear_previous:bool=false) -> void:
	if clear_previous && displayables.size()!=null:
		clear_display()
	
	if no_nft_overlay!=null:
		no_nft_overlay.visible = (nfts.size()==0)
	if nfts.size()==0:
		return
		
	for nft in nfts:
		add_to_list(nft)
		
func add_to_list(nft:Nft) -> void:
	var pass_collection_filter= (collection_filter.size()==0)
	for collection in collection_filter:
		if collection.belongs_to_collection(nft):
			pass_collection_filter=true
			break
	if !pass_collection_filter:
		return
		
	var displayable_nft:DisplayableNFT = displayable_nft_scn.instantiate()
	container.add_child(displayable_nft)
		
	displayable_nft.set_data(nft)
	displayables.append(displayable_nft)
	
func nft_load_finished(owned_nfts:Array[Nft])->void:
	pass
	
		
func clear_display() -> void:
	for nft in displayables:
		nft.queue_free()
	
	displayables.clear()

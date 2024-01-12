extends Node
class_name CandyMachineDisplay

@export var candy_machine_id:String
@export var candy_guard_id:String

@export var nft_display:DisplayableNFT
@export var collection_desc:Label
@export var minted_amount:Label
@export var progress_bar:ProgressBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var cm_data:CandyMachineData = SolanaService.candy_machine_manager.fetch_candy_machine(Pubkey.new_from_string(candy_machine_id))
	setup(cm_data)
	#print(cm_data.max_supply,cm_data.items_available)
	pass # Replace with function body.


func setup(cm_data:CandyMachineData) -> void:
	var collection_nft:Nft = await SolanaService.nft_manager.get_nft_from_mint(cm_data.collection_mint,true)
	nft_display.set_data(collection_nft)
	collection_desc.text = collection_nft.offchain_metadata["description"]

	minted_amount.text = "%s/%s Minted" % [cm_data.items_redeemed,cm_data.items_available]
	progress_bar.value = float(cm_data.items_redeemed)/float(cm_data.items_available)
	
	

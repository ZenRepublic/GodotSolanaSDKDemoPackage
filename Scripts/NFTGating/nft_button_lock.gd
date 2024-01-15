extends Button
class_name NFTButtonLock

enum NFTLockType {HELD_AMOUNT,MINT_MATCH,WALLET_ADDRESS}

@export var lock_active:bool
@export var lock_type:NFTLockType

@export var collection_gate:NFTCollection
@export var unlock_amount:int
@export var mint_list:Array[String]
@export var wallet_addresses:Array[String]

@export var hide_if_locked:bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if lock_active:
		set_interactable(false)
		try_unlock()
		SolanaService.nft_manager.connect("on_nft_load_finished",try_unlock)
	pass # Replace with function body.

func try_unlock() -> void:
	var held_nft_list:Array[Nft]
	if collection_gate!=null:
		held_nft_list = SolanaService.nft_manager.get_nfts_from_collection(collection_gate)
	
	match lock_type:
		NFTLockType.HELD_AMOUNT:
			set_interactable(held_nft_list.size()>=unlock_amount)
		NFTLockType.MINT_MATCH:
			var in_list=false
			for nft in held_nft_list:
				for eligible_nft in mint_list:
					if nft.mint.get_value() == eligible_nft:
						in_list=true
						break
				if in_list:
					break
			set_interactable(in_list)
		NFTLockType.WALLET_ADDRESS:
			var in_list=false
			var user_address:String = SolanaService.wallet.get_pubkey().get_value()
			for eligible_wallet in wallet_addresses:
				if eligible_wallet == user_address:
					in_list=true
					break
			set_interactable(in_list)
	pass

func set_interactable(state:bool) -> void:
	disabled = !state
	if state==false && hide_if_locked:
		visible=false
		

extends Node
class_name CandyMachineManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func fetch_candy_machine(cm_id:Pubkey) -> CandyMachineData:
	return MplCandyMachine.get_candy_machine_info(cm_id)
	
func mint_nft_with_guards(cm_id:Pubkey,guard_id:Pubkey,payer:Keypair,receiver:Pubkey,guards:Dictionary) -> void:
	var mint_account:Keypair = SolanaService.generate_keypair()
	var cm_data:CandyMachineData = fetch_candy_machine(cm_id)
	
	var mint_ix = MplCandyGuard.mint(
		cm_id,
		payer,
		receiver,
		mint_account.get_public_value(),
		payer,
		cm_data.collection_mint,
		cm_data.authority,
		guards
		)
		
	
		
	

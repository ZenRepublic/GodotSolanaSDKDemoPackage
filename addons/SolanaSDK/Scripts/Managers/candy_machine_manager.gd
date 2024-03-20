extends Node
class_name CandyMachineManager

var candy_machine:MplCandyMachine
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func fetch_candy_machine(cm_id:Pubkey) -> CandyMachineData:
	if candy_machine == null:
		candy_machine = MplCandyMachine.new()
		candy_machine.url = SolanaService.active_rpc
		add_child(candy_machine)
		
	candy_machine.get_candy_machine_info(cm_id)
	var cm_data:CandyMachineData = await candy_machine.info_fetched
	return cm_data
	
func mint_nft_with_guards(cm_id:Pubkey,guard_id:Pubkey,cm_data:CandyMachineData,payer:WalletService,receiver,guards:CandyGuardAccessList,group:String,custom_mint_account:Keypair=null) -> String:
	var mint_account:Keypair = custom_mint_account
	if mint_account==null:
		mint_account = SolanaService.generate_keypair()
	var instructions:Array[Instruction]
	
	var mint_ix:Instruction = MplCandyGuard.mint(
		cm_id,
		guard_id,
		payer.get_kp(),
		receiver,
		mint_account,
		payer.get_kp(),
		cm_data.collection_mint,
		cm_data.authority,
		guards,
		group
		)
		
	instructions.append(mint_ix)
	var tx_id:String = await SolanaService.transaction_processor.sign_transaction(payer.get_kp(),instructions,"finalized")
	return tx_id

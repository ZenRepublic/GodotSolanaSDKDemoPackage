extends ButtonLock

@export var token_gate_list:Dictionary

func try_unlock() -> void:
	super()
	var account_address = SolanaService.wallet.get_pubkey()
	
	var all_amounts_met:bool=true
	for key in token_gate_list.keys():
		var token_balance:float
		var token_address:String = key
		var unlock_amount = token_gate_list[key]
		
		if token_address.length()==0:
			token_balance = await SolanaService.get_balance(account_address.to_string())
		else:
			token_balance = await SolanaService.get_balance(account_address.to_string(),token_address)

		if token_balance<unlock_amount:
			all_amounts_met=false
			break
	
	set_interactable(all_amounts_met)

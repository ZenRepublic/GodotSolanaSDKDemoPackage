extends ButtonLock

@export var token_address:String
@export var unlock_amount:float

func try_unlock() -> void:
	super()
	var account_address = SolanaService.wallet.get_pubkey()
	var token_balance:float = SolanaService.get_token_balance(account_address.get_value(),token_address)
	set_interactable(token_balance>=unlock_amount)

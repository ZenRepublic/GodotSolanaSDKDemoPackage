extends Node
class_name SoarProgram

#for building custom program instructions, first goes function name, then array of accounts
#and then variables to pass in

#IMPORTANT:
#if no variables need to be passed in, write 'null'
#if multiple variables, put them in a dictionary
#if the variable is a class, pass it in as dictionary

@onready var soar_program:AnchorProgram = $SOAR_PROGRAM

signal on_game_initialized

func get_pid() -> Pubkey:
	return Pubkey.new_from_string(soar_program.get_pid())

func init_game(game_attributes:SoarUtils.GameAttributes) -> void:
	SolanaService.transaction_processor.connect("on_transaction_finish",init_game_response)
	var game_account:Keypair = SolanaService.generate_keypair()
	var instructions:Array[Instruction]
	print(game_attributes.get_value())
	print(game_account.get_public_value())
	var init_game_ix:Instruction = soar_program.build_instruction("initialize_game",[
		SolanaService.wallet.get_kp(), #creator
		game_account, #game
		Pubkey.new_from_string("11111111111111111111111111111111") #system program
	],{
		"GameMeta":game_attributes.get_value(),
		"GameAuth":[SolanaService.wallet.get_pubkey()]
	})
	
	instructions.append(init_game_ix)
	#SolanaClient.set_commitment("finalized")

	SolanaService.transaction_processor.try_sign_transaction(SolanaService.wallet,instructions)
	
func init_game_response(transaction_id:String) -> void:
	SolanaService.transaction_processor.disconnect("on_transaction_finish",init_game_response)
	if transaction_id!="":
		emit_signal("on_game_initialized")
	
	#var data:Dictionary = soar_program.fetch_account("Game",game_pda)
		
	
	
func add_leaderboard() -> void:
	pass
	
func update_leaderboard() -> void:
	pass

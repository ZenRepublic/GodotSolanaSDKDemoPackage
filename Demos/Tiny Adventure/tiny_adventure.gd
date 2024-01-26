extends Node

@onready var start_screen = $StartingScreen
@onready var game_screen = $GameScreen
@onready var anchor_program:AnchorProgram = $AnchorProgram

@export var tiny_adventure_pid:String
@export var start_button:ButtonLock

@export var player:TextureRect
@export var chest:TextureRect
@export var chest_prize:float
@export var prize_label:Label
@export var step_blocks:Array[CenterContainer]
@export var left_button:TextureButton
@export var right_button:TextureButton

@export var in_game_balance:TokenVisualizer

var level_pda
var vault_pda

var curr_pos:int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneLoader.emit_signal("scene_loaded")
	
	level_pda = Pubkey.new_pda(["Level1"],Pubkey.new_from_string(tiny_adventure_pid))
	vault_pda = Pubkey.new_pda(["Vault1"],Pubkey.new_from_string(tiny_adventure_pid))
	
	start_button.text = "START GAME (%s SOL)" % chest_prize
	start_button.pressed.connect(init_game)
	left_button.pressed.connect(move_left)
	right_button.pressed.connect(move_right)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func init_game() -> void:
	SolanaService.transaction_processor.connect("on_transaction_finish",start_game_callback)
	var prize_in_lamports:int = int(chest_prize*pow(10,9))
	var instructions:Array[Instruction]
	var init_ix:Instruction = anchor_program.build_instruction("restart_level",[
		level_pda, #gamedata
		vault_pda, #gamevault
		SolanaService.wallet.get_kp(), #signer
		Pubkey.new_from_string("11111111111111111111111111111111") #system program
	],
	AnchorProgram.u64(prize_in_lamports))
	
	instructions.append(init_ix)
	SolanaService.transaction_processor.try_sign_transaction(SolanaService.wallet,instructions)

func start_game_callback(transaction_id:String) -> void:
	SolanaService.transaction_processor.disconnect("on_transaction_finish",start_game_callback)
	if transaction_id=="":
		push_error("Failed to start game")
		return
		
	update_prize()
	set_player_pos()
	in_game_balance.load_token()
	
	start_screen.visible=false
	game_screen.visible=true
	
	
func move_left() -> void:
	move("move_left")
func move_right() -> void:
	move("move_right")
	
func move(move_dir:String) -> void:
	SolanaService.transaction_processor.connect("on_transaction_finish",move_callback)
	var instructions:Array[Instruction]
	var move_ix:Instruction = anchor_program.build_instruction(move_dir,[
		level_pda, #gamedata
		vault_pda, #gamevault
		SolanaService.wallet.get_kp(), #signer
		Pubkey.new_from_string("11111111111111111111111111111111") #system program
	],null)
	
	instructions.append(move_ix)
	SolanaService.transaction_processor.try_sign_transaction(SolanaService.wallet,instructions)

func move_callback(transaction_id:String) -> void:
	SolanaService.transaction_processor.disconnect("on_transaction_finish",move_callback)
	if transaction_id=="":
		push_error("Failed to move")
		return
		
	set_player_pos()
	
func update_prize() -> void:
	var data:Dictionary = anchor_program.fetch_account("GameVault",vault_pda)
	var prize_in_sol:float = float(data["chestPrize"])/pow(10,9)
	prize_label.text = "%s SOL" % str(prize_in_sol)
	
func set_player_pos() -> void:
	var data:Dictionary = anchor_program.fetch_account("GameData",level_pda)
	var new_pos = data["characterPos"]
	player.get_parent().remove_child(player)
	step_blocks[new_pos].add_child(player)
	
	if new_pos == step_blocks.size()-1:
		in_game_balance.load_token()
		chest.visible=false

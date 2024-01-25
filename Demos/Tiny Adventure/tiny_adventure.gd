extends Node

@onready var start_screen = $StartingScreen
@onready var game_screen = $GameScreen
@onready var anchor_program:AnchorProgram = $AnchorProgram

@export var tiny_adventure_pid:String
@export var start_button:ButtonLock

@export var player:TextureRect
@export var chest:TextureRect
@export var chest_prize:float
@export var step_blocks:Array[CenterContainer]
@export var left_button:TextureButton
@export var right_button:TextureButton

var level_pda
var vault_pda

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneLoader.emit_signal("scene_loaded")
	
	level_pda = Pubkey.new_pda(["Level1"],Pubkey.new_from_string(tiny_adventure_pid))
	vault_pda = Pubkey.new_pda(["Vault1"],Pubkey.new_from_string(tiny_adventure_pid))
	
	start_button.pressed.connect(init_game)
	left_button.pressed.connect(move_left)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func init_game() -> void:
	SolanaService.transaction_processor.connect("on_transaction_finish",start_game_callback)
	var instructions:Array[Instruction]
	var init_ix:Instruction = anchor_program.build_instruction("restart_level",[
		level_pda, #gamedata
		vault_pda, #gamevault
		SolanaService.wallet.get_kp(), #signer
		Pubkey.new_from_string("11111111111111111111111111111111") #system program
	],
	AnchorProgram.u64(chest_prize))
	
	instructions.append(init_ix)
	SolanaService.transaction_processor.try_sign_transaction(SolanaService.wallet,instructions)

func start_game_callback(transaction_id:String) -> void:
	if transaction_id=="":
		push_error("Failed to start game")
		return
		
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
	if transaction_id=="":
		push_error("Failed to move")
		return
	
	

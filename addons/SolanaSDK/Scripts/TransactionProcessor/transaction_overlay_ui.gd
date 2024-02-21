extends Node

@export var loading_panel:Node
@export var fail_panel:Node
@export var success_panel:Node

@export var time_to_close = 2.5

@onready var screen_switcher = $ScreenSwitcher

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	loading_panel.visible=false
	fail_panel.visible=false
	success_panel.visible=false	
	SolanaService.transaction_processor.on_transaction_init.connect(enable_tx_screen)
	SolanaService.transaction_processor.on_transaction_finish.connect(process_tx_finish)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func enable_tx_screen() -> void:
	screen_switcher.switch_active_panel(loading_panel)
	
func process_tx_finish(tx_id:String) -> void:
	if tx_id=="":
		screen_switcher.switch_active_panel(fail_panel)
	else:
		screen_switcher.switch_active_panel(success_panel)
	
	await get_tree().create_timer(time_to_close).timeout
	screen_switcher.close_active_panel()


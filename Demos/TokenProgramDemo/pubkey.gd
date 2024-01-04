#extends Node2D
#
#
## Called when the node enters the scene tree for the first time.
#func _ready():
#	#$HTTPRequest.request("https://api.mainnet-beta.solana.com", ["Content-Type: application/json"], HTTPClient.METHOD_POST, '{"id":1,"jsonrpc":"2.0","method":"getLatestBlockhash","params":[{"commitment":"processed"}]}"')
#	#var data = await $HTTPRequest.request_completed
#	#print(data)
#	#$Button.text = str(data[1])
#
#
#	SolanaClient.set_url("https://docs-demo.solana-mainnet.quiknode.pro/");
##	SolanaClient.set_url("https://api.testnet.solana.com");
#
#	#print(SolanaClient.get_latest_blockhash())
#	#print(SolanaClient.get_account_info("2MxLx9GYPSpkpGQX5RsLo3BnZsxNPZj9etFiHNy9E4RS"))
#	#print(SolanaClient.get_balance("2MxLx9GYPSpkpGQX5RsLo3BnZsxNPZj9etFiHNy9E4RS"))
#	#print(SolanaClient.get_version())
#
#	$PhantomController.connect_phantom()
#	await $PhantomController.connection_established 
#	$Button/Transaction.update_latest_blockhash("")
#	print("start serialize")
#	print($Button/Transaction.serialize())
#	print("end serialize")
#	print("start serialize22222222222222")
#	print($Button/Transaction.serialize())
#	print("end serialize222222222222222")
#	#print($Button/Transaction.serialize())
#	#print("hello")
#	#print($Button/Transaction.serialize())
#	print($Button/Transaction.get_instructions()[0].data)
#	$Button/Transaction.sign();
#	await $Button/Transaction.fully_signed
#
#	print("fully_signed")
#
#	SolanaClient.set_encoding("base64");
#
#	print($Button/Transaction.send())
#	#print($Button/Transaction.serialize())
#
#	return
#	SolanaClient.set_url("https://api.devnet.solana.com");
#
#	print(SolanaSDK.bs58_encode([2,59,33,202,202,163,65,255,29,189,228,74,93,177,187,124,224,211,88,41,35,3,137,170,249,87,97,63,140,98,50,137,106,182,3,0,234,52,59,186,168,105,100,12,90,227,239,25,156,46,60,198,134,167,178,152,153,1,70,152,164,165,16,76,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2,1,2,4,20,57,225,120,103,96,103,29,157,138,191,101,253,133,18,113,31,250,46,118,39,190,250,94,32,59,119,220,114,139,120,189,59,106,39,188,206,182,164,45,98,163,168,208,42,111,13,115,101,50,21,119,29,226,67,166,58,192,72,161,139,89,218,41,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,101,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,3,3,100,0,0,1,20,4,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,2,3,0,1,3,5,100,97,116,97,114]))
#
#	var arr := PackedStringArray(["hi"])
#	var a = Pubkey.new();
#
#
#	var keyp = Keypair.new();
#	keyp.set_unique(false)
#	var seed := PackedByteArray()
#	seed.resize(32)
#	keyp.set_seed(seed);
#	print("keyp is ", keyp.get_public_value())
#
#	var msg2 = PackedByteArray([0, 0, 0])
#
#	var signat = keyp.sign_message(msg2)
#	print(signat)
#	if keyp.verify_signature(signat, msg2):
#		print("VERIIIFI")
#
#
#	var pid_bytes := PackedByteArray()
#	pid_bytes.resize(32)
#	var pid = Pubkey.new()
#	pid.set_bytes(pid_bytes)
#
#	print(pid.bytes)
#	print(arr)
#
#	a.create_program_address(arr, pid);
#	for i in range(a.bytes.size()):
#		$Button.text += str(a.bytes[i])
#
#	print(a.bytes)
#	#$Button.text = String("Pubkey.new().print()")
#
#	var eee = Pubkey.new()
#	eee.create_from_string("Config1111111111111111111111111111111111111")
#	print(eee.get_associated_token_address(a, a))
#	print(eee.bytes)
#
#	#var ddd = Keypair.new()
#	#print(ddd.get_private_value())
#	#print(ddd.get_public_value())
#
#	$PhantomController.connect_phantom()
#	await $PhantomController.connection_established
#	print("CONNECTED");
#
#	print("serializing")
#	print($Button/Transaction.serialize())
#	#var cont1 = $Button/Transaction.serialize()
#
#	$Button/Transaction.update_latest_blockhash("");
#
#	print($Button/Transaction.sign(1))
#
#	await $Button/Transaction.fully_signed
#	print("FULLY signed")
#
#	$Button/Transaction.send();
#
#	return
#	var temp_message := PackedByteArray();
#	temp_message.resize(20);
#	$PhantomController.sign_message(temp_message)
#	await $PhantomController.message_signed
#	print("SIGNED");
#	pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
#
#
#func _on_phantom_controller_connection_established():
#	print("Connected")
#	pass # Replace with function body.
#
#
#func _on_phantom_controller_connection_error():
#	print("error")
#	pass # Replace with function body.
#
#
#func _on_phantom_controller_message_signed(signature):
#	print("SIGNED: ", signature)
#
#	pass # Replace with function body.

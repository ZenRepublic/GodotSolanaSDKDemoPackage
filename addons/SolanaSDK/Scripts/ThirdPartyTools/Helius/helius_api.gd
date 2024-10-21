extends Node
class_name HeliusAPI
#can add unsafeMax as well
enum PriorityFeeLevel {min,low,medium,high,veryHigh}

@export var helius_api_key:String
## this is important to know whether we can force a staked connection to send a transaction in case of congestion
@export var using_paid_plan:bool

@export var priority_fee_level:PriorityFeeLevel
@export var use_recommended_fee:bool = true
@export var fee_to_consider_congested:int = 10000
@export var override_das_rpc:bool=false

func _ready() -> void:
	if override_das_rpc:
		SolanaService.on_rpc_cluster_set.connect(override_default_das_rpc)
		
func override_default_das_rpc() -> void:
	SolanaService.das_compatible_rpc = get_rpc_url()

func get_rpc_url(staked:bool=false) -> String:
	if helius_api_key == "":
		print("Couldn't get a helius RPC because the API key is missing")	
		return ""
		
	var url_type:String = ""
	if staked:
		if using_paid_plan:
			url_type = "staked"
		else:
			print("Can't use a staked connection without a paid helius plan")
			return ""
	else:
		match SolanaService.rpc_cluster:
			SolanaService.RpcCluster.MAINNET:
				url_type = "mainnet"
			SolanaService.RpcCluster.DEVNET:
				url_type = "devnet"
	
	if url_type == "":
		print("Couldn't get a helius RPC from selected RPC cluster")	
		return ""
		
	var rpc_url:String = "https://%s.helius-rpc.com/?api-key=%s" % [url_type,helius_api_key]
	return rpc_url
	
func is_network_congested(calculated_fee:int) -> bool:
	return calculated_fee >= fee_to_consider_congested
	

func get_estimated_priority_fee(transaction:Transaction) -> int:
	var rpc_url = get_rpc_url()
	if rpc_url == "":
		return 0
		
	var options:Dictionary
	if use_recommended_fee:
		options = {"recommended": true}
	else:
		options = {"includeAllPriorityFeeLevels": true}
		
	var serialized_tx:String = SolanaUtils.bs58_encode(transaction.serialize())
	var headers:Array = ["Content-type: application/json"]
	var body:Dictionary = {
		"jsonrpc": "2.0",
		"id": "1",
		"method": "getPriorityFeeEstimate",
		"params": [{
			"transaction":serialized_tx,
			"options": options
		}]
	}
	var response:Dictionary = await send_post_request(JSON.stringify(body),headers,rpc_url)
	if response.size() == 0 or response.has("error"):
		push_error(response)
		return 0
	
	var fee_estimate:int
	if use_recommended_fee:
		fee_estimate = int(response["result"]["priorityFeeEstimate"])
	else:
		var level:String = str(PriorityFeeLevel.keys()[priority_fee_level])
		fee_estimate = int(response["result"]["priorityFeeLevels"][level])
		
	return fee_estimate
	
func send_post_request(body, headers:Array,endpoint:String) -> Dictionary:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var request = http_request.request(endpoint,headers,HTTPClient.METHOD_POST,body)
	if request != OK:
		push_error("An error occurred in the HTTP request.")
		return {}
		
	var raw_response = await http_request.request_completed
	http_request.queue_free()
	var response_dict = parse_http_response(raw_response,true)

	if response_dict["response_code"] != 200:
		print(response_dict)
		return {}
	
	return response_dict["body"]
	
func parse_http_response(response:Array, body_to_json:bool=false) -> Dictionary:
	var body = response[3]
	if body_to_json:
		var json = JSON.new()
		json.parse(response[3].get_string_from_utf8())
		body = json.get_data()
	
	var dict = {
		"result":response[0],
		"response_code":response[1],
		"headers":response[2],
		"body":body
	}
	return dict

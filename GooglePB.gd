extends Node

# Matches BillingClient.ConnectionState in the Play Billing Library
enum ConnectionState {
	DISCONNECTED, # not yet connected to billing service or was already closed
	CONNECTING, # currently in process of connecting to billing service
	CONNECTED, # currently connected to billing service
	CLOSED, # already closed and shouldn't be used again
}

# Matches Purchase.PurchaseState in the Play Billing Library
enum PurchaseState {
	UNSPECIFIED,
	PURCHASED,
	PENDING,
}

var payment
export(Array, String) var persistent:Array = ["test_premium"]
export(Array, String) var non_persistent:Array = ["test_100coins"]
var list_products: Array = persistent + non_persistent
#persistent examples: premium, special item
#non persistent examples: bag of coins

var pending_purchases
var gpb_product_details

func _ready():
	if Engine.has_singleton("GodotGooglePlayBilling"):
		payment = Engine.get_singleton("GodotGooglePlayBilling")

		# These are all signals supported by the API
		# You can drop some of these based on your needs
		payment.connect("billing_resume", self, "_on_billing_resume") # No params
		payment.connect("connected", self, "_on_connected") # No params
		payment.connect("disconnected", self, "_on_disconnected") # No params
		payment.connect("connect_error", self, "_on_connect_error") # Response ID (int), Debug message (string)
		payment.connect("price_change_acknowledged", self, "_on_price_acknowledged") # Response ID (int)
		payment.connect("purchases_updated", self, "_on_purchases_updated") # Purchases (Dictionary[])
		payment.connect("purchase_error", self, "_on_purchase_error") # Response ID (int), Debug message (string)
		payment.connect("sku_details_query_completed", self, "_on_product_details_query_completed") # SKUs (Dictionary[])
		payment.connect("sku_details_query_error", self, "_on_product_details_query_error") # Response ID (int), Debug message (string), Queried SKUs (string[])
		payment.connect("purchase_acknowledged", self, "_on_purchase_acknowledged") # Purchase token (string)
		payment.connect("purchase_acknowledgement_error", self, "_on_purchase_acknowledgement_error") # Response ID (int), Debug message (string), Purchase token (string)
		payment.connect("purchase_consumed", self, "_on_purchase_consumed") # Purchase token (string)
		payment.connect("purchase_consumption_error", self, "_on_purchase_consumption_error") # Response ID (int), Debug message (string), Purchase token (string)
		payment.connect("query_purchases_response", self, "_on_query_purchases_response") # Purchases (Dictionary[])

		payment.startConnection()
	else:
		print("Android IAP support is not enabled. Make sure you have enabled 'Gradle Build' and the GodotGooglePlayBilling plugin in your Android export settings! IAP will not work.")


###Connecting and getting available products

func _on_connected():
	payment.querySkuDetails(list_products, "inapp") # "subs" for subscriptions

func _on_product_details_query_completed(product_details):
	gpb_product_details = product_details
	get_tree().call_group("gpb listener", "_on_gpb_product_details_updated")
	_query_purchases()

func _on_product_details_query_error(response_id, error_message, products_queried):
	print("on_product_details_query_error id:", response_id, " message: ",
			error_message, " products: ", products_queried)


###Getting purchased products

func _query_purchases():
	payment.queryPurchases("inapp") # Or "subs" for subscriptions

func _on_query_purchases_response(query_result):
	if query_result.status == OK:
		pending_purchases = query_result.purchases
		for purchase in query_result.purchases:
			_process_purchase(purchase)
	else:
		print("queryPurchases failed, response code: ",
				query_result.response_code,
				" debug message: ", query_result.debug_message)

func _on_billing_resume():
	if payment.getConnectionState() == ConnectionState.CONNECTED:
		_query_purchases()

func _on_purchases_updated(purchases):
	for purchase in purchases:
		_process_purchase(purchase)

func _on_purchase_error(response_id, error_message):
	print("purchase_error id:", response_id, " message: ", error_message)

###Processing purchases
func _process_purchase(purchase):
		if purchase.purchase_state == PurchaseState.PURCHASED:
			if purchase.sku in non_persistent:
				#consume if non persistent
				payment.consumePurchase(purchase.purchase_token)
			else:
				#acknowledge if persistent
				payment.acknowledgePurchase(purchase.purchase_token)

func _on_purchase_consumed(purchase_token):
	var _product_id = get_product_id_from_token(purchase_token)
	if _product_id in non_persistent:
		#consume if non persistent
		_handle_purchase_token(purchase_token, true)
	else:
		#tell the game to remove the product if was persistent
		get_tree().call_group("gpb listener", "_on_purchase_consumed", _product_id)

func _on_purchase_consumption_error(response_id, error_message, purchase_token):
	print("_on_purchase_consumption_error id:", response_id,
			" message: ", error_message)
	_handle_purchase_token(purchase_token, false)

func _on_purchase_acknowledged(purchase_token):
	_handle_purchase_token(purchase_token, true)

func _on_purchase_acknowledgement_error(response_id, error_message, purchase_token):
	print("_on_purchase_acknowledgement_error id: ", response_id,
			" message: ", error_message)
	_handle_purchase_token(purchase_token, false)

# Find the sku associated with the purchase token and award the
# product if successful
func _handle_purchase_token(purchase_token, purchase_successful):
	if purchase_successful:
		var _product_id = get_product_id_from_token(purchase_token)
		get_tree().call_group("gpb listener", "_on_purchase_successful", _product_id)


###Useful extra functions
func get_price(product_id) -> String:
	for page in gpb_product_details:
		match page["sku"]:
			product_id:
				return page["price"]
	return "?"

func get_token_from_product_id(purchase: String) -> String:
	for page in pending_purchases:
		match page["sku"]:
			purchase:
				return page["purchase_token"]
	return "?"

func get_product_id_from_token(purchase_token) -> String:
	for page in pending_purchases:
		match page["purchase_token"]:
			purchase_token:
				return page["sku"]
	return "?"

extends Control

onready var btn_buy_premium:= get_node("CenterContainer/VBoxContainer/Purchase")
onready var btn_buy_consumable:= get_node("CenterContainer/VBoxContainer/PurchaseConsumable")

onready var label_status:= get_node("CenterContainer/VBoxContainer/LabelStatus")
onready var label_output:= get_node("CenterContainer/VBoxContainer/LabelOutput")
onready var label_coins:= get_node("CenterContainer/VBoxContainer/LabelCoins")

var list_consumable: Array = ["test_100coins"]
var list_non_consumable: Array =["test_premium"]
var list_products: Array = list_consumable + list_non_consumable

var premium_status: bool = false setget set_premium_status
var coins: int = 0 setget set_coins


func set_premium_status(value: bool) -> void:
	premium_status = value
	
	if premium_status:
		label_status.text = ("premium :)")
	else:
		label_status.text = ("no premium :(")

func set_coins(value):
	coins = value
	label_coins.text = "coins: "+str(coins)


func _ready() -> void:
	if not Engine.has_singleton("GodotGooglePlayBilling"):
		print_label("GooglePlayBilling not found")

func print_label(text: String):
	label_output.text = text

func update_premium_text(price):
	btn_buy_premium.text = "Buy premium (" + price + ")"

func update_consumable_text(price):
	btn_buy_consumable.text = "Buy 100 coins (" + price + ")"


func _on_gpb_product_details_updated():
	print_label("product details updated")
	update_premium_text(GooglePB.get_price("test_premium"))
	update_consumable_text(GooglePB.get_price("test_100coins"))

#here goes the logic to give the player the product for any purchase
func _on_purchase_successful(_product_id):
	print_label("purchased "+_product_id)
	match _product_id:
		"test_premium":
			set_premium_status(true)
		"test_100coins":
			set_coins(coins + 100)

#meant to be used only when a persistent product is consumed
func _on_purchase_consumed(_product_id):
	print_label("consumed "+_product_id)
	match _product_id:
		"test_premium":
			set_premium_status(false)

func _on_Purchase_pressed() -> void:
	if Engine.has_singleton("GodotGooglePlayBilling"):
		GooglePB.payment.purchase("test_premium")

func _on_Revoke_pressed():
	if Engine.has_singleton("GodotGooglePlayBilling"):
		GooglePB.payment.consumePurchase(GooglePB.get_token_from_product_id("test_premium"))

func _on_PurchaseConsumable_pressed() -> void:
	if Engine.has_singleton("GodotGooglePlayBilling"):
		GooglePB.payment.purchase("test_100coins")

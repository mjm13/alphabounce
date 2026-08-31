extends Node

## 商店管理器（Autoload 单例）。
## 货币（星星 Star）与库存由本管理器内存态承担，不依赖 R07 存档先完成；
## R07 完成后可改为读写 PlayerData，接口保持不变。
##
## 注：shop_item.gd 不使用 class_name（全局类缓存对新文件滞后），
## 故这里用 preload 常量实例化并通过 load_from 填充。

const ShopItemClass = preload("res://scripts/systems/shop_item.gd")

signal shop_loaded
signal currency_changed(new_value: int)
signal purchase_made(item_id: String, ok: bool)
signal inventory_changed

const START_CURRENCY := 30

var items: Array = []            # Array[ShopItem]
var currency: int = START_CURRENCY
var inventory: Dictionary = {}    # item_id -> int


func load_shop_from_file(path: String) -> bool:
	var txt := FileAccess.get_file_as_string(path)
	if txt.is_empty():
		printerr("R06_SHOP_MISSING: ", path)
		return false
	var arr = JSON.parse_string(txt)
	if typeof(arr) != TYPE_ARRAY:
		printerr("R06_SHOP_BAD_JSON")
		return false
	items.clear()
	for d in arr:
		var si = ShopItemClass.new()
		if not si.load_from(d):
			continue
		items.append(si)
	shop_loaded.emit()
	return true


## 读取起始货币（R07 接管前用 mock save_demo.json）。
func load_currency_from_save(path: String) -> void:
	var txt := FileAccess.get_file_as_string(path)
	if txt.is_empty():
		return
	var d = JSON.parse_string(txt)
	if typeof(d) == TYPE_DICTIONARY and d.has("currency"):
		currency = int(d["currency"])


func get_item(item_id: String):
	for si in items:
		if si.item_id == item_id:
			return si
	return null


func can_afford(item_id: String) -> bool:
	var si = get_item(item_id)
	if si == null:
		return false
	return currency >= si.price


func purchase(item_id: String) -> bool:
	if not can_afford(item_id):
		purchase_made.emit(item_id, false)
		return false
	var si = get_item(item_id)
	currency -= si.price
	if not inventory.has(item_id):
		inventory[item_id] = 0
	inventory[item_id] += 1
	currency_changed.emit(currency)
	inventory_changed.emit()
	purchase_made.emit(item_id, true)
	return true


func get_inventory_count(item_id: String) -> int:
	return int(inventory.get(item_id, 0))

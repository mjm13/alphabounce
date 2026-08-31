extends Control

## 商店面板：列出 ShopManager 中的商品，含价格与购买按钮。
## 货币不足时对应购买按钮置灰不可点击（AC-4）。
## List 直接挂在面板下（与 MissionPanel 一致），便于 debug 场景 get_node("List") 断言。

var _currency_label: Label
var _list: VBoxContainer


func _ready() -> void:
	_currency_label = Label.new()
	_currency_label.name = "Currency"
	_currency_label.add_theme_font_size_override("font_size", 20)
	add_child(_currency_label)

	_list = VBoxContainer.new()
	_list.name = "List"
	_list.add_theme_constant_override("separation", 4)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_list)

	refresh()


func refresh() -> void:
	_currency_label.text = "🪙 星星: %d" % ShopManager.currency
	for c in _list.get_children():
		c.queue_free()
	for si in ShopManager.items:
		var h := HBoxContainer.new()
		var lbl := Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.text = "%s  [%d⭐]  库存:%d" % [si.name, si.price, ShopManager.get_inventory_count(si.item_id)]
		var btn := Button.new()
		if not ShopManager.can_afford(si.item_id):
			btn.disabled = true
			btn.text = "买(缺星)"
		else:
			btn.text = "买"
			btn.pressed.connect(_on_buy.bind(si.item_id))
		h.add_child(lbl)
		h.add_child(btn)
		_list.add_child(h)


func _on_buy(item_id: String) -> void:
	if ShopManager.purchase(item_id):
		refresh()

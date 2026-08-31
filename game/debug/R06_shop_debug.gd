extends Control

## R06 真机独立验收入口：由 DebugLauncher 进入（res://debug/R06_shop_debug.tscn）。
## 自含 5 个示例商品 + 商店面板；购买触发扣费 + 库存增加。
## 逐 AC 打印 R06_AC-n PASS/FAIL（不依赖任何未完成的上游需求）。
## 货币/库存由 ShopManager 内存态承担，不依赖 R07 存档先完成。

const SHOP_DEMO = "res://debug/fixtures/shop_demo.json"
const SAVE_DEMO = "res://debug/fixtures/save_demo.json"
const PANEL_SCENE = preload("res://scenes/ui/ShopPanel.tscn")

var _hud: Label
var _ac_lines: Array = []


func _ready() -> void:
	_hud = Label.new()
	_hud.position = Vector2(12, 12)
	_hud.add_theme_font_size_override("font_size", 22)
	add_child(_hud)

	# AC-1：ShopItem 可从 JSON 正确解析（id/name/price/type）
	var ok := ShopManager.load_shop_from_file(SHOP_DEMO)
	var ac1 := ok and ShopManager.items.size() == 5
	if ac1:
		for si in ShopManager.items:
			if si.item_id.is_empty() or si.name.is_empty() or si.price <= 0 or si.type.is_empty():
				ac1 = false
	print_ac("R06", 1, ac1)

	# 载入初始货币（来自 mock save）
	ShopManager.load_currency_from_save(SAVE_DEMO)

	# AC-2：加载 5 个商品，玩家初始货币为 30 Star
	var ac2 := ShopManager.items.size() == 5 and ShopManager.currency == 30
	print_ac("R06", 2, ac2)

	# AC-3：购买成功后货币扣除、物品加入 inventory
	var before := ShopManager.currency
	var buy_id := _first_affordable()
	var ac3 := false
	if buy_id != "":
		var si = ShopManager.get_item(buy_id)
		var inv_before := ShopManager.get_inventory_count(buy_id)
		var bought := ShopManager.purchase(buy_id)
		ac3 = bought and ShopManager.currency == before - si.price and ShopManager.get_inventory_count(buy_id) == inv_before + 1
	print_ac("R06", 3, ac3)

	# AC-4：货币不足时购买不可用（can_afford == false）
	var unaff := _first_unaffordable()
	var ac4 := unaff != "" and not ShopManager.can_afford(unaff)
	print_ac("R06", 4, ac4)

	# 创建商店面板
	var panel = PANEL_SCENE.instantiate()
	panel.position = Vector2(12, 60)
	add_child(panel)

	# AC-5：面板正确渲染 5 行商品网格，购买按钮可交互
	var rows := panel.get_node("List").get_child_count()
	var ac5 := rows == 5
	print_ac("R06", 5, ac5)

	panel.refresh()
	_update_hud()

	var done := Label.new()
	done.text = "商店系统验收完成"
	done.position = Vector2(12, 330)
	done.add_theme_font_size_override("font_size", 24)
	add_child(done)

	_flush_ac()


func _first_affordable() -> String:
	for si in ShopManager.items:
		if ShopManager.currency >= si.price:
			return si.item_id
	return ""


func _first_unaffordable() -> String:
	for si in ShopManager.items:
		if ShopManager.currency < si.price:
			return si.item_id
	return ""


func _update_hud() -> void:
	_hud.text = "商品数: %d  货币: %d⭐" % [ShopManager.items.size(), ShopManager.currency]


func print_ac(req_id: String, n: int, ok: bool) -> void:
	var line := "%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"]
	print(line)
	if not ok:
		printerr(line)
	_ac_lines.append(line)


func _flush_ac() -> void:
	# 桌面端（Windows）把 AC 结果落盘，便于无 stdout 捕获环境下核验；Android 端自动跳过。
	if OS.get_name() != "Windows":
		return
	var f := FileAccess.open("d:/Project/SELF/alphabounce/r06_ac_result.txt", FileAccess.WRITE)
	if f != null:
		for l in _ac_lines:
			f.store_string(l + "\n")
		f.close()

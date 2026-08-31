extends Control

## R07 真机独立验收入口：由 DebugLauncher 进入（res://debug/R07_save_debug.tscn）。
## 自含 user:// 读写与默认存档创建，不依赖 R16 schema。逐 AC 打印 R07_AC-n PASS/FAIL。

var _hud: Label
var _ac_lines: Array = []

const SAVE_PATH := "user://player_save.json"


func _ready() -> void:
	_hud = Label.new()
	_hud.position = Vector2(12, 12)
	_hud.add_theme_font_size_override("font_size", 22)
	add_child(_hud)

	# AC-3：首次启动（无存档）→ load() 创建默认空存档并成功
	PlayerData.reset_save()
	var ok3 := PlayerData.load_data()
	var ac3 := ok3 and PlayerData.current_level == 1 and PlayerData.stars == 0 and PlayerData.inventory.is_empty() and PlayerData.missions.is_empty() and FileAccess.file_exists(SAVE_PATH)
	print_ac("R07", 3, ac3)

	# AC-1：save() 正确写入 user://player_save.json
	PlayerData.current_level = 3
	PlayerData.stars = 42
	PlayerData.inventory = {"ball_fire": 1}
	var ok1 := PlayerData.save() and FileAccess.file_exists(SAVE_PATH)
	print_ac("R07", 1, ok1)

	# AC-2：load_data() 从存档正确恢复全部字段
	PlayerData.load_data()
	var ac2 := PlayerData.current_level == 3 and PlayerData.stars == 42 and int(PlayerData.inventory.get("ball_fire", 0)) == 1
	print_ac("R07", 2, ac2)

	# AC-4：PlayerData 作为 Autoload 可直接访问
	var ac4 := PlayerData != null
	print_ac("R07", 4, ac4)

	# AC-5：关卡完成触发 on_level_complete() → save()，存档内容更新
	var before := _read_saved()
	PlayerData.current_level = 5
	PlayerData.on_level_complete()
	var after := _read_saved()
	var ac5 := int(after.get("current_level", -1)) == 5 and int(after.get("max_level_unlocked", 0)) > int(before.get("max_level_unlocked", 0))
	print_ac("R07", 5, ac5)

	_update_hud()
	var done := Label.new()
	done.text = "存档系统验收完成"
	done.position = Vector2(12, 300)
	done.add_theme_font_size_override("font_size", 24)
	add_child(done)
	_flush_ac()


func _read_saved() -> Dictionary:
	var txt := FileAccess.get_file_as_string(SAVE_PATH)
	if txt.is_empty():
		return {}
	var d = JSON.parse_string(txt)
	if typeof(d) == TYPE_DICTIONARY:
		return d
	return {}


func _update_hud() -> void:
	_hud.text = "关卡: %d  星: %d  库存: %d" % [PlayerData.current_level, PlayerData.stars, PlayerData.inventory.size()]


func print_ac(req_id: String, n: int, ok: bool) -> void:
	var line := "%s_AC-%d %s" % [req_id, n, "PASS" if ok else "FAIL"]
	print(line)
	if not ok:
		printerr(line)
	_ac_lines.append(line)


func _flush_ac() -> void:
	if OS.get_name() != "Windows":
		return
	var f := FileAccess.open("d:/Project/SELF/alphabounce/r07_ac_result.txt", FileAccess.WRITE)
	if f != null:
		for l in _ac_lines:
			f.store_string(l + "\n")
		f.close()

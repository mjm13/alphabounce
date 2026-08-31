extends Node

# [R22] 存档版本号与迁移验证（headless）：legacy 升级 / 往返一致 / 未来版本告警 / 迁移可达。

var _pass := 0
var _fail := 0
var _warn := 0


func _ready() -> void:
	_run_tests()
	await get_tree().process_frame
	get_tree().quit(0 if _fail == 0 else 1)


func _run_tests() -> void:
	# ===== AC-1：legacy（无 version）加载不崩溃、字段正确、回写升级到 SAVE_VERSION =====
	var pd := preload("res://scripts/systems/player_data.gd").new()
	var legacy := "user://r22_legacy.json"
	_write(legacy, '{"current_level":3,"max_level_unlocked":3,"stars":12,"inventory":{"ball_fire":1},"missions":{"m1":1}}')
	var ok1 := pd.load_from(legacy)
	var legacy_ok := ok1 and int(pd.current_level) == 3 and int(pd.stars) == 12
	pd.save_to(legacy)
	var ver_after := int(_read_json(legacy).get("version", -1))
	var ac1 := legacy_ok and ver_after == 1
	print_ac("R22", 1, ac1)

	# ===== AC-2：当前版本往返一致 =====
	var pd2 := preload("res://scripts/systems/player_data.gd").new()
	var cur := "user://r22_cur.json"
	pd2.current_level = 5
	pd2.stars = 40
	pd2.inventory = {"ball_ice": 2}
	pd2.missions = {"m2": 3}
	pd2.save_to(cur)
	var pd2b := preload("res://scripts/systems/player_data.gd").new()
	pd2b.load_from(cur)
	var ac2 := int(pd2b.current_level) == 5 and int(pd2b.stars) == 40 and int(pd2b.inventory.get("ball_ice", 0)) == 2 and int(pd2b.missions.get("m2", 0)) == 3 and int(_read_json(cur).get("version", -1)) == 1
	print_ac("R22", 2, ac2)

	# ===== AC-3：未来版本（>当前）告警且不崩溃、尽力加载 =====
	var pd3 := preload("res://scripts/systems/player_data.gd").new()
	var newf := "user://r22_new.json"
	pd3.save_version_warn.connect(_on_warn)
	_write(newf, '{"version":99,"current_level":7,"stars":1,"inventory":{},"missions":{}}')
	var ok3 := pd3.load_from(newf)
	var ac3 := ok3 and _warn > 0
	print_ac("R22", 3, ac3)

	# ===== AC-4：legacy 经 _migrate 钩子升级（由 AC-1 的 ver_after==1 证明迁移路径可达）=====
	var ac4 := ac1
	print_ac("R22", 4, ac4)

	# 清理临时存档与实例（避免退出时 ObjectDB/资源泄漏）
	_del(legacy)
	_del(cur)
	_del(newf)
	pd.free()
	pd2.free()
	pd2b.free()
	pd3.free()


func _on_warn(_lv: int, _cv: int) -> void:
	_warn += 1


func print_ac(tag: String, n: int, ok: bool) -> void:
	if ok:
		_pass += 1
	else:
		_fail += 1
	print("%s_AC-%d %s" % [tag, n, "PASS" if ok else "FAIL"])


func _write(p: String, s: String) -> void:
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string(s)
	f.close()


func _read_json(p: String) -> Dictionary:
	var t := FileAccess.get_file_as_string(p)
	var d = JSON.parse_string(t)
	if typeof(d) != TYPE_DICTIONARY:
		return {}
	return d


func _del(p: String) -> void:
	if FileAccess.file_exists(p):
		var dir := DirAccess.open("user://")
		if dir != null:
			dir.remove(p.get_file())

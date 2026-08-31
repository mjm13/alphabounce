extends TestBase

const StarMapScript = preload("res://scripts/core/star_map.gd")
const ZoneInfoScript = preload("res://scripts/core/zone_info.gd")
const StarMapScene = preload("res://scenes/ui/star_map.tscn")

# R26 验收：星图导航（24 星区选择 / 当前星 / 虫洞 / 进入信号）
func _ready() -> void:
	var sm = StarMapScript.new()

	# AC-1：初始化含 24 星区，current=START，visited 含 START
	var ok1: bool = (sm.selectable_zones().size() == ZoneInfoScript.ZONE_COUNT
			and sm.current_zone == ZoneInfoScript.SOUPALINE
			and sm.visited.has(ZoneInfoScript.SOUPALINE))
	print_ac("R26", 1, ok1)

	# AC-2：虫洞端点对来自 ZoneInfo.holes（5 对）
	var holes = ZoneInfoScript.get_holes()
	var ok2: bool = (sm.wormhole_endpoints().size() == holes.size() and holes.size() == 5)
	print_ac("R26", 2, ok2)

	# AC-3：selectable_zones 返回 24（v0.3.0 MVP 关卡选择，无门禁）
	var ok3: bool = sm.selectable_zones().size() == ZoneInfoScript.ZONE_COUNT
	print_ac("R26", 3, ok3)

	# AC-4：enter_zone 更新 current/visited 并发出 zone_selected
	var received := {"zid": -1, "fired": false}
	sm.zone_selected.connect(func(zid, gp):
		received["zid"] = zid
		received["fired"] = true
	)
	sm.enter_zone(ZoneInfoScript.KARBONIS)
	var ok4: bool = (sm.current_zone == ZoneInfoScript.KARBONIS
			and sm.visited.has(ZoneInfoScript.KARBONIS)
			and received["fired"] == true
			and received["zid"] == ZoneInfoScript.KARBONIS)
	print_ac("R26", 4, ok4)

	# AC-5：银河坐标 → 屏幕投影，不同星区投影位置不同（EARTH 与 SOUPALINE 区分）
	var vp := Vector2(1920.0, 1080.0)
	var sp_earth = sm.get_zone_screen_pos(ZoneInfoScript.EARTH, vp)
	var sp_soup = sm.get_zone_screen_pos(ZoneInfoScript.SOUPALINE, vp)
	var sp_mol = sm.get_zone_screen_pos(ZoneInfoScript.MOLTEAR, vp)
	var ok5: bool = (sp_earth != sp_soup and sp_earth != sp_mol and sp_soup != sp_mol
			and sp_earth.x >= 0.0 and sp_earth.x <= vp.x
			and sp_earth.y >= 0.0 and sp_earth.y <= vp.y)
	print_ac("R26", 5, ok5)

	# AC-6：reachable_zones BFS 忠实运行，至少含起点星区（独立实例，避免被 AC-4 改动 current_zone 影响）
	var sm2 = StarMapScript.new()
	var reach = sm2.reachable_zones(10)
	var ok6: bool = (reach is Array and reach.has(ZoneInfoScript.SOUPALINE))
	print_ac("R26", 6, ok6)

	# AC-7：星图场景可加载且无脚本错误
	var scene = StarMapScene.instantiate()
	var ok7: bool = (scene != null and scene.has_method("_ready"))
	if scene != null:
		scene.free()
	print_ac("R26", 7, ok7)

	if get_tree().current_scene == self:
		get_tree().quit(1 if has_failure() else 0)

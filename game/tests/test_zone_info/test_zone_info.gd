extends TestBase

const ZoneInfoScript = preload("res://scripts/core/zone_info.gd")

# R25 验收：星区数据 ZoneInfo（24 星区 + 小行星带 + 虫洞 + 几何辅助）
func _ready() -> void:
	var list = ZoneInfoScript.get_list()

	# AC-1：24 星区，且每个含合法字段（name / pos[3] / pos[2]>0 / col / pal）
	var ok1: bool = list.size() == ZoneInfoScript.ZONE_COUNT
	for z in list:
		if not (z.has("name") and typeof(z["name"]) == TYPE_STRING
				and z.has("pos") and z["pos"].size() == 3 and int(z["pos"][2]) >= 0
				and z.has("col") and z.has("pal") and z["pal"].size() > 0):
			ok1 = false
	print_ac("R25", 1, ok1)

	# AC-2：小行星带常量 + 5 个虫洞
	var ok2: bool = (ZoneInfoScript.ASTEROBELT == 13
			and ZoneInfoScript.ASTEROBELT_CX == 27
			and ZoneInfoScript.ASTEROBELT_CY == 6
			and ZoneInfoScript.ASTEROBELT_RAY == 110
			and ZoneInfoScript.get_holes().size() == 5)
	print_ac("R25", 2, ok2)

	# AC-3：get_planet 已知坐标映射正确
	var ok3: bool = (ZoneInfoScript.get_planet(-7, 1) == ZoneInfoScript.SOUPALINE
			and ZoneInfoScript.get_planet(8000, 8100) == ZoneInfoScript.EARTH
			and ZoneInfoScript.get_planet(1000, 1000) == -1)
	print_ac("R25", 3, ok3)

	# AC-4：get_squares(Soupaline) 半径为 2 → 全包围盒 16 格，且每格均满足 is_in_circle
	var sq = ZoneInfoScript.get_squares(ZoneInfoScript.SOUPALINE)
	var ok4: bool = sq.size() == 16
	for s in sq:
		if not ZoneInfoScript.is_in_circle(s[0], s[1], -7, 1, 2):
			ok4 = false
	print_ac("R25", 4, ok4)

	# AC-5：is_wormhole 对已知虫洞为真、非虫洞为假
	var ok5: bool = (ZoneInfoScript.is_wormhole(-9, -7)
			and not ZoneInfoScript.is_wormhole(0, 0))
	print_ac("R25", 5, ok5)

	if get_tree().current_scene == self:
		get_tree().quit(1 if has_failure() else 0)

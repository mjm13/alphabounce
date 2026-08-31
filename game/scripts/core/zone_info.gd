extends RefCounted
class_name ZoneInfo

# [核心目的] 星区数据（对标原版 common/src/ZoneInfo.hx）：24 星区（含小行星带 ASTEROBELT
# 与 5 个虫洞），每个星区含 name / pos[x,y,radius] / col / pal。提供 get_planet /
# get_squares / is_wormhole 等几何辅助，供 v0.3.0 星图导航与程序化关卡生成使用。
# [功能描述] 纯数据 + 几何函数，无渲染依赖；数值与原版逐字对齐（十进制 col / pos / pal）。

const ZONE_COUNT := 24

# 星区 ID 常量（与原版 ZoneInfo 一致）
const MOLTEAR = 0
const SOUPALINE = 1
const LYCANS = 2
const SAMOSA = 3
const TIBOON = 4
const BALIXT = 5
const KARBONIS = 6
const SPIGNYSOS = 7
const POFIAK = 8
const SENEGARDE = 9
const DOURIV = 10
const GRIMORN = 11
const DTRITUS = 12
const ASTEROBELT = 13
const NALIKORS = 14
const HOLOVAN = 15
const KHORLAN = 16
const CILORILE = 17
const TARCITURNE = 18
const CHAGARINA = 19
const VOLCER = 20
const BALMANCH = 21
const FOLKET = 22
const EARTH = 23

# 小行星带几何（原版 ASTEROBELT_CX/CY/RAY）
const ASTEROBELT_CX = 27
const ASTEROBELT_CY = 6
const ASTEROBELT_RAY = 110

# 圆形判定容差（原版 TOLERANCE = 0.3）
const TOLERANCE = 0.3

# 24 星区定义（顺序即 id；pos=[x,y,radius]）
static var _list: Array = [
	{"name": "Moltear", "pos": [-55, 34, 7], "col": 11141188, "pal": [[100, 100, 150, 55, 55, 105], [100, 100, 100, 105, 55, 55]]},
	{"name": "Soupaline", "pos": [-7, 1, 2], "col": 4473992, "pal": [[40, 0, 200, 20, 20, 20], [20, 200, 40, 20, 40, 20]]},
	{"name": "Lycans", "pos": [1, 14, 8], "col": 11167266, "pal": [[100, 100, 0, 155, 155, 40]]},
	{"name": "Samosa", "pos": [412, 93, 11], "col": 11167266, "pal": [[55, 55, 55, 200, 200, 200]]},
	{"name": "Tiboon", "pos": [9, -10, 2], "col": 11167266, "pal": [[55, 55, 55, 200, 200, 200]]},
	{"name": "Balixt", "pos": [-9, -39, 5], "col": 8930406, "pal": [[40, 30, 10, 100, 200, 50]]},
	{"name": "Karbonis", "pos": [27, 6, 0], "col": 11176072, "pal": [[170, 40, 70, 80, 60, 70], [180, 180, 20, 70, 70, 40]]},
	{"name": "Spignysos", "pos": [-36, -10, 5], "col": 2237064, "pal": [[20, 40, 150, 20, 20, 100], [0, 175, 175, 50, 75, 75]]},
	{"name": "Pofiak", "pos": [-18, 85, 3], "col": 1148979, "pal": [[20, 80, 60, 20, 150, 80], [150, 150, 20, 100, 100, 0]]},
	{"name": "Senegarde", "pos": [93, 48, 5], "col": 8912998, "pal": [[150, 20, 80, 100, 80, 100], [50, 20, 200, 150, 50, 50]]},
	{"name": "Douriv", "pos": [-84, -102, 7], "col": 8930457, "pal": [[200, 20, 20, 100, 20, 20], [20, 200, 20, 20, 100, 20], [20, 20, 200, 20, 20, 100]]},
	{"name": "Grimorn", "pos": [81, -122, 4], "col": 12303291, "pal": [[60, 60, 60, 60, 60, 60]]},
	{"name": "D-tritus", "pos": [247, -44, 2], "col": 5592405, "pal": [[30, 30, 0, 150, 150, 60]]},
	{"name": "Asteroide", "pos": [0, 0, 0], "col": 5592405, "pal": [[30, 30, 0, 160, 120, 60], [250, 200, 0, 50, 30, 0]]},
	{"name": "Nalikors", "pos": [67, 153, 4], "col": 5614216, "pal": [[0, 0, 40, 0, 50, 210], [0, 40, 40, 0, 210, 210]]},
	{"name": "Holovan", "pos": [-150, 111, 6], "col": 11158664, "pal": [[100, 0, 40, 250, 50, 210], [0, 40, 40, 250, 40, 40]]},
	{"name": "Khorlan", "pos": [180, -191, 5], "col": 8956552, "pal": [[0, 100, 0, 150, 150, 150], [150, 150, 150, 100, 50, 0]]},
	{"name": "Cilorile", "pos": [78, -23, 5], "col": 8868462, "pal": [[150, 80, 100, 100, 100, 100], [100, 200, 200, 50, 50, 50]]},
	{"name": "Tarciturne", "pos": [192, 115, 3], "col": 6728362, "pal": [[60, 60, 60, 60, 60, 60]]},
	{"name": "Chagarina", "pos": [-320, -574, 4], "col": 12307648, "pal": [[50, 60, 60, 50, 60, 60]]},
	{"name": "Volcer", "pos": [-298, -149, 8], "col": 8736938, "pal": [[20, 20, 60, 90, 60, 60], [20, 70, 20, 20, 100, 60]]},
	{"name": "Balmanch", "pos": [-340, 362, 5], "col": 13417335, "pal": [[0, 0, 0, 120, 120, 120], [0, 0, 0, 150, 0, 100]]},
	{"name": "Folket", "pos": [574, -254, 3], "col": 2258858, "pal": [[0, 50, 100, 0, 50, 150]]},
	{"name": "Terre", "pos": [8000, 8100, 3], "col": 2258858, "pal": [[0, 50, 100, 0, 50, 150]]},
]

# 5 个虫洞坐标对（原版 holes）
static var _holes: Array = [
	[[-9, -7], [48, 23]],
	[[-106, 54], [62, -142]],
	[[5, -61], [-230, 1]],
	[[-85, -232], [-19, 143]],
	[[121, -50], [334, -162]],
]

# 返回星区列表（只读副本语义：调用方不应修改）
static func get_list() -> Array:
	return _list

# 返回虫洞坐标对列表
static func get_holes() -> Array:
	return _holes

# 计算星区包围盒（cx,cy,rad,xmin,xmax,ymin,ymax）
static func get_box(p: Dictionary) -> Dictionary:
	var cx: int = p["pos"][0]
	var cy: int = p["pos"][1]
	var rad: int = p["pos"][2]
	return {
		"cx": cx, "cy": cy, "rad": rad,
		"xmin": cx - rad, "xmax": cx + rad - 1,
		"ymin": cy - rad, "ymax": cy + rad - 1,
	}

# 点 (x,y) 是否落在以 (cx,cy) 为圆心、半径 rad 的圆内（含 TOLERANCE 容差）
static func is_in_circle(x: int, y: int, cx: int, cy: int, rad: int) -> bool:
	var dx: float = cx - x - 0.5
	var dy: float = cy - y - 0.5
	return sqrt(dx * dx + dy * dy) <= rad + TOLERANCE

# 返回包含坐标 (x,y) 的星区 id；不在任何星区内返回 -1（对标原版 getPlanet）
static func get_planet(x: int, y: int) -> int:
	var planet: int = -1
	var id: int = 0
	for p in _list:
		var sq: Dictionary = get_box(p)
		if x >= sq["xmin"] and x <= sq["xmax"] and y >= sq["ymin"] and y <= sq["ymax"]:
			planet = id
			break
		id += 1
	if planet == -1:
		return -1
	var p: Dictionary = _list[planet]
	if is_in_circle(x, y, p["pos"][0], p["pos"][1], p["pos"][2]):
		return planet
	return -1

# 返回星区 id 覆盖的所有网格坐标 [x,y]（对标原版 getSquares）
static func get_squares(id: int) -> Array:
	var a: Array = []
	var box: Dictionary = get_box(_list[id])
	for x in range(box["xmin"], box["xmax"] + 1):
		for y in range(box["ymin"], box["ymax"] + 1):
			if is_in_circle(x, y, box["cx"], box["cy"], box["rad"]):
				a.append([x, y])
	return a

# 坐标 (x,y) 是否为虫洞端点（对标原版 isWormhole）
static func is_wormhole(x: int, y: int) -> bool:
	for a in _holes:
		for p in a:
			if x == p[0] and y == p[1]:
				return true
	return false

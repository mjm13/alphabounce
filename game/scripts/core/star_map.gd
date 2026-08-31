extends RefCounted
class_name StarMap

const ZoneInfoScript = preload("res://scripts/core/zone_info.gd")

# [核心目的] 星图导航模型（对标原版 navi/Map.hx 的导航本质：在 24 星区之间导航并选定进入）。
# 提供：当前星区 / 已访问集合 / 虫洞端点 / 银河坐标→屏幕投影 / 进入星区（发出 zone_selected 信号）。
# [功能描述] 纯导航数据结构 + 几何投影；v0.3.0 MVP 采用「关卡选择」式全可选（无迷雾/燃料门禁），
# 原版局部网格移动 + 迷雾/engine 门禁见 Deferred（OQ-001）。reachable_zones 忠实移植原版 reach 的
# 星区方块图 4 邻域 BFS（虫洞端点落在星区内时瞬移），供后续门禁模式复用。

signal zone_selected(zid: int, galaxy_pos: Vector2)

const ZONE_COUNT := 24

# 起点星区（假设）：原版 Cs.pi 初始坐标未在本端口还原，取近原点的 SOUPALINE(=1) 作为家基地。
# 偏离见需求文档 OQ-001。
const START_ZONE = 1

# 移动步数 / 燃料（原版 Cs.pi.engine；门禁模式复用时生效）
const DEFAULT_ENGINE = 5

var current_zone: int = START_ZONE
var visited: Dictionary = {}        # zid -> true
var engine: int = DEFAULT_ENGINE

func _init() -> void:
	visited[START_ZONE] = true

# 全部可选星区（v0.3.0 MVP 关卡选择，无门禁；门禁见 Deferred）
func selectable_zones() -> Array:
	var a: Array = []
	for i in ZoneInfoScript.ZONE_COUNT:
		a.append(i)
	return a

# 虫洞端点对（来自 ZoneInfoScript.holes，供渲染/信息；原版连接的是空间格而非星区对）
func wormhole_endpoints() -> Array:
	return ZoneInfoScript.get_holes()

# 进入星区：更新 current/visited 并发出信号（实际关卡启动由 R27/R28 消费）
func enter_zone(zid: int) -> void:
	if not selectable_zones().has(zid):
		return
	current_zone = zid
	visited[zid] = true
	zone_selected.emit(zid, get_zone_galaxy_pos(zid))

# 星区银河坐标（原版 ZoneInfoScript.pos 的前两维）
func get_zone_galaxy_pos(zid: int) -> Vector2:
	var p: Array = ZoneInfoScript.get_list()[zid]["pos"]
	return Vector2(float(p[0]), float(p[1]))

# 银河坐标 → 归一化屏幕坐标（适配视口、保持相对布局；ASTEROBELT 半径0 视为无穷远，投影到边缘）
func galaxy_to_screen(gp: Vector2, viewport: Vector2, padding: float = 80.0) -> Vector2:
	var minp := get_galaxy_min()
	var maxp := get_galaxy_max()
	var span := maxp - minp
	span.x = maxf(span.x, 1.0)
	span.y = maxf(span.y, 1.0)
	var nx := (gp.x - minp.x) / span.x
	var ny := (gp.y - minp.y) / span.y
	return Vector2(padding + nx * (viewport.x - 2.0 * padding), padding + ny * (viewport.y - 2.0 * padding))

func get_zone_screen_pos(zid: int, viewport: Vector2 = Vector2(1920.0, 1080.0), padding: float = 80.0) -> Vector2:
	return galaxy_to_screen(get_zone_galaxy_pos(zid), viewport, padding)

# 可达星区（忠实移植原版 reach BFS：在星区方块图上 4 邻域扩展 engine 步；ASTEROBELT 半径0 排除）
func reachable_zones(engine_steps: int = -1) -> Array:
	if engine_steps < 0:
		engine_steps = engine
	# 星区方块 → zid 映射（排除半径0的 ASTEROBELT，对标原版 isZoneIn）
	var sq_to_zone := {}
	for i in ZoneInfoScript.ZONE_COUNT:
		if int(ZoneInfoScript.get_list()[i]["pos"][2]) <= 0:
			continue
		for s in ZoneInfoScript.get_squares(i):
			sq_to_zone["%d,%d" % [s[0], s[1]]] = i
	# BFS 起点 = 当前星区方块
	var reach := {}
	var frontier: Array = []
	for s in ZoneInfoScript.get_squares(current_zone):
		var k := "%d,%d" % [s[0], s[1]]
		reach[k] = true
		frontier.append(k)
	var dirs := [[1, 0], [-1, 0], [0, 1], [0, -1]]
	for step in range(engine_steps):
		var nxt: Array = []
		for k in frontier:
			var parts: PackedStringArray = String(k).split(",")
			var x := int(parts[0])
			var y := int(parts[1])
			for d in dirs:
				var nk := "%d,%d" % [x + d[0], y + d[1]]
				if not reach.has(nk) and sq_to_zone.has(nk):
					reach[nk] = true
					nxt.append(nk)
		frontier = nxt
	var zones := {}
	for k in reach.keys():
		if sq_to_zone.has(k):
			zones[sq_to_zone[k]] = true
	var out: Array = []
	for z in zones.keys():
		out.append(z)
	return out

# 银河坐标包围盒（供 galaxy_to_screen 归一化；EARTH 在 (8000,8100) 主导上界）
func get_galaxy_min() -> Vector2:
	var mn := Vector2(INF, INF)
	for i in ZoneInfoScript.ZONE_COUNT:
		var p: Array = ZoneInfoScript.get_list()[i]["pos"]
		mn.x = minf(mn.x, float(p[0]))
		mn.y = minf(mn.y, float(p[1]))
	return mn

func get_galaxy_max() -> Vector2:
	var mx := Vector2(-INF, -INF)
	for i in ZoneInfoScript.ZONE_COUNT:
		var p: Array = ZoneInfoScript.get_list()[i]["pos"]
		mx.x = maxf(mx.x, float(p[0]))
		mx.y = maxf(mx.y, float(p[1]))
	return mx

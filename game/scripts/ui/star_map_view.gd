extends Node2D

# [核心目的] 星图导航视图（v0.3.0 关卡选择）：渲染 24 星区于归一化银河坐标、虫洞端点、
# 当前/已访问高亮，并在点击星区时经 StarMap.enter_zone 发出 zone_selected 信号（R27/R28 消费）。
# [功能描述] 纯绘制（_draw 圆点 + 颜色）；不引入美术资源。局部网格移动/迷雾门禁见对应需求 Deferred。

const StarMapScript = preload("res://scripts/core/star_map.gd")
const ZoneInfoScript = preload("res://scripts/core/zone_info.gd")

var model
var _positions: Dictionary = {}   # zid -> Vector2 (屏幕)

func _ready() -> void:
	model = StarMapScript.new()
	_compute_positions()
	queue_redraw()

func _compute_positions() -> void:
	_positions.clear()
	var vp := get_viewport_rect().size
	for i in StarMapScript.ZONE_COUNT:
		_positions[i] = model.get_zone_screen_pos(i, vp)

func _zone_screen_pos(i: int) -> Vector2:
	return _positions.get(i, Vector2.ZERO)

func _draw() -> void:
	if model == null:
		return
	var vp := get_viewport_rect().size
	# 虫洞端点
	for hole in model.wormhole_endpoints():
		for ep in hole:
			var gp: Vector2 = Vector2(float(ep[0]), float(ep[1]))
			var sp: Vector2 = model.galaxy_to_screen(gp, vp)
			draw_circle(sp, 3.0, Color(0.6, 0.3, 0.9, 0.85))
	# 星区
	for i in StarMapScript.ZONE_COUNT:
		var sp: Vector2 = _zone_screen_pos(i)
		var col: int = int(ZoneInfoScript.get_list()[i]["col"])
		var c := Color8((col >> 16) & 0xFF, (col >> 8) & 0xFF, col & 0xFF)
		if i == model.current_zone:
			draw_circle(sp, 14.0, Color(1.0, 1.0, 1.0, 0.95))
			draw_circle(sp, 9.0, c)
		elif model.visited.has(i):
			draw_circle(sp, 10.0, c)
		else:
			draw_circle(sp, 10.0, Color(c.r, c.g, c.b, 0.55))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var p: Vector2 = mb.position
			var best := -1
			var best_d := INF
			for i in StarMapScript.ZONE_COUNT:
				var sp: Vector2 = _zone_screen_pos(i)
				var d: float = sp.distance_to(p)
				if d < best_d:
					best_d = d
					best = i
			if best >= 0 and best_d <= 16.0:
				model.enter_zone(best)

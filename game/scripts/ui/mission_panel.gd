extends Control

## 任务面板：列出 MissionManager 中的任务及状态。
## 状态文案：-1 未开始 / 0 进行中 / 1 已完成。

var _list: VBoxContainer


func _ready() -> void:
	_list = VBoxContainer.new()
	_list.name = "List"
	_list.add_theme_constant_override("separation", 4)
	add_child(_list)
	refresh()


func refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	for m in MissionManager.missions:
		var h := HBoxContainer.new()
		var icon := Label.new()
		var st: int = MissionManager.get_status(m.mission_id)
		var icon_txt: String
		var s_txt: String
		if st == -2:
			icon_txt = "🔒"
			s_txt = "锁定"
		elif st == -1:
			icon_txt = "⬜"
			s_txt = "可接取"
		elif st == 0:
			icon_txt = "🟦"
			s_txt = "进行中"
		else:
			icon_txt = "✅"
			s_txt = "已完成"
		icon.text = icon_txt
		var lbl := Label.new()
		if st == -2:
			lbl.text = "%s  [锁定] 需先完成：%s" % [m.title, MissionManager.missing_requires(m.mission_id)]   # [R20]
		else:
			lbl.text = "%s  [%s]" % [m.title, s_txt]
		h.add_child(icon)
		h.add_child(lbl)
		_list.add_child(h)

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
		var s_txt := "未开始" if st == -1 else ("进行中" if st == 0 else "已完成")
		var icon_txt := "⬜" if st == -1 else ("🟦" if st == 0 else "✅")
		icon.text = icon_txt
		var lbl := Label.new()
		lbl.text = "%s  [%s]" % [m.title, s_txt]
		h.add_child(icon)
		h.add_child(lbl)
		_list.add_child(h)

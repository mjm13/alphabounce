extends Node

## 任务管理器（Autoload 单例）。
## 状态机：-1 未开始 / 0 进行中 / 1 已完成（INV-001 单调推进）。
## 条件检查仅在 level_complete 信号后由 check_conditions() 触发（INV-002）。

signal missions_loaded
signal mission_updated(mission_id: String, new_status: int)

var missions: Array = []      # Array[MissionData]
var status: Dictionary = {}   # mission_id -> int


func load_missions_from_file(path: String) -> bool:
	var txt := FileAccess.get_file_as_string(path)
	if txt.is_empty():
		printerr("R05_MISSIONS_MISSING: ", path)
		return false
	var arr = JSON.parse_string(txt)
	if typeof(arr) != TYPE_ARRAY:
		printerr("R05_MISSIONS_BAD_JSON")
		return false
	missions.clear()
	status.clear()
	for d in arr:
		var md: MissionData = MissionData.from_dict(d)
		if md == null:
			continue
		missions.append(md)
		status[md.mission_id] = -1
	missions_loaded.emit()
	return true


func get_status(mission_id: String) -> int:
	return status.get(mission_id, -1)


## level_complete 信号消费入口（由 game.gd 或 debug 场景调用）。
## ctx 可含：level / blocks_cleared / score。
func check_conditions(ctx: Dictionary) -> void:
	for m in missions:
		var md: MissionData = m
		var s: int = status.get(md.mission_id, -1)
		if s == -1 and _cond_met(md, ctx):
			status[md.mission_id] = 0   ## 条件满足 → 进行中（INV-001）
			mission_updated.emit(md.mission_id, 0)


func _cond_met(md: MissionData, ctx: Dictionary) -> bool:
	match md.cond_type:
		"COMPLETE_LEVEL":
			return int(ctx.get("level", 0)) >= md.cond_value
		"COLLECT_BLOCKS":
			return int(ctx.get("blocks_cleared", 0)) >= md.cond_value
		"REACH_SCORE":
			return int(ctx.get("score", 0)) >= md.cond_value
		_:
			return false

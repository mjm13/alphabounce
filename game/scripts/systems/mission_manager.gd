extends Node

## 任务管理器（Autoload 单例）。
## 状态机：-2 锁定（前置未达成） / -1 可接取（前置达成、条件未达） / 0 进行中 / 1 已完成（INV-001 单调推进 -2→-1→0→1）。[R20] 解锁树扩展。
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
		status[md.mission_id] = -2 if md.requires.size() > 0 else -1   # [R20] 有前置默认锁定
	_detect_requires_cycle()   # [R20] INV-003：加载期检测环
	missions_loaded.emit()
	return true


func get_status(mission_id: String) -> int:
	return status.get(mission_id, -2)   # [R20] 未知 id 视为锁定


## level_complete 信号消费入口（由 game.gd 或 debug 场景调用）。
## ctx 可含：level / blocks_cleared / score。
## [R20] 两遍：先解锁评估（-2→-1），再条件检查（-1→0），保证同 tick 内顺序无关。
func check_conditions(ctx: Dictionary) -> void:
	for m in missions:
		var md: MissionData = m
		if status.get(md.mission_id, -2) == -2 and is_unlocked(md):   # [R20] 前置达成 → 可接取
			status[md.mission_id] = -1
			mission_updated.emit(md.mission_id, -1)
	for m in missions:
		var md: MissionData = m
		if status.get(md.mission_id, -2) == -1 and _cond_met(md, ctx):   # 条件满足 → 进行中（INV-001）
			status[md.mission_id] = 0
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


## [R20] 前置是否全部达成（status ≥ 0）。原 check_conditions 将任务置为 0（进行中/已达成），
## 故"前置完成"在此模型中等价于 status ≥ 0。
func is_unlocked(md: MissionData) -> bool:
	for r in md.requires:
		if status.get(r, -2) < 0:
			return false
	return true


## [R20] 返回某任务未达成的前置标题（用于面板提示）。
func missing_requires(mission_id: String) -> String:
	var md := _find(mission_id)
	if md == null:
		return ""
	var names: Array[String] = []
	for r in md.requires:
		if status.get(r, -2) < 0:
			var rm := _find(r)
			names.append(rm.title if rm != null else r)
	return "、".join(names)


func _find(mission_id: String) -> MissionData:
	for m in missions:
		if m.mission_id == mission_id:
			return m
	return null


## [R20] INV-003：requires 必须构成无环 DAG。用 Kahn 拓扑消解检测环；
## 残留任务即处于环中，打印告警 R20_REQUIRES_CYCLE（环中任务恒为 -2 锁定，不影响其余）。
func _detect_requires_cycle() -> void:
	var remaining: Dictionary = {}
	for m in missions:
		remaining[m.mission_id] = true
	var changed := true
	while changed:
		changed = false
		for id in remaining.keys():
			var md := _find(id)
			var blocked := false
			if md != null:
				for r in md.requires:
					if remaining.has(r):
						blocked = true
						break
			if not blocked:
				remaining.erase(id)
				changed = true
	for id in remaining.keys():
		printerr("R20_REQUIRES_CYCLE: ", id)

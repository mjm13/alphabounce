extends Resource
class_name MissionData

## 任务配置数据（由 JSON 解析构造）。
## 条件类型：COMPLETE_LEVEL / COLLECT_BLOCKS / REACH_SCORE。

var mission_id: String = ""
var title: String = ""
var cond_type: String = ""
var cond_value: int = 0
var reward: String = ""


static func from_dict(d: Dictionary) -> MissionData:
	if typeof(d) != TYPE_DICTIONARY:
		return null
	var md := MissionData.new()
	md.mission_id = str(d.get("id", ""))
	md.title = str(d.get("title", ""))
	md.cond_type = str(d.get("cond_type", ""))
	md.cond_value = int(d.get("cond_value", 0))
	md.reward = str(d.get("reward", ""))
	if md.mission_id.is_empty():
		return null
	return md

extends Resource

## 商品配置数据（由 JSON 解析构造）。
## 类型：BALL（特殊球体）/ MISSILE（导弹）/ RADAR（辅助道具）/ DRONE（无人机）。
## 不依赖 class_name 全局类缓存：由 ShopManager 通过 preload 实例化后调用 load_from。

var item_id: String = ""
var name: String = ""
var price: int = 0
var type: String = ""


## 从字典填充自身字段；id 为空视为非法返回 false。
func load_from(d: Dictionary) -> bool:
	if typeof(d) != TYPE_DICTIONARY:
		return false
	item_id = str(d.get("id", ""))
	name = str(d.get("name", ""))
	price = int(d.get("price", 0))
	type = str(d.get("type", ""))
	return not item_id.is_empty()

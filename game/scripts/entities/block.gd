extends StaticBody2D
class_name Block

# 方块类型
enum BlockType {
	NORMAL,      # 普通方块
	STEEL,       # 钢铁方块（需要多次打击）
	BONUS,       # 奖励方块
	EXPLOSIVE,   # 爆炸方块
	DRAGON,      # 危险方块：击碎生成 Dragon 事件敌人
	MISSILE,     # 危险方块：击碎掉落导弹 Option
	MINE,        # 危险方块：击碎范围炸毁邻格
	INSECT,      # 危险方块：击碎喷 10 只 fx.Fly
	KILL,        # 危险方块：击碎触发 kill 行为
	GUARDIAN,    # Boss 等价特殊方块：仅导弹可击杀
}

@export var block_type: BlockType = BlockType.NORMAL
@export var health: int = 1
@export var score_value: int = 10

var is_destroyed: bool = false

signal destroyed(position, block_type, score_value)
signal dangerous_triggered(block_type)

func _ready():
	_setup_collision()
	# [R04] 加入 blocks 分组，供 ball 的 body_entered 识别与碰撞积分
	add_to_group("blocks")
	_setup_sprite()

# [R15] 按方块类型渲染原版贴图（具体类型映射待 R16 细化）
func _setup_sprite() -> void:
	var sp := get_node_or_null("Sprite2D")
	if sp == null:
		return
	var map := {
		BlockType.NORMAL: "res://resources/images/mcBlock/01.png",
		BlockType.STEEL: "res://resources/images/mcBlock/02.png",
		BlockType.BONUS: "res://resources/images/mcBlock/03.png",
		BlockType.EXPLOSIVE: "res://resources/images/mcBlock/04.png",
		BlockType.DRAGON: "res://resources/images/mcBlock/05.png",
		BlockType.MISSILE: "res://resources/images/mcBlock/06.png",
		BlockType.MINE: "res://resources/images/mcBlock/07.png",
		BlockType.INSECT: "res://resources/images/mcBlock/08.png",
		BlockType.KILL: "res://resources/images/mcBlock/09.png",
		BlockType.GUARDIAN: "res://resources/images/mcBlock/10.png",
	}
	var path: String = map.get(block_type, "res://resources/images/mcBlock/sprite.png")
	if ResourceLoader.exists(path):
		sp.texture = load(path)

func _setup_collision():
	# 碰撞层设置
	collision_layer = 1  # 被子弹和球检测
	collision_mask = 0   # 不参与主动碰撞

func is_guardian() -> bool:
	return block_type == BlockType.GUARDIAN

# 受击：GUARDIAN 仅导弹(by_missile)可击杀；其余正常扣血（OQ-003 / INV-002）
func hit(damage: int = 1, by_missile: bool = false) -> bool:
	if block_type == BlockType.GUARDIAN and not by_missile:
		return false
	health -= damage
	if health <= 0 and not is_destroyed:
		destroy()
		return true
	return false

func destroy():
	is_destroyed = true
	if block_type in [BlockType.DRAGON, BlockType.MISSILE, BlockType.MINE, BlockType.INSECT, BlockType.KILL]:
		dangerous_triggered.emit(block_type)
	# 发送信号通知游戏逻辑（使用全局坐标，便于世界空间定位粒子等效果）
	emit_signal("destroyed", global_position, block_type, score_value)
	queue_free()

func get_type() -> BlockType:
	return block_type

func get_health() -> int:
	return health

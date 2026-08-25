extends StaticBody2D

# 方块类型
enum BlockType {
	NORMAL,      # 普通方块
	STEEL,       # 钢铁方块（需要多次打击）
	BONUS,       # 奖励方块
	EXPLOSIVE,   # 爆炸方块
}

@export var block_type: BlockType = BlockType.NORMAL
@export var health: int = 1
@export var score_value: int = 10

var is_destroyed: bool = false

func _ready():
	_setup_collision()

func _setup_collision():
	# 碰撞层设置
	collision_layer = 1  # 被子弹和球检测
	collision_mask = 0   # 不参与主动碰撞

func hit(damage: int = 1) -> bool:
	health -= damage
	if health <= 0 and not is_destroyed:
		destroy()
		return true
	return false

func destroy():
	is_destroyed = true
	# 发送信号通知游戏逻辑
	emit_signal("destroyed", position, block_type, score_value)
	queue_free()

func get_type() -> BlockType:
	return block_type

func get_health() -> int:
	return health

signal destroyed(position, block_type, score_value)

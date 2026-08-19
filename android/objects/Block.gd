extends StaticBody2D

# 可破坏砖块（conglomerate）：被球击中耐久递减，归零消失并通知关卡计分。
const SIZE := 120.0
const HEIGHT := 50.0

var durability := 1
var max_durability := 1
var game = null  # LevelBase 引用

func _ready() -> void:
	add_to_group("block")
	max_durability = durability
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(SIZE, HEIGHT)
	add_child(shape)
	var vis := ColorRect.new()
	vis.size = Vector2(SIZE, HEIGHT)
	vis.color = Color(0.85, 0.30, 0.40)
	vis.position = -vis.size / 2.0
	add_child(vis)
	_refresh_color()

func take_hit() -> void:
	durability -= 1
	if durability <= 0:
		if game != null:
			game.on_block_destroyed()
		queue_free()
	else:
		_refresh_color()

# 耐久越低颜色越暗，提供视觉反馈。
func _refresh_color() -> void:
	var vis := get_node_or_null("ColorRect")
	if vis == null:
		return
	var t := clampf(float(durability) / float(max(1, max_durability)), 0.15, 1.0)
	vis.color = Color(0.85 * t + 0.15, 0.30 * t + 0.10, 0.40 * t + 0.15)

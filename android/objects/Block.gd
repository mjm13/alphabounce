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
	# 视觉：优先用 EternalTwin 真实砖块精灵，按碰撞盒尺寸自适应缩放。
	var vis: CanvasItem
	var sprite := Sprite2D.new()
	sprite.name = "Vis"
	sprite.texture = load("res://assets/sprites/mcBlock/01.png")
	if sprite.texture != null:
		var tex := sprite.texture.get_size()
		sprite.scale = Vector2(SIZE / tex.x, HEIGHT / tex.y)
		vis = sprite
	else:
		var fb := ColorRect.new()
		fb.size = Vector2(SIZE, HEIGHT)
		fb.color = Color(0.85, 0.30, 0.40)
		fb.position = -fb.size / 2.0
		vis = fb
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

# 耐久越低越暗，提供视觉反馈（精灵用 modulate，占位回退用 color）。
func _refresh_color() -> void:
	var vis := get_node_or_null("Vis")
	if vis == null:
		return
	var t := clampf(float(durability) / float(max(1, max_durability)), 0.15, 1.0)
	if vis is Sprite2D:
		vis.modulate = Color(t, t, t)
	else:
		vis.color = Color(0.85 * t + 0.15, 0.30 * t + 0.10, 0.40 * t + 0.15)

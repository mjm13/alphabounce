extends StaticBody2D

# 挡板（envelope）：跟随指针（鼠标/触控）左右移动，限制在屏幕内。
const WIDTH := 320.0
const HEIGHT := 36.0
var half_width := WIDTH / 2.0

func _ready() -> void:
	add_to_group("paddle")
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(WIDTH, HEIGHT)
	add_child(shape)
	# 视觉：EternalTwin 挡板飞船精灵，按碰撞盒尺寸自适应缩放。
	var vis: CanvasItem
	var sprite := Sprite2D.new()
	sprite.name = "Vis"
	sprite.texture = load("res://assets/sprites/mcPad/01.png")
	if sprite.texture != null:
		var tex := sprite.texture.get_size()
		sprite.scale = Vector2(WIDTH / tex.x, HEIGHT / tex.y)
		vis = sprite
	else:
		var fb := ColorRect.new()
		fb.size = Vector2(WIDTH, HEIGHT)
		fb.color = Color(0.30, 0.70, 1.00)
		fb.position = -fb.size / 2.0
		vis = fb
	add_child(vis)

# 指针 X 跟随；Y 固定在底部上方。坐标使用实时视口尺寸，自动适配不同屏幕比例。
func follow_pointer(x: float) -> void:
	var vps := get_viewport_rect().size
	global_position.x = clampf(x, half_width + 12.0, vps.x - half_width - 12.0)
	global_position.y = vps.y * 0.82

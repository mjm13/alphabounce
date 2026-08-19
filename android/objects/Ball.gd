extends CharacterBody2D

# 球：定步长运动（_physics_process，60Hz）；与墙/挡板/砖块反弹。
# 挡板命中位置影响入射角（经典打砖块手感）。
const SPEED := 660.0
const SIZE := 26.0
const MAX_BOUNCE := deg_to_rad(60.0)
const MIN_VY := 0.22  # 垂直分量下限，避免接近水平来回弹导致卡死

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("ball")
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(SIZE, SIZE)
	add_child(shape)
	# 视觉：EternalTwin 主球精灵，等比缩放适配球尺寸。
	var vis: CanvasItem
	var sprite := Sprite2D.new()
	sprite.name = "Vis"
	sprite.texture = load("res://assets/sprites/ballMain/ball_main0001.png")
	if sprite.texture != null:
		var tex := sprite.texture.get_size()
		var s := SIZE / maxf(tex.x, tex.y)
		sprite.scale = Vector2(s, s)
		vis = sprite
	else:
		var fb := ColorRect.new()
		fb.size = Vector2(SIZE, SIZE)
		fb.color = Color(1.0, 0.86, 0.25)
		fb.position = -fb.size / 2.0
		vis = fb
	add_child(vis)

func launch(dir: Vector2) -> void:
	velocity = dir.normalized() * SPEED

# 反射后归一化，并保证最小垂直分量，防止球在水平方向无限来回。
func _normalize(v: Vector2) -> Vector2:
	v = v.normalized() * SPEED
	if abs(v.y) < SPEED * MIN_VY:
		var sign_y := -1.0 if v.y <= 0.0 else 1.0
		v.y = sign_y * SPEED * MIN_VY
		v.x = sign(v.x) * sqrt(max(0.0, SPEED * SPEED - v.y * v.y))
	return v

func _physics_process(delta: float) -> void:
	var collision := move_and_collide(velocity * delta)
	if collision == null:
		return
	var collider := collision.get_collider() as Node2D
	if collider != null and collider.is_in_group("paddle") and velocity.y > 0.0:
		# 挡板：命中位置（相对中心偏移）决定反弹角，最大 MAX_BOUNCE。
		var hw = collider.get("half_width")
		if hw == null:
			hw = 160.0
		var offset := clampf((global_position.x - collider.global_position.x) / float(hw), -1.0, 1.0)
		var a := offset * MAX_BOUNCE
		velocity = Vector2(sin(a), -cos(a)).normalized() * SPEED
		# 推出挡板上方，避免连续重复碰撞。
		global_position.y = collider.global_position.y - 40.0
	else:
		velocity = velocity.bounce(collision.get_normal())
		if collider != null and collider.is_in_group("block"):
			collider.call("take_hit")
	velocity = _normalize(velocity)

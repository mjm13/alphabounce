extends CharacterBody2D

# 球：定步长运动；尺寸随关卡布局（对齐 Cs.hx 球/砖比例）。
const SPEED := 660.0
const DEFAULT_SIZE := 26.0
const MAX_BOUNCE := deg_to_rad(60.0)
const MIN_VY := 0.22

var diameter := DEFAULT_SIZE

func configure(p_diameter: float) -> void:
	diameter = maxf(p_diameter, 12.0)
	if is_inside_tree():
		_rebuild_body()

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("ball")
	_rebuild_body()

func _rebuild_body() -> void:
	for c in get_children():
		c.queue_free()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(diameter, diameter)
	add_child(shape)
	var sprite := Sprite2D.new()
	sprite.name = "Vis"
	sprite.centered = true
	sprite.texture = load("res://assets/sprites/ballMain/ball_main0001.png")
	if sprite.texture != null:
		var tex := sprite.texture.get_size()
		var s := diameter / maxf(tex.x, tex.y)
		sprite.scale = Vector2(s, s)
		add_child(sprite)
	else:
		var fb := ColorRect.new()
		fb.size = Vector2(diameter, diameter)
		fb.color = Color(1.0, 0.86, 0.25)
		fb.position = -fb.size / 2.0
		add_child(fb)

func launch(dir: Vector2) -> void:
	velocity = dir.normalized() * SPEED

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
		var hw = collider.get("half_width")
		if hw == null:
			hw = 160.0
		var offset := clampf((global_position.x - collider.global_position.x) / float(hw), -1.0, 1.0)
		var a := offset * MAX_BOUNCE
		velocity = Vector2(sin(a), -cos(a)).normalized() * SPEED
		global_position.y = collider.global_position.y - diameter * 0.75
	else:
		velocity = velocity.bounce(collision.get_normal())
		if collider != null and collider.is_in_group("block"):
			collider.call("take_hit")
	velocity = _normalize(velocity)

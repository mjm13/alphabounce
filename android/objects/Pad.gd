extends StaticBody2D

# 挡板（envelope）：尺寸随关卡布局（对齐 Cs.hx 挡板/砖比例）。
const DEFAULT_WIDTH := 320.0
const DEFAULT_HEIGHT := 36.0

var pad_width := DEFAULT_WIDTH
var pad_height := DEFAULT_HEIGHT
var half_width := DEFAULT_WIDTH / 2.0

func configure(p_width: float, p_height: float) -> void:
	pad_width = maxf(p_width, 80.0)
	pad_height = maxf(p_height, 18.0)
	half_width = pad_width / 2.0
	if is_inside_tree():
		_rebuild_body()

func _ready() -> void:
	add_to_group("paddle")
	_rebuild_body()

func _rebuild_body() -> void:
	for c in get_children():
		c.queue_free()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(pad_width, pad_height)
	add_child(shape)
	var sprite := Sprite2D.new()
	sprite.name = "Vis"
	sprite.centered = true
	sprite.texture = load("res://assets/sprites/mcPad/01.png")
	if sprite.texture != null:
		var tex := sprite.texture.get_size()
		var sx := pad_width / tex.x
		var sy := pad_height / tex.y
		sprite.scale = Vector2(sx, sy)
		add_child(sprite)
	else:
		var fb := ColorRect.new()
		fb.size = Vector2(pad_width, pad_height)
		fb.color = Color(0.30, 0.70, 1.00)
		fb.position = -fb.size / 2.0
		add_child(fb)

func follow_pointer(x: float) -> void:
	var vps := get_viewport_rect().size
	global_position.x = clampf(x, half_width + 12.0, vps.x - half_width - 12.0)
	global_position.y = vps.y * 0.82

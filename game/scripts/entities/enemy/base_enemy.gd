extends Area2D
class_name BaseEnemy

## 敌人基类：生命/速度/状态、球碰撞检测、受击与消灭。
## 事件敌人(ev)与 Molecule 飞行怪物均继承自此类。

@export var health: int = 1
@export var speed: float = 60.0
var velocity := Vector2.ZERO
var enemy_kind: String = "enemy"   # "enemy" | "molecule"
var _radius: float = 12.0
var sprite_path: String = ""        # 由子类赋值，[R15] 渲染原版精灵
var placeholder_color: Color = Color(1, 1, 1, 1)  # [R15] 缺原版资源时的兜底颜色

signal destroyed(pos: Vector2)

func _ready() -> void:
	add_to_group("enemies")
	# 代码实例化的敌人需手动挂碰撞体，确保 Area2D 可检测球
	var shape := CircleShape2D.new()
	shape.radius = _radius
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	area_entered.connect(_on_area_entered)
	_setup_sprite()
	_init_enemy()

# [R15] 渲染原版精灵（sprite_path 由子类赋值），按 24px 等比例缩放，避免原始画布过大导致重叠。
# 若原版资源缺失（部分敌人精灵原版快照本身未提供），退化为程序化彩色圆形，确保真机截图可见可辨识实体。
func _setup_sprite() -> void:
	var sp := Sprite2D.new()
	sp.name = "Sprite2D"
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		var tex: Texture2D = load(sprite_path)
		sp.texture = tex
		var size := tex.get_size()
		var target := 24.0
		var big: float = maxf(size.x, size.y)
		var s: float = target / big
		sp.scale = Vector2(s, s)
	else:
		sp.texture = _make_placeholder(placeholder_color)
	add_child(sp)

# [R15] 程序化生成 24x24 实心圆贴图（缺原版资源时的视觉兜底）
func _make_placeholder(col: Color) -> Texture2D:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(12, 12)
	for y in range(24):
		for x in range(24):
			if c.distance_to(Vector2(x + 0.5, y + 0.5)) <= 11.0:
				img.set_pixel(x, y, col)
	var t := ImageTexture.create_from_image(img)
	return t

## 子类可覆写以做初始化（读 fixture 等）
func _init_enemy() -> void:
	pass

func _physics_process(delta: float) -> void:
	step(delta)

## 每帧行为（可被 debug 自检同步调用，行为确定性可复现）
func step(delta: float) -> void:
	position += velocity * delta

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("ball"):
		hit(1)

## 球/导弹对敌人造成伤害；返回是否消灭
func hit(damage: int = 1) -> bool:
	health -= damage
	if health <= 0 and not is_queued_for_deletion():
		destroy()
		return true
	return false

func destroy() -> void:
	destroyed.emit(position)
	queue_free()

## 碰撞层约定：layer=8(enemy) mask=5(ball+boundary)（OQ-001/INV）
func _setup_layers() -> void:
	collision_layer = 8
	collision_mask = 5

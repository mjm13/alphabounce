extends Node2D

# [R11] 导弹实体：由 Pad 向上发射，碰撞方块时以 by_missile=true 调用 hit()，
# 唯一能击杀 GUARDIAN 方块的途径。

const SPEED := 320.0
var _dir: Vector2 = Vector2.UP

func _ready() -> void:
	var sp := $Sprite2D
	if ResourceLoader.exists("res://resources/images/mcOption/sprite.png"):
		sp.texture = load("res://resources/images/mcOption/sprite.png")
	$Area2D.body_entered.connect(_on_body_entered)

func launch(dir: Vector2 = Vector2.UP) -> void:
	_dir = dir.normalized()

func _physics_process(delta: float) -> void:
	position += _dir * SPEED * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("blocks") and body.has_method("hit"):
		body.hit(999, true)
		queue_free()

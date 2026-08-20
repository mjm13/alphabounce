extends StaticBody2D

# 可破坏砖块：StaticBody2D 物理 + P2 数据驱动行为（BlockDef / blocks.json）。
const BS = preload("res://scripts/brick_system.gd")
const SIZE := 120.0
const HEIGHT := 50.0

var def: BS.BlockDef = null
var hp := 1
var max_hp := 1
var current_stage := 0
var stages: Array = []
var alive := true
var counts_toward_win := true
var game = null

func setup_from_def(p_def: BS.BlockDef) -> void:
	def = p_def
	alive = true
	counts_toward_win = p_def.behavior != BS.Behavior.UNBREAKABLE
	match def.behavior:
		BS.Behavior.NORMAL:
			hp = maxi(def.hp, 1)
		BS.Behavior.DURABLE:
			hp = maxi(def.hp, 2)
		BS.Behavior.UNBREAKABLE:
			hp = -1
		BS.Behavior.MULTISTAGE:
			stages = def.stages.duplicate()
			if stages.is_empty():
				stages = [maxi(def.hp, 1), 1]
			current_stage = 0
			hp = int(stages[current_stage])
		BS.Behavior.SPECIAL:
			hp = maxi(def.hp, 1)
	max_hp = hp if hp > 0 else 9999

func _ready() -> void:
	add_to_group("block")
	if def == null:
		var fallback := BS.BlockDef.new()
		fallback.id = "fallback_normal"
		fallback.behavior = BS.Behavior.NORMAL
		fallback.hp = 1
		fallback.score = 100
		fallback.color = Color(0.85, 0.30, 0.40)
		fallback.drop_letter = false
		setup_from_def(fallback)
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(SIZE, HEIGHT)
	add_child(shape)
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
		fb.position = -fb.size / 2.0
		vis = fb
	add_child(vis)
	_refresh_color()

func take_hit(damage: int = 1) -> void:
	if not alive or def == null:
		return
	if def.behavior == BS.Behavior.UNBREAKABLE:
		_flash_hit()
		return
	if def.behavior == BS.Behavior.MULTISTAGE:
		var remaining := damage
		while remaining > 0:
			if hp > remaining:
				hp -= remaining
				remaining = 0
			else:
				remaining -= hp
				current_stage += 1
				if current_stage < stages.size():
					hp = int(stages[current_stage])
				else:
					_destroy()
					return
		_refresh_color()
		return
	hp -= damage
	if hp > 0:
		_refresh_color()
		return
	_destroy()

func _destroy() -> void:
	if not alive:
		return
	alive = false
	var parent := get_parent()
	if parent != null and def != null:
		var fx := BS.FX.new()
		fx.setup(def)
		fx.global_position = global_position
		parent.add_child(fx)
		if def.drop_letter:
			var pu := BS.Pickup.new()
			pu.setup(def)
			pu.global_position = global_position
			parent.add_child(pu)
	if game != null:
		game.on_block_destroyed(def.score if def != null else 100)
	queue_free()

func _flash_hit() -> void:
	var vis := get_node_or_null("Vis")
	if vis == null:
		return
	var tw := create_tween()
	tw.tween_property(vis, "modulate", Color(1.4, 1.4, 1.4), 0.05)
	tw.tween_property(vis, "modulate", Color.WHITE, 0.12)

func _refresh_color() -> void:
	var vis := get_node_or_null("Vis")
	if vis == null or def == null:
		return
	var base := def.color
	if hp <= 0 or def.behavior == BS.Behavior.UNBREAKABLE:
		var t := 1.0
		if vis is Sprite2D:
			vis.modulate = base
		else:
			vis.color = base
		return
	var ratio := clampf(float(hp) / float(max(1, max_hp)), 0.2, 1.0)
	var c := Color(base.r * ratio, base.g * ratio, base.b * ratio)
	if vis is Sprite2D:
		vis.modulate = c
	else:
		vis.color = c

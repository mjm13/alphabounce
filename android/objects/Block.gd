extends StaticBody2D

# 可破坏砖块：StaticBody2D 物理 + P2 数据驱动行为与 mcBlock 贴图（BlockDef / blocks.json）。
const BS = preload("res://scripts/brick_system.gd")
const BallSys = preload("res://scripts/ball_system.gd")
const DEFAULT_W := 96.0
const DEFAULT_H := 48.0

var def: BS.BlockDef = null
var hp := 1
var max_hp := 1
var current_stage := 0
var stages: Array = []
var alive := true
var counts_toward_win := true
var game = null
var _vis_base: CanvasItem = null
var _vis_smc: Sprite2D = null
var _frozen_ice := false

func _block_w() -> float:
	if game != null and game.has_method("block_w"):
		return float(game.block_w())
	return DEFAULT_W

func _block_h() -> float:
	if game != null and game.has_method("block_h"):
		return float(game.block_h())
	return DEFAULT_H

func _uniform_scale(tex: Vector2, box_w: float, box_h: float) -> Vector2:
	if tex.x <= 0.0 or tex.y <= 0.0:
		return Vector2.ONE
	var s := minf(box_w / tex.x, box_h / tex.y)
	return Vector2(s, s)

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
	if is_inside_tree():
		_apply_visuals()

func _ready() -> void:
	add_to_group("block")
	if def == null:
		var fallback := BS.BlockDef.new()
		fallback.id = "fallback_normal"
		fallback.behavior = BS.Behavior.NORMAL
		fallback.hp = 1
		fallback.score = 100
		fallback.color = Color(0.85, 0.30, 0.40)
		fallback.sprite = "01"
		fallback.use_tint = true
		fallback.drop_letter = false
		setup_from_def(fallback)
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = Vector2(_block_w(), _block_h())
	add_child(shape)
	_build_visual_nodes()
	_apply_visuals()

func _build_visual_nodes() -> void:
	for n in ["Vis", "VisSmc"]:
		var old := get_node_or_null(n)
		if old != null:
			old.queue_free()
	_vis_base = null
	_vis_smc = null

	var sprite := Sprite2D.new()
	sprite.name = "Vis"
	sprite.centered = true
	add_child(sprite)
	_vis_base = sprite

	if _needs_smc_overlay():
		var smc := Sprite2D.new()
		smc.name = "VisSmc"
		smc.centered = true
		add_child(smc)
		_vis_smc = smc

func _needs_smc_overlay() -> bool:
	if def == null:
		return false
	if not def.sprite_smc.is_empty():
		return true
	return def.behavior == BS.Behavior.DURABLE or def.behavior == BS.Behavior.MULTISTAGE

func _apply_visuals() -> void:
	if def == null:
		return
	if _vis_base == null:
		return

	var bw := _block_w()
	var bh := _block_h()
	var base_tex: Texture2D = load(BS.BlockDef.mc_block_path(def.sprite))
	if base_tex != null and _vis_base is Sprite2D:
		var sp := _vis_base as Sprite2D
		sp.texture = base_tex
		sp.scale = _uniform_scale(base_tex.get_size(), bw, bh)
	elif _vis_base is Sprite2D:
		var fb := ColorRect.new()
		fb.name = "Vis"
		fb.size = Vector2(bw, bh)
		fb.position = -fb.size / 2.0
		_vis_base.queue_free()
		add_child(fb)
		_vis_base = fb

	if _vis_smc != null:
		var smc_path := def.sprite_smc
		if smc_path.is_empty() and _needs_smc_overlay():
			smc_path = "1"
		if not smc_path.is_empty():
			var smc_tex: Texture2D = load(BS.BlockDef.mc_block_smc_path(smc_path))
			if smc_tex != null:
				_vis_smc.texture = smc_tex
				_vis_smc.scale = _uniform_scale(smc_tex.get_size(), bw, bh)
				_vis_smc.visible = hp > 0 and def.behavior != BS.Behavior.UNBREAKABLE
			else:
				_vis_smc.visible = false

	_refresh_color()

func _smc_frame_for_hp() -> int:
	if hp <= 0:
		return 1
	return clampi(hp, 1, 6)

func is_soft() -> bool:
	return alive and def != null and def.behavior != BS.Behavior.UNBREAKABLE

func get_life_value() -> float:
	if not alive or def == null:
		return 0.0
	if def.behavior == BS.Behavior.UNBREAKABLE:
		return -1.0
	return float(hp)

func apply_ice_ball() -> void:
	if not alive or def == null or def.behavior == BS.Behavior.UNBREAKABLE or _frozen_ice:
		return
	_frozen_ice = true
	_flash_hit()
	_set_vis_modulate(_vis_base, Color(0.65, 0.85, 1.0))
	if _vis_smc != null:
		_set_vis_modulate(_vis_smc, Color(0.8, 0.95, 1.0))

func damage_from_ball(ball) -> void:
	if not alive or def == null:
		return
	if ball != null and ball.has_method("is_ghost") and ball.is_ghost():
		return
	if ball != null and ball.has_method("get_kind"):
		if ball.get_kind() == BallSys.BallKind.ICE:
			apply_ice_ball()
			return
		if ball.get_kind() == BallSys.BallKind.VOLT:
			_flash_hit()
			return
	var dmg := 1.0
	if ball != null and ball.has_method("get_damage"):
		dmg = float(ball.get_damage())
	if dmg <= 0.05:
		_flash_hit()
		return
	take_hit(maxi(int(ceil(dmg)), 1))

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
		fx.setup(def, _block_w(), _block_h())
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
	for vis in [_vis_base, _vis_smc]:
		if vis == null:
			continue
		var tw := create_tween()
		tw.tween_property(vis, "modulate", Color(1.4, 1.4, 1.4), 0.05)
		tw.tween_property(vis, "modulate", Color.WHITE, 0.12)

func _refresh_color() -> void:
	if _vis_base == null or def == null:
		return

	if _vis_smc != null and _vis_smc.visible:
		var bw := _block_w()
		var bh := _block_h()
		var smc_tex: Texture2D = load(
			BS.BlockDef.mc_block_smc_path(str(_smc_frame_for_hp()))
		)
		if smc_tex != null:
			_vis_smc.texture = smc_tex
			_vis_smc.scale = _uniform_scale(smc_tex.get_size(), bw, bh)

	var base := def.color if def.use_tint else Color.WHITE
	if hp <= 0 or def.behavior == BS.Behavior.UNBREAKABLE:
		_set_vis_modulate(_vis_base, base)
		if _vis_smc != null:
			_set_vis_modulate(_vis_smc, Color.WHITE)
		return

	if def.use_tint:
		var ratio := clampf(float(hp) / float(max(1, max_hp)), 0.35, 1.0)
		var c := Color(base.r * ratio, base.g * ratio, base.b * ratio)
		_set_vis_modulate(_vis_base, c)
	else:
		_set_vis_modulate(_vis_base, Color.WHITE)
	if _vis_smc != null:
		_set_vis_modulate(_vis_smc, Color.WHITE)

func _set_vis_modulate(vis: CanvasItem, c: Color) -> void:
	if vis is Sprite2D:
		vis.modulate = c
	elif vis is ColorRect:
		vis.color = c

extends CharacterBody2D

# 球：定步长运动 + P3 类型行为（对齐 el/Ball.hx）。
const BS = preload("res://scripts/ball_system.gd")
const SPEED := 660.0
const DEFAULT_SIZE := 26.0
const MAX_BOUNCE := deg_to_rad(60.0)
const MIN_VY := 0.22

var diameter := DEFAULT_SIZE
var def: BS.BallDef = null
var manager = null
var game = null

var _drunk_va := 0.0
var _ghost := false
var _ghost_motion := false
var _glue_offset_x: float = NAN
var _seek_pad := true
var _pierce_damage := 0.0
var _kamikaze_target: Node2D = null
var _kamikaze_va := 0.0
var _kamikaze_ca := 0.01
var _base_damage := 1.0

func configure(p_diameter: float) -> void:
	diameter = maxf(p_diameter, 12.0)
	if is_inside_tree():
		_rebuild_body()

func setup_from_def(p_def: BS.BallDef) -> void:
	def = p_def
	_base_damage = float(p_def.damage if p_def != null else 1)
	if is_inside_tree():
		_apply_visual()

func set_manager(p_manager) -> void:
	manager = p_manager

func get_kind() -> int:
	return def.kind if def != null else BS.BallKind.STANDARD

func get_damage() -> float:
	if def == null:
		return 1.0
	match def.kind:
		BS.BallKind.FIRE:
			return _base_damage + 1.0
		BS.BallKind.VOLT:
			return 0.1
	return _base_damage

func is_ghost() -> bool:
	return _ghost

func is_glued() -> bool:
	return not is_nan(_glue_offset_x)

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("ball")
	if def == null:
		var reg := BS.BallsRegistry.new()
		reg.load_from_file()
		def = reg.find_by_kind(BS.BallKind.STANDARD)
		_base_damage = float(def.damage)
	_rebuild_body()

func _rebuild_body() -> void:
	for c in get_children():
		c.queue_free()
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = diameter * 0.5
	add_child(shape)
	_apply_visual()

func _apply_visual() -> void:
	var old := get_node_or_null("Vis")
	if old != null:
		old.queue_free()
	var sprite := Sprite2D.new()
	sprite.name = "Vis"
	sprite.centered = true
	var tex_path := BS.BallDef.sprite_path(def)
	sprite.texture = load(tex_path)
	if sprite.texture != null:
		var tex := sprite.texture.get_size()
		var s := diameter / maxf(tex.x, tex.y)
		sprite.scale = Vector2(s, s)
	else:
		sprite.scale = Vector2.ONE
	if def != null:
		sprite.modulate = def.color
	add_child(sprite)
	modulate.a = 0.45 if _ghost else 1.0

func launch(dir: Vector2) -> void:
	_glue_offset_x = NAN
	_seek_pad = true
	_pierce_damage = 0.0
	velocity = dir.normalized() * SPEED

func unglue() -> void:
	if is_nan(_glue_offset_x):
		return
	_glue_offset_x = NAN
	_seek_pad = true
	launch(Vector2(randf_range(-0.35, 0.35), -1.0))

func set_ghost(p_on: bool) -> void:
	if _ghost == p_on:
		return
	_ghost = p_on
	_ghost_motion = p_on
	modulate.a = 0.45 if _ghost else 1.0

func _paddle_top_y(paddle: Node2D) -> float:
	var ph: float = paddle.get("pad_height") if paddle.get("pad_height") != null else 36.0
	return paddle.global_position.y - ph * 0.5

func _snap_above_paddle(paddle: Node2D) -> void:
	global_position.y = _paddle_top_y(paddle) - diameter * 0.5 - 2.0

func _normalize(v: Vector2) -> Vector2:
	v = v.normalized() * _current_speed()
	if abs(v.y) < _current_speed() * MIN_VY:
		var sign_y := -1.0 if v.y <= 0.0 else 1.0
		v.y = sign_y * _current_speed() * MIN_VY
		v.x = sign(v.x) * sqrt(max(0.0, _current_speed() * _current_speed() - v.y * v.y))
	return v

func _current_speed() -> float:
	if def != null and def.yoyo and game != null and game.has_method("_vp"):
		var floor_y: float = game._vp().y * 0.82 + 15.0
		var mult := 4.0 * (1.0 - global_position.y / maxf(floor_y, 1.0))
		return SPEED * clampf(mult, 0.25, 4.0)
	return SPEED

func _apply_type_motion(delta: float) -> void:
	if def == null:
		return
	if def.drunk:
		_drunk_va += (randf() * 2.0 - 1.0) * 0.03 * (_current_speed() / 6.0) * delta * 60.0
		_drunk_va *= pow(0.95, delta * 60.0)
		var a := velocity.angle() + _drunk_va * delta * 60.0
		velocity = Vector2.from_angle(a) * _current_speed()
	if def.kamikaze:
		_update_kamikaze(delta)
	if def.yoyo:
		velocity = velocity.normalized() * _current_speed()

func _update_kamikaze(delta: float) -> void:
	if _kamikaze_target == null or not is_instance_valid(_kamikaze_target):
		_kamikaze_target = _pick_soft_block()
		_kamikaze_ca = 0.01
		_kamikaze_va = 0.0
	if _kamikaze_target == null:
		return
	var cur := velocity.angle()
	var desired := (_kamikaze_target.global_position - global_position).angle()
	_kamikaze_ca = minf(_kamikaze_ca + 0.002 * delta * 60.0, 1.0)
	_kamikaze_va += _angle_delta(desired, cur) * _kamikaze_ca
	_kamikaze_va *= pow(0.8, delta * 60.0)
	var na := cur + _kamikaze_va
	velocity = Vector2.from_angle(na) * _current_speed()
	if randf() < delta * (60.0 / 60.0):
		_kamikaze_target = null

func _angle_delta(target: float, current: float) -> float:
	return wrapf(target - current, -PI, PI)

func _pick_soft_block() -> Node2D:
	var blocks: Array = []
	for n in get_tree().get_nodes_in_group("block"):
		if n is Node2D and n.has_method("is_soft") and n.is_soft():
			blocks.append(n)
	if blocks.is_empty():
		return null
	return blocks[randi() % blocks.size()]

func _find_nearest_soft_block() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("block"):
		if not (n is Node2D) or not n.has_method("is_soft") or not n.is_soft():
			continue
		var d := global_position.distance_squared_to(n.global_position)
		if d < best_d:
			best_d = d
			best = n
	return best

func _separate_from_other_balls() -> void:
	for n in get_tree().get_nodes_in_group("ball"):
		if n == self or not (n is CharacterBody2D):
			continue
		var other: CharacterBody2D = n
		var delta_p := global_position - other.global_position
		var dist := delta_p.length()
		var min_dist := diameter * 0.92
		if dist < min_dist and dist > 0.001:
			var push := delta_p.normalized() * (min_dist - dist) * 0.5
			global_position += push
			var nrm := delta_p.normalized()
			velocity = velocity.bounce(nrm)
			other.velocity = other.velocity.bounce(-nrm)

func _physics_process(delta: float) -> void:
	if not is_nan(_glue_offset_x):
		var paddle = _find_paddle()
		if paddle != null:
			global_position.x = paddle.global_position.x + _glue_offset_x
			_snap_above_paddle(paddle)
			velocity = Vector2.ZERO
		return

	if global_position.y > get_viewport_rect().size.y + diameter:
		if manager != null and manager.has_method("on_ball_exited"):
			manager.on_ball_exited(self)
		else:
			queue_free()
		return

	var paddle_ref = _find_paddle()
	if paddle_ref != null and global_position.y > _paddle_top_y(paddle_ref) + diameter and velocity.y > 0.0:
		_seek_pad = false

	if _ghost_motion:
		_process_ghost_motion(delta)
		return

	_apply_type_motion(delta)
	var collision := move_and_collide(velocity * delta)
	_separate_from_other_balls()

	if collision == null:
		return
	_handle_collision(collision)

func _process_ghost_motion(delta: float) -> void:
	global_position += velocity * delta
	var vps := get_viewport_rect().size
	if global_position.x < diameter:
		global_position.x = diameter
		velocity.x *= -1.0
	elif global_position.x > vps.x - diameter:
		global_position.x = vps.x - diameter
		velocity.x *= -1.0
	if global_position.y < diameter:
		global_position.y = diameter
		velocity.y *= -1.0
	if velocity.y > 0.0:
		set_ghost(false)
	velocity = _normalize(velocity)

func _find_paddle() -> Node2D:
	for n in get_tree().get_nodes_in_group("paddle"):
		if n is Node2D:
			return n
	return null

func _handle_collision(collision: KinematicCollision2D) -> void:
	var collider := collision.get_collider() as Node2D
	if collider == null:
		velocity = velocity.bounce(collision.get_normal())
		velocity = _normalize(velocity)
		return

	if collider.is_in_group("ball"):
		velocity = velocity.bounce(collision.get_normal())
	elif collider.is_in_group("paddle") and _seek_pad and velocity.y > 0.0:
		_bounce_off_paddle(collider)
	elif collider.is_in_group("block"):
		_hit_block(collider, collision)
	elif collider.is_in_group("paddle"):
		velocity = velocity.bounce(collision.get_normal())
	else:
		if def != null and def.shade:
			var n := collision.get_normal()
			if abs(n.x) > 0.5:
				_destroy_self()
				return
		velocity = velocity.bounce(collision.get_normal())
	velocity = _normalize(velocity)

func _bounce_off_paddle(paddle: Node2D) -> void:
	if def != null and def.shade:
		_destroy_self()
		return
	var hw = paddle.get("half_width")
	if hw == null:
		hw = 160.0
	var offset := clampf((global_position.x - paddle.global_position.x) / float(hw), -1.0, 1.0)
	var a := offset * MAX_BOUNCE
	velocity = Vector2(sin(a), -cos(a)).normalized() * _current_speed()
	_snap_above_paddle(paddle)
	_seek_pad = true
	if def != null and def.halo:
		set_ghost(true)
	if def != null and def.pierce:
		_pierce_damage = get_damage()
	if paddle.has_method("is_glue_pad") and paddle.is_glue_pad():
		_glue_offset_x = global_position.x - paddle.global_position.x
		velocity = Vector2.ZERO

func _hit_block(block: Node2D, collision: KinematicCollision2D) -> void:
	if not _ghost and block.has_method("damage_from_ball"):
		block.damage_from_ball(self)
	if def != null and def.volt:
		_volt_chain(block.global_position)
	var should_bounce := true
	if _pierce_damage > 0.0 and block.has_method("get_life_value"):
		var life: float = block.get_life_value()
		if life > 0.0:
			_pierce_damage -= life
			if _pierce_damage > 0.0 and def != null and def.kind != BS.BallKind.ICE:
				should_bounce = false
	if def == null or should_bounce:
		velocity = velocity.bounce(collision.get_normal())

func _volt_chain(center: Vector2) -> void:
	var radius := 120.0
	if game != null and game.has_method("block_w"):
		radius = float(game.block_w()) * 2.5
	for n in get_tree().get_nodes_in_group("block"):
		if not (n is Node2D) or not n.has_method("take_hit"):
			continue
		if n.global_position.distance_to(center) <= radius:
			n.take_hit(1)

func _destroy_self() -> void:
	if manager != null and manager.has_method("on_ball_exited"):
		manager.on_ball_exited(self)
	else:
		queue_free()

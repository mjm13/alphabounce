extends StaticBody2D

# 挡板（envelope）：P3 PadDef 类型钩子（GLUE/LASER 等）。
const BS = preload("res://scripts/ball_system.gd")
const DEFAULT_WIDTH := 320.0
const DEFAULT_HEIGHT := 36.0

var pad_width := DEFAULT_WIDTH
var pad_height := DEFAULT_HEIGHT
var half_width := DEFAULT_WIDTH / 2.0
var pad_def: BS.PadDef = null

func configure(p_width: float, p_height: float) -> void:
	pad_width = maxf(p_width, 80.0)
	pad_height = maxf(p_height, 18.0)
	half_width = pad_width / 2.0
	if is_inside_tree():
		_rebuild_body()

func setup_from_def(p_def: BS.PadDef) -> void:
	pad_def = p_def
	if is_inside_tree():
		_rebuild_body()

func get_kind() -> int:
	return pad_def.kind if pad_def != null else BS.PadKind.STANDARD

func is_glue_pad() -> bool:
	return pad_def != null and pad_def.glue

func has_laser() -> bool:
	return pad_def != null and pad_def.laser

func has_generator() -> bool:
	return pad_def != null and pad_def.generator

func has_aimant() -> bool:
	return pad_def != null and pad_def.aimant

func has_shake() -> bool:
	return pad_def != null and pad_def.shake

func has_slow_time() -> bool:
	return pad_def != null and pad_def.slow_time

func _ready() -> void:
	add_to_group("paddle")
	if pad_def == null:
		var reg := BS.PadsRegistry.new()
		reg.load_from_file()
		pad_def = reg.find_by_kind(BS.PadKind.STANDARD)
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
		sprite.scale = Vector2(pad_width / tex.x, pad_height / tex.y)
		if pad_def != null:
			match pad_def.kind:
				BS.PadKind.GLUE:
					sprite.modulate = Color(0.6, 1.0, 0.6)
				BS.PadKind.LASER:
					sprite.modulate = Color(1.0, 0.5, 0.5)
				BS.PadKind.GENERATOR:
					sprite.modulate = Color(0.7, 0.85, 1.0)
				BS.PadKind.AIMANT:
					sprite.modulate = Color(0.8, 0.8, 1.0)
				BS.PadKind.SHAKE:
					sprite.modulate = Color(1.0, 0.85, 0.5)
				BS.PadKind.TIME:
					sprite.modulate = Color(0.75, 1.0, 1.0)
				_:
					sprite.modulate = Color.WHITE
		add_child(sprite)
	else:
		var fb := ColorRect.new()
		fb.size = Vector2(pad_width, pad_height)
		fb.color = Color(0.30, 0.70, 1.00)
		fb.position = -fb.size / 2.0
		add_child(fb)

func follow_pointer(x: float) -> void:
	var vps := get_viewport_rect().size
	var follow_x := x
	if has_aimant():
		for n in get_tree().get_nodes_in_group("ball"):
			if n is Node2D and n.global_position.y > global_position.y - pad_height:
				follow_x = n.global_position.x
				break
	global_position.x = clampf(follow_x, half_width + 12.0, vps.x - half_width - 12.0)
	global_position.y = vps.y * 0.82
	if has_shake():
		global_position.x += sin(Time.get_ticks_msec() * 0.02) * 4.0

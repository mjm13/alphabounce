extends Node
# 砖块系统统一模块（数据驱动，详见 P2 需求文档）。
# 采用「单脚本内联类 + preload」模式，避免依赖 Godot headless 下不生成的全局 class_name 缓存，
# 保证导出 / 无头测试均可稳定解析。
#
# 行为策略（与原版 Block.hx 对照）：
#   NORMAL      标准砖：hp=1，销毁掉字母（原版 bonusTable -> newOption）
#   DURABLE     高耐久：多 hp，逐次命中扣血（原版 PUSHER life=6 / JUMPER life=3）
#   UNBREAKABLE 不可破：等效原版 life==null，仅闪烁永不销毁
#   MULTISTAGE  多段破坏：逐段扣血，全段清空才销毁
#   SPECIAL     特殊触发：销毁发射 special_triggered（原版 REDUC/STEEL 等 onDamage）

enum Behavior { NORMAL, DURABLE, UNBREAKABLE, MULTISTAGE, SPECIAL }

class BlockDef extends Resource:
	var id: String = ""
	var name: String = ""
	var behavior: int = Behavior.NORMAL
	var hp: int = 1
	var score: int = 10
	var color: Color = Color(1, 1, 1)
	var sprite: String = "01"
	var sprite_smc: String = ""
	var use_tint: bool = false
	var drop_letter: bool = false
	var drop_letter_char: String = "A"
	var special_id: int = 0
	var stages: Array = []

	static func mc_block_path(frame: String) -> String:
		var id := frame.strip_edges()
		if id.is_empty():
			id = "01"
		if id.ends_with(".png"):
			return "res://assets/sprites/mcBlock/%s" % id
		if id.is_valid_int():
			return "res://assets/sprites/mcBlock/%02d.png" % int(id)
		return "res://assets/sprites/mcBlock/%s.png" % id

	static func mc_block_smc_path(frame: String) -> String:
		var id := frame.strip_edges()
		if id.is_empty():
			return ""
		if id.begins_with("mcBlockSMC"):
			return "res://assets/sprites/mcBlockSmc/%s.png" % id
		if id.is_valid_int():
			return "res://assets/sprites/mcBlockSmc/mcBlockSMC%04d.png" % int(id)
		return "res://assets/sprites/mcBlockSmc/%s" % id

class Block extends Node2D:
	signal destroyed(b)
	signal damaged(b, remaining_hp)
	signal special_triggered(b, special_id)
	signal fx_spawned(fx)
	signal pickup_spawned(pu)

	var def: BlockDef
	var hp: int = 0
	var max_hp: int = 0
	var current_stage: int = 0
	var stages: Array = []
	var alive: bool = true

	func setup(p_def: BlockDef) -> void:
		def = p_def
		alive = true
		match def.behavior:
			Behavior.NORMAL:
				hp = maxi(def.hp, 1)
			Behavior.DURABLE:
				hp = maxi(def.hp, 2)
			Behavior.UNBREAKABLE:
				hp = -1
			Behavior.MULTISTAGE:
				stages = def.stages.duplicate()
				if stages.is_empty():
					stages = [maxi(def.hp, 1), 1]
				current_stage = 0
				hp = int(stages[current_stage])
			Behavior.SPECIAL:
				hp = maxi(def.hp, 1)
		max_hp = hp if hp > 0 else 9999

	func expected_hits_to_destroy() -> int:
		if def == null:
			return -1
		match def.behavior:
			Behavior.UNBREAKABLE:
				return -1
			Behavior.MULTISTAGE:
				var s := 0
				for v in stages:
					s += int(v)
				return s
			_:
				return maxi(hp, 1)

	func take_hit(damage: int = 1) -> void:
		if not alive:
			return
		if def.behavior == Behavior.UNBREAKABLE:
			emit_signal("damaged", self, -1)
			return
		if def.behavior == Behavior.MULTISTAGE:
			# 伤害溢出逐段传递：一段清空后剩余伤害带入下一段，全段清空才销毁
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
			emit_signal("damaged", self, hp)
			return
		hp -= damage
		if hp > 0:
			emit_signal("damaged", self, hp)
			return
		_destroy()

	func _destroy() -> void:
		if not alive:
			return
		alive = false
		var fx := FX.new()
		fx.setup(def, 28.0, 14.0)
		var parent := get_parent()
		if parent != null:
			fx.global_position = global_position
			parent.add_child(fx)
		else:
			add_child(fx)
		emit_signal("fx_spawned", fx)
		if def.drop_letter:
			var pu := Pickup.new()
			pu.setup(def)
			get_parent().add_child(pu)
			emit_signal("pickup_spawned", pu)
		if def.behavior == Behavior.SPECIAL:
			emit_signal("special_triggered", self, def.special_id)
		emit_signal("destroyed", self)
		queue_free()

class FX extends Node2D:
	const FRAME_COUNT := 24
	const FRAME_TIME := 0.028

	var _sprite: Sprite2D
	var _frame := 1
	var _elapsed := 0.0
	var _block_w := 28.0
	var _block_h := 14.0

	func setup(p_def: BlockDef, block_w: float = 28.0, block_h: float = 14.0) -> void:
		_block_w = block_w
		_block_h = block_h
		_sprite = Sprite2D.new()
		_sprite.centered = true
		_sprite.modulate = p_def.color if p_def != null else Color.WHITE
		add_child(_sprite)
		_set_frame(1)
		_spawn_sparks(p_def)

	func _set_frame(n: int) -> void:
		var path := "res://assets/sprites/partExplode/%02d.png" % n
		if not ResourceLoader.exists(path):
			return
		_sprite.texture = load(path)
		if _sprite.texture == null:
			return
		var tex := _sprite.texture.get_size()
		if tex.x <= 0.0 or tex.y <= 0.0:
			return
		var sx := (_block_w / 30.0) * (tex.x / 64.0)
		var sy := (_block_h / 14.0) * (tex.y / 44.0)
		_sprite.scale = Vector2(maxf(sx, sy), maxf(sx, sy))

	func _spawn_sparks(p_def: BlockDef) -> void:
		for i in range(4):
			var sp := Sprite2D.new()
			sp.centered = true
			sp.texture = load("res://assets/sprites/partSpark/0%d.png" % (1 + (i % 3)))
			if sp.texture == null:
				continue
			sp.modulate = p_def.color if p_def != null else Color(1, 0.9, 0.5)
			sp.position = Vector2(randf_range(-_block_w * 0.3, _block_w * 0.3), randf_range(-_block_h * 0.2, _block_h * 0.2))
			var sc := randf_range(0.25, 0.5) * (_block_w / 28.0)
			sp.scale = Vector2(sc, sc)
			add_child(sp)
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(sp, "position", sp.position + Vector2(randf_range(-20, 20), randf_range(-30, 10)), 0.35)
			tw.tween_property(sp, "modulate:a", 0.0, 0.35)

	func _process(delta: float) -> void:
		_elapsed += delta
		while _elapsed >= FRAME_TIME:
			_elapsed -= FRAME_TIME
			_frame += 1
			if _frame > FRAME_COUNT:
				queue_free()
				return
			_set_frame(_frame)

class Pickup extends Node2D:
	var letter: String = ""
	func setup(p_def: BlockDef) -> void:
		# 字母拾取物占位（原版经 bonusTable -> newOption 掉落）；动画/效果 P4 接管
		letter = p_def.drop_letter_char if p_def.drop_letter_char.length() > 0 else "A"
		var t := Timer.new()
		t.wait_time = 2.0
		t.one_shot = true
		add_child(t)
		t.timeout.connect(queue_free)
		t.start()

class BlocksRegistry extends RefCounted:
	var defs: Array = []

	func load_from_file(path: String = "res://data/blocks/blocks.json") -> int:
		defs.clear()
		if not FileAccess.file_exists(path):
			push_error("BlocksRegistry: 数据文件缺失 -> " + path)
			return 0
		var txt := FileAccess.get_file_as_string(path)
		var data = JSON.parse_string(txt)
		if data == null or not ("blocks" in data):
			push_error("BlocksRegistry: JSON 非法 -> " + path)
			return 0
		for b in data["blocks"]:
			var d := BlockDef.new()
			d.id = b.get("id", "")
			d.name = b.get("name", d.id)
			d.behavior = int(b.get("behavior", 0))
			d.hp = int(b.get("hp", 1))
			d.score = int(b.get("score", 10))
			var cstr: String = b.get("color", "#ffffff")
			d.color = Color.from_string(cstr, Color.WHITE)
			d.sprite = str(b.get("sprite", "01"))
			d.sprite_smc = str(b.get("sprite_smc", ""))
			d.use_tint = bool(b.get("use_tint", false))
			d.drop_letter = bool(b.get("drop_letter", false))
			d.drop_letter_char = str(b.get("drop_letter_char", "A"))
			d.special_id = int(b.get("special_id", 0))
			if b.has("stages"):
				for s in b["stages"]:
					d.stages.append(int(s))
			defs.append(d)
		return defs.size()

	func get_all() -> Array:
		return defs

	func count() -> int:
		return defs.size()

	func find_by_id(p_id: String) -> BlockDef:
		for d in defs:
			if d.id == p_id:
				return d
		return null

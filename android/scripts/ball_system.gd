extends Node
# 球/挡板类型系统（P3）：单脚本内联类 + preload，对齐 brick_system 模式。

const MAX_BALL := 18

enum BallKind {
	STANDARD, FIRE, ICE, DRUNK, KAMIKAZE, YOYO, HALO, SHADE, VOLT
}

enum PadKind {
	STANDARD, GLUE, TIME, LASER, GENERATOR, AIMANT, SHAKE
}

class BallDef extends Resource:
	var id: String = ""
	var name: String = ""
	var kind: int = BallKind.STANDARD
	var damage: int = 1
	var pierce: bool = false
	var drunk: bool = false
	var kamikaze: bool = false
	var yoyo: bool = false
	var halo: bool = false
	var shade: bool = false
	var fire: bool = false
	var ice: bool = false
	var volt: bool = false
	var color: Color = Color(1, 0.9, 0.4)
	var sprite: String = "ball_main0001.png"
	var sprite_dir: String = "ballMain"

	static func sprite_path(p_def: BallDef) -> String:
		if p_def == null:
			return "res://assets/sprites/ballMain/ball_main0001.png"
		var folder := p_def.sprite_dir if p_def.sprite_dir.length() > 0 else "ballMain"
		return "res://assets/sprites/%s/%s" % [folder, p_def.sprite]


class PadDef extends Resource:
	var id: String = ""
	var name: String = ""
	var kind: int = PadKind.STANDARD
	var glue: bool = false
	var slow_time: bool = false
	var laser: bool = false
	var generator: bool = false
	var aimant: bool = false
	var shake: bool = false


class BallsRegistry extends RefCounted:
	var defs: Array = []

	func load_from_file(path: String = "res://data/balls/balls.json") -> int:
		defs.clear()
		if not FileAccess.file_exists(path):
			push_error("BallsRegistry: missing " + path)
			return 0
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data == null or not ("balls" in data):
			push_error("BallsRegistry: invalid JSON " + path)
			return 0
		for b in data["balls"]:
			var d := BallDef.new()
			d.id = str(b.get("id", ""))
			d.name = str(b.get("name", d.id))
			d.kind = int(b.get("kind", 0))
			d.damage = int(b.get("damage", 1))
			d.pierce = bool(b.get("pierce", false))
			d.drunk = bool(b.get("drunk", false))
			d.kamikaze = bool(b.get("kamikaze", false))
			d.yoyo = bool(b.get("yoyo", false))
			d.halo = bool(b.get("halo", false))
			d.shade = bool(b.get("shade", false))
			d.fire = bool(b.get("fire", false))
			d.ice = bool(b.get("ice", false))
			d.volt = bool(b.get("volt", false))
			d.sprite = str(b.get("sprite", "ball_main0001.png"))
			d.sprite_dir = str(b.get("sprite_dir", "ballMain"))
			var cstr: String = str(b.get("color", "#FFE066"))
			d.color = Color.from_string(cstr, Color.WHITE)
			defs.append(d)
		return defs.size()

	func get_all() -> Array:
		return defs

	func find_by_id(p_id: String) -> BallDef:
		for d in defs:
			if d.id == p_id:
				return d
		return null

	func find_by_kind(p_kind: int) -> BallDef:
		for d in defs:
			if d.kind == p_kind:
				return d
		return null


class PadsRegistry extends RefCounted:
	var defs: Array = []

	func load_from_file(path: String = "res://data/pads/pads.json") -> int:
		defs.clear()
		if not FileAccess.file_exists(path):
			push_error("PadsRegistry: missing " + path)
			return 0
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data == null or not ("pads" in data):
			push_error("PadsRegistry: invalid JSON " + path)
			return 0
		for p in data["pads"]:
			var d := PadDef.new()
			d.id = str(p.get("id", ""))
			d.name = str(p.get("name", d.id))
			d.kind = int(p.get("kind", 0))
			d.glue = bool(p.get("glue", false))
			d.slow_time = bool(p.get("slow_time", false))
			d.laser = bool(p.get("laser", false))
			d.generator = bool(p.get("generator", false))
			d.aimant = bool(p.get("aimant", false))
			d.shake = bool(p.get("shake", false))
			defs.append(d)
		return defs.size()

	func get_all() -> Array:
		return defs

	func find_by_kind(p_kind: int) -> PadDef:
		for d in defs:
			if d.kind == p_kind:
				return d
		return null


class BallManager extends RefCounted:
	signal all_balls_lost
	signal ball_count_changed(count: int)

	var owner: Node2D = null
	var ball_script: Script = null
	var diameter: float = 26.0
	var balls: Array = []

	func setup(p_owner: Node2D, p_diameter: float, p_ball_script: Script) -> void:
		owner = p_owner
		diameter = p_diameter
		ball_script = p_ball_script
		balls.clear()

	func count() -> int:
		_prune_dead()
		return balls.size()

	func is_empty() -> bool:
		return count() == 0

	func clear_all() -> void:
		for b in balls.duplicate():
			if is_instance_valid(b):
				b.queue_free()
		balls.clear()
		ball_count_changed.emit(0)

	func spawn(p_def: BallDef, p_pos: Vector2, p_dir: Vector2):
		_prune_dead()
		if balls.size() >= MAX_BALL:
			return null
		if ball_script == null or owner == null or p_def == null:
			return null
		var b = ball_script.new()
		b.configure(diameter)
		if b.has_method("setup_from_def"):
			b.setup_from_def(p_def)
		if b.has_method("set_manager"):
			b.set_manager(self)
		if owner.has_method("block_w"):
			b.game = owner
		owner.add_child(b)
		b.global_position = p_pos
		if b.has_method("launch"):
			b.launch(p_dir)
		balls.append(b)
		ball_count_changed.emit(balls.size())
		return b

	func spawn_multiball(p_count: int, p_center: Vector2, p_dir: Vector2, p_def: BallDef) -> int:
		var spread := diameter * 1.15
		var spawned := 0
		for i in p_count:
			if balls.size() >= MAX_BALL:
				break
			var side := -1.0 if i % 2 == 0 else 1.0
			var lane := float(i / 2 + 1)
			var pos := p_center + Vector2(side * spread * lane, -diameter * 0.8)
			if spawn(p_def, pos, p_dir) != null:
				spawned += 1
		return spawned

	func remove_ball(p_ball) -> void:
		if p_ball == null:
			return
		balls.erase(p_ball)
		if is_instance_valid(p_ball):
			p_ball.queue_free()
		_prune_dead()
		ball_count_changed.emit(balls.size())
		if balls.is_empty():
			all_balls_lost.emit()

	func on_ball_exited(p_ball) -> void:
		remove_ball(p_ball)

	func get_spread_x_positions(p_count: int, p_center_x: float) -> Array:
		var spread := diameter * 1.15
		var out: Array = []
		for i in p_count:
			var side := -1.0 if i % 2 == 0 else 1.0
			var lane := float(i / 2 + 1)
			out.append(p_center_x + side * spread * lane)
		return out

	func _prune_dead() -> void:
		var live: Array = []
		for b in balls:
			if is_instance_valid(b):
				live.append(b)
		balls = live

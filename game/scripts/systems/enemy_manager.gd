extends Node

## 敌人领域服务（Autoload；全局名 EnemyManager 由 project.godot 注册，勿用 class_name 以免与单例同名冲突）：
## 协调事件敌人生命周期、Molecule 网格与 GUARDIAN 跟踪。
## 数据来自 game/debug/fixtures/enemy_demo.json（替代 R16 enemies.json）。

var world: Node2D = null
var enemies: Array = []
var molecules: Array = []
var guardian = null
var _data: Dictionary = {}

const EvEnemyScript = preload("res://scripts/entities/enemy/ev_enemy.gd")
const MoleculeScript = preload("res://scripts/entities/molecule/molecule.gd")

func _ready() -> void:
	_load_data()

func _load_data() -> void:
	var p := "res://debug/fixtures/enemy_demo.json"
	if FileAccess.file_exists(p):
		var txt := FileAccess.get_file_as_string(p)
		if not txt.is_empty():
			var d = JSON.parse_string(txt)
			if typeof(d) == TYPE_DICTIONARY:
				_data = d

func get_molecule_data(t: String) -> Dictionary:
	return _data.get("molecule", {}).get(t, {})

func get_ev_data(t: String) -> Dictionary:
	return _data.get("ev", {}).get(t, {})

func set_world(w: Node2D) -> void:
	world = w

func spawn_ev(name: String, pos: Vector2 = Vector2.ZERO) -> Node:
	var e = EvEnemyScript.new()
	e.set_behavior(get_ev_data(name).get("behavior", name).to_lower())
	e.position = pos
	if world != null:
		world.add_child(e)
	enemies.append(e)
	e.destroyed.connect(_on_enemy_destroyed.bind(e))
	return e

func spawn_molecule(sub: String, pos: Vector2 = Vector2.ZERO) -> Node:
	var m = MoleculeScript.new()
	m.molecule_type = sub
	m.position = pos
	if world != null:
		world.add_child(m)
	molecules.append(m)
	return m

func register_guardian(b) -> void:
	guardian = b

func _on_enemy_destroyed(_pos: Vector2, e: Node) -> void:
	enemies.erase(e)

func update(delta: float) -> void:
	for e in enemies:
		if is_instance_valid(e):
			e.step(delta)
	for m in molecules:
		if is_instance_valid(m):
			m.step(delta)

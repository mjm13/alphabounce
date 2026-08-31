extends "res://scripts/entities/enemy/base_enemy.gd"
class_name Molecule

## 7 种 Molecule 飞行怪物（el/Molecule.hx），数据驱动（hp/speed/damage 来自 enemy_demo.json）。

var molecule_type: String = "M1" : set = set_molecule_type
var dmg: int = 1
var _t: float = 0.0

# [R15] 缺原版精灵时的兜底颜色
const _MCOLORS := {
	"M1": Color(0.9, 0.3, 0.3), "M2": Color(0.95, 0.6, 0.2), "M3": Color(0.95, 0.95, 0.3),
	"M4": Color(0.3, 0.9, 0.4), "M5": Color(0.3, 0.9, 0.9), "M6": Color(0.3, 0.5, 0.95), "M7": Color(0.8, 0.3, 0.95),
}

func set_molecule_type(t: String) -> void:
	molecule_type = t
	placeholder_color = _MCOLORS.get(t, Color.WHITE)

# [R15] 占位色须在 _setup_sprite 之前定好（_init_enemy 在其之后才执行）
func _ready() -> void:
	placeholder_color = _MCOLORS.get(molecule_type, Color.WHITE)
	super._ready()

func _init_enemy() -> void:
	enemy_kind = "molecule"
	add_to_group("molecules")
	_setup_layers()
	sprite_path = "res://resources/images/mcMonster/sprite.png"
	var d: Dictionary = EnemyManager.get_molecule_data(molecule_type)
	if not d.is_empty():
		health = int(d.get("hp", 1))
		speed = float(d.get("speed", 50))
		dmg = int(d.get("damage", 1))
		_radius = 10.0

func step(delta: float) -> void:
	_t += delta
	velocity = Vector2(sin(_t * 2.0) * speed, cos(_t * 1.5) * speed * 0.5)
	position += velocity * delta
	rotation += delta

## 敌/闪电/Molecule 碰玩家造成的生命损耗
func damage_player() -> int:
	return dmg

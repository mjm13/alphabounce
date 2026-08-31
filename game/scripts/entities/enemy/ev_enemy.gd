extends "res://scripts/entities/enemy/base_enemy.gd"
class_name EvEnemy

## 11 种事件型敌人（ev），行为对齐原版 ev/*.hx。数据来自 enemy_demo.json（R16 未就绪时 mock）。

enum Behavior {
	DRAGON, DRONE, GENERATOR, INDIGESTION, JAVELOT,
	OUVERTURE, QUASAR, STORM, ULTRAVIOLET, UNIFICATION, WAVE,
}

const NAME_TO_BEHAVIOR := {
	"dragon": Behavior.DRAGON, "drone": Behavior.DRONE, "generator": Behavior.GENERATOR,
	"indigestion": Behavior.INDIGESTION, "javelot": Behavior.JAVELOT, "ouverture": Behavior.OUVERTURE,
	"quasar": Behavior.QUASAR, "storm": Behavior.STORM, "ultraviolet": Behavior.ULTRAVIOLET,
	"unification": Behavior.UNIFICATION, "wave": Behavior.WAVE,
}

var behavior: int = Behavior.DRAGON
var behavior_name: String = "dragon"
var _t: float = 0.0
var _dir: int = 1

# [R15] 缺原版精灵时的兜底颜色（原版快照部分敌人图缺失）
const _COLORS := {
	"dragon": Color(0.9, 0.2, 0.2), "drone": Color(0.2, 0.8, 0.9),
	"generator": Color(0.9, 0.9, 0.2), "indigestion": Color(0.6, 0.4, 0.2),
	"javelot": Color(0.95, 0.5, 0.1), "ouverture": Color(0.3, 0.9, 0.4),
	"quasar": Color(0.7, 0.3, 0.9), "storm": Color(0.5, 0.5, 0.9),
	"ultraviolet": Color(0.45, 0.2, 0.95), "unification": Color(0.2, 0.9, 0.9),
	"wave": Color(0.2, 0.6, 0.9),
}

const _SPRITES := {
	"dragon": "res://resources/images/mcDragon/sprite.png",
	"drone": "res://resources/images/mcDrone/sprite.png",
	"generator": "res://resources/images/mcGenerator/sprite.png",
	"indigestion": "res://resources/images/mcNut/sprite.png",
	"javelot": "res://resources/images/mcJavelot/sprite.png",
	"ouverture": "res://resources/images/mcOnde/sprite.png",
	"quasar": "res://resources/images/mcQuasar/sprite.png",
	"storm": "res://resources/images/mcProtection/sprite.png",
	"ultraviolet": "res://resources/images/mcUltraViolet/sprite.png",
	"unification": "res://resources/images/mcShape/sprite.png",
	"wave": "res://resources/images/mcWave/sprite.png",
}

func set_behavior(name: String) -> void:
	behavior_name = name
	behavior = NAME_TO_BEHAVIOR.get(name, Behavior.DRAGON)
	sprite_path = _SPRITES.get(name, "")
	placeholder_color = _COLORS.get(name.to_lower(), Color.WHITE)

func _init_enemy() -> void:
	enemy_kind = "enemy"
	_setup_layers()
	placeholder_color = _COLORS.get(behavior_name, Color.WHITE)
	var d: Dictionary = EnemyManager.get_ev_data(behavior_name)
	if not d.is_empty():
		speed = float(d.get("speed", 60.0))

func step(delta: float) -> void:
	_t += delta
	match behavior:
		Behavior.DRAGON:
			velocity.x = _dir * speed
			position += velocity * delta
			if position.x < 20.0 or position.x > 380.0:
				_dir *= -1
		Behavior.DRONE:
			velocity.x = cos(_t * 1.3) * speed * 0.4
			velocity.y = sin(_t * 3.0) * speed
			position += velocity * delta
		Behavior.GENERATOR:
			if _t >= 2.0:
				_t = 0.0
				EnemyManager.spawn_molecule("M1", position + Vector2(0, 16))
		Behavior.INDIGESTION:
			pass
		Behavior.JAVELOT:
			velocity.y = -speed
			position += velocity * delta
		Behavior.OUVERTURE:
			var to_center := Vector2(200, 180) - position
			velocity = to_center.normalized() * speed * 0.3
			position += velocity * delta
		Behavior.QUASAR:
			rotation += delta * 2.0
		Behavior.STORM:
			pass
		Behavior.ULTRAVIOLET:
			velocity.y = speed
			position += velocity * delta
		Behavior.UNIFICATION:
			_radius += delta * 6.0
		Behavior.WAVE:
			velocity.y = -speed * 0.5
			position += velocity * delta

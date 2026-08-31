extends Node
class_name TouchInputManager

# [R09] 触摸输入映射：将屏幕触摸事件翻译为语义化游戏动作，对齐原版 AlphaBounce 动作集。
# 原版（EternalTwin-Alphabounce）核心触摸动作：
#   aim_start   单指在发射台区按下 → 开始瞄准
#   aim_move    单指拖动 → 更新瞄准方向
#   aim_release 单指松开 → 发射
#   tap         轻点非发射台区域 → 激活 Option/按钮
#   pause       多指（≥3）或系统按键 → 暂停
# 键盘回退（便于桌面/headless 调试）：方向键/空格/回车 → 对应动作。
signal action(action_name: String, payload: Variant)

enum Action { AIM_START, AIM_MOVE, AIM_RELEASE, TAP, PAUSE }

const ACTION_NAMES := {
	Action.AIM_START: "aim_start",
	Action.AIM_MOVE: "aim_move",
	Action.AIM_RELEASE: "aim_release",
	Action.TAP: "tap",
	Action.PAUSE: "pause",
}

# 发射台区域占屏幕底部比例（仅此区域内的触摸视为瞄准操作）
const AIM_ZONE_BOTTOM_RATIO := 0.35

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.index >= 2:
				_emit(Action.PAUSE)
				return
			if _in_aim_zone(event.position):
				_emit(Action.AIM_START, event.position)
			else:
				_emit(Action.TAP, event.position)
		else:
			_emit(Action.AIM_RELEASE, event.position)
	elif event is InputEventScreenDrag:
		_emit(Action.AIM_MOVE, event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		# 键盘回退：空格/回车=发射，方向键=瞄准移动，Esc=暂停
		match event.keycode:
			KEY_SPACE, KEY_ENTER:
				_emit(Action.AIM_RELEASE, Vector2.ZERO)
			KEY_ESCAPE:
				_emit(Action.PAUSE)
			KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN:
				_emit(Action.AIM_MOVE, event.position)

func _in_aim_zone(pos: Vector2) -> bool:
	var rect := get_viewport().get_visible_rect()
	return pos.y >= rect.size.y * (1.0 - AIM_ZONE_BOTTOM_RATIO)

func _emit(a: Action, payload: Variant = null) -> void:
	action.emit(ACTION_NAMES[a], payload)

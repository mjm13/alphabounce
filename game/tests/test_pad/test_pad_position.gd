extends TestBase

const PAD_SCENE = preload("res://scenes/entities/Pad.tscn")

# AC-1：Pad 节点可实例化，位置固定于屏幕底部中央（x=W/2, y=H-60）
func _ready() -> void:
	var pad = PAD_SCENE.instantiate()
	add_child(pad)
	var rect := get_viewport().get_visible_rect()
	var expected := Vector2(rect.size.x * 0.5, rect.size.y - 60.0)
	var ok: bool = pad.position.is_equal_approx(expected)
	print_ac("R01", 1, ok)
	if get_tree().current_scene == self:
		get_tree().quit(1 if not ok else 0)

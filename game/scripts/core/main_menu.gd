extends Control

@onready var start_button = $StartButton
@onready var quit_button = $QuitButton

func _ready():
	# Debug 构建自动进入 DebugLauncher 真机验收入口；release 包不进入（见 R19）
	if OS.is_debug_build():
		# 延迟到 _ready 完成、节点树稳定后再切换，避免在节点添加阶段
		# 触发内部 remove_child 报 "Parent node is busy" ERROR
		get_tree().call_deferred("change_scene_to_file", "res://debug/debug_launcher.tscn")
		return
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/main/Game.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _input(event):
	if event.is_action_pressed("tap_pause"):
		get_tree().paused = not get_tree().paused

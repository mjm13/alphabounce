extends Node2D

func _ready():
	# 运行时再次确认全屏窗口模式（引擎初始化已由导出预设 command_line/extra_args="--fullscreen" 进 FULLSCREEN 隐藏导航栏；此处为兜底）
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	print("Alphabounce started")

func _process(_delta):
	pass

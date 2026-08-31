extends Node
class_name AudioManager

# [R12] 音频系统：架构 + 静音 stub。
# 原版 AlphaBounce 使用 BGM 与多种 SFX（击球/击中方块/敌人出现/关卡完成等）。
# 当前阶段提供完整 API（play_sfx / play_music / stop_music / set_mute），以 stub 形式静音，
# 后续 R16/R18 接入真实资源后可直接替换内部实现。
signal mute_changed(mute: bool)

var muted: bool = false

func play_sfx(name: String) -> void:
	# TODO [R16]：接入真实 SFX 资源；当前 stub 仅打印用于调试
	if not muted:
		print("AUDIO_SFX: %s" % name)

func play_music(name: String) -> void:
	# TODO [R16]：接入真实 BGM 资源；当前 stub 仅打印用于调试
	if not muted:
		print("AUDIO_MUSIC: %s" % name)

func stop_music() -> void:
	# TODO [R16]：停止 BGM
	pass

func set_mute(v: bool) -> void:
	muted = v
	# 同步 Godot AudioServer 总线静音（Master 总线索引 0）
	AudioServer.set_bus_mute(0, v)
	mute_changed.emit(v)

func is_muted() -> bool:
	return muted

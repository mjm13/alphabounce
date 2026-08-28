# AlphaBounce_M 需求验收标准

## 概述

本文档定义了 AlphaBounce_M 项目的验收标准和测试要求。

## 验收标准分类

### 1. 功能验收

| ID | 需求 | 验收标准 | 状态 |
|----|------|----------|------|
| F001 | 游戏核心逻辑 | 球体物理、方块消除、任务系统正常运行 | ⏳ |
| F002 | UI 系统 | 主菜单、游戏界面、设置界面正常显示 | ⏳ |
| F003 | 触摸控制 | 触摸响应延迟 < 100ms | ⏳ |

### 2. 性能验收

| ID | 需求 | 验收标准 | 状态 |
|----|------|----------|------|
| P001 | 帧率 | 稳定 60 FPS（高端设备） | ⏳ |
| P002 | 内存 | 运行时长 30 分钟内存增长 < 50MB | ⏳ |
| P003 | 启动时间 | 冷启动 < 3 秒 | ⏳ |

### 3. 兼容性验收

| ID | 需求 | 验收标准 | 状态 |
|----|------|----------|------|
| C001 | Android 版本 | 支持 Android 8.0+ (API 26+) | ⏳ |
| C002 | 设备适配 | 支持常见屏幕尺寸和分辨率 | ⏳ |
| C003 | 横竖屏 | 竖屏模式稳定运行 | ⏳ |

### 4. 集成测试验收

| ID | 需求 | 验收标准 | 状态 |
|----|------|----------|------|
| I001 | 模拟器测试 | 在 Android 15 模拟器上通过所有测试 | ✅ |
| I002 | 真机测试 - ADB 连接 | USB 调试模式正常连接，ADB 可识别设备 | ✅ |
| I003 | 真机测试 - 设备通信 | 可执行 shell 命令、截图、触摸输入 | ✅ |
| I004 | 真机测试 - 应用安装 | APK 可成功安装到真机 | ✅ |
| I005 | 真机测试 - 应用启动 | 应用可正常启动并显示主界面 | ⏳ |
| I006 | 自动化测试 | MCP 集成测试 5/5 通过 | ✅ |
| I007 | 截图验证 | 成功截取设备屏幕并保存 | ✅ |
| I008 | 触摸输入 | 成功模拟触摸和按键事件 | ✅ |

### 5. 代码质量验收

| ID | 需求 | 验收标准 | 状态 |
|----|------|----------|------|
| Q001 | 代码规范 | 符合 GDScript 风格指南 | ⏳ |
| Q002 | 注释覆盖 | 关键函数有注释说明 | ⏳ |
| Q003 | Git 提交 | 提交信息符合规范 | ⏳ |

## 真机测试验收流程

### 前置条件

1. 手机开启开发者选项和 USB 调试
2. 手机屏幕弹出"允许 USB 调试"时点击允许
3. 如设备未被识别，切换 USB 模式为"传输文件 (MTP)"

### 测试步骤

```powershell
# 1. 检查设备连接
adb devices

# 2. 验证设备信息
adb -s <设备序列号> shell getprop ro.product.model
adb -s <设备序列号> shell getprop ro.build.version.release

# 3. 安装 APK
adb -s <设备序列号> install -r <apk路径>

# 4. 验证安装
adb -s <设备序列号> shell pm list packages | Select-String <包名>

# 5. 启动应用
adb -s <设备序列号> shell am start -n <包名>/<Activity>

# 6. 截取屏幕
adb -s <设备序列号> shell screencap -p /sdcard/test.png
adb -s <设备序列号> pull /sdcard/test.png ./tests/screenshots/

# 7. 模拟触摸
adb -s <设备序列号> shell input tap 540 960
adb -s <设备序列号> shell input keyevent 4
```

### 验收标准

| 项目 | 标准 | 通过条件 |
|------|------|----------|
| 设备连接 | ADB 识别设备 | `adb devices` 显示 device 状态 |
| 设备通信 | 可执行 shell 命令 | 获取设备信息成功 |
| 截图功能 | 成功截图并拉取 | 截图文件存在且大小 > 0 |
| 触摸输入 | 模拟点击成功 | 无错误返回 |
| 应用安装 | APK 安装成功 | `pm list packages` 可见 |
| 应用启动 | 应用启动成功 | 前台应用为游戏 |

### 常见问题处理

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 设备显示 unauthorized | USB 调试未授权 | 在手机上点击"允许" |
| 安装失败 INSTALL_PARSE_FAILED | APK 未签名或签名错误 | 使用 Godot Editor 导出或 apksigner 重新签名 |
| 应用无法启动 | Activity 配置错误 | 检查 AndroidManifest.xml 中的 Activity 名称 |
| 设备不被识别 | USB 模式错误 | 切换 USB 模式为 MTP 或传输文件 |

## 测试命令

```powershell
# 运行 MCP 集成测试
python tests/mcp_integration_test.py

# 运行 Godot 单元测试
godot --path game --headless --scene tests/test_ball_physics.tscn

# 安装 APK 到设备
adb install -r game/bin/android_debug.apk

# 查看设备列表
adb devices
```

## 设备支持

| 设备类型 | 设备 ID | 状态 |
|----------|---------|------|
| 模拟器 | emulator-5554 | ✅ 已验证 |
| 真机 | 49PZY5AQR4ZPPBV4 (REDMI K80 Ultra) | ✅ ADB 连接已验证 |

## 验收流程

1. **Gate-1**: 切片实现完成，单文件/模块测试通过
2. **Gate-2**: 全量测试通过，性能达标
3. **Gate-3**: 归档完成，所有验收标准通过

---

最后更新：2026-08-28

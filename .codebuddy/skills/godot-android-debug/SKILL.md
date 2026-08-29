---
name: godot-android-debug
description: "Use when debugging the Godot Android game on a real device via MCP (android-debug adb-mcp for device ops + optional godot_mcp editor bridge) — build APK, install, launch, screenshot, read logcat, simulate touch. Covers local toolchain paths and known project.godot/export gotchas. Note: godot_mcp bridge is editor-side only, not in standalone APK."
version: "1.1.0"
---

# Godot Android 真机调试（MCP 闭环）

## When to Use

- 需要在 **Android 真机** 上验证 Godot 4 游戏（渲染、触摸、性能、GDScript 运行时报错）。
- 通过 MCP 驱动设备形成「改码 → 导出 → 安装 → 运行 → 截图/日志/触摸 → 反馈」闭环。
- 与 `godot-android-export` 互补：本技能聚焦**调试闭环**，导出配置见该技能。

## 真机实测记录（2026-08-28）

设备：`49PZY5AQR4ZPPBV4`（Xiaomi 25060RK16C），物理分辨率 1280×2772。

| 步骤 | 命令/操作 | 结果 |
|------|-----------|------|
| 构建 | `game/build_android.bat` | `EXIT_CODE=0`，产出 `bin/AlphaBounce_debug.apk`（28.5 MB） |
| 安装 | `adb -s 49PZY5AQR4ZPPBV4 install -r bin/AlphaBounce_debug.apk` | `Success` |
| 解析启动 Activity | `cmd package resolve-activity -c android.intent.category.LAUNCHER com.eternaltwin.alphabounce` | `com.godot.game.GodotAppLauncher` |
| 启动 | `am start -n com.eternaltwin.alphabounce/com.godot.game.GodotAppLauncher` | 应用前台启动 |
| 截图 | `adb shell screencap -p /sdcard/shot.png` + `pull` | 画面正常，显示 HUD（分数/生命/导弹） |
| 日志 | `adb logcat -s Godot:V *:S` | `OnGodotMainLoopStarted`，无 ERROR |
| 触摸 | `adb shell input tap 640 1386` | 命令成功下发；本次未触发可见交互，后续需按游戏状态机验证 |

> 本会话中 IDE 未加载 `android-debug` MCP，因此使用**等价的直连 adb** 完成闭环；MCP 可用时命令相同，只是由 server 自动调用。

## 环境（本机自带，无需全局安装）

| 工具 | 路径 |
|------|------|
| Godot 4.7.1（导出用 console 版） | `D:\Project\Self\alphabounce\tools\godot\Godot_v4.7.1-stable_win64_console.exe` |
| Godot 编辑器（GUI） | `D:\Project\Self\alphabounce\tools\godot\Godot_v4.7.1-stable_win64.exe` |
| JDK | `D:\Project\Self\alphabounce\tools\jdk` |
| Android SDK | `D:\Project\Self\alphabounce\tools\android-sdk` |
| adb | `D:\Project\Self\alphabounce\tools\android-sdk\platform-tools\adb.exe` |
| Android 导出模板 | `D:\Project\Self\alphabounce\tools\godot\templates\4.7.1.stable` |
| 项目根 | `D:\Project\Self\alphabounce\game` |

> **只用这一个 adb**，避免与系统 adb 版本不一致导致 `adb devices` 看不到设备。

## 真机前置条件（硬阻塞）

1. 手机开启 **开发者选项 → USB 调试**（部分国产 ROM 还需「允许通过 USB 安装应用 / 关闭 MIUI 优化」）。
2. 连接电脑后，在手机上**授权当前电脑的调试弹窗**。
3. 确认连接：`adb devices -l` 能看到序列号且状态为 `device`（非 `unauthorized`）。
   - 若显示 `unauthorized`：重拔插并点允许；若为空：检查线缆/USB 模式（选「文件传输/MTP」）。

## MCP 架构（两层）

本项目真机调试有两条 MCP 通道，可叠加使用：

1. **`android-debug`（adb-mcp）** — 在 `.codebuddy/mcp.json` 已注册，把 adb 能力（装包/启停/截图/模拟触摸/读 logcat/设备信息）暴露给 AI。
   ```json
   "android-debug": {
     "command": "npx", "args": ["-y", "adb-mcp"],
     "env": {
       "ANDROID_HOME": "D:\\Project\\Self\\alphabounce\\tools\\android-sdk",
       "ADB_PATH": "D:\\Project\\Self\\alphabounce\\tools\\android-sdk\\platform-tools\\adb.exe",
       "ANDROID_SERIAL": ""
     }
   }
   ```
   配置后**重启 IDE** 使 MCP 生效。多设备时把 `ANDROID_SERIAL` 填为具体序列号。

2. **`godot_mcp` 游戏内桥接**（编辑器侧 `127.0.0.1:6550` WebSocket）— 编辑器插件 `plugin.gd` 在**编辑器进程**中起 WebSocket 服务（`websocket_server.gd`）；`MCPGameBridge` 作为 autoload 打进游戏，但它**只在 `EngineDebugger.is_active()` 时激活**（见 `mcp_game_bridge.gd` 的 `_ready` 提前 return）。
   - **编辑器内调试**：F5 运行游戏后，直接连 `ws://127.0.0.1:6550`，桥接经 EngineDebugger 与游戏通信。
   - **真机深度调试**：必须从**编辑器「部署到设备并带调试器运行」**（Run on device / 远程调试），此时设备端游戏 `EngineDebugger` 连回编辑器，桥接自动生效——**不需要 `adb forward`**（WS 服务在编辑器侧，不在设备侧）。
   - **注意**：纯 `adb install` 安装的独立 APK 里，游戏内桥接处于休眠态（无 EditorDebugger）；这类场景请用 `android-debug` MCP 做设备级操作，godot_mcp 无法接管。

> MCP 与脚本二选一：优先 MCP；若 `android-debug` 未加载，回退到下方 adb 命令（效果等价）。

## 标准调试循环（AI 操作步骤）

### 1. 导出 debug APK（已验证可用）

项目 `project.godot` 当前需要以下修正才能导出（见「已知坑」）：
- `[input]` 段必须是 Godot 4 的 `Object(InputEventKey, ...)` 格式。
- 需开启 `rendering/textures/vram_compression/import_etc2_astc=true`。
- Godot 只识别 `export_presets.cfg`（项目里是 `.export_presets.cfg` 点文件，需复制为 `export_presets.cfg`）。
- 导出模板需挂到 `C:\Users\mjm13\AppData\Roaming\Godot\export-templates\4.7.1-stable`（注意是**连字符**目录名）。

> 项目当前**没有** `game/build_android.bat`（早期版本引用过，已不存在）。用下方手动命令导出（路径均已实测可用）。
> ⚠ **Godot 二进制**：本环境**只有** `tools/godot_std/Godot_v4.7.1-stable_win64.exe` 可运行（`tools/godot`、`tools/godot_official` 副本启动即 Access Violation，见 `AGENTS.md`「Dev environment tips」）。导出用这个二进制加 `--headless`。

```powershell
# 1) 建导出模板 junction（仅需一次；当前用户是 admin，不是 mjm13）
cmd /c 'mklink /J "C:\Users\admin\AppData\Roaming\Godot\export-templates\4.7.1-stable" "D:\Project\Self\alphabounce\tools\godot\templates\4.7.1.stable"'
# 2) Godot 只认 export_presets.cfg（不认 .export_presets.cfg）
if (-not (Test-Path "D:\Project\Self\alphabounce\game\export_presets.cfg")) {
  Copy-Item "D:\Project\Self\alphabounce\game\.export_presets.cfg" "D:\Project\Self\alphabounce\game\export_presets.cfg"
}
# 3) 导出
$env:ANDROID_HOME="D:\Project\Self\alphabounce\tools\android-sdk"
$env:ANDROID_SDK_ROOT="D:\Project\Self\alphabounce\tools\android-sdk"
$env:JAVA_HOME="D:\Project\Self\alphabounce\tools\jdk"
$env:PATH="$env:PATH;D:\Project\Self\alphabounce\tools\android-sdk\platform-tools;D:\Project\Self\alphabounce\tools\jdk\bin"
& "D:\Project\Self\alphabounce\tools\godot_std\Godot_v4.7.1-stable_win64.exe" --headless --path "D:\Project\Self\alphabounce\game" --export-debug "Android" "bin/AlphaBounce_debug.apk"
# 产物：D:\Project\Self\alphabounce\game\bin\AlphaBounce_debug.apk
```

> 导出时若报 `Could not find version of build tools that matches Target SDK, using 34.0.0` 属正常（自动选 build-tools 34）。`EXIT_CODE=0` 即成功。

> 导出时若报 `Could not find version of build tools that matches Target SDK, using 34.0.0` 属正常（自动选 build-tools 34）。`EXIT_CODE=0` 即成功。

### 2. 安装并启动

```bash
# 通过 MCP android-debug 工具，或等价 adb：
adb install -r D:\Project\Self\alphabounce\game\bin\AlphaBounce_debug.apk
# 启动（动态解析启动 Activity，避免记错包名/Activity）：
adb shell cmd package resolve-activity -c android.intent.category.LAUNCHER com.eternaltwin.alphabounce
adb shell am start -n com.eternaltwin.alphabounce/com.godot.game.GodotAppLauncher
```

- 国产 ROM 首次安装可能报 `INSTALL_FAILED_USER_RESTRICTED`：到开发者选项开启「允许通过 USB 安装」并手动确认弹窗。
- 包名见 `export_presets.cfg` 的 `package/unique_name`（当前 `com.eternaltwin.alphabounce`）。

### 3. 看画面（截图）

```bash
# 推荐：先写设备，再 pull 到本地（实测中 `adb exec-out ... > file` 会被拒绝重定向）
adb shell screencap -p /sdcard/shot.png
adb pull /sdcard/shot.png D:\Project\Self\alphabounce\game\screenshot.png
```
检查：是否灰屏 / 错位 / 卡登录界面（本项目若 `http_enabled=true` 且离线，可能停在登录界面——区分「登录阻塞」与「游戏 bug」）。

### 4. 读日志（定位 GDScript 报错）

```bash
adb logcat -s Godot:V *:S          # 只看 Godot 标签
adb logcat | findstr /i "Godot ERROR"   # 抓取错误
```
重点关注 `Godot` / `ERROR` / `SCRIPT ERROR` 关键字。

### 5. 测交互（模拟触摸）

```bash
adb shell input tap 400 300        # 点击（像素坐标基于设备真实分辨率）
adb shell input swipe 200 500 800 500   # 滑动
```
> 逻辑坐标需按设备分辨率换算（本项目视口 800×600，`stretch mode=viewport`）。

### 6. 游戏内 MCP 桥接（可选，深度调试）

`godot_mcp` 桥接只在「编辑器带调试器运行游戏」时可用（含从编辑器部署到真机并**保留调试器**）。WS 服务在**编辑器进程**的 `127.0.0.1:6550`，不在导出包里：

```bash
# 编辑器内运行游戏后，本机连：
ws://127.0.0.1:6550
# 编辑器→真机（保留调试器运行）时同样连此处，桥接经 EngineDebugger 转发到设备端游戏
```

> 不要对独立 APK 用 `adb forward tcp:6550 tcp:6550` 去连游戏内桥接——导出包内并没有监听 6550 的服务，该端口只在编辑器侧。真机独立 APK 的深度交互靠 `android-debug` MCP 的 `input tap/swipe` 完成。

### 7. 迭代
根据画面与日志回到第 1 步改码 → 重新导出 → 重装 → 验证，形成闭环。

## 真机验收闭环（per-requirement acceptance closure · 强制）

游戏/物理/交互/UI 类需求（R01–R18、BASE、R19 等）的 **Gate-2 必须走本闭环**，不得用 headless 单测冒充（硬门禁见 `42-verification-output.mdc` #11 与 `docs/requirements/execution-plan.md` §真机独立验收标准）。R19（DebugLauncher）已就绪：每个需求有 `debug/R0x_debug.tscn` 独立验收入口，进入后逐 AC 打印 `R0x_AC-n PASS/FAIL`，**不依赖任何未完成的上下游需求**。

**标准 6 步（可复跑）**

```bash
# 0 构建（见上节）+ 安装 + 启动
adb -s <SERIAL> install -r game/bin/AlphaBounce_debug.apk
adb shell am force-stop com.eternaltwin.alphabounce
adb logcat -c
adb shell am start -n com.eternaltwin.alphabounce/com.godot.game.GodotAppLauncher
# 1 等 DebugLauncher 出现（约 3–5s，Debug 构建自动进入）；用键盘码快速进需求，无需点屏幕
#    REQ_ITEMS 顺序：0=R19,1=R01,2=R02,3=R03,4=R04... 数字键 1-9,0 对应前 10 个
#    R02(idx=2) -> KEYCODE_3(10)；R03(idx=3) -> KEYCODE_4(11)
adb shell input keyevent 10   # -> R02
# adb shell input keyevent 11  # -> R03
# 2 抓取 AC 断言（须全部 PASS）。print() 走小写 `godot` 标签，勿用 -s Godot 漏掉
adb logcat -d | findstr /i "R0x_AC"
# 3 截图取证（先写设备再 pull，避免 exec-out 重定向被拒）
adb shell screencap -p /sdcard/R0x.png
adb pull /sdcard/R0x.png docs/evidence/R0x.png
# 4 日志门禁：零 Godot ERROR / SCRIPT ERROR（仅看含 godot 的 ERROR，过滤系统服务误报）
adb logcat -d | findstr /i "godot.*ERROR"
adb logcat -d | findstr /i "SCRIPT ERROR"
```

- **通过判定**：步骤 2 全部 AC PASS **且** 步骤 4 零 ERROR **且** 步骤 3 截图符合视觉预期。
- **证据落盘**：把 `docs/evidence/R0x.png` + logcat 片段 + 零 ERROR 结论写进该需求 shipped 文档「真机独立验收」小节，方可置 `Gate-2=已验收`、方可移入 `shipped`；否则状态回置 `已实现待验收` 并登记缺陷（禁止签字）。
- **`<SERIAL>`**：取 `adb devices -l` 首列（当前示例 `582ddb67`）。
- **常见串号**：若 DebugLauncher 未自动弹出，先 `am start` 后手动点 Debug 入口；`R03_debug.tscn` 内部实例化 `tests/test_ball_physics.tscn`，AC 由该测试场景打印。

## 已知坑（本项目实测）

| 问题 | 现象 | 解决 |
|------|------|------|
| `project.godot` 解析失败 | `Unexpected identifier 'InputEventKey'` | `[input]` 段改为 Godot 4 的 `Object(InputEventKey,"keycode":N,...)` 格式（不是 Godot3 的 `InputEventKey({...})`） |
| Android 导出被拒 | 要求 ETC2/ASTC 压缩 | `project.godot` 加 `rendering/textures/vram_compression/import_etc2_astc=true` |
| 找不到 Android 预设 | `--export-debug "Android"` 报 preset 不存在 | 把 `.export_presets.cfg` 复制为 `export_presets.cfg`（Godot 只认无点前缀名） |
| 导出模板缺失 | 报找不到 android_debug 模板 | 把 `tools/godot/templates/4.7.1.stable` 以 **junction** 挂到 `AppData\Roaming\Godot\export-templates\4.7.1-stable`（连字符目录名） |
| 导出找不到 SDK/Java | 报 signing/build-tools 错误 | 导出前设 `ANDROID_HOME`/`JAVA_HOME`/`PATH` 指向 `tools/android-sdk`、`tools/jdk` |
| adb 看不到设备 | `adb devices` 为空 | 仅用 `tools/android-sdk/platform-tools/adb.exe`；手机开 USB 调试并授权弹窗 |
| 联网登录阻塞 | 真机停在登录界面 | `http_enabled=true` 时原作需 EternalTwin 账号；离线调试需区分登录阻塞与游戏 bug |
| godot_mcp 桥接不生效 | 真机 `adb install` 的 APK 连不上 6550 / 收不到桥接 | `MCPGameBridge` 仅在 `EngineDebugger.is_active()` 激活，`godot_mcp` WS 服务跑在**编辑器**侧；独立 APK 用 `android-debug` MCP 即可，深度桥接需从编辑器带调试器部署到设备 |

| logcat 抓不到 AC 断言 | `adb logcat -s Godot:V *:S` 只匹配大写 `Godot` 引擎标签，漏掉 `print()` 输出的小写 `godot` 标签 | 用 `adb logcat -d \| findstr /i "R0x_AC"`（全量 dump + grep）；错误门禁用 `findstr /i "godot.*ERROR"` |
| 导出告警 Ball.tscn Parse Error / No project icon | 非致命；Ball.tscn 运行时可加载（R02/R03 真机 AC 均过），但缺 icon 与首行可疑应修 | Project Settings 设 Application→Config→Icon；核查 `scenes/entities/Ball.tscn` 首行是否被误改 |

## 验证清单

- [x] `adb devices -l` 显示设备且状态 `device`
- [x] `build_android.bat` 退出码 0，产出 `bin/AlphaBounce_debug.apk`
- [x] `adb install -r` 成功
- [x] `am start -n com.eternaltwin.alphabounce/com.godot.game.GodotAppLauncher` 后应用前台运行
- [x] 截图非灰屏、无错位，HUD 正常显示
- [x] `logcat -s Godot:V *:S` 无 `SCRIPT ERROR` / `ERROR`
- [ ] `input tap/swipe` 触发预期交互（adb 命令已下发；是否触发游戏响应取决于当前状态机的触摸区域）

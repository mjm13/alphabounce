# MCP 配置验证

## 已配置的 MCP Servers

### 1. mobile-mcp (Android 测试)
- **包名**: @mobilenext/mobile-mcp
- **用途**: 控制 Android 模拟器/真机
- **状态**: ✅ 已安装 (v1.0.2)
- **配置**:
  - ANDROID_HOME: D:\Project\Self\alphabounce\tools\android-sdk
  - ADB_PATH: D:\Project\Self\alphabounce\tools\android-sdk\platform-tools\adb.exe
  - DEFAULT_DEVICE: emulator-5554

### 2. local-file (本地文件操作)
- **包名**: @modelcontextprotocol/server-filesystem
- **用途**: 读写项目文件
- **状态**: ✅ 已安装
- **配置**:
  - 工作目录: D:\Project\Self\alphabounce

## 使用方式

### Cursor IDE 中启用 MCP
1. 打开 Cursor Settings (Ctrl+,)
2. 进入 Features > MCP
3. 确认以下服务器已启用:
   - [x] mobile-mcp
   - [x] local-file

### 测试命令

```powershell
# 检查设备连接
adb devices

# 截图
adb -s emulator-5554 shell screencap -p /sdcard/screenshot.png
adb -s emulator-5554 pull /sdcard/screenshot.png ./tests/screenshots/

# 启动应用
adb -s emulator-5554 shell am start -n com.eternaltwin.alphabounce/.GodotApp
```

### MCP 工具调用示例

```
# 触摸输入
mobile_mcp.tap(x=100, y=500)

# 截图验证
mobile_mcp.screenshot(path="./tests/screenshots/test.png")

# 读取日志
local_file.read(path="game/scripts/core/game.gd")
```

## 验证状态

- [x] mobile-mcp 已安装
- [x] 模拟器已启动 (emulator-5554)
- [x] ADB 连接正常
- [x] MCP 配置文件已更新

# AlphaBounce_M MCP 配置与使用指南

## 配置状态

| MCP Server | 状态 | 版本 | 用途 |
|-----------|------|------|------|
| mobile-mcp | ✅ 已配置 | @mobilenext/mobile-mcp@1.0.2 | Android 模拟器控制 |
| local-file | ✅ 已配置 | @modelcontextprotocol/server-filesystem | 项目文件读写 |

## 环境状态

- **模拟器**: emulator-5554 (Android 15, API 35)
- **ADB 连接**: ✅ 正常
- **设备型号**: Android SDK built for x86

## 可用工具

### mobile-mcp 工具

1. **触摸输入**
   ```
   mobile_mcp.tap(x=540, y=960)
   ```

2. **滑动操作**
   ```
   mobile_mcp.swipe(x1=540, y1=960, x2=540, y2=480)
   ```

3. **按键事件**
   ```
   mobile_mcp.keyevent("BACK")
   mobile_mcp.keyevent("HOME")
   mobile_mcp.keyevent("MENU")
   ```

4. **截图**
   ```
   mobile_mcp.screenshot(path="./tests/screenshots/test.png")
   ```

5. **文本输入**
   ```
   mobile_mcp.input_text("Hello World")
   ```

### local-file 工具

1. **读取文件**
   ```
   read_file(path="game/scripts/core/game.gd")
   ```

2. **写入文件**
   ```
   write_file(path="tests/result.txt", content="test passed")
   ```

3. **列出目录**
   ```
   list_directory(path="game/scenes")
   ```

## 使用示例

### 示例 1: 截图验证
```
请在模拟器上截图并保存到 tests/screenshots/
```

### 示例 2: 触摸测试
```
模拟点击屏幕中心位置 (540, 960)
```

### 示例 3: 读取代码
```
读取 game/scripts/entities/ball.gd 的内容
```

### 示例 4: 运行测试
```
运行 tests/mcp_integration_test.py
```

## 测试命令

```powershell
# 运行 MCP 集成测试
python tests/mcp_integration_test.py

# 运行 Godot 单元测试
"D:\Project\Self\alphabounce\tools\godot\Godot_v4.7.1-stable_win64.exe" --path game --headless --scene tests/test_ball_physics.tscn

# ADB 命令
adb -s emulator-5554 shell screencap -p /sdcard/test.png
adb -s emulator-5554 pull /sdcard/test.png ./tests/screenshots/
```

## 注意事项

1. 模拟器需要保持运行状态
2. 首次使用需要确认 ADB 授权
3. 截图路径需要手动创建目录


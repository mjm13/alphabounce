# USB 设备连接指南

## 当前状态

| 设备 | 类型 | 状态 | 说明 |
|------|------|------|------|
| emulator-5554 | 模拟器 | ✅ 正常 | Android 15, API 35 |
| REDMI K80 Ultra | USB 真机 | ⚠️ 待检测 | 序列号：49PZY5AQR4ZPPBV4 |

## MCP 配置

已配置 `adb-mcp` 服务器，支持自动检测设备：

```json
{
  "mcpServers": {
    "android-debug": {
      "command": "npx",
      "args": ["-y", "adb-mcp"],
      "env": {
        "ANDROID_HOME": "D:\\Project\\Self\\alphabounce\\tools\\android-sdk",
        "ADB_PATH": "D:\\Project\\Self\\alphabounce\\tools\\android-sdk\\platform-tools\\adb.exe",
        "ANDROID_SERIAL": ""
      }
    },
    "local-file": {
      "command": "node",
      "args": [
        "D:\\Project\\npm_Repository\\npm_global\\node_modules\\@modelcontextprotocol\\server-filesystem\\dist\\index.js",
        "D:\\Project\\Self\\alphabounce"
      ]
    }
  }
}
```

## USB 设备诊断

### 设备识别状态

```
设备 ID: USB\VID_2717&PID_FF48\49PZY5AQR4ZPPBV4
状态: Unknown
类: USBDevice, WPD
```

### 可能原因

1. **缺少 ADB 驱动** - 设备处于 WPD（Windows Portable Devices）模式
2. **USB 配置错误** - 手机设置为"充电"模式而非"传输文件"
3. **未授权 USB 调试** - 手机屏幕未点击"允许"

## 解决方案

### 方案 1：切换 USB 模式（推荐）

1. 在手机上：设置 → 开发者选项
2. 找到"USB 配置"或"选择 USB 模式"
3. 选择"传输文件 (MTP)"或"传输照片 (PTP)"
4. 重新插拔 USB 线缆

### 方案 2：授权 USB 调试

1. 查看手机屏幕是否有"允许 USB 调试"弹窗
2. 如果有，点击"允许"
3. 如果没有，尝试：
   - 断开 USB 连接
   - 重新连接
   - 查看是否弹出授权请求

### 方案 3：更换 USB 端口/线缆

1. 使用原装 USB 线缆
2. 尝试 USB 2.0 端口（黑色接口）
3. 避免使用 USB Hub

### 方案 4：重启设备

```powershell
# 重启 ADB 服务
adb kill-server
adb start-server

# 重新插拔 USB
```

## 使用 adb-mcp

adb-mcp 支持自动检测设备，无需手动指定设备 ID：

```python
# 测试脚本会自动选择第一个可用设备
python tests/mcp_integration_test.py

# 或指定设备
python tests/mcp_integration_test.py emulator-5554
python tests/mcp_integration_test.py 49PZY5AQR4ZPPBV4
```

## DSH 使用方式

在对话中直接使用自然语言：

```
"在设备上截图并保存"
"点击屏幕中心位置"
"读取 game/scripts/core/game.gd 的内容"
"运行集成测试"
"模拟触摸输入测试球体物理"
```

## 故障排除

| 问题 | 可能原因 | 解决方法 |
|------|----------|----------|
| 设备显示 "unauthorized" | USB 调试未授权 | 在手机上点击"允许" |
| 设备显示 "no permissions" | 权限不足 | 检查驱动安装 |
| 设备不出现 | USB 连接问题 | 更换线缆/端口 |
| 驱动状态 Unknown | 缺少驱动 | 切换 USB 模式为 MTP |

## 参考项目对比

参考项目 `D:\Project\Self\alphabounce_agents` 使用相同配置：
- ADB 版本：1.0.41 (37.0.1-15733141)
- MCP 包：adb-mcp@0.1.1
- 配置路径：`.mcp.json`


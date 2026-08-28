# USB 设备连接指南

## 当前状态

| 设备 | 类型 | 状态 | 说明 |
|------|------|------|------|
| emulator-5554 | 模拟器 | ✅ 正常 | Android 15, API 35 |
| REDMI K80 Ultra | USB 真机 | ⚠️ 驱动异常 | USB 状态 Unknown |

## 问题诊断

**现象**：
- 设备被系统识别（`REDMI K80 Ultra`）
- USB 设备类：`USBDevice`, `WPD`
- ADB 无法识别设备

**原因**：
- 缺少 Xiaomi/Redmi 专用 USB 驱动
- 设备处于"Unknown"状态
- ADB 驱动未正确安装

## 解决方案

### 方案 1：授权 USB 调试（推荐优先尝试）

1. 检查手机屏幕是否有弹出框请求"允许 USB 调试"
2. 如果有，点击"允许"
3. 如果没有，尝试：
   - 断开 USB 连接
   - 重新连接
   - 查看是否弹出授权请求

### 方案 2：更换 USB 配置

1. 在手机上：设置 → 开发者选项
2. 找到"USB 配置"
3. 选择"传输文件 (MTP)"或"传输照片 (PTP)"
4. 重新连接 USB

### 方案 3：更换 USB 端口/线缆

1. 使用原装 USB 线缆
2. 尝试 USB 2.0 端口（黑色接口，非蓝色）
3. 避免使用 USB Hub

### 方案 4：安装 Xiaomi USB 驱动

```powershell
# 方法 1: 使用小米官方工具
# 下载：https://www.mi.com/download/
# 安装 Mi Assistant 或 Mi PC Suite

# 方法 2: 手动安装 ADB 驱动
# 1. 打开设备管理器
# 2. 找到"未知设备"或"ADB Interface"
# 3. 右键 → 更新驱动 → 浏览我的电脑
# 4. 选择：D:\Project\Self\alphabounce\tools\android-sdk\extras\google\usb_driver
```

### 方案 5：网络调试模式（备用）

如果 USB 无法解决，可使用网络调试：

```powershell
# 1. 在手机上开启无线调试（Android 11+）
#    设置 → 开发者选项 → 无线调试

# 2. 获取设备 IP 地址
#    设置 → 关于手机 → 状态信息 → IP 地址

# 3. 连接设备
adb connect <设备 IP>:5555
```

## 验证命令

```powershell
# 检查设备连接
adb devices

# 检查设备详情
adb -s <设备 ID> shell getprop ro.product.model

# 截图测试
adb -s <设备 ID> shell screencap -p /sdcard/test.png
adb -s <设备 ID> pull /sdcard/test.png ./tests/screenshots/

# 查看日志
adb -s <设备 ID> logcat -s Godot
```

## 临时方案

在 USB 驱动问题解决前，可继续使用模拟器进行测试：

```powershell
# 使用模拟器
adb -s emulator-5554 devices

# 运行测试
python tests/mcp_integration_test.py
```

## 故障排除

| 问题 | 可能原因 | 解决方法 |
|------|----------|----------|
| 设备显示 "unauthorized" | USB 调试未授权 | 在手机上点击"允许" |
| 设备显示 "no permissions" | 权限不足 | 检查 udev 规则（Linux）或驱动（Windows） |
| 设备不出现 | USB 连接问题 | 更换线缆/端口 |
| 驱动状态 Unknown | 缺少驱动 | 安装 Xiaomi USB 驱动 |

## 参考链接

- [Android USB 驱动安装指南](https://developer.android.com/tools/devices)
- [小米 USB 驱动下载](https://www.mi.com/download/)
- [ADB 调试指南](https://developer.android.com/tools/adb)

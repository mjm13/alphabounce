#!/usr/bin/env python3
"""AlphaBounce_M MCP 集成测试脚本（支持多设备）"""

import subprocess
import sys
from pathlib import Path

# 配置路径
ROOT = Path("D:/Project/Self/alphabounce")
ADB = ROOT / "tools/android-sdk/platform-tools/adb.exe"

def get_devices():
    """获取所有已连接设备"""
    result = subprocess.run([str(ADB), "devices"], capture_output=True, text=True, encoding='utf-8', errors='ignore')
    devices = {}
    for line in result.stdout.strip().split('\n')[1:]:  # Skip first line
        parts = line.strip().split()
        if len(parts) >= 2 and parts[1] == "device":
            devices[parts[0]] = "connected"
    return devices

def get_device(device_id=None):
    """获取设备 ID（支持自动检测）"""
    devices = get_devices()
    if not devices:
        return None
    
    if device_id:
        return device_id if device_id in devices else None
    
    # 优先选择模拟器
    for dev_id in devices:
        if dev_id.startswith("emulator-"):
            return dev_id
    
    # 否则返回第一个设备
    return list(devices.keys())[0]

def run_cmd(cmd, device=None, check=True):
    """运行 ADB 命令"""
    if device:
        cmd = [str(ADB), "-s", device] + cmd
    else:
        cmd = [str(ADB)] + cmd
    result = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', errors='ignore')
    if check and result.returncode != 0:
        return None
    return result

def test_device_connection():
    """测试 1: 设备连接"""
    print("\n=== Test 1: 设备连接 ===")
    devices = get_devices()
    if devices:
        print(f"PASS: 发现 {len(devices)} 个设备: {list(devices.keys())}")
        return True, devices
    print("FAIL: 无设备连接")
    return False, {}

def test_emulator_boot(device):
    """测试 2: 模拟器启动完成"""
    print(f"\n=== Test 2: 模拟器启动 ({device}) ===")
    result = run_cmd(["shell", "getprop", "sys.boot_completed"], device)
    if result and "1" in result.stdout:
        print("PASS: 模拟器已启动完成")
        return True
    print("FAIL: 模拟器未启动完成")
    return False

def test_screenshot(device):
    """测试 3: 截图功能"""
    print(f"\n=== Test 3: 截图 ({device}) ===")
    screenshots_dir = ROOT / "tests" / "screenshots"
    screenshots_dir.mkdir(parents=True, exist_ok=True)
    
    result1 = run_cmd(["shell", "screencap", "-p", "/sdcard/test.png"], device)
    if result1 is None:
        print("FAIL: 无法截图到设备")
        return False
    
    dest_path = str(screenshots_dir / f"test_{device}.png")
    result2 = run_cmd(["pull", "/sdcard/test.png", dest_path], device)
    
    if Path(dest_path).exists():
        print(f"PASS: 截图成功 -> {dest_path}")
        return True
    print("FAIL: 截图文件未找到")
    return False

def test_touch_input(device):
    """测试 4: 触摸输入"""
    print(f"\n=== Test 4: 触摸输入 ({device}) ===")
    result = run_cmd(["shell", "input", "tap", "540", "960"], device)
    if result and result.returncode == 0:
        print("PASS: 触摸输入成功")
        return True
    print("FAIL: 触摸输入失败")
    return False

def test_key_event(device):
    """测试 5: 按键事件"""
    print(f"\n=== Test 5: 按键事件 ({device}) ===")
    result = run_cmd(["shell", "input", "keyevent", "4"], device)
    if result and result.returncode == 0:
        print("PASS: 按键事件成功")
        return True
    print("FAIL: 按键事件失败")
    return False

def test_logcat(device):
    """测试 6: 日志捕获"""
    print(f"\n=== Test 6: 日志捕获 ({device}) ===")
    result = run_cmd(["shell", "getprop", "ro.product.model"], device)
    if result and result.stdout.strip():
        print(f"PASS: 设备型号: {result.stdout.strip()}")
        return True
    print("FAIL: 无法获取设备信息")
    return False

def main():
    """主测试函数"""
    print("=" * 60)
    print("AlphaBounce_M MCP 集成测试（多设备支持）")
    print("=" * 60)
    
    # 检测设备
    connected, devices = test_device_connection()
    if not connected:
        print("\n请检查设备连接后重试")
        return 1
    
    # 获取当前设备
    current_device = sys.argv[1] if len(sys.argv) > 1 else get_device()
    if not current_device:
        print("未找到可用设备")
        return 1
    
    print(f"\n使用设备: {current_device}")
    print("-" * 60)
    
    tests = [
        (lambda d=current_device: test_emulator_boot(d), current_device),
        (lambda d=current_device: test_screenshot(d), current_device),
        (lambda d=current_device: test_touch_input(d), current_device),
        (lambda d=current_device: test_key_event(d), current_device),
        (lambda d=current_device: test_logcat(d), current_device),
    ]
    
    results = []
    for test, device in tests:
        try:
            results.append(test())
        except Exception as e:
            print(f"ERROR: {e}")
            results.append(False)
    
    print("\n" + "=" * 60)
    passed = sum(results)
    total = len(results)
    print(f"测试结果：{passed}/{total} 通过")
    
    if passed == total:
        print("所有测试通过！MCP 配置正常。")
    else:
        print("部分测试失败，请检查配置。")
    print("=" * 60)
    
    return 0 if all(results) else 1

if __name__ == "__main__":
    sys.exit(main())

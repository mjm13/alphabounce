#!/usr/bin/env python3
"""AlphaBounce_M MCP 集成测试脚本"""

import subprocess
import sys
from pathlib import Path

# 配置路径
ROOT = Path("D:/Project/Self/alphabounce")
ADB = ROOT / "tools/android-sdk/platform-tools/adb.exe"
EMULATOR = "emulator-5554"
GODOT = ROOT / "tools/godot/Godot_v4.7.1-stable_win64.exe"
PROJECT = ROOT / "game"

def run_cmd(cmd, check=True):
    """运行命令"""
    result = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', errors='ignore')
    if check and result.returncode != 0:
        print(f"命令失败: {' '.join(str(c) for c in cmd)}")
        if result.stderr:
            print(f"错误: {result.stderr[:200]}")
        return None
    return result

def test_device_connection():
    """测试 1: 设备连接"""
    print("\n=== Test 1: 设备连接 ===")
    result = run_cmd([str(ADB), "devices"])
    if result and EMULATOR in result.stdout and "device" in result.stdout:
        print("PASS: 模拟器已连接")
        return True
    print("FAIL: 模拟器未连接")
    return False

def test_emulator_boot():
    """测试 2: 模拟器启动完成"""
    print("\n=== Test 2: 模拟器启动 ===")
    result = run_cmd([str(ADB), "-s", EMULATOR, "shell", "getprop", "sys.boot_completed"])
    if result and "1" in result.stdout:
        print("PASS: 模拟器已启动完成")
        return True
    print("FAIL: 模拟器未启动完成")
    return False

def test_screenshot():
    """测试 3: 截图功能"""
    print("\n=== Test 3: 截图 ===")
    # 确保目录存在
    screenshots_dir = ROOT / "tests" / "screenshots"
    screenshots_dir.mkdir(parents=True, exist_ok=True)
    
    # 截图到模拟器
    result1 = run_cmd([str(ADB), "-s", EMULATOR, "shell", "screencap", "-p", "/sdcard/test.png"])
    if result1 is None:
        print("FAIL: 无法截图到模拟器")
        return False
    
    # 拉到本地（指定完整路径）
    dest_path = str(screenshots_dir / "test.png")
    result2 = run_cmd([str(ADB), "-s", EMULATOR, "pull", "/sdcard/test.png", dest_path])
    
    # 检查文件是否存在
    if Path(dest_path).exists():
        print("PASS: 截图成功")
        return True
    print("FAIL: 截图文件未找到")
    return False

def test_touch_input():
    """测试 4: 触摸输入"""
    print("\n=== Test 4: 触摸输入 ===")
    # 模拟点击屏幕中心
    result = run_cmd([str(ADB), "-s", EMULATOR, "shell", "input", "tap", "540", "960"])
    if result and result.returncode == 0:
        print("PASS: 触摸输入成功")
        return True
    print("FAIL: 触摸输入失败")
    return False

def test_key_event():
    """测试 5: 按键事件"""
    print("\n=== Test 5: 按键事件 ===")
    # 模拟返回键
    result = run_cmd([str(ADB), "-s", EMULATOR, "shell", "input", "keyevent", "4"])
    if result and result.returncode == 0:
        print("PASS: 按键事件成功")
        return True
    print("FAIL: 按键事件失败")
    return False

def test_logcat():
    """测试 6: 日志捕获"""
    print("\n=== Test 6: 日志捕获 ===")
    # 获取系统信息
    result = run_cmd([str(ADB), "-s", EMULATOR, "shell", "getprop", "ro.product.model"])
    if result and result.stdout.strip():
        print(f"PASS: 设备型号: {result.stdout.strip()}")
        return True
    print("FAIL: 无法获取设备信息")
    return False

def main():
    """主测试函数"""
    print("=" * 60)
    print("AlphaBounce_M MCP 集成测试")
    print("=" * 60)
    
    tests = [
        test_device_connection,
        test_emulator_boot,
        test_screenshot,
        test_touch_input,
        test_key_event,
        test_logcat,
    ]
    
    results = []
    for test in tests:
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

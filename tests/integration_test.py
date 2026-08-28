#!/usr/bin/env python3
"""AlphaBounce_M Android 集成测试"""

import subprocess
import sys
from pathlib import Path

ADB = Path(r"D:\Project\Self\alphabounce\tools\android-sdk\platform-tools\adb.exe")
DEVICE = "emulator-5554"
PACKAGE = "com.eternaltwin.alphabounce"

def run_cmd(cmd):
    """运行 ADB 命令"""
    result = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', errors='ignore')
    return result.returncode, result.stdout, result.stderr

def test_device_connected():
    """测试设备连接"""
    print("\n=== Test 1: 设备连接 ===")
    code, stdout, stderr = run_cmd([str(ADB), "-s", DEVICE, "devices"])
    if DEVICE in stdout and "device" in stdout:
        print("PASS: 设备已连接")
        return True
    else:
        print("FAIL: 设备未连接")
        return False

def test_app_installed():
    """测试应用安装"""
    print("\n=== Test 2: 应用安装 ===")
    code, stdout, stderr = run_cmd([str(ADB), "-s", DEVICE, "shell", "pm", "list", "packages"])
    if PACKAGE in stdout:
        print("PASS: 应用已安装")
        return True
    else:
        print("FAIL: 应用未安装")
        return False

def test_app_launch():
    """测试应用启动"""
    print("\n=== Test 3: 应用启动 ===")
    code, stdout, stderr = run_cmd([
        str(ADB), "-s", DEVICE, "shell", "am", "start",
        "-n", f"{PACKAGE}/.GodotApp"
    ])
    if "Starting" in stdout or code == 0:
        print("PASS: 应用启动成功")
        return True
    else:
        print("FAIL: 应用启动失败")
        return False

def test_screenshot():
    """测试截图"""
    print("\n=== Test 4: 截图 ===")
    # 截图到模拟器
    code, stdout, stderr = run_cmd([
        str(ADB), "-s", DEVICE, "shell", "screencap", "-p", "/sdcard/test.png"
    ])
    if code == 0:
        # 拉到本地
        code2, _, _ = run_cmd([
            str(ADB), "-s", DEVICE, "pull", "/sdcard/test.png", "tests/screenshots/"
        ])
        if code2 == 0:
            print("PASS: 截图成功")
            return True
    print("FAIL: 截图失败")
    return False

def main():
    """主测试函数"""
    print("=" * 60)
    print("AlphaBounce_M Android 集成测试")
    print("=" * 60)
    
    tests = [
        test_device_connected,
        test_app_installed,
        test_app_launch,
        test_screenshot,
    ]
    
    results = []
    for test in tests:
        try:
            results.append(test())
        except Exception as e:
            print(f"ERROR: {e}")
            results.append(False)
    
    print("\n" + "=" * 60)
    print(f"测试结果：{sum(results)}/{len(results)} 通过")
    print("=" * 60)
    
    return 0 if all(results) else 1

if __name__ == "__main__":
    sys.exit(main())

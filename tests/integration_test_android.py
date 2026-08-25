#!/usr/bin/env python3
"""
AlphaBounce_M Android 集成测试脚本
使用 Android 模拟器进行集成测试
"""

import subprocess
import sys
import time
from pathlib import Path

# 路径配置
ROOT = Path("D:/Project/Self/alphabounce")
GODOT = ROOT / "tools/godot/Godot_v4.7.1-stable_win64.exe"
ADB = ROOT / "tools/android-sdk/platform-tools/adb.exe"
EMULATOR = ROOT / "tools/android-sdk/emulator/emulator.exe"
PROJECT = ROOT / "game"
AVD_NAME = "alphabounce_test"
OUTPUT_DIR = ROOT / "bin"

def run_cmd(cmd, check=True, capture=True):
    """运行命令并返回结果"""
    print(f">>> {' '.join(str(c) for c in cmd)}")
    result = subprocess.run(cmd, capture_output=capture, text=True, encoding='utf-8', errors='ignore')
    if result.stdout:
        print(result.stdout)
    if result.stderr and capture:
        print(result.stderr, file=sys.stderr)
    if check and result.returncode != 0:
        print(f"命令失败，返回码：{result.returncode}")
        return None
    return result

def start_emulator():
    """启动 Android 模拟器"""
    print("\n=== 启动 Android 模拟器 ===")
    
    # 检查模拟器是否已运行
    result = run_cmd([str(ADB), "devices"])
    if result and "emulator-5554" in result.stdout:
        print("模拟器已在运行")
        return True
    
    # 启动模拟器
    cmd = [
        str(EMULATOR),
        "-avd", AVD_NAME,
        "-no-window",
        "-gpu", "host",
        "-no-audio"
    ]
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    # 等待模拟器启动
    print("等待模拟器启动...")
    for i in range(60):
        time.sleep(1)
        result = run_cmd([str(ADB), "devices"], check=False, capture=True)
        if result and "emulator-5554" in result.stdout:
            print("模拟器启动成功！")
            return True
        print(f"等待中... ({i+1}/60)")
    
    print("模拟器启动超时")
    process.kill()
    return False

def export_apk():
    """导出 Android APK"""
    print("\n=== 导出 Android APK ===")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    apk_path = OUTPUT_DIR / "android_debug.apk"
    
    cmd = [
        str(GODOT),
        "--path", str(PROJECT),
        "--headless",
        "--export-debug", "Android",
        str(apk_path)
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', errors='ignore')
    print(result.stdout)
    if result.stderr:
        print(result.stderr, file=sys.stderr)
    
    if apk_path.exists():
        size_mb = apk_path.stat().st_size / 1024 / 1024
        print(f"APK 导出成功：{apk_path} ({size_mb:.2f} MB)")
        return True
    else:
        print("APK 导出失败")
        return False

def install_apk(device="emulator-5554"):
    """安装 APK 到设备"""
    print("\n=== 安装 APK 到设备 ===")
    
    apk_path = OUTPUT_DIR / "android_debug.apk"
    if not apk_path.exists():
        print("APK 文件不存在")
        return False
    
    cmd = [str(ADB), "-s", device, "install", "-r", str(apk_path)]
    result = run_cmd(cmd)
    
    if result and "Success" in result.stdout:
        print("APK 安装成功")
        return True
    else:
        print("APK 安装失败")
        return False

def run_tests(device="emulator-5554"):
    """运行集成测试"""
    print("\n=== 运行集成测试 ===")
    
    tests = [
        ("启动游戏", ["shell", "am", "start", "-n", "com.eternaltwin.alphabounce/.GodotApp"]),
        ("等待启动", ["shell", "sleep", "5"]),
        ("截图验证", ["shell", "screencap", "-p", "/sdcard/test_start.png"]),
        ("拉取截图", ["pull", "/sdcard/test_start.png", str(OUTPUT_DIR / "screenshots")]),
    ]
    
    results = {}
    for test_name, test_cmd in tests:
        cmd = [str(ADB), "-s", device] + test_cmd
        result = run_cmd(cmd, check=False)
        results[test_name] = result.returncode == 0
        status = "✓ 通过" if results[test_name] else "✗ 失败"
        print(f"{test_name}: {status}")
    
    return all(results.values())

def stop_emulator():
    """停止模拟器"""
    print("\n=== 停止模拟器 ===")
    run_cmd([str(ADB), "emu", "kill"], check=False)

def main():
    """主函数"""
    print("=" * 60)
    print("AlphaBounce_M Android 集成测试")
    print("=" * 60)
    
    try:
        # 1. 启动模拟器
        if not start_emulator():
            print("模拟器启动失败")
            return 1
        
        # 2. 导出 APK
        if not export_apk():
            print("APK 导出失败")
            return 1
        
        # 3. 安装 APK
        if not install_apk():
            print("APK 安装失败")
            return 1
        
        # 4. 运行测试
        if not run_tests():
            print("部分测试失败")
            return 1
        
        print("\n" + "=" * 60)
        print("所有测试通过！")
        print("=" * 60)
        return 0
        
    finally:
        # 可选：停止模拟器
        pass
        # stop_emulator()

if __name__ == "__main__":
    sys.exit(main())

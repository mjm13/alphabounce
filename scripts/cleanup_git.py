#!/usr/bin/env python3
"""清理 Git 仓库中的大文件"""

import subprocess
import sys
from pathlib import Path

def run_cmd(cmd):
    """运行命令"""
    result = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', errors='ignore')
    return result.returncode, result.stdout, result.stderr

def main():
    """主函数"""
    print("=" * 60)
    print("Git 仓库清理工具")
    print("=" * 60)
    
    # 检查当前大小
    print("\n1. 检查当前 Git 仓库大小...")
    returncode, stdout, stderr = run_cmd(["git", "count-objects", "-vH"])
    print(stdout)
    
    # 更新 .gitignore
    print("\n2. 确保 .gitignore 包含以下内容...")
    gitignore = Path(".gitignore")
    if gitignore.exists():
        content = gitignore.read_text(encoding='utf-8')
        lines_to_add = [
            "\n# 大文件类型",
            "*.apk",
            "*.aab", 
            "*.exe",
            "*.zip",
            "*.7z",
            "*.dmg",
        ]
        for line in lines_to_add:
            if line not in content:
                content += line + "\n"
        gitignore.write_text(content, encoding='utf-8')
        print("✓ .gitignore 已更新")
    
    # 从索引中移除大文件
    print("\n3. 从 Git 索引中移除大文件...")
    large_patterns = ["*.apk", "*.aab", "*.exe", "*.zip", "*.7z", "tools/"]
    for pattern in large_patterns:
        returncode, stdout, stderr = run_cmd(["git", "rm", "-r", "--cached", pattern])
        if returncode == 0:
            print(f"✓ 已移除: {pattern}")
    
    # 运行垃圾回收
    print("\n4. 运行垃圾回收...")
    returncode, stdout, stderr = run_cmd(["git", "gc", "--aggressive", "--prune=now"])
    print("✓ 垃圾回收完成")
    
    # 检查清理后大小
    print("\n5. 检查清理后大小...")
    returncode, stdout, stderr = run_cmd(["git", "count-objects", "-vH"])
    print(stdout)
    
    print("\n" + "=" * 60)
    print("清理完成！")
    print("=" * 60)
    print("\n下一步:")
    print("1. 检查变更: git status")
    print("2. 提交变更: git commit -m 'chore: clean up large files'")
    print("3. 推送变更: git push")

if __name__ == "__main__":
    main()

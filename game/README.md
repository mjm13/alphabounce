# AlphaBounce Godot Project

这是 AlphaBounce 游戏的 Godot 4.7.1 实现版本，源自 Haxe/Pixi.js 原始项目。

## 项目结构

```
game/
├── project.godot          # Godot 项目配置
├── scenes/               # 场景文件
│   ├── main/            # 主菜单、加载画面
│   │   ├── Main.tscn    # 主菜单场景
│   │   └── Game.tscn    # 游戏主场景
│   ├── levels/          # 关卡场景（待创建）
│   ├── ui/              # UI 场景（待创建）
│   └── entities/        # 实体场景
│       ├── Ball.tscn    # 球体
│       └── Block.tscn   # 方块
├── scripts/             # GDScript 脚本
│   ├── core/            # 核心系统
│   │   ├── main_menu.gd # 主菜单逻辑
│   │   └── game.gd      # 游戏主逻辑
│   ├── entities/        # 实体逻辑
│   │   ├── ball.gd      # 球体物理
│   │   └── block.gd     # 方块逻辑
│   ├── ui/              # UI 逻辑（待创建）
│   └── systems/         # 游戏系统（待创建）
└── resouces/            # 资源文件
    ├── textures/        # 图片（待添加）
    ├── audio/           # 音频（待添加）
    └── fonts/           # 字体（待添加）
```

## 快速开始

1. 用 Godot 4.7.1 打开 `game/` 目录
2. 等待导入完成
3. 按 F5 运行主场景

## 构建 Android APK

### 前置条件
- Godot 4.7.1（含 Android 导出模板）
- Android SDK（位于 `tools/android-sdk/`）
- JDK 17（位于 `tools/jdk/jdk17/`）

### 在 Godot Editor 中导出
1. 菜单栏: Project → Export
2. 点击 "Add..." 添加 Android 导出预设
3. 配置 Android SDK 路径和 JDK 路径
4. 点击 "Export APK" 或 "Export AAB"

### 命令行导出

```bash
# Debug APK
"D:\Project\Self\alphabounce\tools\godot\Godot_v4.7.1-stable_win64.exe" --path game --export-debug "Android"

# Release AAB
"D:\Project\Self\alphabounce\tools\godot\Godot_v4.7.1-stable_win64.exe" --path game --export-release "Android"
```

### 安装到设备

```bash
adb install -r bin/android_debug.apk
```

## 项目配置

- **屏幕尺寸**: 800x600 视口
- **拉伸模式**: viewport（保持宽高比）
- **触摸输入**: 已启用
- **目标 SDK**: Android 33+
- **最小 SDK**: Android 21

## 触摸控制

| 操作 | 按键 |
|------|------|
| 左移 | 左箭头 / 触摸左侧 |
| 右移 | 右箭头 / 触摸右侧 |
| 发射 | 空格 / 触摸中心 |
| 暂停 | P / 触摸暂停按钮 |

## 开发说明

- 所有脚本遵循 GDScript 规范
- 触摸控制是主要输入方式
- 物理系统使用 Godot 内置 Physics2D
- 资源路径使用 `res://` 前缀

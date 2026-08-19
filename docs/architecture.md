# 架构与栈真相源（Alphabounce 安卓复刻）

> 本文件是「栈真相源」：技术栈摘要须与 `README.md`、`AGENTS.md` 保持一致；
> Gate-3 栈变化时须同步本文件后再开启下一需求。

## compiled_truth

- 引擎/语言：Godot 4.7.1（GDScript，非 C#/Mono）
- 目标平台：Android（导出 debug/release APK，minSdk 24 / targetSdk 34）
- 架构形态：纯单机、无后端、无数据库；资源（精灵）直接导入 Godot，关卡数据驱动
- 关键模块：
  - P1 核心玩法：球（Ball）/ 挡板（Pad）/ 砖块（Block）物理与碰撞，StaticBody2D + 球物理
  - P2 砖块类型系统：数据驱动（44 种类型，见 `android/scripts/brick_system.gd` + `android/data/blocks/blocks.json`）
  - 工具链：Temurin JDK 17、Android cmdline-tools / build-tools;34.0.0 / platforms;android-34、debug keystore
- 导出策略：当前采用预构建安卓模板（`gradle_build=false`），APK 包名为模板默认；后续可切 Gradle 构建改写包名

## 目录边界

- `android/`：Godot 工程根（project.godot、scenes、scripts、objects、resources、data、levels、build）
- `tools/`：本地工具链（godot/JDK/SDK），不入库
- `docs/`：需求 / 计划 / 活文档（含本文件）
- `E:\Project\Self\WebGamesArchives\Alphabounce`、`E:\Project\Self\EternalTwin-Alphabounce`：原版与重写源码参考（工程外）

## 依赖与约束

- 不引入后端/数据库/网络依赖（首里程碑纯单机 MVP）
- 砖块行为以原版 `Block.hx` 为保真对照（耐久/不可破/计分/掉字母）

# MEMORY.md — Alphabounce 安卓复刻

## 项目事实
- 目标：用 Godot 4（GDScript/C#）+ 安卓导出，复刻 Motion Twin 的 2D 物理打砖块游戏 Alphabounce。纯单机、无后端；首里程碑=可玩 MVP demo（球+挡板+砖块+物理+关卡加载）。
- 本地工程根：`E:\Project\Self\alphabounce`（WorkBuddy 项目），代码壳 `android/`（Godot 工程根，尚未建可跑工程）。
- 初始化按 xijia-init 流程完成（docs 基座 + 种子需求 + 技能推荐清单 0 安装）。
- 技术栈决策（2026-08-18 用户确认）：**Godot 4 + GDScript**（非 C#/Mono）；P0 安卓工具链=**完整构建打通**——本期装齐 Android SDK + JDK 17 + debug keystore 并实际导出可安装 debug APK（非仅配置导出预设）。
- P0 需求 `docs/requirements/inbox/20260818205718-AB-安卓工程初始化.md` 已通过双 guard（intake+plan OK），Gate-1 待用户文字批准；批准后进入 Gate-2 实施（Spike-0 先探下载能力，Godot/SDK 当前均未装）。

## 源码参考（已下载到 E:\Project\Self\）
- `WebGamesArchives/Alphabounce/`：原版 2007 Haxe/Flash 源码（72 .hx + FLA + SWF + i18n de/en/es/fr）。保真对照用，难直接运行。
- `EternalTwin-Alphabounce/`：现代重写 Haxe→HTML5/JS（94 .hx + 4179 PNG 精灵 + 字体 + Node/Redis 后端 + 设计文档 `doc/alphabounce_ds_guide.txt`）。**主参考**：精灵按元素分目录，可直接导入 Godot。
- DSi 零售版闭源不可得；`eternaltwin/alphabounce/libs-haxe` 是 EternalTwin 的 Haxe 依赖（可选补）。

## 关键机制（来自设计文档，供复刻对照）
- 挡板叫 envelopes（飞船），球=balls，砖块=conglomerates，导弹=missiles，无人机=drones。
- 增益/减益：Multiball/Nebula/Open/Quasar/Regeneration/Sapper/Terraforming/Ultraviolet/Provision/Pilot/Pogo/Attraction/INSOMNIA 等。
- 关卡以星球(planet)组织，程序生成 2500 万关；矿物(minerals)为货币。

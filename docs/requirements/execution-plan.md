# AlphaBounce Android 完整重构 — 执行计划（完全对标原版）

> 来源：重写后的 `prd-android-complete.md` + 18 项需求（R00–R14 + R15–R18）+ 2 份基础需求
> 维护规则：每完成一个需求（Gate-2 验收通过 / Gate-3 归档），回填下方「状态追踪表」对应行的 **状态 / 完成日期 / 验收证据**，并同步更新 `AGENTS.md` 的 Execution plan 指针行。
> 原版事实基线：`D:\Project\Self\EternalTwin-Alphabounce`（Haxe/Pixi）

---

## 目标

逐条推进需求，使「全部实现即等于原版」：画面/操作/任务与原版一致，安卓可一键导出 Debug APK / Release AAB。

## 真机独立验收标准（USB 调试模式 · 强制）

> **核心原则（本计划的验收基线）**：每一个需求（R01–R18 + BASE-1/2）都必须能**在不依赖任何尚未完成的上游需求**的前提下，
> 独立构建 debug 包 → USB 安装到真机 → 进入本需求专属验收入口 → 完成交互与 AC 断言 → 产出截图与 logcat 证据。
> **不再接受**「仅 headless 单测」或「进入 Game 场景手动观察」作为 Gate-2 证据。

### 1. 独立性判定（四要素，缺一不可）

1. **可独立构建**：`--export-debug` 产出的 APK 不因其他需求未完成而失败。
2. **可独立进入**：真机启动后经统一 DebugLauncher 菜单点选本需求条目即直达其验收入口，无需先通关或先完成其他需求。
3. **可独立断言**：debug 场景内嵌 AC 自检，输出 `print("<REQ_ID>_AC-n PASS/FAIL")`，logcat 可直接 grep。
4. **可独立取证**：截图 + logcat 零 ERROR，落盘 `docs/evidence/<REQ_ID>.png`。

### 2. Debug 验收载具（工程约定）

| 构件 | 路径 | 职责 |
|---|---|---|
| DebugLauncher 场景 | `game/debug/debug_launcher.tscn` | 真机启动入口，列出全部 20 个需求条目按钮 |
| DebugLauncher 脚本 | `game/debug/debug_launcher.gd` | 点击条目 → `get_tree().change_scene_to_file(该需求 debug 场景)` |
| 需求 debug 场景 | `game/debug/<REQ_ID>_debug.tscn` | 每需求一个，自包含该需求能力 + AC 自检打印 |
| Mock fixture 目录 | `game/debug/fixtures/` | 上游数据未就绪时的替代数据（levels/missions/shop/save/enemies/audio/fx） |

> DebugLauncher 仅在 **debug 导出**中生效；release 导出不打包 `game/debug/`，不影响正式包。

### 3. Mock 解耦规则（关键 · 解决依赖扇入）

- 凡某需求依赖的上游需求**尚未验收完成**，该需求 debug 场景**必须**改加载 `game/debug/fixtures/` 下 mock 数据，使本需求可独立启动与验收。
- Mock 数据的**字段结构必须与 R16 最终产出的正式 schema 一致**（ADR-002 数据格式 / ADR-003 存档），R16 完成后仅替换数据源，不改逻辑。
- **禁止**为验收某需求而要求先完成其全部依赖需求（尤其 R16 扇入的 R02/R05/R06/R07/R08/R11）。
- R16 验收完成后，逐个需求将 fixture 切换为正式数据并重跑一次真机验收，作为回归。

### 4. 标准验收流程（每个需求逐条执行，全部可复跑）

```bash
# 1 构建本需求独立 debug 包
godot --path game --headless --export-debug "Android" game/bin/AlphaBounce_debug.apk
# 2 USB 安装 + 启动
adb -s <DEVICE_SERIAL> install -r game/bin/AlphaBounce_debug.apk
adb shell am start -n com.eternaltwin.alphabounce/com.godot.game.GodotAppLauncher
# 3 在 DebugLauncher 中点选 <REQ_ID>，进入本需求独立验收入口
# 4 AC 断言日志（须全部 PASS）
adb logcat -d | grep "<REQ_ID>_AC"
# 5 截图取证
adb shell screencap -p /sdcard/<REQ_ID>.png
adb pull /sdcard/<REQ_ID>.png docs/evidence/<REQ_ID>.png
# 6 日志门禁（必须零 ERROR）
adb logcat -d -v brief | grep -iE "godot|script error"
```

### 5. 门禁判定

- **通过**：步骤 4 全部 AC 打印 PASS；步骤 6 零 Godot ERROR / SCRIPT ERROR；步骤 5 截图符合视觉预期。
- **不通过**：任一条不满足 → Gate-2 退回，状态回置 `已实现待验收` 并登记缺陷，**禁止签字**（`42-verification-output`）。

### 6. 真机独立验收矩阵

| 需求 | 验收入口（debug 场景） | Mock 基线（依赖未就绪时） | 验收类型 |
|---|---|---|---|
| R01 Pad | `debug/R01_pad_debug.tscn` | 无（自含 Pad+Ball，不依赖 R02/R16） | 真机交互 |
| R02 关卡网格 | `debug/R02_grid_debug.tscn` | `fixtures/level_demo.json`（替 R16 `levels.json`） | 真机视觉+断言 |
| R03 物理完整化 | `debug/R03_physics_debug.tscn` | 无（自含 Ball+4 边界，不依赖 R01/R02） | 真机交互+断言 |
| R04 碰撞集成 | `debug/R04_collision_debug.tscn` | `fixtures/level_demo.json` 方块布局（替 R16） | 真机交互 |
| R05 任务系统 | `debug/R05_mission_debug.tscn` | `fixtures/mission_demo.json`（替 R16 `missions.json`） | 真机 UI+断言 |
| R06 商店系统 | `debug/R06_shop_debug.tscn` | `fixtures/shop_demo.json` + `fixtures/save_demo.json` | 真机 UI+断言 |
| R07 存档系统 | `debug/R07_save_debug.tscn` | 无（自含 `user://` 读写，不依赖 R16 schema） | 真机持久化 |
| R08 敌人系统 | `debug/R08_enemy_debug.tscn` | `fixtures/enemy_demo.json` + `fixtures/level_demo.json` | 真机交互+视觉 |
| R09 触摸映射 | `debug/R09_input_debug.tscn` | 无（自含 InputMap 探针） | 真机交互 |
| R10 游戏循环 | `debug/R10_loop_debug.tscn` | `fixtures/level_demo.json` + 最小子集 stub（Pad/Ball/Block/1 敌人） | 真机端到端 |
| R11 导弹系统 | `debug/R11_missile_debug.tscn` | `fixtures/level_demo.json`（含 GUARDIAN）+ `fixtures/save_demo.json` | 真机交互 |
| R12 音频系统 | `debug/R12_audio_debug.tscn` | `fixtures/audio/` 占位 ogg（替 R15 迁移音频） | 真机听感+断言 |
| R13 粒子特效 | `debug/R13_fx_debug.tscn` | `fixtures/level_demo.json` + 程序生成纹理（替 R15） | 真机视觉 |
| R14 UI+导出 | `debug/R14_full_debug.tscn` | 全部 fixture（R16 完成后切正式数据） | 真机端到端 |
| R15 资产迁移 | `debug/R15_asset_debug.tscn` | 无（直接展示 `game/resources/` 已迁移精灵/音频） | 真机视觉比对 |
| R16 数据搬运 | `debug/R16_data_debug.tscn` | 无（本需求产出正式数据；校验 JSON 可解析并加载） | 真机断言+加载 |
| R17 物理对等 | `debug/R17_parity_debug.tscn` | `fixtures/physics_demo.json`（原版常量对照） | 真机手感+断言 |
| R18 画面规格 | `debug/R18_visual_debug.tscn` | `fixtures/level_demo.json`（替 R16） | 真机截图比对 |
| BASE-1 物理基础 | `debug/BASE1_debug.tscn` | 无（已 Gate-2；Game 接入待 R03/R17） | 真机已闭环 |
| BASE-2 方块基础 | `debug/BASE2_block_debug.tscn` | `fixtures/block_demo.json`（替 R16 全量类型） | 真机视觉 |

## 更新约定

- 状态取值：`待开始` / `进行中` / `已实现待验收` / `已完成(归档)`
- 每完成一条需求：改状态 → 填完成日期 → 贴**真机验收证据**（`docs/evidence/<REQ_ID>.png` 截图 + `<REQ_ID>_AC-n PASS` logcat 片段 + 零 ERROR 结论）
- **缺真机证据不得签字**：Gate-2 验收证据列为空或仅 headless 输出时，视为未验收（`42-verification-output`）
- 同步 `AGENTS.md`「Execution plan」头条状态

---

## 执行阶段（按依赖排序）

### 阶段 0 — 对等基线准备（资源 + 数据 + 规格）

| 需求 | 依赖 | 说明 |
|---|---|---|
| R15 资产迁移（精灵/音频） | R00 | 原版资源导入 + 命名映射 + 真机视觉比对 |
| R16 原版内容数据搬运 | R00 | 关卡/任务/敌人/方块原始定义 → JSON |
| R18 画面动画对等规格 | R15 | 布局/特效/反馈/动画对等规格 + 截图比对清单 |

### 阶段 1 — 核心玩法骨架

| 需求 | 依赖 | 说明 |
|---|---|---|
| R00 项目初始化 | — | project.godot + 导出配置（**已完成**）|
| R01 Pad 发射台系统 | R00 | 触摸瞄准发射，对齐 `Pad.hx` |
| R02 关卡网格与关卡数据系统 | R00, R16 | GridManager + LevelLoader，字段对齐 `Level.hx` |
| R03 球体物理系统完整化 | R01, R02 | **重构 ball.gd 为 `move_and_slide()`（ADR-001）** |
| R17 物理对等校验 | R03 | 强制 ADR-001 + 原版弹跳手感对齐（refactor 后验证/微调）|
| R04 球-块碰撞集成 | R03, R02 | ball 碰撞回调 → block.hit() → score |

### 阶段 2 — 系统层

| 需求 | 依赖 | 说明 |
|---|---|---|
| R05 任务系统 | R00, R16 | MissionManager + 原版任务数据 |
| R06 商店系统 | R00, R05, R16 | ShopManager + 原版商品/兑换数据 |
| R07 玩家存档系统 | R00, R16 | PlayerData + 原版存档字段 |
| R09 触摸输入映射配置 | R00, R18 | 对齐原版控制动作集 |
| R08 敌人系统（全量）| R02, R16 | 11 ev + 7 Molecule + GUARDIAN(Boss) |
| R10 游戏循环状态机与关卡管理 | R01~R08 | 含原版通关/GameOver 规则 |
| R11 导弹系统 | R04, R07, R16 | 对齐原版导弹逻辑（GUARDIAN 击杀）|

### 阶段 3 — 表现层 + 验收

| 需求 | 依赖 | 说明 |
|---|---|---|
| R12 音频系统 | R00, R15 | AudioManager + 原版音频资源 |
| R13 粒子特效系统 | R04, R15 | 原版 `fx/` 消除/击中反馈特效 |
| R14 完整 UI 层与 Android 导出验证 | R01~R13, R15, R18 | 原版布局/按钮对等 + APK 验证 |

### 基础需求（已部分 Gate-2，补齐对标）

| 需求 | 依赖 | 说明 |
|---|---|---|
| 20250101120001 物理系统基础 | — | 基础定理已 Gate-2；Game 接入待 R03/R17 |
| 20250101120002 方块系统基础 | — | 基础类型/击破已 Gate-2；全量方块类型待 R16 |

---

## 状态追踪表

> 列：ID ｜ 需求文件 ｜ 分级 ｜ 阶段 ｜ 状态 ｜ 完成日期 ｜ 验收证据

| ID | 需求文件 | 分级 | 阶段 | 状态 | 完成日期 | 验收证据 |
|---|---|---|---|---|---|---|
| R00 | 20250101120000-… | 黄 | 1 | 已完成 | 2026-08-28 | project.godot + .export_presets.cfg |
| R01 | 20250101130000-Pad发射台系统.md | 黄 | 1 | 待开始 | — | — |
| R02 | 20250101130001-关卡网格与关卡数据系统.md | 黄 | 1 | 待开始 | — | — |
| R03 | 20250101130002-球体物理系统完整化.md | 红 | 1 | 待开始 | — | — |
| R04 | 20250101130003-球-块碰撞集成.md | 黄 | 1 | 待开始 | — | — |
| R05 | 20250101130004-任务系统.md | 黄 | 2 | 待开始 | — | — |
| R06 | 20250101130005-商店系统.md | 黄 | 2 | 待开始 | — | — |
| R07 | 20250101130006-玩家存档系统.md | 黄 | 2 | 待开始 | — | — |
| R08 | 20250101130007-敌人系统.md | 红 | 2 | 待开始 | — | — |
| R09 | 20250101130008-触摸输入映射配置.md | 绿 | 2 | 待开始 | — | — |
| R10 | 20250101130009-游戏循环状态机与关卡管理.md | 黄 | 2 | 待开始 | — | — |
| R11 | 20250101130010-导弹系统.md | 黄 | 2 | 待开始 | — | — |
| R12 | 20250101130011-音频系统.md | 绿 | 3 | 待开始 | — | — |
| R13 | 20250101130012-粒子特效系统.md | 绿 | 3 | 待开始 | — | — |
| R14 | 20250101130013-完整UI层与Android导出验证.md | 黄 | 3 | 待开始 | — | — |
| R15 | 20260101130014-资产迁移（精灵_音频）.md | 红 | 0 | 待开始 | — | — |
| R16 | 20260101130015-原版内容数据搬运.md | 红 | 0 | 待开始 | — | — |
| R17 | 20260101130016-物理对等校验.md | 红 | 1 | 待开始 | — | — |
| R18 | 20260101130017-画面动画对等规格.md | 黄 | 0 | 待开始 | — | — |
| BASE-1 | 20250101120001-物理系统基础.md | — | 基础 | 进行中 | — | 基础定理 Gate-2；Game 接入待 R03/R17 |
| BASE-2 | 20250101120002-方块系统基础.md | — | 基础 | 进行中 | — | 基础类型 Gate-2；全量类型待 R16 |

---

## 关键事实备忘（避免执行期偏差）

- **Boss 不存在独立实体**：顶级威胁 = `Block.GUARDIAN` 特殊方块（仅导弹可击杀，见 `Pad.hx:607`、`Level.hx:777,840`）。R08 已将其作为 Boss 等价实现。
- **物理硬约束**：`ball.gd` 当前手写 `position += velocity*delta` 违反 ADR-001，R03/R17 必须改 `CharacterBody2D.move_and_slide()`。
- **资产缺口**：`game/` 当前无任何原版精灵/音频，R15 须先行导入才能在 R12/R13/R14 对标画面。
- **降级已废除**：R08 原「不做全部 11 种敌人 / 不做 Boss」Out of Scope 已移除，须全量实现。
</content>
</invoke>

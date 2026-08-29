# AlphaBounce Android 重构 — 计划与需求梳理报告

> 梳理日期：2026-08-29
> 梳理对象：`docs/requirements/prd-android-complete.md`、`execution-plan.md`、inbox 20 份需求 + shipped 1 份
> 事实基线：`D:\Project\Self\EternalTwin-Alphabounce`（原版 Haxe/Pixi，79 个 .hx + 4328 个资源）
> 目标校验：**完全在安卓上重构，不降级实现和验收**

---

## 摘要

对照原版源码逐项核查后，结论是：**现有 18 个需求的整体结构是合理的，但有 3 个致命问题会使需求无法按现有文本落地，7 项范围未定义，9 处需求文本缺关键规格。**

其中最重要的一条：**原版本身是一个残缺移植**——音频系统完全没有实现，关卡数据完全依赖服务端。现有需求文档把这两项写成了「从原版迁移/搬运」，属于基于错误前提的不可执行需求。这不是我方降级，必须在需求层面先纠正事实，再决定处置。

---

## 一、原版事实基线（本次新提取，需求文档均未记载）

以下常量/清单是 R02/R03/R06/R07/R08/R16/R17/R18 的验收依据，但现有需求文档全部缺失，导致 AC 无法判定。

### 1.1 画面与网格硬规格（`Cs.hx`）

| 项 | 原版值 | 推导 |
|---|---|---|
| 画布 | **400 × 360** | `mcw=400, mch=360` |
| 顶部 HUD 高度 | 30 px | `YMAX=(mch-30)/BH` |
| 格子尺寸 | **28 × 14** | `BW=28, BH=14` |
| 网格 | **14 列 × 23 行** | `400/28=14`，`330/14=23` |
| 左右边距 | 4 px | `SIDE=(400-14*28)/2` |
| 节奏常量 | `TEMPO=120` | 帧节拍 |
| 上限 | `MAX_BALL=18`、`MAX_OPTION=6` | 同屏球/道具上限 |

> **影响**：这是「画面对等」的唯一可量化基线。R18、R02、R09 都必须以此为准。当前需求文档通篇没有出现过 400×360 或 14×23。

### 1.2 球体类型（9 种，`Cs.hx`）

`STANDARD / FIRE / ICE / DRUNK / KAMIKAZE / YOYO / HALO / SHADE / VOLT`

> **影响**：R06（商店）写「兑换特殊球体」，但无类型清单；**9 种球没有独立需求承接**，其中 FIRE/ICE/DRUNK/KAMIKAZE/YOYO 各有特殊行为（R03 的 Out of Scope 明确写了「不做特殊球体效果」，与 R06 直接冲突）。

### 1.3 发射台类型（7 种，`Cs.hx`）

`STANDARD / GLUE / TIME / LASER / GENERATOR / AIMANT / SHAKE`

> **影响**：R01 只描述「触摸瞄准+发射」，**未覆盖 7 种 Pad 形态及各自行为**，而 LASER/GENERATOR 与 R11 导弹、R08 敌人生成器存在耦合。

### 1.4 无人机（3 种，`Cs.hx` Info typedef）

`_droneMine`（采矿）/`_droneFight`（战斗）/`_droneCollector`（收集）

> **影响**：玩家可装备单位，**无任何需求承接**，且占用存档字段与商店兑换。

### 1.5 方块类型（约 30 种，`Block.hx`）

编号不连续：

- 矿物：`MIN_GREEN=1`（1-4 级）、`MIN_BLUE=5`、`MIN_PINK=25`
- 特殊：`BONUS=10`、`BONUS2=11`、`BONUS3=12`、`BALL=13`、`BOOM=14`、`SPACE=15`、`REDUC=16`、`STEEL=17`、`PUSHER=18`、`JUMPER=19`、`STORM=20`、`ITEM=21`、`CAGE=22`、`GENERATOR=32`、`LURE=42`、`DRAGON_LEFT=43`、`DRAGON_RIGHT=44`、`INSECT=45`、`SWAP=46`、`MISSILE=47`、`DOOR=48`、`DEPLETED=49`、`NUT=50`、`KILL=51`、`LIFE=52`、`DEATH=53`、`GLUE=54`、`GUARDIAN=55`、`MINE=56`

> **影响**：BASE-2 状态为「全量类型待 R16」，但 R16 未列出清单，验收时无法判定「全量」是 30 种还是 56 种。
> `GUARDIAN=55` 再次印证它**是方块类型、不是独立 Boss**，PRD 的事实澄清正确。

### 1.6 敌人（与需求一致，可确认）

- **11 种 ev**（`ev/*.hx` 正好 11 个文件）：Dragon、Drone、Generator、Indigestion、Javelot、Ouverture、Quasar、Storm、UltraViolet、Unification、Wave ✅
- **7 种 Molecule**（`el/Molecule.hx` INFOS）：SPEEDER、BUILDER、CLEANER、SPACER、ARMORER、FIXER、LIGHTER ✅
  - 每种由 **3 个子球**组成（`mols` 数组），各有出现概率权重 `pb`，各有专属行为分支

### 1.7 存档字段（`Cs.hx`）

```
_x, _y, _chl, _chs, _minerai, _mission, _motor,
_droneMine, _droneFight, _droneCollector,
_fog:Array<Int>, _items:Array<Int>
+ pref { mouse, gfx, bools[4] }
```

> **影响**：R07 写「字段对齐原版」但未列出，审计时无从对照。

---

## 二、致命问题（必须用户决策，否则需求无法执行）

### 问题 1：原版没有任何音频资源，音频系统在原版本身就是未实现状态

**事实**：

- 全项目搜索 `*.mp3/*.ogg/*.wav` → **0 个文件**
- `frontend/src/haxe/Sound.hx`：`static var MUTE = true`，`play()` 与 `loop()` 函数体中全部是 `trace("FIXME")`，原 Flash 的 `attachSound` 调用被注释掉

**受影响的位置**：

| 位置 | 现有文本 | 问题 |
|---|---|---|
| R15 | 「音频迁移：将原版音效/音乐导入 `game/resources/audio/`，格式转码 ogg/wav」 | 无源可迁，AC-3 无法达成 |
| R12 | 「AudioManager + 原版音频资源」 | 依赖不存在的资源，R15→R12 链路断开 |
| ADR-004 | 「资源来自原版迁移」 | 前提错误 |
| ADR-005 | 「`images/`、`sounds/` 迁移」 | `sounds/` 目录不存在 |
| PRD 用户故事 8 | 「游戏有音效和背景音乐」 | 原版移植版也无音效 |
| 缺口 G-07 / G-10 | 「音频系统缺失」「音频资源缺失」 | 不是我方缺口，是原版缺失 |
| PRD 对等原则 1 | 「所有精灵/音频须从原版资源迁移」 | 音频部分不成立 |

**需要决策**（三选一）：

1. **承认无源**：音频列入「原版本身缺失」，R12 降级为「音频架构预留 + 静音 stub」，R15 删除音频迁移范围 → **符合「不降级」原则，因为原版就是无音的**
2. **自配音效**：自行制作/寻找替代音效 → 属新增创作，需单独立需求并接受「非原版对等」
3. **暂缓**：R12 挂起，主游戏完成后再议

> 建议选 1，并在 PRD 中明确记录「原版 Haxe 移植版音频未实现，非本次重构降级」。

### 问题 2：原版关卡数据不可搬运（存服务端 + 编解码未实现）

**事实**：

- `Api.hx`：`askPendingLevels(x, y)` 注释为「Appelé lorsque l'admin ou l'editeur veut afficher la liste des niveaux proposés」——**关卡是 UGC（玩家投稿、管理员审核）模式**，按大地图坐标 `(x,y)` 组织，每格最多 32 个候选关卡
- 数据落在服务端 Redis（`backend/RedisClient.hx`），`#if prod` 分支才走网络请求；非 prod 分支用 `JSSharedObject` 本地模拟
- `Level.hx:56-58`：关卡序列化/反序列化处为 `trace("FIXME")`，`PersistCodec` 被注释掉 → **Haxe 移植版的关卡编解码根本没写完**
- `backend/` 仅 14 个文件（Api/Config/JWT/Redis/Express 等），**无任何关卡种子数据**

**受影响的位置**：

| 位置 | 现有文本 | 问题 |
|---|---|---|
| R16 | 「关卡/任务/敌人/方块原始定义 → JSON」 | 关卡定义不在源码里，无源可搬 |
| R02 | 「LevelLoader + 原版关卡数据搬运」 | 同上 |
| ADR-002 | 「关卡数据采用 JSON，字段须对齐原版 `Level.hx`」 | 字段结构可推导，但**没有内容数据** |
| 缺口 G-13 | 「内容对等缺失…无数值基线」 | 需要换一种取数方式 |
| execution-plan | R02/R05/R06/R08/R10/R11 均以 R16 为 Mock 基线源 | 链路根部的 R16 无法产出关卡数据 |

**需要决策**（三选一）：

1. **自建关卡集**：按原版 `Level.hx` 字段结构 + 方块类型表，**手工设计 N 个关卡**作为安卓版首发内容（需单独立需求「关卡内容设计」，明确 N 与难度曲线）
2. **仅搬运可搬部分**：R16 只搬运**方块定义/敌人定义/任务定义/商店商品**（硬编码在 .hx 里，可取），关卡改为自建
3. **程序化生成**：按原版规则随机生成（原版有 `seed` 与 `Random.hx`，但原版实际是人工投稿，程序化生成属新增行为）

> 建议选 2+1 组合：R16 缩小为「可搬运数据」，新增「关卡内容设计」需求。

### 问题 3：PRD 存在循环依赖 R03 ↔ R17（死锁）

**事实**：

- PRD 需求表：R03 依赖 `R01, R02, R17`；R17 依赖 `R03` → 互为前置，无法排期
- `execution-plan.md` 阶段 1 写的却是 R03 → R17（R17 依赖 R03）

**处置**：以 execution-plan 为准，**修正 PRD 需求表**，删除 R03 对 R17 的依赖，改为「R03 实现 + R17 校验/微调」的单向关系。

---

## 三、范围缺口（原版有，需求未定义，需明确纳入或书面排除）

原版是**网页游戏**，除 AlphaBounce 主玩法外还包含周边系统。PRD 只定义了「单人游戏」，但未列出排除项，容易被判定为隐性降级。

| # | 原版模块 | 源码 | 资源量 | 建议 |
|---|---|---|---|---|
| 1 | **多语言** | `Texts.hx` + `TextEn/Fr/Es/De.hx`（约 150KB）+ `groundText`(46) | 中 | 需决策：安卓版出哪种语言？建议**只做中文或英文**，并在 PRD 书面排除其余 3 语种 |
| 2 | **navi 大地图选关** | `navi/Map.hx`(36KB)、`menu/World.hx` | `mcMapIcon`(70)、`mcMapIconSmc`(121)、`worldAsteroMap`(6) | 原版**选关入口**就是大地图。R02/R10 只提「关卡管理」，未定义选关界面 → 建议**补进 R14 或单独立需求** |
| 3 | **lander 登月舱小游戏** | `lander/` 8 个 .hx（Game/Pad/Hero/House/Mineral/Drone/Pix） | **约 2000+ 文件**（`landerDecor` 1044、`landerPlan1-24` 约 1300、`mcHero*` 约 200） | 独立迷你游戏，占资源总量近半。建议**明确排除**，R15 迁移范围据此砍掉一半工作量 |
| 4 | **关卡编辑器** | `navi/menu/Editor.hx`(11KB) | `visualize`(169)、`mcEditorBrush`、`mcBrush`、`debugBlock` | 开发工具，非玩家功能。建议**排除**，但原版关卡是 UGC，若排除则必须配合「自建关卡集」 |
| 5 | **演示/自动模式** | `Demo.hx`、`Game.PLAY_AUTO`、`mcModeDemo`(25) | 小 | 建议**排除**或归入 R14 可选 |
| 6 | **账号/社交后端** | `Api.hx`(13KB)、`Web.hx`、`menu/People/Traveler/ItemGiver` | `etwinbar`(8)、`mcPeople` 等 | 离线单机。建议**排除**（与 AGENTS.md「离线单机游戏」一致） |
| 7 | **etwinbar 网页组件** | `static/etwinbar/` | 8 | 网页专用，**必然排除** |

> **关键提醒**：第 2 项（大地图选关）如果排除，就没有进入关卡的入口，R02/R10 的「关卡管理」会悬空。建议至少做一个简化版星球选择列表。

---

## 四、R15 范围的重大问题：迁移规模未界定

**事实**：`static/` 下共 **4328 个文件**（`images/` 4113 + `img/` 215 + fonts 5 + etwinbar 8）。

其中：

- `lander*` 系列约 2000+ 文件（登月舱小游戏）
- `etwinbar` 8 个（网页组件）
- `visualize`(169)、`debugBlock`、`mcDebugSquare`（编辑器/调试）
- `ast*`（小行星菜单）、`world*`（世界地图）

**R15 现有 AC-1** 只写「产出《原版资源清单》，覆盖…」，未界定**是否全量迁移**。

**建议**：R15 必须补一条明确的**迁移范围白名单**（按资源目录前缀）：

- 纳入：`mcBlock*`、`mcBall*`、`ballMain`、`mcPad*`、`mcDrone*`、`mcInsect*`、`mcJumper*`、`mcNut*`、`mcQuasar*`、`mcDragon*`、`mcGenerator*`、`mcJavelot*`、`mcUltraViolet*`、`mcWave*`、`fx*`、`part*`、`mcMenu*`、`mcShop*`/`shopIcon`、`mcLife*`、`mcScore*`、`mcBg*`、`mcSpeederBall`
- 排除：`lander*`（登月舱）、`etwinbar`、`visualize`/`debug*`（编辑器）、`ast*`（小行星菜单，若排除 navi）

否则 R15 会变成「迁 4000 个文件但游戏只用 2000 个」的包袱，且真机包体积失控。

---

## 五、工程约定缺失（20 个需求的验收都依赖它，但它不存在）

`execution-plan.md` 的「真机独立验收标准」要求每个需求有独立 debug 场景，经 `DebugLauncher` 进入。但：

| 约定构件 | 文档中的路径 | 实际状态 |
|---|---|---|
| DebugLauncher 场景/脚本 | `game/debug/debug_launcher.tscn` / `.gd` | 不存在 |
| 需求 debug 场景 ×20 | `game/debug/<REQ_ID>_debug.tscn` | 不存在 |
| Mock fixture 目录 | `game/debug/fixtures/` | 不存在 |
| 测试基类 | `game/scripts/tests/test_base.gd`（AGENTS.md 引用） | 不存在 |
| 测试套件场景 | `tests/test_suite.tscn`（AGENTS.md 测试命令引用） | 不存在 |

当前 `game/` 实际只有：6 个 .gd（`core/game|grid|main_menu`、`editor/setup_addon`、`entities/ball|block`）+ 4 个 .tscn（`Main`/`Game`/`Ball`/`Block`）+ 1 个 `tests/test_ball_physics.*`。

**影响**：

- AGENTS.md 的测试命令 `godot --path game --headless --quit tests/test_suite.tscn` 当前**无法执行**
- 20 个需求的真机验收流程**第一步就无法运行**（没有 DebugLauncher 就没有验收入口）

**建议**：**新增前置需求 R19「Debug 验收载具与测试框架」**，依赖 R00，产出：

1. `game/debug/debug_launcher.tscn/.gd`（20 个需求条目菜单）
2. `game/scripts/tests/test_base.gd` + `tests/test_suite.tscn`（AGENTS.md 已承诺的测试框架）
3. `game/debug/fixtures/` 目录骨架与 mock 数据 schema 约定
4. AC 自检打印规范 `<REQ_ID>_AC-n PASS/FAIL`

> 若无此需求，R01–R18 每一个在 Gate-2 时都会因「无验收入口」被卡。这是**当前最大的可执行性风险**。

---

## 六、验收基线的可行性问题

### 6.1 R18「与原版截图比对」不可执行

R18 / R15 多次要求「真机截图与原版逐项比对」。但：

- 原版是**网页版**，需要后端服务（Redis + 认证）才能进入游戏
- 原版 Haxe 移植版的 `Sound.hx`、`Level.hx` 编解码都是 `FIXME`
- 当前环境**无法运行原版**取得对照截图

**建议**：改为「**与资源清单比对**」——真机截图对照 `assets_map.md` 中记录的原版精灵原始尺寸/帧数，验证渲染结果一致；放弃「与原版运行时截图」的比对。

### 6.2 20 次真机验收的成本

每个需求一次「构建 → 安装 → 启动 → 点选 → 断言 → 截图 → 零 ERROR」，20 个需求 = 20 轮。单轮 5-10 分钟计，总计 2-3 小时纯验收时间（不含返工）。

**建议**：

- 保持门禁不变（用户明确要求不降级验收）
- 但允许**批量验收**：DebugLauncher 支持一次启动后连续进入多个需求场景，减少重复的构建/安装次数；证据仍按需求分目录保存

---

## 七、需求文本质量问题清单

| # | 需求 | 问题 | 建议 |
|---|---|---|---|
| 1 | R01 | 只写「触摸瞄准+发射」，未覆盖 **7 种 Pad 类型** | 补齐类型清单与各自行为，LASER/GENERATOR 与 R11/R08 对齐 |
| 2 | R03 | Out of Scope 写「不做特殊球体效果（火焰/冰冻）」，但 R06 商店要「兑换特殊球体」 | 二者冲突，需明确：R03 只做 STANDARD 球物理，特殊球行为归入 R06 |
| 3 | R06 | 「兑换特殊球体」无类型清单 | 补齐 9 种球 + 7 种 Pad + 3 种无人机的商品清单 |
| 4 | R07 | 「字段对齐原版」但未列出字段 | 补齐 §1.7 的 12 个字段 + pref |
| 5 | R08 | 「11 种敌人 + 7 Molecule」清单正确，但 Molecule 的**子球构成（3 球）与概率权重 pb** 未写 | 补齐 INFOS 表，作为 AC 依据 |
| 6 | R15 | 未界定迁移范围（见 §四）；音频部分前提错误（见问题 1） | 补白名单 + 删音频或改写 |
| 7 | R16 | 「关卡/任务/敌人/方块原始定义 → JSON」，但关卡不可搬（见问题 2） | 缩小为可搬运项，关卡另立需求 |
| 8 | R02/R18 | 全篇未出现 400×360 / 14×23 / 28×14 | 补齐 §1.1 硬规格，作为画面/网格的验收基线 |
| 9 | execution-plan | 「真机独立验收矩阵」里 R03 写「不依赖 R01/R02」，与 PRD 的 R03 依赖 R01,R02 **矛盾** | 统一为：验收场景自包含（不依赖），但**功能依赖**仍按 PRD 排期 |

---

## 八、建议的处置顺序

1. **先决策 3 个致命问题**（音频 / 关卡数据 / 循环依赖）—— 不做决策，R12/R15/R16/R02 无法开工
2. **新增 R19「Debug 验收载具与测试框架」** —— 解除全部需求的验收阻塞
3. **明确范围排除清单**（多语言 / lander / 编辑器 / 后端社交 / 大地图），写入 PRD 的 Out of Scope，避免被当作隐性降级
4. **补齐硬规格到需求文本**（400×360 网格、9 球、7 Pad、3 无人机、30 方块、存档字段）
5. **修订 R15 迁移白名单**
6. 然后才按 execution-plan 阶段 0 → 3 推进

---

## 附：当前工程实际状态（供对照）

```
game/
├── project.godot, export_presets.cfg, debug.keystore
├── scenes/
│   ├── main/Main.tscn, Game.tscn
│   └── entities/Ball.tscn, Block.tscn
├── scripts/
│   ├── core/game.gd, grid.gd, main_menu.gd
│   ├── editor/setup_addon.gd
│   └── entities/ball.gd, block.gd
├── tests/test_ball_physics.gd, .tscn
├── addons/godot_mcp/          （MCP 桥接插件，非游戏代码）
└── resources/icons/icon.svg
```

- 代码修改已全部回撤，`git status` 干净（`deb91ef`）
- R00 已归档：`docs/requirements/shipped/20250101120000-Godot项目初始化.md`
- `ball.gd` 仍为手写 `position += velocity*delta`，ADR-001 未落地（与 PRD 现状审计一致）

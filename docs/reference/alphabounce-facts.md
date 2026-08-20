# Alphabounce 原作事实提取（OQ 拍板依据）

> 创建：2026-08-20 ｜ 用途：为 `docs/requirements/inbox/` 各阶段需求的 Must-Confirm OQ 提供可引用的事实依据。

## 来源与引用声明

| 来源 | 类型 | 本仓可见性 |
|---|---|---|
| Michael Lamparski, *AlphaBounce (DSi) Envelope Guide*, 2010（GameFAQs） | 玩家攻略 | **不入库**，见下文 |
| 上游 Haxe 源码 | 代码 | 已入库 `docs/reference/haxe/` |

**为什么攻略不入库**：该攻略明确限制转载——"You're allowed to save the document on your hard drive for personal review... Just don't put it anywhere online without my permission."，授权站点白名单仅 GameFAQs / neoseeker / supercheats。因此本仓**不保存其全文**；仅依据其 Fair Use 条款（"reproduce small parts of the guide for the purposes of commentary, research... so long as you cite my guide as the source"）提取本文档所需事实并标注出处。

本地全文位于 `../EternalTwin-Alphabounce/doc/alphabounce_ds_guide.txt`（工程外，不受版本控制）。

**注意**：该攻略描述的是 **DSi 版**，且为玩家视角，不含数值公式。凡涉及生成算法、数值常量的结论，一律以 `docs/reference/haxe/` 源码为准。

---

## 1. 星球与推进（P7）

- 共 **27 颗**星球：26 颗可玩（清光全部关卡即获得该星球的 envelope），第 27 颗为 Earth。
- Earth **位置每局随机**；需收集散落在部分星球上的 **Earth 地图碎片** 才能得知其坐标。
- **Sonar** 装备可在雷达上用星标指示哪些星球含碎片；只需打该星球的特定一关即可拿到碎片，不必清关。
- Earth 不可游玩：进入即播片并结束游戏。
- **难度模式三档：Easy / Normal / Hard**。星球在地图上的**排布随难度不同**（攻略举例：Asmech 在 Easy 靠前、在 Normal 靠后），因此难度曲线本身不随距离单调递增。通关 Easy+Normal 解锁 Hard；Hard 专属奖励为 HILAN-DR。

> 出处：攻略 §2.0 Planets [ROCKS]。星球↔envelope 的 27 项对应表见攻略同节（本文不复制全表）。

## 2. 舰队与飞船（P8）

- **envelope（飞船）共 28 种**：`#01 ESC-STD` 为初始船，`#02`–`#28` 各对应一颗星球的通关奖励。
- **舰队槽位初始 3 个**，拾取 plus 形道具 *Additional Ship* 后扩到 **4 个**。
- 槽位内首船被摧毁后，其余作为**备用船按顺序依次出场**；剩余数量以左下角黄色矩形显示。
- 全部船损失 → 关卡失败。

> **重要修正**：`document/复刻计划.md` 与 P8 需求写的「3 艘飞船各有 P-Bonus 与特性」是误读——**3 是舰队槽位数，不是飞船总数**；飞船实际有 28 种。

> 出处：攻略 §2.1 Your Fleet [FLEET]、§3 Envelope Reference 目录 #01–#28。

## 3. 装备与 Defense（**当前无需求认领**）

- 每艘 envelope 有 **2–6 个装备槽**（源码 `Cs.MAX_OPTION = 6` 一致）。
- 装备类别与限制：

| 类别 | 限制 | 说明 |
|---|---|---|
| 顶部武器（激光/加农） | 每船 1 | 无限弹药，威力多低于标准钻球 |
| 导弹 | 每船 1 | 弹药有限；主要用于砖块而非敌人 |
| 球 | 至少 1 | 多于 1 时额外球分配到左右两侧 |
| 无人机 / 地雷 | 多个 | 见 §5 |
| Extension（扩板） | 无限制 | 增大初始船体，略微降速 |
| 护甲 | 每船 1 | 见下方 Defense |
| 杂项 | 无限制 | 如 Ammo Supplies（提升**初始**弹药） |

- **Defense 为隐藏属性**，每 1 点使所有伤害来源 **-1**：Metal Scraps 1 / Steel Plates 2 / Shield 5 / Advanced Shield 7。BEGNE-TWO 是唯一自带 Defense 的船。
- **全游戏每件装备只有一份**，需在舰队内分配。

> **缺口提示**：装备槽位/Defense 是原作策略核心（攻略原话 "Equipment is a huge part of strategy"），但 `document/复刻计划.md` 与 13 篇需求均未覆盖，P8 只写到「购买挡板/球升级」。

> 出处：攻略 §2.4 About Equipment [EQUIP]；槽位上限与源码 `Cs.MAX_OPTION` 交叉验证。

## 4. 增益与减益（P4）

- 字母掉落拾取触发；共 **25 种**（字母 A–Z 除 P），加 **7 种 P-Bonus** 合计 32。
- **18 Bonus**：Attraction, Barrier, Chaos Field, Extension, Frenzy, Halo, Javelin, Laceration, Multiball, Nebula, Open!!!, Quasar, Regeneration, Sapper, Terraforming, Ultraviolet, Vendetta, Xenox
- **7 Malus**：Diminish, Gelato, Indigestion, Kamikaze, Whisky, Yoga, Zealot
- 上述好坏分类以 **INSOMNIA 免疫 Malus** 的行为为判定依据。
- **7 种 P-Bonus（随飞船而定，过半为负面）**：

| P-Bonus | 性质 | 效果 |
|---|---|---|
| Pilot | Bonus（名义） | 自动驾驶，自动左右接球；仅自动**水平**移动 |
| Pyromancer | Bonus | 对随机一片砖块造成伤害，单发不足以击破，需叠加 |
| Provision | Bonus | **导弹补满至上限**；会顶掉 Ammo Supplies 带来的额外弹药 |
| Pogo | **Malus** | 所有球周期性改变方向 |
| Paradox | **Malus** | 左右操作暂时反转（有 Gravitron 时上下不反转） |
| Pause | **Malus** | 船体短暂冻结无法移动 |
| Peace | **Malus** | 船「睡着」，移动大幅变慢 |

> **P4 OQ-002 答案**：复刻计划列出的 6 个已知 P-Bonus 缺的**第 7 种是 Provision**。
> Pilot 被归为 Bonus 的原因是它是 INSOMNIA 的 P-Bonus，而 INSOMNIA 对它不免疫。

> 出处：攻略 §2.2 [BONUS]、§2.3 [PPPPP]。

## 5. 导弹与无人机（P5）

- 导弹装在船体左右，弹药有限，**设计意图是打砖块而非敌人**。
- **补充规则**：`Ammo Supplies` 装备提升**初始**弹药量；关卡内补满只有一条途径——拾取 P 字母且**当前飞船的 P-Bonus 恰为 Provision**。
- **无人机部署与索敌**：
  - 每个无人机有**特定目标类型**（某类砖块或敌人），例如禁用炮塔、把钢砖转为岩砖。
  - **球从船体反弹即部署**；部署后直接跳向目标，处理完跳下一个，直到该类目标清空。
  - 部署后常驻场上。
  - **多无人机严格按装备顺序部署**；若某个无人机因场上无有效目标而无法部署，**其后所有无人机也不会部署**（地雷例外，可越过前面卡住的无人机）。
  - 地雷是无人机特例：吸附任意砖块，直到该砖被摧毁或被 Open!!! 移动时爆炸；Sapper 增益也给地雷。

> **P5 需求模型修正**：需求把 Provision 写成「Provision 类补充道具」并把 OQ-001 设为「浏览器版不补 / DSi 版补」之争。实际 Provision 是**飞船的 P-Bonus**，不是道具。
> **P5 OQ-002 答案**：索敌优先级不是按距离或威胁，而是**装备顺序 + 目标类型匹配**，且有「前一个卡住则后续全卡住」的串行规则。

> 出处：攻略 §2.4 [EQUIP] 之 Missiles / Drones and Mines、§2.3 之 Provision。

## 6. 球与挡板类型（P3）

源码 `docs/reference/haxe/Cs.hx` 给出**确切枚举**，优先于攻略描述：

- **球 9 种**：`BALL_STANDARD / FIRE / ICE / DRUNK / KAMIKAZE / YOYO / HALO / SHADE / VOLT`
- **同时存在球数上限**：`MAX_BALL = 18`
- **挡板（船体）7 种**：`PAD_STANDARD / GLUE / TIME / LASER / GENERATOR / AIMANT（磁吸）/ SHAKE`
- 装备槽上限：`MAX_OPTION = 6`
- 节奏常量：`TEMPO = 120`；`DOOR_COEF = 0.25`
- 砖块网格单元：`BW = 28`、`BH = 14`；游玩区 `mcw = 400`、`mch = 360`

> **P3 需求修正**：AC 写「≥ 3 种球类型」，实际原作为 9 种，且球数上限 18（与 Multiball 相关）。

## 7. 确定性关卡生成（P7）

### PRNG

`docs/reference/haxe/Random.hx` 为 30 位掩码线性同余发生器：

```haxe
seed = Std.int(1664525.0 * seed + 1013904223.0) & 0x3FFFFFFF;
rand()    -> (seed % 1000) / 1000   // [0,1) 浮点，仅千分之一精度
random(n) -> seed % n               // [0,n) 整数
```

移植注意：乘加在 **float64** 中完成后再截断取整，且掩码为 `0x3FFFFFFF`（30 位，非 32 位）；GDScript 复刻须逐位一致，否则同 seed 不同结果。

### 种子来源

`Level.hx` `initSeed()`：`seed = new OldRandom(wx * 10000 + wy)`。

**即关卡种子由星球的世界坐标唯一决定**，无需额外持久化 seed —— 这正是原作「2500 万关可复现」的实现方式。

### 难度参数

```haxe
dst  = sqrt(wx*wx + wy*wy)              // 距原点距离
ang  = atan2(wy, wx)
lvl  = int(pow(dst * 0.1, 0.5))         // 难度档
ymax = int(min(12 + lvl, Cs.YMAX - 6))  // 可用网格高度随难度增长
```

### 特征概率表

`initProba()` 生成 `proba[]`，语义为**倒数概率**：判定写作 `seed.random(proba[X]) == 0`，故 **值越大越罕见**；`NEVER = 100000` 表示不出现。各特征的 `n` 由 `dst`、`wx/wy` 正负、`ang`、以及到具名区域（`ZoneInfo.SOUPALINE / MOLTEAR / LYCANS / KARBONIS / POFIAK`）的距离共同决定。例（原式）：

| 特征 | 概率公式（摘） |
|---|---|
| `PB_STEEL_BAR` | `max(5 - dst/200, 2)`；近 SOUPALINE(<12) 则 1000；再乘 `min(dist(MOLTEAR)/50, 1)` |
| `PB_PUSHER` | 12；`dst<6` 不出；`dst<20` 为 40 |
| `PB_BOOM` | 12；`dst<4` 不出；`wx<0` 或 `wy<0` 时 `+dst*0.5`；LYCANS 区为 1（极常见） |
| `PB_STORM` | `dst>30` 时 `max(60 - dst*0.5, 4)` |
| `PB_CAGE` | `dst>15` 时 `max(50 - dst, 3)` |
| `PB_GENERATOR` | `dst>20` 时 `max(100 - dst*0.5, 12)` |
| `PB_DRAGON` | `wy>10` 时 10；近 POFIAK(<30) 时 `1 + dist/30*10` |
| `PB_MISSILE` | `dst>4` 时 `min(3 + dst*0.1, 20)`；LYCANS 区为 2 |
| `PB_DOOR` | `13<dst<18` 为 7；`dst>58` 为 16 |
| `PB_KILL` | `dst>80` 时 `max(3, 80*abs(hMod(ang-2.504, 3.14)))` |
| `PB_DEATH` | `dst>40` 时 `max(2, 100 - pow(dst*10, 0.5))` |

生成流程还包含左右镜像（`flMirror = random(2)==0`）与调色板镜像、按区域调色板取色、水平线段（`getHoriLine`）等，完整序列见 `docs/reference/haxe/Level.hx`。

> **P7 OQ-001 答案**：参数模型不需要自拟——直接照搬 `Level.hx` 的 `initProba()` + 生成序列，并按坐标派生 seed。
> **P7 OQ-002 答案**：星球解锁 = 清光该星球全部关卡得 envelope；碎片收集只需打特定一关；Sonar 指示含碎片星球；碎片集齐得 Earth 坐标，进入即结局。

## 8. 尚未取证的项

- 经济数值（矿物产出/价格/升级曲线）：需读 `docs/reference/haxe/lander/Mineral.hx`、`navi/menu/Shop.hx`（本轮未展开）。
- 敌人射击节奏具体数值：需读 `docs/reference/haxe/ev/Dragon.hx`、`ev/Generator.hx`。
- 激光对船体伤害数值：需读 `docs/reference/haxe/el/shot/Laser.hx`；但伤害经 Defense 减免、船毁则换备用船的框架已由 §2/§3 确定。

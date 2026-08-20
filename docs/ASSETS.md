# Alphabounce 安卓复刻 · 资产管线（Asset Pipeline）

> 创建：2026-08-19 ｜ 关联：`document/复刻计划.md`（技术决策"直接复用 EternalTwin 的 PNG + 字体"）
> 目的：把原版/现代版素材系统化导入 Godot 工程，为 P1~P10 全部阶段提供可消费的精灵与字体。

---

## 1. 素材来源

上游为 EternalTwin 重写版，从公开仓库浅克隆到工程**同级目录**（`sync_assets.ps1` 缺失时自动克隆）：

```bash
git clone --depth 1 https://gitlab.com/eternaltwin/alphabounce/alphabounce.git ../EternalTwin-Alphabounce
```

| 来源 | 上游路径 | 内容 | 许可证 |
|---|---|---|---|
| 精灵 | `frontend/src/static/images/` | **4113 张 PNG**（按元素分目录） | AGPL-3.0 |
| 字体 | `frontend/src/static/fonts/` | 5 个 woff（Godot 4 原生支持，无需转 ttf） | AGPL-3.0 |
| 设计文档 / Haxe 源 | `doc/`、`frontend/src/haxe/` | 已入库快照，见 `docs/reference/` | AGPL-3.0 |

> **历史教训**：上游原先只存在于本机 `E:` 盘，盘卸载后精灵与同步脚本一并丢失（脚本曾放在 gitignore 的 `tools/` 下）。现改为：脚本入库 `scripts/`，文本类真相源入库 `docs/reference/`，精灵由脚本从公开仓库可复得。
>
> **许可证立场（当前）**：个人/学习用途，直接复用 OK；衍生整体须遵守 AGPL。原版 2007（CC BY-NC-SA，非商业）存档当前不在本机，其被引用模块在上游均有对应文件。**发布合规延后到 P12 处理**。

---

## 2. 工程内目录约定

```
android/
  assets/
    sprites/            # 从上游 images/ 镜像（子目录同名保留）
      mcPad/  mcBall/  ballMain/            # P1 已同步
      mcBlock/  mcBlockSmc/  blockMissile/  # P2 已同步
      part*/                                # P2 破坏粒子，已同步
      # 后续阶段按 §7 映射追加，未同步的目录不占仓库与包体
    fonts/              # woff 直接使用，Godot 4 原生支持
      Digital.woff  Verdana.woff  Verdana-Bold.woff
      Kiloton_Condensed_Italic_Normal.woff  gau_font_cube_b.woff
```

- 镜像脚本：`scripts/sync_assets.ps1`（保留子目录、文件名空格→下划线、上游缺失时自动克隆）。
- **只同步已交付阶段所需目录**（当前 176 张 / 388 KB），原因见 §6。全量镜像用 `-All`（4113 张 / 24.6 MB）。
- 无需字体转换：Godot 4 原生支持 WOFF/WOFF2，原 `tools/convert_fonts.py` 已不必要。

---

## 3. 文件名清洗规则

Godot 的 `res://` 路径对空格不友好，复制时统一把 ` ` 替换为 `_`：

- `ball main0001.png` → `ball_main0001.png`
- `fleche retour.png` → `fleche_retour.png`

脚本已自动处理，勿手动回改。

---

## 4. 在 GDScript 中引用

```gdscript
# 静态精灵（以砖块为例）
var sprite := Sprite2D.new()
sprite.texture = load("res://assets/sprites/mcBlock/01.png")
var tex := sprite.texture.get_size()
sprite.scale = Vector2(SIZE / tex.x, HEIGHT / tex.y)   # 适配碰撞盒尺寸
add_child(sprite)
```

- 引用字符串会被 Godot 依赖扫描捕获，**导出时自动导入该 PNG**，无需手动先开编辑器。
- 防御：若 `texture == null`（未导入/缺失），回退 `ColorRect` 占位，避免空引用报错。

---

## 5. 动画序列帧规范（SpriteFrames）

部分精灵是**多帧序列**（每帧一个 PNG），例如：

| 元素 | 目录 | 帧数 |
|---|---|---|
| 球 | `mcBall/` | 11 |
| 主球 | `ballMain/` | 5 |

组织方式（后续 P1/P3 落实）：

1. 用 `AnimatedSprite2D` + `SpriteFrames` 资源，将同目录帧按文件名顺序（01,02,…）加入同一动画（如 `"spin"`）。
2. 帧率参考原版（`Game.hx`/`SpriteData.hx`），先 30fps 起步。
3. 资源文件 `.tres` 置于 `android/assets/sprites/<dir>/<dir>.tres`，同名便于查找。

> 当前 MVP 为静态单帧（`mcBlock/01`、`mcPad/01`、`ballMain/ball_main0001`），动画化留待 P1/P3 打磨。

---

## 6. 导出体积控制（关键）

**结论：包体由「同步了多少精灵」决定，不能靠导出配置过滤。**

此前本节声称 `export_filter="used_resources"` 会「只导出被引用的资源」——**该结论是错的**。
Godot 4 的合法取值只有 `all_resources` / `scenes` / `resources` / `exclude` / `customized`
（见 `editor/export/editor_export.cpp`）；`used_resources` 不匹配任何分支，`export_filter`
保持默认 `EXPORT_ALL_RESOURCES`，即**全量打包**，是个静默失效的空操作。

实测（2026-08-20）：全量镜像 4113 张后 APK 从 27.0 MB 涨到 **50.7 MB**，与资产体积 24.6 MB
基本吻合，证实未发生任何过滤。配置已改为诚实的 `all_resources`。

因此体积控制改为**只同步当前阶段需要的精灵目录**（见 §2、§7），当前 176 张 / 388 KB，
APK 27.5 MB。若要用 Godot 的「只打包被引用资源」能力，需改 `export_filter="scenes"` 并显式
列出 `export_files`；但本工程精灵通过 `load("res://...")` 字符串在运行时加载，依赖扫描不保证
覆盖，故未采用。

---

## 7. P1~P10 素材消费映射（摘自建复刻计划）

| Phase | 主要素材目录 | 说明 |
|---|---|---|
| P1 核心玩法 | `mcPad/ mcBall/ mcBlock/ ballMain/` | 本管线已接好基础 3 对象 |
| P2 砖块 | `mcBlock/ mcBlockSmc/ blockMissile/ part*/` | 40+ 砖类型按 `Block.hx` 行为对照 |
| P3 球 | `el/Ball` `mcBall/ ballMain/ mcSpeederBall/` | 多球/多类型 |
| P4 增益减益 | `fx*/ ev/* mc*/` | 25+7 效果表现 |
| P5 导弹/无人机 | `mcMissile/ mcDrone/ mcQueueDrone/` | |
| P6 敌人 | `mcMonster/ mcDragon/ mcInsect/ mcLaser/ mcWarning/` | |
| P7 地图 | `worldAsteroMap/ mcMapAsteroide/ mcMapIcon*/ landerPlan*/` | 27 星球 |
| P8 经济 | `mcShop/ shopGem/ shopIcon/ mcPeople/` | |
| P9 UI | `navi/menu/* mcMenu*/ mcOption/ mcPref*/` + `fonts/` | i18n 用 `Text*.hx` 文本 |
| P10 表现力 | `part*/ fx*/ mcExplo*/ spark*/` + `Sound.hx` 逻辑 | 粒子/juice |

---

## 8. 复跑命令

```bash
# 同步已交付阶段所需精灵与字体（上游缺失时自动浅克隆）
powershell -ExecutionPolicy Bypass -File scripts/sync_assets.ps1
# 追加某阶段的精灵目录（示例：P5 导弹/无人机）
powershell -ExecutionPolicy Bypass -File scripts/sync_assets.ps1 -Dirs mcMissile,mcDrone,mcQueueDrone
# 全量镜像（4113 张 / 24.6 MB，会同等撑大 APK，见 §6）
powershell -ExecutionPolicy Bypass -File scripts/sync_assets.ps1 -All
# 构建 APK
powershell -ExecutionPolicy Bypass -File scripts/build_android.ps1
```

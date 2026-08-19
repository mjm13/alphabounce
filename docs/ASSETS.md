# Alphabounce 安卓复刻 · 资产管线（Asset Pipeline）

> 创建：2026-08-19 ｜ 关联：`document/复刻计划.md`（技术决策"直接复用 EternalTwin 的 PNG + 字体"）
> 目的：把原版/现代版素材系统化导入 Godot 工程，为 P1~P10 全部阶段提供可消费的精灵与字体。

---

## 1. 素材来源

| 来源 | 路径 | 内容 | 许可证 |
|---|---|---|---|
| 现代重写版（主参考） | `E:/Project/Self/EternalTwin-Alphabounce/frontend/src/static/images/` | **4113 张 PNG 精灵**（按元素分目录） | AGPL-3.0 |
| 现代重写版字体 | `E:/Project/Self/EternalTwin-Alphabounce/frontend/src/static/fonts/` | 5 个 woff | AGPL-3.0 |
| 原版 2007（保真对照） | `E:/Project/Self/WebGamesArchives/Alphabounce/` | FLA/SWF/i18n（如需更高保真再取） | CC BY-NC-SA 4.0 |

> **许可证立场（当前）**：个人/学习用途，直接复用 OK；衍生整体须遵守 AGPL。**发布合规（含 CC BY-NC-SA 不可商用问题）延后到 P12 处理**。

---

## 2. 工程内目录约定

```
android/
  assets/
    sprites/            # 从 EternalTwin images/ 整体镜像（子目录同名保留）
      mcPad/  mcBall/  ballMain/  mcBlock/  blockMissile/
      part*/  fx*/  mcExplo*/  spark*/
      worldAsteroMap/  landerPlan1~24/  mcShop/  mcMapIcon*/ ...
    fonts/              # 由 woff 转出的 ttf
      Digital.ttf  Verdana.ttf  Verdana-Bold.ttf
      Kiloton_Condensed_Italic_Normal.ttf  gau_font_cube_b.ttf
```

- 镜像脚本：`tools/sync_assets.py`（保留子目录、文件名空格→下划线）。
- 字体转换：`tools/convert_fonts.py`（fonttools `woff → ttf`）。

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

`android/export_presets.cfg` 已设：

```
export_filter="used_resources"
```

含义：**只导出被场景/脚本实际引用的资源**。因此虽然工程里躺着 4113 张 PNG，APK 仅包含当前用到的几张（砖/板/球），不会撑大包体。新增素材后只要被引用即自动入包，未引用自动忽略。

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
# 重新同步素材（源有更新时）
python tools/sync_assets.py
# 重新转换字体（源有更新时）
python tools/convert_fonts.py
# 构建 APK（含自动导入被引用资源）
bash tools/build_android.sh
```

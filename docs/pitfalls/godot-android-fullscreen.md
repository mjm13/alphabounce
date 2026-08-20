# Pitfall：Godot 4 安卓横屏满屏与 letterbox

> 来源需求：`20260818214301-AB-P1核心玩法MVP`（2026-08-20）

## 触发条件

- Godot 4 安卓导出使用预构建模板（`gradle_build=false`）
- 期望横屏铺满、无黑边/letterbox
- 使用 `stretch/mode=viewport` 或依赖 `display/window/handheld/immersive_mode`

## 结论 / 规避

1. **`immersive_mode` 为死配置**：Godot 4.7.1 安卓层不读取 `project.godot` 的 `display/window/handheld/immersive_mode`，勿指望该键消除系统栏 inset。
2. **`viewport` 模式 letterbox**：预构建模板上根视口不 resize，`stretch/mode=viewport` 易出现黑边。
3. **推荐组合**：`stretch/mode=canvas_items` + `stretch/aspect=expand` + `export_presets.cfg` 的 `command_line/extra_args="--fullscreen"`（引擎初始化即 FULLSCREEN，早于模板 Runnable）。
4. **安全带布局**：`expand` 会裁边，挡板/砖块/HUD 须用 `get_viewport_rect().size` 实时计算位置（例：挡板 `vps.y×0.82`、砖块 `start_y=200`、HUD `y≥110`）。
5. **诊断**：运行时打印 VP / win / disp / stretch / aspect 签名，便于真机对比。

## 可复跑验证

```bash
bash tools/build_android.sh
adb install -r android/build/alphabounce-debug.apk
```

## 修订记录

| 日期 | 说明 |
| --- | --- |
| 2026-08-20 | P1 Gate-3 沉淀（真机 VP=2338×1080 满屏验收） |

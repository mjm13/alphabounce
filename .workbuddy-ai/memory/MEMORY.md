# MEMORY.md — Alphabounce 安卓复刻（Godot 4）

## 工程基线
- 根：`android/`；技术栈 Godot 4.7.1（GDScript）+ 安卓导出；纯单机无后端。
- 工具链本地不入库（`tools/` gitignore）：Godot 二进制 + JDK17(Temurin 17.0.20) + Android SDK(cmdline-tools 12.0, platform-tools, build-tools;34.0.0, platforms;android-34) + debug keystore。
- 调试 keystore 密码不入库：存 `android/keystore.local.env`(gitignore)，export_presets.cfg 只引用路径。
- 旧工作盘 E: 已卸载，E: 上的工具链与过期 Gate-2 结论不可直接复用；新工作一律在 D:，从零重建。
- 沙箱执行环境与宿主 D: 隔离：沙箱写入不保证落盘（关键写操作用 `dangerouslyDisableSandbox=true`），沙箱无 USB 透传（真机 adb 必须在宿主终端跑）。

## Godot 4 安卓导出命令（坑）
- `godot --headless --path <工程根> --export-debug "Android" <输出.apk>` 的**输出路径必须绝对路径**。`--path` 把工程根切到 `<工程根>`，相对路径会解析成 `<工程根>/<rel>`，报"目标文件夹不存在或无法访问"。
- Godot 4.7 APK 内嵌 `assets/project.binary`（编译后的 project.godot），不是文本。确认 `project.godot` 改动生效：`unzip -p <apk> assets/project.binary | grep -aoE "<key>"`。导出预设的命令行参数在 `assets/_cl_`：`unzip -p <apk> assets/_cl_ | tr -c '[:print:]' ' '`（查 `--fullscreen` 等；`strings` 命令在 Windows 不可用，用 `tr` 替代）。
- APK 验签用 `.bat`：`build-tools/34.0.0/apksigner.bat verify --verbose <apk>`（同目录无 `.exe`）。
- 预构建模板导出（`export_presets.cfg` 里 `gradle_build/use_gradle_build=false` + `custom_template/debug`/`release` 指向官方 `android_debug.apk`/`android_release.apk`）跳过 Gradle 联网拉依赖，代理/离线环境首选。代价：APK 包名锁模板默认 `com.example.alphabounce`；正式 `org.godotengine.alphabounce` 要 P12 切 Gradle 改写 manifest。
- ETC2/ASTC 强约束：`project.godot` 的 `[rendering]` 必须 `textures/vram_compression/import_etc2_astc=true`，否则报"导出 Android 版本需要 ETC2/ASTC 纹理压缩格式"。
- 渲染后端：`renderer/rendering_method="gl_compatibility"` + `renderer/rendering_method.mobile="gl_compatibility"`（GL Compatibility 是安卓模板默认）。

## 屏幕适配（letterbox 防治）
- `project.godot` **必须**有 `[display]` 段，否则 viewport 走默认 1152×648，与非默认分辨率场景（典型 1920×1080）一起会等比缩放产生 letterbox（游戏区只占屏幕一角）。
- 打砖块/街机类满屏（无黑边无裁切）：**`window/stretch/mode="canvas_items"` + `window/stretch/aspect="expand"`**——`expand` 会**把根视口 resize 到匹配屏宽高比**（实测 2772×1280 屏上 VP=2338×1080，宽高比与屏一致），内容真实填满屏幕、无黑边、无 GPU letterbox。布局用 **比例/安全带** 锚定（挡板 y = VP.y × 0.82、HUD 落到设计 y ≥ 约 0.1×VP.y、砖块 start_y ≈ 200、MessageLabel 收窄到 0.6×VP.y 高），避免关键元素被裁。⚠️ **不要用 `stretch/mode="viewport"`**：在 Godot 4 安卓预构建模板上 viewport 模式**不会**把根视口 framebuffer resize 到全屏（实测 VP 锁在 1920×1080、Win=Disp=2772×1280），GPU 缩放器按 aspect 把固定画布投到物理屏 → keep 左右 letterbox、expand 名义填满但底/顶被裁、忽略则拉伸变形。⚠️ **也不要 `canvas_items`+`aspect="keep"`**：宽于 16:9 的手机横屏以左右 letterbox 保比例（用户实测"左右还是有空白"）。诊断方法：在 HUD 实时打印 `VP/Win/Disp/stretch/aspect`，`VP 锁在 1920x1080 但 Win=Disp=物理全屏` 就是 viewport 模式踩坑的标志；`VP 宽高比=屏宽高比` 才是 expand 真正满屏的标志。
- 写实/剧情类要保比例：`stretch/aspect="keep"`（保留比例，可能留黑边）。
- **沉浸式隐藏导航栏（横屏右侧竖条）【勘误】**：Godot 4.7.1 安卓层 Kotlin 化（`GodotActivity.kt`/`Godot.kt`）。模板 `GodotApp` 的 `updateWindowAppearance` Runnable（onGodotMainLoopStarted/onResume）以 `enableImmersiveMode(isInImmersiveMode(), override=true)` 触发；`useImmersive=false` 时会 `setDecorFitsSystemWindows(true)` 撤销 edge-to-edge，SurfaceView 被 inset 到系统栏右侧。**真正修复**：`export_presets.cfg` 加 `command_line/extra_args="--fullscreen"`，引擎初始化即 FULLSCREEN（早于 Runnable），避免回退 inset。`display/window/handheld/immersive_mode` 在 Godot 4.7.1 为**死配置**（引擎不读，已删除）。`main.gd` 运行时 `WINDOW_MODE_FULLSCREEN` 作兜底。**无需切 Gradle 构建，无需 SDK36**。
- 真机自测是唯一可靠验证（PC 预览默认窗口大小可能掩盖问题）；流程：`adb install -r` → `am start` → 看首屏是否铺满。

## 包名与 Activity
- 当前（预构建模板）：包名 `com.example.alphabounce`，启动 Activity `org.godotengine.godot.GodotApp`。
- 启动命令：`adb shell am start -n com.example.alphabounce/org.godotengine.godot.GodotApp`
- P12 Gradle 构建后可改 `org.godotengine.alphabounce`。

## GDScript 坑
- **`class_name` 跨脚本类型解析失败**：Godot 4 headless/导出场景下，新脚本的 `class_name X` 全局类型常无法在另一脚本解析（`Parse Error: Could not find type "X"`）。**改用 `preload("res://.../X.gd")` 常量 + 不依赖跨脚本强类型注解**：管理器里 `const XScript := preload(...)`，用 `XScript.new()` 创建实例；跨脚本访问对方自定义属性/方法时，先 `as Node2D` 以满足 `is_in_group`/`global_position` 等 Node 方法，自定义属性用 `obj.get("prop")`、方法用 `obj.call("method")`。
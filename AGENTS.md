# AGENTS.md — Alphabounce_M

> [agents.md](https://agents.md/) 格式。本文每轮进上下文，因此只放**每轮都用得到**的运行时事实与可执行命令；领域细节走渐进披露（`docs/llms.txt` 文档路由、`.cursor/rules/*`、skills）。xijia 门禁见 `.cursor/rules/00-workflow.mdc`。Gate-3 **有限度**增量维护（先就地替换，再考虑新增）；未命中写 `Living Docs: no-op`。

<!-- 追加限度（勿删；细则见 docs/process/knowledge-maintenance.md）：1) 同一事实已在文中 → 改写原句，不新增段落；2) 仅单一领域/阶段需要 → 写入对应 doc 或 rule，此处只留一行指针；3) 新增 ≥3 行时同轮评估能否下沉等量旧内容；4) 禁止镜像目录树、代码文件清单、文档树路由。 -->

## Project overview

Godot 4.x 版 AlphaBounce 游戏项目，将 Haxe/Pixi.js 源码完整重构为 GDScript，支持 Android 平台。

- **Initial modules**：物理系统、方块系统、任务系统、敌人系统、UI系统
- **Stack**：Godot 4.2+ / GDScript / Android Export
- **Maintainer**：EternalTwin Team
- **Backend root**：无（离线单机游戏）
- **Frontend root**：game/
- **UI reference**：<待补充：无外部原型；参考 EternalTwin-Alphabounce 视觉风格>
- **能力 → 代码坐标**：<待补充，或链接 `docs/capability-map.md`>（目录与入口读代码即得，本文不镜像）

## Dev environment tips

- 命令须在 `game/` 目录执行
- Godot Editor 打开 `game/` 目录即可开始开发
- 触摸控制优先于虚拟按钮
- 日常需求入口：`/xijia:start`

## Build and test commands

```bash
# 打开 Godot Editor
godot --path game --editor

# 运行测试
godot --path game --headless --build-sceens tests/test_suite.tscn

# 导出 Android Debug APK
godot --path game --export-debug "Android"

# 导出 Android Release AAB
godot --path game --export-release "Android"

# 安装到设备
adb install -r game/bin/android_debug.apk
```

**CI**：暂无（本地开发为主）；命令须与上文一致。

## Testing instructions

- 改代码后运行上文 **Build and test commands** 中对应 test 命令，直至通过再提请验收
- 测试栈：Godot 内置 Test Framework
- 约定：Gate-1 切片实现期间按需求切片 `Test:`/`Done:` 测；**全量测试**仅最后一切片或 regression
- Mock 边界：禁止 mock 物理引擎；允许 mock 数据配置

## Agent coding behavior（实现阶段）

本节只写**本项目特有**的实现期约定，范围为已获 Gate-1 批准后的写代码 diff；Gate-0~3、破坏性 DB、发布门禁优先。通用编码素养与变更边界见 `.cursor/rules/41-change-boundary.mdc`。

**取舍顺序**（停在第一个可行项）：Gate-1/AC 范围内？→ 代码库已有可复用？→ Godot 内置功能？→ 最小 diff。**不新增**未在 Gate-1 批准的依赖。

**不简化**：物理稳定性、防卡死处理、触摸响应延迟优化、Gate-2 要求的测试证据。

**Bug 修复**：优先在共享函数/服务处修一次（查全部 caller），不顺手重构无关代码。

### Gate-1 切片 verify 顺序（实现阶段）

1. **禁止**在首个切片未完成前运行全量测试（见 **Build and test commands** 中全量命令）
2. **顺序**：单文件/单模块测 → 场景测试 → 最后全量 + guard
3. 测试命令须**前台**执行（Godot Test Runner 阻塞等待）
4. 物理改动后，先跑最小 smoke，再扩全量

## Observability

> Godot 输出通过 Editor Output 面板或 Logcat（Android）查看。

- **Log format**：Godot 默认格式
- **Required fields**：自动包含时间戳
- **Correlation**：<待补充：trace_id 用于多设备调试>
- **Redaction**：<待补充：敏感数据脱敏>

## Security

- **Secrets**：无（离线游戏）
- **High-risk operations**：存档文件读写见 `.cursor/rules/22-db-destructive-safety.mdc`
- **Do not modify without approval**：见 `.cursor/rules/00-workflow.mdc`「Approval Gates」

## Commit and PR instructions

- 提交规范：`type(scope): description`
  - `feat: add ball physics system`
  - `fix: resolve collision detection bug`
  - `chore: update project settings`
- Gate-2 收尾：`python .cursor/hooks/pipeline_guard.py --check-release --req <requirement-file>`
- Gate-3 归档：`python .cursor/hooks/pipeline_guard.py --check-closeout --req <shipped-requirement>`
- 合并前检查：上文 **Build and test commands** 的 test 全绿

## Xijia workflow

| 场景 | 入口 |
| --- | --- |
| 推进需求（默认） | `/xijia:start` 或自然语言 → `xijia-feature-pipeline` |
| 工程基线（init 后首批） | inbox 种子需求 |
| 登记缺陷 | `/xijia:defect` |
| 项目速览 | `/xijia:overview` |

其余入口（`/xijia:adopt`、`/xijia:prd`、`/xijia:release`、`/xijia:backfill-index`、`/xijia:status`）与阶段对照见 `docs/process/project-lifecycle.md`。

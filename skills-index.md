# DSH 技能索引 — 从 .cursor 加载的技能规则

本文档汇总了从 `.cursor/skills/` 目录加载的所有技能规则，供 DeepSeek Harness (DSH) 使用。

---

## 技能列表

### 1. brainstorming
**文件**: `.cursor/skills/brainstorming/SKILL.md`
**描述**: 创意工作前的设计探索技能
**核心规则**:
- 必须先探索项目上下文
- 视觉相关问题时提供 visual companion
- 一次只问一个问题
- 提出 2-3 个方案并给出推荐
- 分节展示设计并获得用户批准
- 写入设计文档到 `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
- **硬门禁**: 在用户批准设计前不得调用任何实现技能

---

### 2. dispatching-parallel-agents
**文件**: `.cursor/skills/dispatching-parallel-agents/SKILL.md`
**描述**: 并行任务分发
**核心规则**:
- 3+ 个独立失败的测试文件时使用
- 每个问题域分配一个 agent
- Agent 之间不能有共享状态
- 不相关的问题可以并行调查
- 故障相关时需一起调查

---

### 3. executing-plans
**文件**: `.cursor/skills/executing-plans/SKILL.md`
**描述**: 执行已编写的实现计划
**核心规则**:
- 开始前声明: "我正在使用 executing-plans 技能"
- 先读取计划文件并批判性审查
- 遇到问题立即停止并询问
- 完成后调用 finishing-a-development-branch 技能

---

### 4. receiving-code-review
**文件**: `.cursor/skills/receiving-code-review/SKILL.md`
**描述**: 接收代码审查反馈
**核心规则**:
- 验证后再实现，不要盲目执行
- 外部反馈 = 建议而非命令
- 不清除时先询问澄清
- 禁止表演性同意 ("You're absolutely right!")
- 技术正确性 > 社交舒适度
- YAGNI 检查: 未使用的功能不应添加

---

### 5. requesting-code-review
**文件**: `.cursor/skills/requesting-code-review/SKILL.md`
**描述**: 请求代码审查
**核心规则**:
- 完成每个任务后必须请求审查
- 主要功能完成前必须审查
- 合并到 main 前必须审查
- 使用 code-reviewer subagent 进行审查

---

### 6. subagent-driven-development
**文件**: `.cursor/skills/subagent-driven-development/SKILL.md`
**描述**: 子 agent 驱动开发
**核心规则**:
- 每个任务分发独立的 subagent
- 每任务两阶段审查: spec 合规 → 代码质量
- 使用最小可用模型以节省成本
- Implementer 状态处理: DONE / DONE_WITH_CONCERNS / NEEDS_CONTEXT / BLOCKED
- 禁止在主分支上开始实现
- 禁止跳过审查

---

### 7. systematic-debugging
**文件**: `.cursor/skills/systematic-debugging/SKILL.md`
**描述**: 系统性调试
**核心规则**:
- **铁律**: 先找到根因再尝试修复
- 四阶段流程:
  1. 根因调查
  2. 模式分析
  3. 假设和测试
  4. 实现
- 3+ 次修复失败后质疑架构
- 禁止跳过 Phase 1

---

### 8. test-driven-development
**文件**: `.cursor/skills/test-driven-development/SKILL.md`
**描述**: 测试驱动开发
**核心规则**:
- **铁律**: 没有失败测试就不写生产代码
- Red-Green-Refactor 循环
- 先写测试，看它失败，写最少代码让它通过
- 禁止在测试后写代码
- 每个新函数/方法必须有测试
- 必须看到测试失败过才能信任它

---

### 9. using-superpowers
**文件**: `.cursor/skills/using-superpowers/SKILL.md`
**描述**: 技能使用入口
**核心规则**:
- 任何可能适用技能的场景必须先调用 skill 工具
- 1% 可能性也要调用
- 用户指令 > 技能规则 > 系统默认
- 技能按优先级: 流程技能 > 实现技能

---

### 10. writing-plans
**文件**: `.cursor/skills/writing-plans/SKILL.md`
**描述**: 编写实现计划
**核心规则**:
- 假设工程师对项目零上下文
- bite-sized 任务粒度 (2-5 分钟一步)
- 禁止占位符 (TBD, TODO, "类似 Task N")
- 每步包含实际代码和命令
- 完成后提供执行选择: subagent-driven 或 inline

---

### 11. verification-before-completion
**文件**: `.cursor/skills/verification-before-completion/SKILL.md`
**描述**: 完成前验证
**核心规则**:
- **铁律**: 没有新鲜验证证据不得声明完成
- 执行门: 识别命令 → 运行 → 读取输出 → 验证
- 禁止使用 "should", "probably", "seems to"
- 代理报告不能替代独立验证

---

### 12. openspec-explore
**文件**: `.cursor/skills/openspec-explore/SKILL.md`
**描述**: 探索模式
**核心规则**:
- 思考伙伴，不实现
- 可以自由阅读文件和调查代码库
- 禁止写代码或实现功能
- 可以使用 ASCII 图表可视化
- Spike 模式用于需求不清时

---

### 13. openspec-propose
**文件**: `.cursor/skills/openspec-propose/SKILL.md`
**描述**: 提议新变更
**核心规则**:
- 一次性生成所有工件
- proposal.md, design.md, tasks.md
- 切片化命名: 端到端薄切片

---

### 14. openspec-apply-change
**文件**: `.cursor/skills/openspec-apply-change/SKILL.md`
**描述**: 实施 OpenSpec 变更
**核心规则**:
- 按任务顺序实施
- 保持最小和聚焦的变更
- 完成每任务后标记 checkbox

---

### 15. openspec-archive-change
**文件**: `.cursor/skills/openspec-archive-change/SKILL.md`
**描述**: 归档已完成的变更
**核心规则**:
- 检查工件完成状态
- 检查任务完成状态
- 同步 delta specs (可选)
- 移动到 archive 目录

---

### 16. openspec-sync-specs
**文件**: `.cursor/skills/openspec-sync-specs/SKILL.md`
**描述**: 同步 delta specs 到主 specs
**核心规则**:
- 智能合并而非程序化合并
- 保留未提及的内容
- 幂等操作

---

### 17. xijia-project-init
**文件**: `.cursor/skills/xijia-project-init/SKILL.md`
**描述**: 项目初始化
**核心规则**:
- 仅用于空仓库
- 硬门禁: 非空仓库停止
- 技术栈必须用户确认
- 技能安装上限: 10 个
- 禁止实现业务代码

---

### 18. xijia-project-adopt
**文件**: `.cursor/skills/xijia-project-adopt/SKILL.md`
**描述**: 历史项目采用
**核心规则**:
- 多模块工作区接入
- scaffold → preflight → discover → content → verify
- 禁止覆盖活文档
- 硬门禁: 无 `.cursor/rules/` 时阻止

---

### 19. xijia-ddd-modeling
**文件**: `.cursor/skills/xijia-ddd-modeling/SKILL.md`
**描述**: DDD 建模
**核心规则**:
- 业务语义沉淀为可校验契约
- 每个聚合至少 1 条 INV-xxx 不变量
- propose-not-mint: AI 不得自主铸造最终定义
- 仅 business/hybrid 类型进入

---

### 20. hallmark
**文件**: `.cursor/skills/hallmark/SKILL.md`
**描述**: UI 设计技能 (反 AI slop)
**核心规则**:
- 结构多样性 > 视觉多样性
- 6 大纪律: 自我批评、诚实内容、锁定 tokens、禁止重绘 chrome、移动响应式、纯排版
- Design flow 包含 macrostructure 选择和 theme 轮换
- 组件作用域 vs 页面作用域
- 58 个 slop-test gates

---

## 命令映射

| 命令 | 对应技能 |
|------|----------|
| `/xijia:init` | xijia-project-init |
| `/xijia:adopt` | xijia-project-adopt |
| `/xijia:start` | xijia-ops-pipeline |
| `/opsx:explore` | openspec-explore |
| `/opsx:propose` | openspec-propose |
| `/opsx:apply` | openspec-apply-change |
| `/opsx:archive` | openspec-archive-change |
| `/opsx:sync` | openspec-sync-specs |

---

## 脚本工具

| 脚本 | 路径 | 用途 |
|------|------|------|
| memory_prune.py | `.cursor/skills/xijia-memory/scripts/` | 过期记忆条目归档 |
| memory_lint.py | `.cursor/skills/xijia-memory/scripts/` | 记忆 lint 检查 |
| validate_domain_contracts.py | `.cursor/skills/xijia-ddd-modeling/scripts/` | DDD 契约验证 |
| run_skill_evals.py | `.cursor/skills/evals/scripts/` | 技能路由评估 |

---

## 加载方法

在 DSH 中加载这些技能:

```python
from deepseek_harness import SkillLoader

loader = SkillLoader()
loader.load_from_cursor_skills('.cursor/skills/')
```

或在对话中使用:
```
load skill: brainstorming
load skill: test-driven-development
load skill: systematic-debugging
```

---

*生成时间: 2025*

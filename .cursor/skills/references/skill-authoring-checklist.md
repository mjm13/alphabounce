# xijia 技能作者检查表

对照 Matt Pocock `writing-great-skills`（可预测性优先），约束本仓库 **自建** `xijia-*` 技能。命名硬约束见 [`.cursor/rules/07-xijia-skill-naming.mdc`](../../rules/07-xijia-skill-naming.mdc)。

上游 Superpowers / OpenSpec 技能不在本表范围。

## 根美德

**Predictability**：同一技能每次走同一过程（步骤 + 完成标准），不要求输出字节相同。

## 1. Invocation（调用轴）

- [ ] 默认 **model-invoked**（保留 `description`）；Cursor 下暂不依赖 `disable-model-invocation`
- [ ] 仅当 agent 必须自触发、或其它技能须 reach 时，才付 description 的 **context load**
- [ ] 稀有人工入口优先 `/xijia:*` 命令，而不是再拆一个常驻 description 技能
- [ ] **不扩大粒度**：不为「模块化观感」新增一批常驻 model-invoked 技能

## 2. Description CSO（触发层）

- [ ] 以 `Load when …` 开头；写触发分支，不写能力说明书
- [ ] **禁 workflow-in-desc**：不得出现 Orchestrates / Outputs / 步骤摘要 / End-to-end 流程复述
- [ ] **One trigger per branch**：同义 NL 塌缩；禁止 ops 与 feature-pipeline 双载同一批 NL
- [ ] 预算（见 `07` 规则）：
  - 高频 model-invoked ≤ ~120 字符
  - 命令驱动 ≤ ~80 字符（以 `/xijia:*` 为主 + 1–2 互斥词）
  - Alias 极短（如 feature-pipeline）
- [ ] 改 description 前先改 [`evals/skill-routing.eval.yaml`](../evals/skill-routing.eval.yaml)，再跑：
  ```bash
  python .cursor/skills/evals/scripts/run_skill_evals.py
  ```

## 3. Information hierarchy（正文层级）

- [ ] `SKILL.md` 只留**全分支共用**步骤 + 强措辞 context pointer
- [ ] 分支专属 / 长表 / 模板 → `references/<topic>.md`（一跳可达，不深链）
- [ ] 主文建议 ≤ ~100 行；超过则披露而非堆砌
- [ ] Pointer 用硬措辞：`进入 X 前**必须** Read references/…`，避免弱「详见」

## 4. Completion criterion（完成标准）

- [ ] 主路径每步结尾有可判定条件
- [ ] 优先：命令 exit 0 / 文件证据 / `--resolve-gate=` 输出 / frontmatter 字段
- [ ] 格式统一：`完成：…`
- [ ] 模糊「理解清楚」类标准必须改写或拆步

## 5. Leading words（已有词优先）

优先复用，勿另造：`Gate`、`closeout`、`GOTCHAS`、`verify`、`Move`、`no-op`（禁词场景）、`intake`。

## 6. Prune（剪枝）

- [ ] **SSOT**：同一含义只在一处维护（技能正文 vs references vs rule）
- [ ] 句级 **no-op** 测试：删后行为不变则整句删除
- [ ] **negation**：硬护栏外改正向目标；硬禁令须并列正向动作
- [ ] GOTCHAS 用「症状 | 根因 | 修复」，正文不重复同一禁令堆

## 7. Failure modes 自检

| 模式 | 自问 |
| --- | --- |
| Premature completion | 后续步骤是否可见且完成标准模糊？ |
| Duplication | 同义触发 / 同段正文是否双份？ |
| Sediment | 是否引用已删文件或空目录？ |
| Sprawl | 主文是否 >100 行且可披露？ |
| No-op | 是否在教模型默认就会做的事？ |
| Negation | 「禁止 X」能否改为「须做 Y」？ |

## 8. SOP — 新建技能

1. 确认需要技能（判断调用 / 不可正则强制）而非仅 rule/脚本
2. 命名：目录 = `name:` = `xijia-<kebab>`
3. 先写 routing eval case（RED）→ 再写 description/body（GREEN）
4. `SKILL.md`：步骤 + `完成：`；>100 行或分支材料 → `references/`
5. `python .cursor/skills/evals/scripts/run_skill_evals.py`
6. 若改流程交叉文件：`python .cursor/hooks/policy_flow_drift_check.py`
7. 新失败模式 → 更新 [`gotchas-index.md`](gotchas-index.md) + 目标技能 GOTCHAS

## 9. SOP — 修改已有技能

1. 标明改动轴：`invocation` | `hierarchy` | `steering` | `prune`
2. 改 description：先 eval 期望 → 再 desc → 再 `run_skill_evals.py`
3. 拆 references：主文只留 pointer + 全分支必需步骤；禁止双份正文
4. `python .cursor/skills/evals/scripts/audit_skill_metrics.py`：desc/lines/negation 不得无说明回退
5. 相关 pitfall / GOTCHAS 同行更新

## 10. SOP — 季度/批次剪枝（随 `/xijia:release` 或每月）

风格指标只能发现「写得啰嗦」，发现不了「赌注已到期」。两类判据都要跑：

**A. 风格层**

1. `python .cursor/skills/evals/scripts/audit_skill_metrics.py`
2. 对 TOP sprawl / TOP negation / OVER_DESC 做句级删除
3. 确认无 workflow-in-desc、无双载触发

**B. 到期层**（判别式与步骤见 `xijia-policy-drift-check`「到期审计」）

4. 逐条问 `defends` 写的失败**现在还复现吗**；不复现 → 删除候选，标注「不到期」的 L3 条目跳过
5. 能表达成 guard / 测试 / lint 的条目 → 下沉工具层后从指令层删除
6. 抽 2–3 条真实会话做消融对照：无技能基线 vs 有技能（writing-skills TDD）；删前删后各跑 `run_skill_evals.py` + `pytest .cursor/hooks/tests -q`，无回归才落地

> 敢删的前提是有裁判。本仓库的裁判是 evals + hooks tests + guard，不是判断力。

## 11. 与门禁衔接

- 改 skills/rules/commands 后宣称「流程已同步」→ `xijia-policy-drift-check`
- Gate-3 新 pitfall → 目标技能 GOTCHAS + gotchas-index
- 优化技能时不得放宽 Gate 硬停或改业务需求语义

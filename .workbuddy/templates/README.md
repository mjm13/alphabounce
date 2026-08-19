# 公共模板区（`.cursor/templates/`）

跨技能 / 规则引用的模板 **唯一 SSOT**。日常流程 Read 或复制本目录文件，**禁止**在 `docs/requirements/` 再维护 `*-template.md` 副本。

## 迁入判定

| 条件 | 位置 |
| --- | --- |
| ≥2 个技能、命令或 `.cursor/rules` 引用 | **本目录**（当前仅 `requirements/`） |
| 仅单一技能 `references/` 自用 | 留在该技能（如 `gate0-closed-loop.md`） |
| init/adopt 一次性渲染到 `docs/` 的基座 | 仍在 `xijia-project-init/templates/`（scaffold，非 copy 骨架） |

## `requirements/` — inbox 复制骨架 + Gate 字段

| 文件 | 用途 | 入口 |
| --- | --- | --- |
| [`requirements-template.md`](requirements/requirements-template.md) | 业务/混合 PRD | `/xijia:prd` |
| [`technical-requirement-template.md`](requirements/technical-requirement-template.md) | 纯技术需求 | 技术诉求立项 |
| [`defect-template.md`](requirements/defect-template.md) | 缺陷登记 | `/xijia:defect` |
| [`gate1-plan-template.md`](requirements/gate1-plan-template.md) | Gate-1 字段骨架 | prd / A.0.5 |
| [`section-fragments.md`](requirements/section-fragments.md) | 按需 H2 片段 | 落盘时插入 |
| [`gate0-intake.md`](requirements/gate0-intake.md) | Gate-0 程序细节 | intake / refinement |
| [`gate1-by-tier.md`](requirements/gate1-by-tier.md) | Gate-1 按分档落盘 | `/xijia:prd` |

结构校验真相源：[`45-requirement-intake.mdc`](../rules/45-requirement-intake.mdc)（inbox 实例仍在 `docs/requirements/inbox/`）。

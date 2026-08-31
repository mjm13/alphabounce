# Progression 领域模型

限界上下文：Progression（任务/进度子域）。
来源需求：`20250101130004-任务系统`（R05，混合 / 黄档）。

## 聚合与实体

- **Mission（任务聚合根）**：`mission_id` / `title` / `cond_type` / `cond_value` / `reward`
- **MissionData（任务配置 Resource）**：由 JSON 解析构造（`MissionData.from_dict`）
- **MissionManager（Autoload 单例 / 任务状态机）**：持有 `missions: Array[MissionData]` 与 `status: Dictionary`

## 状态枚举

| 值 | 含义 |
|---|---|
| -1 | 未开始 |
| 0  | 进行中 |
| 1  | 已完成 |

## 条件类型（cond_type）

- `COMPLETE_LEVEL`：完成关卡数 `level >= cond_value`
- `COLLECT_BLOCKS`：消除方块数 `blocks_cleared >= cond_value`
- `REACH_SCORE`：累计得分 `score >= cond_value`

## 不变量（INV）

- **INV-001**：任务状态单调推进（-1 → 0 → 1），禁止回退或跳级。
- **INV-002**：条件检查仅在 `level_complete` 信号后由 `MissionManager.check_conditions(ctx)` 触发，不在每帧轮询。
- **INV-003**：奖励仅记录到任务状态（字段 `reward`），实际发放由 R06 商店系统消费；本切片不修改背包/库存。

## 信号

- `missions_loaded`：任务集加载完成
- `mission_updated(mission_id, new_status)`：单个任务状态变更

# 能力追溯索引（Capability Map）

> 行主键：`moduleKey` + `前端入口`（normalize 后）。Gate-3 **动态合并**（ADD/UPDATE/DEPRECATE），禁止同主键重复行。
> 操作级细节真相源：各 `docs/requirements/shipped/*` 需求「数据流闭环表」。

| 模块 | moduleKey | 前端入口 | 后端能力 | 相关表 | 来源摘要 | 去向摘要 | 状态 | 需求来源 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 任务加载 | 任务加载 | — | JSON 解析 → Mission 对象 | missions | resources/missions/*.json | MissionManager.missions | active | docs/requirements/shipped/20250101130004-任务系统.md |
| 任务面板渲染 | 任务面板渲染 | — | UI 绑定 → Label/Button 更新 | — | MissionManager 状态 | MissionPanel.tscn | active | docs/requirements/shipped/20250101130004-任务系统.md |
| 变形 | 变形 | frontend/src/haxe/ev/ | `block.damage()` | 关卡可通 | 导弹碰撞 | 关卡可通 | active | docs/requirements/shipped/20250101130007-敌人系统.md |
| 变形 | 变形 | 事件敌人生成 | EnemyManager 实例化 | World | `Block.*` 击碎 / Option | World 节点 | active | docs/requirements/shipped/20250101130007-敌人系统.md |
| 变形 | 变形 | 敌人移动 | `_physics_process` | position | 状态机 | position | active | docs/requirements/shipped/20250101130007-敌人系统.md |
| 变形 | 变形 | 玩家受伤 | `PlayerData.lives-=1` | Game | 敌/闪电/Molecule 碰玩家 | Game Over | active | docs/requirements/shipped/20250101130007-敌人系统.md |
| 变形 | 变形 | 球-敌碰撞 | `enemy.hit()`/`mon.damage()` | 生命值 | ball body_entered | 生命值 | active | docs/requirements/shipped/20250101130007-敌人系统.md |
| 条件检查 | 条件检查 | — | check_conditions() | — | MissionManager + Game 状态 | mission.status 更新 | active | docs/requirements/shipped/20250101130004-任务系统.md |

## 修订记录

| 日期 | 操作 | 主键 | 需求来源 | 说明 |
| --- | --- | --- | --- | --- |
| 2026-08-30 | ADD | 任务加载&#124;— | docs/requirements/shipped/20250101130004-任务系统.md | new capability from docs/requirements/shipped/20250101130004-任务系统.md |
| 2026-08-30 | ADD | 条件检查&#124;— | docs/requirements/shipped/20250101130004-任务系统.md | new capability from docs/requirements/shipped/20250101130004-任务系统.md |
| 2026-08-30 | ADD | 任务面板渲染&#124;— | docs/requirements/shipped/20250101130004-任务系统.md | new capability from docs/requirements/shipped/20250101130004-任务系统.md |
| 2026-08-30 | ADD | 变形&#124;事件敌人生成 | docs/requirements/shipped/20250101130007-敌人系统.md | new capability from docs/requirements/shipped/20250101130007-敌人系统.md |
| 2026-08-30 | ADD | 变形&#124;frontend/src/haxe/ev/ | docs/requirements/shipped/20250101130007-敌人系统.md | new capability from docs/requirements/shipped/20250101130007-敌人系统.md |
| 2026-08-30 | ADD | 变形&#124;敌人移动 | docs/requirements/shipped/20250101130007-敌人系统.md | new capability from docs/requirements/shipped/20250101130007-敌人系统.md |
| 2026-08-30 | ADD | 变形&#124;球-敌碰撞 | docs/requirements/shipped/20250101130007-敌人系统.md | new capability from docs/requirements/shipped/20250101130007-敌人系统.md |
| 2026-08-30 | UPDATE | 变形&#124;frontend/src/haxe/ev/ | docs/requirements/shipped/20250101130007-敌人系统.md | columns changed via docs/requirements/shipped/20250101130007-敌人系统.md |
| 2026-08-30 | ADD | 变形&#124;玩家受伤 | docs/requirements/shipped/20250101130007-敌人系统.md | new capability from docs/requirements/shipped/20250101130007-敌人系统.md |

# Debug Fixtures 约定

本目录存放各需求 debug 场景的上游 mock 数据，解决依赖扇入（详见 `execution-plan.md` §3 Mock 解耦规则）。

## Mock 数据清单（依赖未就绪时使用）

- `levels.json`：关卡数据（由「关卡内容设计」需求产出，字段对齐 `Level.hx`）
- `mission_demo.json`：任务数据（替 R16 `missions.json`）
- `shop_demo.json`：商店商品（替 R16 `shop.json`）
- `save_demo.json`：存档样例（替 R16 存档 schema）
- `enemy_demo.json`：敌人配置（替 R16 `enemies.json`）
- `block_demo.json`：方块类型全量（替 R16 `blocks.json`）
- `physics_demo.json`：原版物理常量对照（R17 用）

## 约定

1. 字段结构必须与正式 schema（ADR-002 / ADR-003）一致。
2. 正式数据就绪后仅替换数据源，不改 debug 场景逻辑。
3. 不要求联网或服务端。

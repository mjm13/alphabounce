# 多篇 inbox 并存规则

## `/xijia:start` 与 active-req

1. **用户指定 path/文件名** → 仅对该篇输出 CTA（`--resolve-gate --req <path> --format cta`）
2. **未指定** → 仅输出指定提醒（`--resolve-gate --format cta`，无 `--req`）；**禁止** auto-pick 并展开单篇 Gate CTA
3. **禁止** 单独用 mtime 选篇

`--scan-inbox` 仅供 `/xijia:status`、诊断或未指定时的 inbox 一行摘要数据源：

```powershell
python .cursor/hooks/pipeline_guard.py --scan-inbox
```

## Gate-1 批准

- **逐篇**文字批准；禁止「批准全部 N 篇」单次口令
- 每篇批准后同轮进入该篇实现；未批准篇保持 Gate-1 待批准

## 并行禁止

- 同一 worktree **同时仅一篇**处于「实现」态
- 切换需求前须完成当前篇 verify/Gate-2，或用户显式指定新 path

## 批量 PRD 交付顺序

- 技能层仅给 **依赖提示**（如 oper-log 依赖 config/dict 写接口），不自动排序
- 用户在 Gate-1 时选择下一篇；Gate-1 附录可注明 full path

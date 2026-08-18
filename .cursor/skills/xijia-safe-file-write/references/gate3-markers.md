# Gate-3 沉淀标记模板

写「实现记录与沉淀（Gate-3）」标记前**必须** Read 本文件。

## 标记措辞

- `updated(...)` / 说明文字中**勿出现子串** `no-op`（closeout 会整行当成 no-op）。
- 真无变更：整行 `Flow: no-op` 或 `Capability Index: no-op` 可以；若 git 工作区**触及**对应活文档，则改用下方 `updated` 模板（见 false-noop）。

## 推荐模板（技术壳层 / 无业务变更）

```text
- Capability Index: updated（docs/capability-map.md 修订记录；无业务行）
- Flow: updated（docs/flow.md 修订记录；无业务主流程变更）
- Living Docs: updated（AGENTS.md：…）
- Patterns: ADD docs/patterns/<name>.md
- Pitfalls: no-op
```

真无触及活文档时才允许：

```text
- Capability Index: no-op
- Flow: no-op
```

## false-noop：untracked 活文档

Gate-3 开始前：

```bash
git status --short docs/capability-map.md docs/flow.md
```

若为 `??`（untracked）或本次变更触及这些路径：写上方 `updated（修订记录；…）` 模板，勿写对应 no-op。工程建议：init 占位活文档尽早 `git add`。

**完成：** 标记与 `git status` 触及面一致；说明内无 `no-op` 子串（整行真 no-op 除外）。

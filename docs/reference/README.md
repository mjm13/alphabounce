# 上游参考源（vendored 真相源）

> 创建：2026-08-20 ｜ 关联：`document/复刻计划.md`、`docs/ASSETS.md`

## 为什么入库

本目录的内容原先只存在于本机 `E:\Project\Self\EternalTwin-Alphabounce\`。E: 盘卸载后：

- `alphabounce_ds_guide.txt`（25 种增益减益定义、27 星球规则、经济数值）丢失，
  P4 / P7 / P8 / P10 / P12 共 20 条 Must-Confirm OQ 全部失去拍板依据；
- 各需求「约束引用」中的 `.hx` 对照路径全部不可达，P2 那种「对照原版 `Block.hx` 验证」
  的验收方式无法复现。

因此把**体积小、且被需求直接引用的文本类真相源**入库，使其不再依赖任何本机路径。
大体积精灵不入本目录，见下文「资产」。

## 内容与上游对应

| 本地路径 | 上游路径 | 说明 |
|---|---|---|
| `alphabounce-facts.md` | —（本仓自写） | 从攻略与源码提取的事实，各阶段 OQ 的拍板依据 |
| `haxe/` | `frontend/src/haxe/` | 79 个 `.hx`，行为对照基准（`Block.hx` `Level.hx` `Random.hx` `Codec.hx` `Sound.hx` `ev/*` `el/*` `lander/*` `navi/*`） |
| `UPSTREAM-LICENSE.md` | `LICENSE.md` | 上游许可证正文 |

### 攻略全文不入库（转载限制）

`doc/alphabounce_ds_guide.txt` 并非官方设计文档，而是 Michael Lamparski 2010 年的玩家攻略
（GameFAQs），其条款明确禁止未经许可的在线转载，授权站点白名单仅 GameFAQs / neoseeker /
supercheats。因此**本仓不保存其全文**，改为按其 Fair Use 条款提取所需事实并标注出处，见
`alphabounce-facts.md`。本地全文位于 `../EternalTwin-Alphabounce/doc/`（工程外）。

另注：该攻略描述 **DSi 版**且为玩家视角，不含数值公式；凡生成算法与数值常量一律以
`haxe/` 源码为准。

**上游快照**：`https://gitlab.com/eternaltwin/alphabounce/alphabounce.git`
commit `3a0d5239fd67b6c42acd8cdb5512598b7423b79c`（2026-08-16 "Remove debug"）

重新获取完整上游（含精灵与字体）：

```bash
git clone --depth 1 https://gitlab.com/eternaltwin/alphabounce/alphabounce.git ../EternalTwin-Alphabounce
```

## 资产

4113 张精灵与 5 个字体不放本目录，由 `scripts/sync_assets.ps1` 从上游克隆镜像到
`android/assets/`。目录约定与消费映射见 `docs/ASSETS.md`。

## 许可证

上游为 **AGPL-3.0**（见 `UPSTREAM-LICENSE.md`），本工程为其衍生作品，整体须遵守 AGPL。
原版 2007（`WebGamesArchives`）为 CC BY-NC-SA 4.0，**非商业**；该份存档目前不在本机，
其被引用的模块（`Block.hx` `Random.hx` `Codec.hx` `Sound.hx` 等）在上游 EternalTwin
中均有对应文件，故约束引用统一指向本目录。

商业发布则 NC 资产不可用、须自绘或授权——该立场仍未拍板，见
`docs/requirements/inbox/20260818214312-AB-P12安卓打包与发布打磨.md` OQ-002。

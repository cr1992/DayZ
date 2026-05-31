# Spec 规范（DayZ · AI 执行版）

> **方法论规则的唯一真源 = [`../spec-kit/spec-guide.md`](../spec-kit/spec-guide.md)。**
> 本文件只放 **DayZ 专项 overlay**，**不复述规则**——历史上它曾是「Flutter 具体版」，与 kit 的「通用版」并存而 drift；
> 现已把规则统一收进 kit（含写时白名单默认 deny、`可改文件 ⊆ design 文件变更` 不变式等最新约定），本文降为薄 overlay。

## 规则看哪（都在 kit）

- 选档（精简/标准）、`R`/`NF`/`D` 编号、EARS 句式、任务卡字段、**验收抗规避（信任根）**、
  **可改文件 ⊆ design「## 文件变更」** 不变式、**硬执行闸**（死链/验收/关键词/白名单**默认 deny**+反馈模型）、
  归档（`archive_spec.sh`）、契约/不变式 spec、完整示例 —— **全在 [`../spec-kit/spec-guide.md`](../spec-kit/spec-guide.md)**。
- 闸的安装与用法（`install.sh --with-<agent>` / 兜底闸 / CI）—— [`../spec-kit/README.md`](../spec-kit/README.md)。
- 设计与缘由（为什么 deny、实操发现的问题、多-agent 适配）—— [`../spec-kit/docs/`](../spec-kit/docs/)。

## DayZ 占位映射（kit 是栈中立的，代入 DayZ 技术栈即可）

| kit 里的占位 | DayZ 实际 |
|---|---|
| `{测试运行器} {测试文件}` | `flutter test test/...` |
| 源码后缀 `.{ext}` / 目录 `src/` | `.dart` / `lib/` |
| 测试目录与命名 | `test/`，`*_test.dart`（白名单 hook 已按此约定自动放行） |
| 「状态容器 / 持久化层」等中性词 | 对应 DayZ 的状态方案、Drift + Repository 数据层 |

> 验收命令闸的「源码后缀」与白名单 hook 的「测试文件自动放行」已是 Dart 约定，无需再裁剪（见 `../spec-kit/README.md`「按你的技术栈裁剪」）。

## DayZ 专项约定（在通用规则之上的加法，记此以免污染通用 kit）

- **视觉验收的默认升级**：通用规则说「确实无法自动化的（视觉/真机/人因）走人工核查项，禁止用假装能测的 grep 凑数」。
  DayZ 在 UI 还原线把默认从 *default-人工* 升级为 *default-确定性闸（参数/几何断言）+ golden/SSIM 自动验，视觉模型/人眼仅标红终审、不阻断*——
  详见 [`design/10-ui-restore-and-design-sync.md`](./design/10-ui-restore-and-design-sync.md)，随 `design-sync-automation` spec 定稿。UI 还原默认走闸① token / 闸②样式参数 / 闸③布局几何 of 确定性硬闸，闸④ golden/SSIM 自动验为 advisory；人工或视觉模型只做标红终审，不作为阻塞闸。**「禁止假装能测的 grep」红线不变**。
- **状态命名统一**：DayZ 直接采用 kit 的生命周期状态 `草稿 / 待实现 / 进行中 / 已完成 / 已废弃`；已写完但尚未开始实现的 spec 用 README 状态 `待实现`，不再使用 `已预审`。文件头 `文档状态` 只表达文档成熟度，取值仍为 `草稿 / 定稿`。
- **屏幕 spec 维护态泳道（唯一例外，通用归档规则不变）**：默认仍遵守 [`../spec-kit/spec-guide.md`](../spec-kit/spec-guide.md) 的生命周期规则：spec 完成后归档，后续新需求另开 spec。唯一例外是 DayZ UI 页面级 / 屏幕级 spec：交付 v1 后不移入 `specs/archive/`，而转入 `specs/README.md` 的「已交付·随设计维护」泳道，用来承接后续设计稿同步卡；对齐状态以 `specs/active/design-sync-automation/screens.yaml` 的 `pinned`、各屏 `test/ui/<feature>/element-map.yaml`、参数 fixture 与 golden 为准，不从 `specs/archive/` 复活屏幕 spec。这不是「未完成」，也不参与普通 active spec 的优先级竞争；非屏幕 spec 不得借用此例外。
- **设计变更三档分流**：设计稿 diff 的处理档位用语义名，不用编号。微调档 = 只 token 值 / 参数变、元素集和结构不变，自动同步且不碰 spec；实质档 = 未映射类 / 新 `data-when` / DOM 结构重排 / 新交互，在对应屏幕维护态 spec 追加 sync 卡并补映射；大改档 = 信息架构或导航变化，开新 active spec。判定信号由 `design-sync-automation` 的确定性检测器输出驱动，禁止用 agent 主观判断替代。
- **UI 页面级 spec 的优先级 = 页面层级 × 数据依赖就绪**：通用「排序维护纪律」（见 [`../spec-kit/spec-guide.md`](../spec-kit/spec-guide.md)）落到 DayZ UI 线时再加一条——页面级 spec 之间的先后**按页面层级（导航树深度：外壳 → 入口 / landing 页 → 次级页 → 叶子页）细排**，并叠加「该页所依赖的底层数据 spec 是否就绪」这一硬门。三档拆分与波次（W0 基础层 → W1 ui-kit/shell → W2 页面级并行 → W3/W4 依附件）见 [`design/10-ui-restore-and-design-sync.md`](./design/10-ui-restore-and-design-sync.md) §9；**页面层级与屏清单一律以设计稿真源 `ui-design/current/` 为准，不在规范里写死屏数 / 屏清单**。
- （后续 DayZ 专项约定追加于此；通用规则的改动一律去改 [`../spec-kit/spec-guide.md`](../spec-kit/spec-guide.md)，不在本文重复。）

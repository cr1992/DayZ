---
作者：@Ray
创建日期：2026-05-29
最后更新：2026-05-29
文档状态：定稿
---

# 验证：design-tokens-theme

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 六套主题取值 | 经六套 ThemeData 各取 `context.dayz` | 全部 token 非空，accent 等于该 theme×mode 真值 | R1 | 自动 |
| token 机械生成一致 | 跑 `gen_tokens` 后比对 `.g.dart` 与 `tokens.css` | 每值逐项一致（hex/rgba/多层 shadow 全对） | R2 | 自动 |
| 解析失败显形 | 喂畸形 `tokens.css` | 非零退出、不产出文件 | R5 | 自动 |
| 生成确定性 | 同输入跑两次 | 产出逐字节一致（diff 为空） | NF3 | 自动 |
| 三份同源 | 跑 `check_tokens_sync.sh`（一致 / 人为分叉两输入） | 一致 exit 0；分叉 exit 非零并指出 | R3 | 自动 |
| 字体回退 | 渲染中英混排 | Latin 走品牌字、CJK 走系统回退，无缺字 | R4 | 自动 + 人工 |
| 排版角色与行高 | 取 `.t-*` 各角色 TextStyle | UI 正文 height 1.7、日记 1.85、`leadingDistribution` even、字族符合 R4 | R6 | 自动 |

## 专项检查

### 无障碍（NF1）
> 按 `ThemeData` 实际**渲染对**算相对亮度比，**断言值**、不 grep token 文件；六套逐项。
- [ ] `--ink`、`--ink-2` 对底（bg/surface）≥ 4.5:1 — 自动：`flutter test test/ui/theme/contrast_test.dart`（实测安全）
- [ ] `--accent-ink` 落 accent-soft/浅底 ≥ 4.5:1（着色文字）— 自动：同上
- [ ] `--on-accent` 落 `--accent`（按钮文字，非大字）≥ 4.5:1 — 自动：同上（**已知 sage 3.97 expected-fail → 阻塞、报 @Ray 调 token**）
- [ ] `--accent` 当有意义 UI（聚焦/选中边/图标）贴 bg ≥ 3.0:1 — 自动：同上（**已知 amber 2.43 expected-fail → 阻塞、报 @Ray**）
- [ ] `--ink-3` 作真实辅助文本 ≥ 4.5:1（纯 placeholder 豁免）— 自动：同上（**已知 2.77 expected-fail → 阻塞、报 @Ray 或改用 ink-2**）
> 三条 expected-fail 已在 design `## 已知风险` 预登记；测试遇到须**显形并阻塞放行**（不静默通过），待 @Ray 调 token 后转通过。`--accent` 当正文/链接（purple 4.32 / sage 3.71）设计未走此路径，不验。

### 多端兼容（NF2）
- [ ] iOS 13+ 真机/模拟器：Latin 品牌字 + CJK（PingFang/Songti）回退正常 — 人工（@Ray）
- [ ] Android 8+ 真机/模拟器：Latin 品牌字 + CJK（PingFang→Noto 回退）观感可接受 — 人工（@Ray）

> 数据迁移 / 回滚：本 spec 无持久化 schema 变更或数据格式演进 → 整段省略（不涉及）。

## 回归检查
- [ ] Debug Home 仍可正常构建与遍历（主题画廊追加未破坏既有 demo） — 自动：`flutter test test/demo/debug_home_test.dart`（回归）
- [ ] `flutter analyze` 无新增告警 — 自动：`flutter analyze`（回归）

## 需求↔验证覆盖核验（双向闭环）
> 闭环检查，任一不通过则 verification 未定稿。
- [ ] 正向：R1（六套取值）、R2（生成一致）、R3（同源）、R4（字体）、R5（解析失败）、R6（排版/行高）、NF1（对比度，含三处 expected-fail）、NF2（多端）、NF3（确定性）均有对应场景/专项检查覆盖，无孤儿需求。
- [ ] 反向：各验证项「关联需求」均指向真实 R/NF；回归项（Debug Home / analyze）已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项）
```bash
flutter test test/ui/theme/        # gen/colors/text_theme/theme/contrast/font_bundle
bash test/scripts/check_tokens_sync_test.sh
flutter test test/demo/            # 主题画廊 + Debug Home 回归
flutter analyze
```

> 共享测试基建说明：`*_test.dart`（含 `contrast_test.dart`、`gen_tokens_test.dart`、`font_bundle_test.dart`）由白名单 hook 对 `test/**/*_test.dart` **无条件放行、无需预批**；真正需预批的是非 `_test.dart` 的共享基建——`test/ui/theme/fixtures/`（对抗 CSS + 期望 Dart）与 `test/scripts/check_tokens_sync_test.sh`，已在 T1/T6 的 inline `验收基建` 字段预批（执行协议第 2 条）。`contrast_test.dart` 属跨主题专项、归 verification，自动放行。

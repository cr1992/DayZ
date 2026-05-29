# DayZ 设计稿 · Flutter 验收回馈（design-side todo）

> 本文件是 **Flutter 端验收 → 设计侧待调** 的回馈渠道，放在 `ui-design/` 根（**不在 `current/` 内**）——`dayz-design-sync` 同步时以 `rsync --delete` 整体替换 `current/`，写进 `current/docs/BACKLOG.md` 会被下次同步覆盖；根级文件不受影响。
> 这里只记 todo，**不擅自改 `tokens.css`**（设计稿真源）。调色请在设计稿 `tokens.css` 落实后回这里勾掉；理想终点是同步进设计工具自身的 BACKLOG。
> **机器真源**：CI / design-sync 读的 xfail allowlist 在仓内 `test/ui/theme/contrast_xfail.yaml`（机器可读，单一来源）；本文件是给人看的设计侧 todo，二者勿各写一份数值——调色后两处同步勾掉。

## 待调：强调色 / 辅助色对比度未达 WCAG（来自 `specs/active/design-tokens-theme` NF1，2026-05-29）

光模式实测三处不达标（dark 全套 ≥6.5，健康）。这是 NF1 的**「阻塞放行」**项——**不调则 `design-tokens-theme` 的 NF1 / T7 验收无法转绿**，实现到 T7 才撞红就晚了，故前置记此。

- [ ] **sage 按钮白字 on accent = 3.97**（< 4.5；`.btn-primary` 15px/600 非大字、不可豁免）→ 建议 sage `--accent` 向 `--accent-strong` 加深 / `--on-accent` 改深墨。
- [ ] **amber accent 当聚焦框 / 选中边 / 选中图标贴 bg = 2.43**（< 3.0；`.input:focus` / `.opt.on` / `.mood.sel`）→ amber light `--accent` 加深到 ≥ 3.0（≈ 现 `--accent-strong`）。
- [ ] **ink-3 当真实辅助文本 = 2.77**（< 4.5；`.entry .date .m` / `.tl-month .c` / `.field .help` / 空态 meta）→ `--ink-3` 加深，或这些场景改用 `--ink-2`（5.5 ✓）；纯 placeholder 保留豁免。

> 不在待调之列：`accent` 当正文 / 链接（purple 4.32 / sage 3.71）——设计未走此路径，着色文字一律用 `accent-ink` 落 `accent-soft`/浅底（三套 ≥ 5.0）。

---
作者：@Ray
创建日期：2026-05-30
最后更新：2026-05-30
文档状态：草稿
---

# 验证：i18n-localization

## 功能验证（端到端）
| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 系统中文 | 系统 locale=zh 启动 | UI 显示中文 | R2, R3 | 自动 |
| 系统英文 | 系统 locale=en 启动 | UI 显示英文 | R2, R3 | 自动 |
| 不支持语言回退 | 系统 locale=fr 启动 | 回退中文 | R3 | 自动 |
| 手动切换即时生效 | 经 LocaleController 切到 en | 界面即时变英文，无需重启 | R5 | 自动 |
| 偏好持久化 | 切到 en 后重启（重读 prefs） | 仍为英文 | R5 | 自动 |
| 跟随系统复位 | followSystem() 后重启 | 回到跟随系统 | R5 | 自动 |
| 复数（中） | zh 下取 onThisDayCount(0/1/3) | 各返回正确中文复数串 | R4, R6 | 自动 |
| 复数（英） | en 下取 onThisDayCount(0/1/3) | 各返回正确英文复数串（one/other） | R4, R6 | 自动 |

## 专项检查

### 多端兼容（NF1）
- [ ] iOS 13+ 切系统语言 zh/en，文案正确、中文 CJK 字形正常（系统字回退）— 人工（@Ray）
- [ ] Android 8+ 切系统语言 zh/en，文案正确、中文 CJK 字形正常（多落 Noto CJK）— 人工（@Ray）

### 翻译完整性 / key 对齐（NF2）
- [ ] `app_zh.arb` 与 `app_en.arb` key 集合完全一致（无缺漏/孤儿）— 自动：`bash scripts/check_arb_sync.sh`
- [ ] 缺一个翻译时校验报错（故障注入夹具）— 自动：`bash test/scripts/check_arb_sync_test.sh`

### 生成确定性 / 可复现（NF3）
- [ ] 连续两次 `flutter gen-l10n` 后 `git diff lib/l10n/gen/` 为空 — 人工（@Ray，跑两次比对）
- [ ] 生成产物已纳入版本库、未被 gitignore — 自动：`git ls-files --error-unmatch lib/l10n/gen/app_localizations.dart && ! git check-ignore -q lib/l10n/gen/app_localizations.dart`

## 回归检查
- [ ] Debug Home 既有 demo 不受影响（仅末尾追加一行 i18n demo）— 自动：`flutter test test/demo/`（回归）
- [ ] App 启动不因 localizationsDelegates 接线报错 — 自动：`flutter test test/l10n/material_app_locale_test.dart`（回归）

## 需求↔验证覆盖核验（双向闭环）
- [ ] 正向：R1（T2 生成测试）、R2/R3（material_app_locale_test）、R4（arb + app_localizations_test）、R5（locale_controller_test + 持久化场景）、R6（复数场景 + i18n_demo_test）、NF1（多端人工）、NF2（check_arb_sync）、NF3（幂等 + 入库）均有验证，无孤儿需求。
- [ ] 反向：各验证项「关联需求」均指向真实 R/NF；回归项已显式标「回归」，无孤儿测试。

## 验证命令（汇总自动项）
```bash
flutter test test/l10n/ test/demo/i18n_demo_test.dart
bash scripts/check_arb_sync.sh
bash test/scripts/check_arb_sync_test.sh
git ls-files --error-unmatch lib/l10n/gen/app_localizations.dart
```

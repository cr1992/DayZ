---
作者：@Ray
创建日期：2026-05-23
最后更新：2026-05-23
文档状态：草稿
---

# 验证：app-scaffold

> 跨任务质量校验。命中：多端兼容（NF1, NF3）、性能（NF2）、可扩展（NF4）。

## 功能验证（端到端）

| 场景 | 操作 | 预期结果 | 关联需求 | 方式 |
|------|------|----------|----------|------|
| 冷启动 | 杀进程 → 启动 | 进入 Debug Home（不是 counter） | R3 | 人工（@Ray） |
| Demo 列表 | 滑动 Debug Home | 至少看到 Hello Demo | R4, R5 | 自动 widget test |
| 进入 Demo | 点 Hello Demo | 进入页面看到 "Hello, DayZ demo!" | R5 | 自动 widget test |
| 返回 | 在 demo 页 back | 回到 Debug Home | R4 | 自动 widget test |
| 扩展新 demo | 在 demos 末尾加一行 | Debug Home 自动多一行 | NF4 | 人工（@Ray） |

## 专项检查

### 性能（NF2）
- [ ] iOS 真机冷启动到 Debug Home 可交互 < 2s — 人工（@Ray），秒表 / 录屏帧计
- [ ] Android 真机同上 — 人工（@Ray）

### 多端兼容（NF1, NF3）
- [ ] iOS 13 设备/模拟器可安装并启动 — 人工（@Ray）
- [ ] Android 8（API 26）设备/模拟器可安装并启动 — 人工（@Ray）
- [ ] `flutter build apk --debug` 退出码 0 — 自动
- [ ] `flutter build ios --debug --no-codesign` 退出码 0 — 自动

### 可扩展（NF4）
- [ ] 新增一个 demo 仅动 `demo_entry.dart`（demos 列表）+ 一个新文件 — 人工（@Ray），通过 `git diff` 审查

## 回归检查

> 项目首次落地，无既有功能需回归。

## 验证命令（汇总自动项）

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --debug --no-codesign
```

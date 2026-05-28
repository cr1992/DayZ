---
作者：@Ray
创建日期：2026-05-29
---

# assets-management（类型安全静态资源引用 + assets 目录规范）

## 背景

`docs/design/07-static-resource-management-scheme.md` 定调：内置静态资源（图片、图标、字体、动效等）若用硬编码字符串路径引用（如 `Image.asset('assets/images/logo.png')`）易拼写错、重构时静态分析无法发现问题。方案是用 **`flutter_gen`** 自动生成类型安全的资源引用类，并统一 `assets/` 目录结构。

本能力原误并入 data-layer（其 R9/D11/T15），但与「数据层」职责无关、编号也脱离 data-layer 的 R1–R8 序列，故剥离为独立 spec 承接。属精简档：单模块、纯本地构建工具、无安全/性能/无障碍/多端专项约束、任务数 ≤ 8。

## 范围外

- 具体业务图片/图标/字体资产本体的设计与入库（按需各功能 spec 自带）。
- 图片无损压缩、多倍率切图等运维流程（design 07 第 4 节，归资产入库时执行，不在本期建基础设施范围）。
- Icon Font（.ttf 打包）与 `flutter_svg` 的实际接入——本期仅建目录占位与生成基础设施；用到时由对应 UI spec 接入。

## 需求

### R1 · 类型安全资源引用
系统 MUST 提供类型安全的静态资源访问能力（经 `flutter_gen` 生成 `lib/gen/assets.gen.dart`），代码中引用内置资源 MUST 用强类型类（如 `Assets.images.xxx`）而非硬编码字符串路径。
- 前提：`assets/` 下存在一个资源文件
- 操作：运行代码生成命令
- 结果：`lib/gen/assets.gen.dart` 生成，含对应强类型引用类，IDE 可补全、编译期可类型检查

### R2 · assets 目录规范
内置资源 MUST 统一放在根目录 `assets/` 下，并按类别分子目录，至少建立 design 07 第 2 节规定的分类：`assets/images/`、`assets/icons/`、`assets/fonts/`（`editor/`、`lotties/` 按需扩展）。
- 前提：项目根目录
- 操作：检视 `assets/` 结构
- 结果：存在 `images/`、`icons/`、`fonts/` 子目录；新增资源按类别归位，不散落根目录

### R3 · 生成工作流可复现
系统 MUST 把 `flutter_gen` 配置（`pubspec.yaml` 的 `flutter_gen`/`flutter.assets` 段 + `flutter_gen.yaml`）纳入版本库，使任意开发者 / CI 执行同一条生成命令 MUST 产出一致的 `lib/gen/assets.gen.dart`。
- 前提：干净检出
- 操作：`dart run build_runner build`
- 结果：生成文件就位，无需手工编辑；可重复执行结果幂等

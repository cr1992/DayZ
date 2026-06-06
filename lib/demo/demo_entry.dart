import 'package:flutter/material.dart';
import 'package:dayz/demo/hello_demo.dart';

import 'package:dayz/demo/editor_appflowy_demo.dart';
import 'package:dayz/demo/argon2id_ffi_demo.dart';
import 'package:dayz/demo/theme_gallery_demo.dart';
import 'package:dayz/security/demo.dart';
import 'package:dayz/data/demo.dart';
import 'package:dayz/demo/observability_demo.dart';
import 'package:dayz/demo/i18n_demo.dart';
import 'package:dayz/demo/widget_gallery_demo.dart';
import 'package:dayz/drafts/demo.dart';
import 'package:dayz/media/demo.dart';
import 'package:dayz/thumbnails/demo.dart';
import 'package:dayz/demo/shell_nav_demo.dart';
import 'package:dayz/backup/demo.dart';
import 'package:dayz/demo/reader_demo.dart';
import 'package:dayz/demo/timeline_demo.dart';
import 'package:dayz/demo/editor_screen_demo.dart';
import 'package:dayz/demo/settings_screen_demo.dart';

/// 新增 demo 在 demos 列表尾部追加，不在中间插入；不修改 DemoEntry 模型字段，避免影响其他模块。
class DemoEntry {
  final String title;
  final String? subtitle;
  final WidgetBuilder builder;

  const DemoEntry({required this.title, this.subtitle, required this.builder});
}

final List<DemoEntry> demos = [
  DemoEntry(
    title: 'Hello Demo',
    subtitle: '验证 demo 框架可用',
    builder: (context) => const HelloDemo(),
  ),
  DemoEntry(
    title: 'AppFlowy 编辑器 demo',
    subtitle: 'A 方案：纯 Dart 编辑器预研',
    builder: (context) => const EditorAppflowyDemo(),
  ),
  DemoEntry(
    title: 'argon2id_ffi demo',
    subtitle: '自研 Argon2id（手写 dart:ffi）在 app 内验证',
    builder: (context) => const Argon2idFfiDemo(),
  ),
  DemoEntry(
    title: '主题画廊 demo',
    subtitle: '设计 Token 与六套主题画廊',
    builder: (context) => const ThemeGalleryDemo(),
  ),
  DemoEntry(
    title: 'Security',
    subtitle: '密钥与 Argon2 派生',
    builder: (context) => const SecurityDemo(),
  ),
  DemoEntry(
    title: '可观测性',
    subtitle: '日志与可观测性基建',
    builder: (context) => const ObservabilityDemo(),
  ),
  DemoEntry(
    title: 'i18n Demo',
    subtitle: '国际化：语言切换 + 文案取值示范',
    builder: (context) => const I18nDemo(),
  ),
  DemoEntry(
    title: 'UI Kit 组件画廊',
    subtitle: '原生画廊：组件 × 状态 × 六套主题',
    builder: (context) => const WidgetGalleryDemo(),
  ),
  DemoEntry(
    title: 'Data demo',
    subtitle: 'Drift Repository 插入 / 查询 / 软删除',
    builder: (context) => const DataDemo(),
  ),
  DemoEntry(
    title: 'Drafts demo',
    subtitle: '自动保存草稿与恢复状态演示',
    builder: (context) => const DraftsDemo(),
  ),
  DemoEntry(
    title: 'Media demo',
    subtitle: '媒体加密写入 / 读取 / 备份重加密',
    builder: (context) => const MediaDemo(),
  ),
  DemoEntry(
    title: '缩略图缓存 demo',
    subtitle: '缩略图生成 / 脏重建 / 取消与预热',
    builder: (context) => const ThumbnailsDemo(),
  ),
  // 各模块 demo 在此追加
  DemoEntry(
    title: '外壳与导航 demo',
    subtitle: 'AppShell 外壳、导航抽屉与 FAB 二级动作交互',
    builder: (context) => const ShellNavDemo(),
  ),
  DemoEntry(
    title: '备份与恢复 demo',
    subtitle: '整库备份（.mydiary）与覆盖式还原演示',
    builder: (context) => const BackupDemo(),
  ),
  DemoEntry(
    title: 'Reader demo',
    subtitle: '阅读页 UI 状态演示',
    builder: (context) => const ReaderDemo(),
  ),
  DemoEntry(
    title: '编辑页 demo',
    subtitle: '编辑页三状态与六套主题演示',
    builder: (context) => const EditorScreenDemo(),
  ),
  DemoEntry(
    title: '时间线屏 demo',
    subtitle: '时间线首页、月级跳转与空态切换',
    builder: (context) => const TimelineDemo(),
  ),
  DemoEntry(
    title: '设置屏 demo',
    subtitle: '设置屏、红线文案与回调上抬演示',
    builder: (context) => const SettingsScreenDemo(),
  ),
];

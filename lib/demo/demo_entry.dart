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
    subtitle: 'Widgetbook：组件 × 状态 × 六套主题',
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
  // 各模块 demo 在此追加
];

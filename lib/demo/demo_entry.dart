import 'package:flutter/material.dart';
import 'package:dayz/demo/hello_demo.dart';

import 'package:dayz/demo/editor_appflowy_demo.dart';
import 'package:dayz/demo/editor_webview_tiptap_demo.dart';

/// 新增 demo 在 demos 列表尾部追加，不在中间插入；不修改 DemoEntry 模型字段，避免影响其他模块。
class DemoEntry {
  final String title;
  final String? subtitle;
  final WidgetBuilder builder;

  const DemoEntry({
    required this.title,
    this.subtitle,
    required this.builder,
  });
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
    title: 'WebView+TipTap 编辑器 demo',
    subtitle: 'B 方案：WebView 离线打包预研',
    builder: (context) => const EditorWebviewTiptapDemo(),
  ),
  // 各模块 demo 在此追加
];

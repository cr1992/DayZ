// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

// Author: @Ray

import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/data/database.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:dayz/thumbnails/demo.dart';
import 'package:dayz/thumbnails/generator.dart';

class MockKeyProvider extends KeyProvider {
  final Uint8List _key;
  MockKeyProvider(this._key);

  @override
  Future<Uint8List> getDeviceMediaKey() async {
    return _key;
  }
}

void main() {
  late AppDatabase db;
  late MockKeyProvider keyProvider;
  final deviceMediaKey = Uint8List.fromList(List.generate(32, (i) => i));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    keyProvider = MockKeyProvider(deviceMediaKey);
    disableIsolateForTesting = true;
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('ThumbnailsDemo widget and interactions', (
    WidgetTester tester,
  ) async {
    // 1. 验证 demos 列表中已注册
    final demoEntry = demos.firstWhere((d) => d.title == '缩略图缓存 demo');
    expect(demoEntry, isNotNull);

    // 2. 渲染 Demo 页面
    await tester.pumpWidget(
      MaterialApp(
        home: ThumbnailsDemo(database: db, keyProvider: keyProvider),
      ),
    );

    // 3. 验证按钮是否渲染
    expect(find.text('插入 demo 大图'), findsOneWidget);
    expect(find.text('生成缩略图 (request)'), findsOneWidget);
    expect(find.text('显示缩略图 (解密渲染)'), findsOneWidget);
    expect(find.text('篡改原图 updated_at'), findsOneWidget);
    expect(find.text('取消生成 (cancel)'), findsOneWidget);
    expect(find.text('批量预热 10 张 (warmup)'), findsOneWidget);
    expect(find.text('系统消息: 未开始'), findsOneWidget);

    // 4. 测试“生成缩略图”按钮但无大图时的拦截
    await tester.tap(find.text('生成缩略图 (request)'));
    await tester.pumpAndSettle();
    expect(find.text('系统消息: 错误：请先插入 demo 大图'), findsOneWidget);
  });
}

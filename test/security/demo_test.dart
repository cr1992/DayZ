// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/security/demo.dart';
import 'package:dayz/security/key_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Security demo', () {
    test('demos 列表中包含 Security 入口', () {
      final entry = demos.firstWhere((d) => d.title == 'Security');
      expect(entry.subtitle, '密钥与 Argon2 派生');
    });

    testWidgets('Debug Home 渲染 Security 入口', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: DebugHome()));

      expect(find.text('Security'), findsOneWidget);
      expect(find.text('密钥与 Argon2 派生'), findsOneWidget);
    });

    testWidgets('SecurityDemo 渲染设备密钥状态与当前模式', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SecurityDemo(
            deviceKeyExists: () async => true,
            modeLoader: () async => AppPasswordMode.password,
            deriveBenchmarker: () async => const Duration(milliseconds: 123),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('设备密钥状态'), findsOneWidget);
      expect(find.text('已生成'), findsOneWidget);
      expect(find.text('当前模式'), findsOneWidget);
      expect(find.text('password'), findsOneWidget);
    });

    testWidgets('点击派生按钮后展示耗时数字', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SecurityDemo(
            deviceKeyExists: () async => true,
            modeLoader: () async => AppPasswordMode.none,
            deriveBenchmarker: () async => const Duration(milliseconds: 123),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('触发一次 Argon2 派生'));
      await tester.pumpAndSettle();

      expect(find.textContaining('123 ms'), findsOneWidget);
    });
  });
}

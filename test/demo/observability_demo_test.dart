// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/demo/observability_demo.dart';
import 'package:dayz/observability/observability.dart';

import '../l10n/localized_test_app.dart';

void main() {
  group('ObservabilityDemo Registration & Widget Tests', () {
    test('demos list has Observability entry', () {
      expect(demos.isNotEmpty, isTrue);
      final entry = demos.firstWhere((e) => e.title == '可观测性');
      expect(entry.subtitle, '日志与可观测性基建');

      final context = DummyBuildContext();
      final widget = entry.builder(context);
      expect(widget, isA<ObservabilityDemo>());
    });

    testWidgets('ObservabilityDemo builds and interaction works', (
      WidgetTester tester,
    ) async {
      AppLogger.instance.setLevel(LogLevel.info);

      await tester.pumpWidget(
        localizedTestApp(child: const ObservabilityDemo()),
      );

      expect(find.text('可观测性演示'), findsOneWidget);
      expect(find.text('日志级别：INFO'), findsOneWidget);

      await tester.tap(find.text('记录 INFO'));
      await tester.pump();

      await tester.tap(find.text('WARN'));
      await tester.pump();
      expect(find.text('日志级别：WARNING'), findsOneWidget);

      await tester.tap(find.text('记录 WARN'));
      await tester.pump();

      await tester.tap(find.text('刷新状态'));
      await tester.pump();
    });

    testWidgets('ObservabilityDemo does not overflow on iPhone width', (
      WidgetTester tester,
    ) async {
      AppLogger.instance.setLevel(LogLevel.info);
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        localizedTestApp(child: const ObservabilityDemo()),
      );

      expect(find.text('可观测性演示'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class DummyBuildContext extends Fake implements BuildContext {}

// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/demo/observability_demo.dart';
import 'package:dayz/observability/observability.dart';

void main() {
  group('ObservabilityDemo Registration & Widget Tests', () {
    test('demos list has Observability entry', () {
      expect(demos.isNotEmpty, isTrue);
      final entry = demos.firstWhere((e) => e.title == 'Observability');
      expect(entry.subtitle, '日志与可观测性基建');

      final context = DummyBuildContext();
      final widget = entry.builder(context);
      expect(widget, isA<ObservabilityDemo>());
    });

    testWidgets('ObservabilityDemo builds and interaction works',
        (WidgetTester tester) async {
      AppLogger.instance.setLevel(LogLevel.info);
      
      await tester.pumpWidget(const MaterialApp(
        home: ObservabilityDemo(),
      ));

      expect(find.text('Observability Demo'), findsOneWidget);
      expect(find.text('Log Level: INFO'), findsOneWidget);

      await tester.tap(find.text('Log INFO'));
      await tester.pump();

      await tester.tap(find.text('WARN'));
      await tester.pump();
      expect(find.text('Log Level: WARNING'), findsOneWidget);

      await tester.tap(find.text('Log WARN'));
      await tester.pump();

      await tester.tap(find.text('Refresh Status'));
      await tester.pump();
    });
  });
}

class DummyBuildContext extends Fake implements BuildContext {}

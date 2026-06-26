// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/demo/timeline_demo.dart';

import '../l10n/localized_test_app.dart';

void main() {
  testWidgets(
    'TimelineDemo renders loaded timeline and can switch to empty state',
    (tester) async {
      await tester.pumpWidget(localizedTestApp(child: const TimelineDemo()));
      await tester.pumpAndSettle();

      expect(find.text('六月二十二日'), findsOneWidget);

      await tester.tap(find.text(testL10n.timelineEmptyTitle));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text(testL10n.timelineEmptyTitle), findsWidgets);
      expect(find.text(testL10n.timelineEmptyDescription), findsOneWidget);
    },
  );

  testWidgets('demos registers the timeline demo entry', (tester) async {
    final entry = demos.firstWhere((e) => e.title == '时间线屏 demo');

    await tester.pumpWidget(
      localizedTestApp(child: Builder(builder: entry.builder)),
    );

    expect(find.byType(TimelineDemo), findsOneWidget);
  });

  testWidgets('Debug Home can navigate to timeline demo from real demos list', (
    tester,
  ) async {
    await tester.pumpWidget(localizedTestApp(child: const DebugHome()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('时间线屏 demo'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('时间线屏 demo'));
    await tester.pumpAndSettle();

    expect(find.byType(TimelineDemo), findsOneWidget);
    expect(find.text('六月二十二日'), findsOneWidget);
  });
}

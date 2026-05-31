// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import 'package:dayz/demo/debug_home.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/demo/reader_demo.dart';
import 'package:dayz/ui/reader/reader_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../l10n/localized_test_app.dart';

void main() {
  test('demos list exposes reader demo', () {
    final entry = demos.singleWhere((entry) => entry.title == 'Reader demo');

    expect(entry.subtitle, '阅读页 UI 状态演示');
    expect(entry.builder, isNotNull);
  });

  testWidgets('ReaderDemo renders default and text-only states', (
    tester,
  ) async {
    await tester.pumpWidget(localizedTestApp(child: const ReaderDemo()));
    await tester.pump();

    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.text('雨后的院子'), findsWidgets);
    expect(find.byKey(ReaderScreen.heroKey), findsOneWidget);

    await tester.tap(find.text('纯文字'));
    await tester.pump();
    await tester.pump();

    expect(find.text('只写文字的一天'), findsWidgets);
    expect(find.byKey(ReaderScreen.heroKey), findsNothing);
  });

  testWidgets('Debug Home can navigate to reader demo', (tester) async {
    await tester.pumpWidget(localizedTestApp(child: const DebugHome()));

    await tester.scrollUntilVisible(
      find.text('Reader demo'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Reader demo'), findsOneWidget);

    await tester.tap(find.text('Reader demo'));
    await tester.pumpAndSettle();

    expect(find.byType(ReaderDemo), findsOneWidget);
    expect(find.byType(ReaderScreen), findsOneWidget);
  });
}

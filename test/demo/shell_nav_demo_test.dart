// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/demo/demo_entry.dart';
import 'package:dayz/demo/shell_nav_demo.dart';
import '../l10n/localized_test_app.dart';

void main() {
  Widget buildTestApp() {
    return localizedTestApp(child: const ShellNavDemo());
  }

  testWidgets(
    'ShellNavDemo renders correctly and contains AppShell and placeholder journals',
    (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // AppShell title defaults to "全部日记"
      expect(find.text(testL10n.allJournals), findsOneWidget);

      // Open drawer
      final menuBtn = find.bySemanticsLabel(testL10n.menu);
      await tester.tap(menuBtn);
      await tester.pumpAndSettle();

      // Verify stub/mock journals in the drawer
      expect(find.text('工作日志'), findsOneWidget);
      expect(find.text('生活随笔'), findsOneWidget);
      expect(find.text('灵感便签'), findsOneWidget);
    },
  );

  testWidgets('ShellNavDemo selecting journal updates main text', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Open drawer
    await tester.tap(find.bySemanticsLabel(testL10n.menu));
    await tester.pumpAndSettle();

    // Select "生活随笔"
    await tester.tap(find.bySemanticsLabel('生活随笔'));
    await tester.pumpAndSettle();

    // Verify main screen updates to "生活随笔"
    expect(find.text('生活随笔'), findsOneWidget);
  });

  testWidgets('ShellNavDemo new journal adds it to the list in memory', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Open drawer
    await tester.tap(find.bySemanticsLabel(testL10n.menu));
    await tester.pumpAndSettle();

    // Tap new journal icon
    await tester.tap(find.bySemanticsLabel(testL10n.newJournal));
    await tester.pumpAndSettle();

    // Form sheet should be open. Type a new name
    await tester.enterText(find.byType(TextField), 'Travel Journal');
    await tester.pumpAndSettle();

    // Confirm
    await tester.tap(find.text(testL10n.sheetCreate));
    await tester.pumpAndSettle();

    // Open drawer again to verify Travel Journal was added
    await tester.tap(find.bySemanticsLabel(testL10n.menu));
    await tester.pumpAndSettle();

    expect(find.text('Travel Journal'), findsOneWidget);
  });

  testWidgets('demos list contains ShellNavDemo entry', (tester) async {
    final entry = demos.singleWhere(
      (entry) => entry.title == '外壳与导航 demo',
      orElse: () => throw StateError('ShellNavDemo entry not found'),
    );

    await tester.pumpWidget(
      localizedTestApp(child: Builder(builder: entry.builder)),
    );

    expect(find.byType(ShellNavDemo), findsOneWidget);
  });
}

// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/ui/shell/app_router.dart';
import '../../l10n/localized_test_app.dart';

/// Test application wrapper.
Widget _routerTestApp() => localizedRouterTestApp(routerConfig: appRouter);

/// Unit & widget tests for [appRouter] configuration.
///
/// Author: @Ray
void main() {
  testWidgets('initial location is timeline placeholder screen', (
    tester,
  ) async {
    await tester.pumpWidget(_routerTestApp());
    await tester.pumpAndSettle();

    expect(find.text(testL10n.timeline), findsAtLeastNWidgets(1));
    expect(find.text(testL10n.shellPlaceholderSuffix), findsOneWidget);
  });

  testWidgets('timeline shell exposes on-this-day icon navigation', (
    tester,
  ) async {
    appRouter.go(Routes.timelinePath);
    await tester.pumpWidget(_routerTestApp());
    await tester.pumpAndSettle();

    final onThisDayButton = find.bySemanticsLabel(testL10n.onThisDay);
    expect(onThisDayButton, findsOneWidget);

    await tester.tap(onThisDayButton);
    await tester.pumpAndSettle();

    expect(find.text(testL10n.onThisDay), findsAtLeastNWidgets(1));
    expect(find.text(testL10n.shellPlaceholderSuffix), findsOneWidget);
  });

  testWidgets('navigating to all valid routes renders correct title', (
    tester,
  ) async {
    await tester.pumpWidget(_routerTestApp());
    await tester.pumpAndSettle();

    final routesToTest = {
      Routes.timeline: testL10n.timeline,
      Routes.reader: testL10n.reader,
      Routes.editor: testL10n.editor,
      Routes.onthisday: testL10n.onThisDay,
      Routes.search: testL10n.search,
      Routes.settings: testL10n.settings,
      Routes.calendar: testL10n.calendar,
      Routes.favorites: testL10n.favorites,
      Routes.trash: testL10n.trash,
      Routes.memory: testL10n.memoryCardExport,
      Routes.debugHome: testL10n.debugHome,
    };

    for (final entry in routesToTest.entries) {
      appRouter.goNamed(entry.key);
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsAtLeastNWidgets(1));
      if (entry.key != Routes.debugHome) {
        expect(find.text(testL10n.shellPlaceholderSuffix), findsOneWidget);
      }
    }
  });

  testWidgets('path constants navigate to placeholder screens', (tester) async {
    await tester.pumpWidget(_routerTestApp());
    await tester.pumpAndSettle();

    final pathsToTest = {
      Routes.timelinePath: testL10n.timeline,
      Routes.readerPath: testL10n.reader,
      Routes.editorPath: testL10n.editor,
      Routes.onthisdayPath: testL10n.onThisDay,
      Routes.searchPath: testL10n.search,
      Routes.settingsPath: testL10n.settings,
      Routes.calendarPath: testL10n.calendar,
      Routes.favoritesPath: testL10n.favorites,
      Routes.trashPath: testL10n.trash,
      Routes.memoryPath: testL10n.memoryCardExport,
    };

    for (final entry in pathsToTest.entries) {
      appRouter.go(entry.key);
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsAtLeastNWidgets(1));
      expect(find.text(testL10n.shellPlaceholderSuffix), findsOneWidget);
    }
  });

  testWidgets('navigating to invalid path redirects to error not-found page', (
    tester,
  ) async {
    await tester.pumpWidget(_routerTestApp());
    await tester.pumpAndSettle();

    appRouter.go('/some-invalid-path-that-does-not-exist');
    await tester.pumpAndSettle();

    expect(find.text(testL10n.notFound), findsOneWidget);
  });
}

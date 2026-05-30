// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dayz/ui/shell/app_router.dart';
import 'package:dayz/ui/strings/app_strings.dart';
import 'package:dayz/ui/theme/dayz_theme.dart';

/// Test application wrapper.
class _RouterTestApp extends StatelessWidget {
  const _RouterTestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      theme: DayzThemes.purpleLight,
    );
  }
}

/// Unit & widget tests for [appRouter] configuration.
///
/// Author: @Ray
void main() {
  testWidgets('initial location is timeline placeholder screen', (
    tester,
  ) async {
    await tester.pumpWidget(const _RouterTestApp());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.timeline), findsOneWidget);
    expect(find.text(AppStrings.shellPlaceholderSuffix), findsOneWidget);
  });

  testWidgets('navigating to all valid routes renders correct title', (
    tester,
  ) async {
    await tester.pumpWidget(const _RouterTestApp());
    await tester.pumpAndSettle();

    final routesToTest = {
      Routes.timeline: AppStrings.timeline,
      Routes.reader: AppStrings.reader,
      Routes.editor: AppStrings.editor,
      Routes.onthisday: AppStrings.onThisDay,
      Routes.search: AppStrings.search,
      Routes.settings: AppStrings.settings,
      Routes.calendar: AppStrings.calendar,
      Routes.favorites: AppStrings.favorites,
      Routes.trash: AppStrings.trash,
      Routes.memory: AppStrings.memoryCardExport,
      Routes.debugHome: AppStrings.debugHome,
    };

    for (final entry in routesToTest.entries) {
      appRouter.goNamed(entry.key);
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsOneWidget);
      if (entry.key != Routes.debugHome) {
        expect(find.text(AppStrings.shellPlaceholderSuffix), findsOneWidget);
      }
    }
  });

  testWidgets('path constants navigate to placeholder screens', (tester) async {
    await tester.pumpWidget(const _RouterTestApp());
    await tester.pumpAndSettle();

    final pathsToTest = {
      Routes.timelinePath: AppStrings.timeline,
      Routes.readerPath: AppStrings.reader,
      Routes.editorPath: AppStrings.editor,
      Routes.onthisdayPath: AppStrings.onThisDay,
      Routes.searchPath: AppStrings.search,
      Routes.settingsPath: AppStrings.settings,
      Routes.calendarPath: AppStrings.calendar,
      Routes.favoritesPath: AppStrings.favorites,
      Routes.trashPath: AppStrings.trash,
      Routes.memoryPath: AppStrings.memoryCardExport,
    };

    for (final entry in pathsToTest.entries) {
      appRouter.go(entry.key);
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsOneWidget);
      expect(find.text(AppStrings.shellPlaceholderSuffix), findsOneWidget);
    }
  });

  testWidgets('navigating to invalid path redirects to error not-found page', (
    tester,
  ) async {
    await tester.pumpWidget(const _RouterTestApp());
    await tester.pumpAndSettle();

    appRouter.go('/some-invalid-path-that-does-not-exist');
    await tester.pumpAndSettle();

    expect(find.text('Not Found'), findsOneWidget);
  });
}
